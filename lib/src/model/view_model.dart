// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flextable/src/builders/shared_text_controller.dart';
import 'package:flextable/src/model/model.dart';
import '../../flextable.dart';
import '../gesture_scroll/table_animation_controller.dart';
import '../gesture_scroll/table_drag_details.dart';
import '../gesture_scroll/table_scroll_activity.dart';
import '../gesture_scroll/table_scroll_physics.dart';
import '../listeners/inner_change_notifiers.dart';
import '../panels/flextable_context.dart';
import 'properties/flextable_freeze_change.dart';
import 'properties/flextable_grid_layout.dart';
import 'properties/flextable_header_properties.dart';
import 'properties/flextable_selection_index.dart';
import 'scroll_metrics.dart';

const precisionMargin = 0.01;

enum SplitChange { start, edit, no }

typedef _SetPixels = Function(int scrollIndexX, int scrollIndexY, double value);

typedef ChangedCellValueCallback<C extends AbstractCell> = Function(
    FtIndex index, C? previous, C? next);

enum DrawScrollBar { left, top, right, bottom, multiple, none }

ScrollDirection get userScrollDirectionY => _userScrollDirectionY;
ScrollDirection _userScrollDirectionY = ScrollDirection.idle;

ScrollDirection get userScrollDirectionX => _userScrollDirectionX;
ScrollDirection _userScrollDirectionX = ScrollDirection.idle;

// TableDragDecision dragDecision;

class FtViewModel<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends ChangeNotifier
    with TableScrollMetrics
    implements TableScrollActivityDelegate {
  FtViewModel({
    required this.physics,
    required this.context,
    FtViewModel<C, M>? oldPosition,
    required this.model,
    required this.tableBuilder,
    String? debugLabel,
    required InnerScrollChangeNotifier scrollChangeNotifier,
    required this.tableChangeNotifiers,
    required this.properties,
    this.changedCellValue,
    required this.scaleChangeNotifier,
    ScrollableState? sliverScrollable,
    required this.softKeyboard,
  })  : _scrollChangeNotifier = scrollChangeNotifier,
        sharedTextControllersByIndex =
            oldPosition?.sharedTextControllersByIndex ??
                SharedTextControllersByIndex() {
    ///
    ///
    this.scaleChangeNotifier
      ..addListener(changeScale)
      ..scale = model.tableScale
      ..min = properties.minTableScale
      ..max = properties.maxTableScale;

    model
      ..calculatePositionsX()
      ..calculatePositionsY();

    if (oldPosition case (FtViewModel vm) when vm.model == model) {
      firstLayout = false;
      _heightMainPanel = vm.heightMainPanel;
      _widthMainPanel = vm.widthMainPanel;
      previousEditCell = vm.previousEditCell;
      restoreScroll = vm.restoreScroll;
      scrollToEditCell = vm.scrollToEditCell;
      _editCell = vm.currentEditCell;
      modifySplit = vm.modifySplit;

      if (_editCell.isIndex) {
      } else if (previousEditCell.isIndex) {
        animateRestoreScroll();
      }
    }

    /// Scroll
    ///
    ///
    ///
    ///
    context.setCanDrag(true);

    if (activity == null) goIdle(0, 0);

    assert(activity != null);

    _adjustScroll = AdjustScroll(
        viewModel: this,
        scrollIndexX: 0,
        scrollIndexY: 0,
        direction: tableScrollDirection,
        vsync: context.vsync);

    sliverScrollPosition = sliverScrollable?.position;

    if (sliverScrollPosition != null &&
        sliverScrollPosition?.axis != Axis.vertical) {
      sliverScrollPosition = null;
    }

    // sliverScrollPosition?.addListener(notifyListeners);

    ///
    ///

    // ViewModel
    //
    //
    //
    //

    ratioSizeAnimatedSplitChangeX = stateSplitX != SplitState.split ? 0.0 : 1.0;
    ratioSizeAnimatedSplitChangeY = stateSplitY != SplitState.split ? 0.0 : 1.0;

    calculateHeaderWidth();

    _layoutIndex = List.generate(16, (int index) {
      int r = index % 4;
      int c = index ~/ 4;
      return LayoutPanelIndex(xIndex: c, yIndex: r);
    });

    _panelIndex = List.generate(16, (index) => index);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        scrollBarTrack = false;
        sizeScrollBarTrack = 0.0;

        break;
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        scrollBarTrack = true;
        sizeScrollBarTrack = thumbSize + paddingOutside + paddingInside;
        break;
    }

    if (model.tableScale < properties.minTableScale) {
      model.tableScale = properties.minTableScale;
    }

    if (model.tableScale > properties.maxTableScale) {
      model.tableScale = properties.maxTableScale;
    }
  }

  /// Layout
  ///
  ///
  ///
  bool firstLayout = true;
  bool softKeyboard;

  bool _mounted = true;
  bool get mounted => _mounted;

  ChangedCellValueCallback? changedCellValue;
  FtScaleChangeNotifier scaleChangeNotifier;

  changeScale() {
    if (scaleChangeNotifier.scale case double s when model.tableScale != s) {
      setTableScale(s);
    }

    if (scaleChangeNotifier.end) {
      correctOffScroll(0, 0);
    }
  }

  // Scroll
  //
  //
  //
  //
  //
  late AdjustScroll _adjustScroll;
  final FlexTableContext context;
  final TableScrollPhysics physics;
  final M model;
  final AbstractTableBuilder tableBuilder;
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);
  bool gridIndexAvailable = false;
  bool scrollNotificationEnabled = false;
  ScrollPosition? sliverScrollPosition;
  bool scrolling = false;

  HashSet<FtIndex> cellsToRemove = HashSet<FtIndex>();
  HashSet<FtIndex> cellsToUpdate = HashSet<FtIndex>();

  DateTime? previousCellTime;

  PanelCellIndex previousEditCell = const PanelCellIndex();

  FtIndex lastEditIndex = const FtIndex();
  PanelCellIndex _editCell = const PanelCellIndex();
  bool scrollToEditCell = false;

  set editCell(PanelCellIndex value) {
    if (_editCell == value) {
      return;
    }

    previousCellTime = null;

    previousEditCell = _editCell;

    if (value.isIndex) {
      scrollToEditCell = true;
      store(value.scrollIndexX, value.scrollIndexY);
      // showCell(value);
    }

    // if (previousEditCell.isIndex && !value.isIndex) {}
    _editCell = value;
  }

  PanelCellIndex get editCell => _editCell;

  store(scrollIndexX, scrollIndexY) {
    switch (stateSplitY) {
      case SplitState.freezeSplit || SplitState.split:
        {
          restoreScroll = RestoreScroll(
              scrollIndexX: scrollIndexX,
              scrollIndexY: scrollIndexY,
              scrollY0: getScrollY(scrollIndexX, 0),
              scrollY1: getScrollY(scrollIndexX, 1));

          break;
        }
      case SplitState.autoFreezeSplit || SplitState.noSplit:
        {
          restoreScroll = RestoreScroll(
              scrollIndexX: scrollIndexX,
              scrollIndexY: scrollIndexY,
              mainScrollY: mainScrollY);
          break;
        }

      default:
        {}
    }
  }

  void clearEditCell({FtIndex? cellIndex}) {
    if ((cellIndex == null && _editCell.isIndex) || _editCell == cellIndex) {
      previousEditCell = _editCell;

      _editCell = const PanelCellIndex();
      cellsToUpdate.add(_editCell);
      markNeedsLayout();
    }
    scrollToEditCell = false;
  }

  void updateCellPanel(LayoutPanelIndex layoutPanelIndex) {
    _editCell = _editCell.copyWith(
        panelIndexX: layoutPanelIndex.xIndex,
        panelIndexY: layoutPanelIndex.yIndex);
  }

  final SharedTextControllersByIndex sharedTextControllersByIndex;

  // ViewModel
  //
  //
  //
  //
  //

  // AbstractFlexTableDataModel get dataTable => ftm._dataTable;
  double _widthMainPanel = 0.0;
  double _heightMainPanel = 0.0;

  double get widthMainPanel => _widthMainPanel;

  double get heightMainPanel => _heightMainPanel;

  List<GridLayout> widthLayoutList =
      List.generate(4, (i) => GridLayout(), growable: false);
  List<GridLayout> heightLayoutList =
      List.generate(4, (i) => GridLayout(), growable: false);

  double get scrollX0pY0 => model.scrollX0pY0;
  set scrollX0pY0(double value) => model.scrollX0pY0 = value;

  double get scrollX1pY0 => model.scrollX1pY0;
  set scrollX1pY0(double value) => model.scrollX1pY0 = value;

  double get scrollY0pX0 => model.scrollY0pX0;
  set scrollY0pX0(double value) => model.scrollY0pX0 = value;

  double get scrollY1pX0 => model.scrollY1pX0;
  set scrollY1pX0(double value) => model.scrollY1pX0 = value;

  double get scrollX0pY1 => model.scrollX0pY1;
  set scrollX0pY1(double value) => model.scrollX0pY1 = value;

  double get scrollX1pY1 => model.scrollX1pY1;
  set scrollX1pY1(double value) => model.scrollX1pY1 = value;

  double get scrollY0pX1 => model.scrollY0pX1;
  set scrollY0pX1(double value) => model.scrollY0pX1 = value;

  double get scrollY1pX1 => model.scrollY1pX1;
  set scrollY1pX1(double value) => model.scrollY1pX1 = value;

  double get mainScrollX => model.mainScrollX;
  set mainScrollX(double value) => model.mainScrollX = value;

  double get mainScrollY => model.mainScrollY;
  set mainScrollY(double value) => model.mainScrollY = value;

  double get _xSplit => model.xSplit;
  set _xSplit(double value) => model.xSplit = value;

  double get _ySplit => model.ySplit;
  set _ySplit(double value) => model.ySplit = value;

  bool modifySplit = false;

  final autoFreezeNoRange = AutoFreezeArea.noArea();
  AutoFreezeArea autoFreezeAreaX = AutoFreezeArea.noArea();
  AutoFreezeArea autoFreezeAreaY = AutoFreezeArea.noArea();

  late List<LayoutPanelIndex> _layoutIndex;
  late List<int> _panelIndex;

  double ratioVerticalScrollBarTrack = 1.0;
  double ratioHorizontalScrollBarTrack = 1.0;
  double ratioSizeAnimatedSplitChangeX = 1.0;
  double ratioSizeAnimatedSplitChangeY = 1.0;
  double ratioFreezeChangeX = 1.0;
  double ratioFreezeChangeY = 1.0;

  List<HeaderProperties> headerRows = List.empty();
  HeaderProperties rightRowHeaderProperty = noHeader;
  HeaderProperties leftRowHeaderProperty = noHeader;

  final InnerScrollChangeNotifier _scrollChangeNotifier;
  List<TableChangeNotifier> tableChangeNotifiers;
  FtProperties properties;

  bool scrollBarTrack = false;
  double sizeScrollBarTrack = 0.0;
  double thumbSize = 6.0;
  double paddingOutside = 2.0;
  double paddingInside = 2.0;

  bool scheduleCorrectOffScroll = false;
  double? correctSliverOffset;

  TableScrollActivity? get activity => _activity;
  TableScrollActivity? _activity;

  double get scaleRowHeader => (properties.maxRowHeaderScale < tableScale)
      ? properties.maxRowHeaderScale
      : tableScale;

  double get scaleColumnHeader => (properties.maxColumnHeaderScale < tableScale)
      ? properties.maxColumnHeaderScale
      : tableScale;

  double scaleHeader(TableHeaderIndex tableHeaderIndex) {
    return tableHeaderIndex.index <= 3 || tableHeaderIndex.index >= 12
        ? scaleColumnHeader
        : scaleRowHeader;
  }

  // bool applyTableDimensions({List<GridLayout> layoutX, List<GridLayout> layoutY}) {
  //   _layoutX = layoutX;
  //   _layoutY = layoutY;
  //   context.setCanDrag(true);
  //   return true;
  // }

  List<GridLayout> get layoutX => widthLayoutList;

  List<GridLayout> get layoutY => heightLayoutList;

  void correctBy(Offset value) {}

  void jumpTo(int scrollIndexX, int scrollIndexY,
      {Offset? offset, double? scrollX, double? scrollY}) {
    if (offset != null) {
      Offset pixels = getScrollScaled(scrollIndexX, scrollIndexY, true);
      if (pixels != offset) {
        final oldPixels = pixels;
        pixels = setPixels(scrollIndexX, scrollIndexY, offset);
        didStartScroll();
        didUpdateScrollPositionBy(pixels - oldPixels);
        didEndScroll();
      }
    } else if (scrollX != null) {
      double pixels = getScrollScaledX(
        scrollIndexX,
        scrollIndexY,
      );
      if (pixels != scrollX) {
        final oldPixels = pixels;
        pixels = setPixelsX(scrollIndexX, scrollIndexY, scrollX);
        didStartScroll();
        // didUpdateScrollPositionBy(pixels - oldPixels);
        didEndScroll();
      }
    } else if (scrollY != null) {
      double pixels = getScrollScaledY(
        scrollIndexX,
        scrollIndexY,
      );
      if (pixels != scrollY) {
        final oldPixels = pixels;
        pixels = setPixelsX(scrollIndexX, scrollIndexY, scrollY);
        didStartScroll();
        // didUpdateScrollPositionBy(pixels - oldPixels);
        didEndScroll();
      }
    }
    goBallistic(scrollIndexX, scrollIndexY, 0.0, 0.0);
  }

  /// underscroll.
  Future<void> moveTo(
    int scrollIndexX,
    int scrollIndexY,
    Offset to, {
    Duration? duration,
    Curve? curve,
    bool? clamp,
  }) {
    if (duration == null || duration == Duration.zero) {
      // To
      jumpTo(scrollIndexX, scrollIndexY, offset: to);

      return Future<void>.value();
    } else {
      return animateTo(scrollIndexX, scrollIndexY,
          toScaledOffset: to,
          duration: duration,
          curve: curve ?? Curves.ease,
          correctOffset: false);
    }
  }

  @mustCallSuper
  void debugFillDescription(List<String> description) {
    // description.add('offset: $pixelsY');
  }

  void beginActivity(TableScrollActivity? newActivity) {
    _heldPreviousXvelocity = 0.0;
    if (newActivity == null) return;

    assert(newActivity.delegate == this);

    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity!.shouldIgnorePointer;
      wasScrolling = _activity!.isScrolling;
      if (wasScrolling && !newActivity.isScrolling) {
        didEndScroll(); // notifies and then saves the scroll offset
      }
      _activity!.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;

    // print('TableScroll Activity');

    if (oldIgnorePointer != activity!.shouldIgnorePointer) {
      context.setIgnorePointer(activity!.shouldIgnorePointer);
    }

    isScrollingNotifier.value = activity!.isScrolling;

    if (!wasScrolling && _activity!.isScrolling) didStartScroll();

    currentChange?.dispose();
    currentChange = null;
  }

  TableChange? currentChange;

  double _heldPreviousXvelocity = 0.0;
  double _heldPreviousYvelocity = 0.0;

  /// Called by [beginActivity] to report when an activity has started.
  void didStartScroll() {
    // scrollChangeNotifier.notify((FlexTableScrollNotification listener) =>
    //     listener.didStartScroll(this, context.notificationContext));

    scrolling = true;
    _scrollChangeNotifier.changeScrolling(scrolling);
    _notifyChange();

    if (scrollNotificationEnabled) {
      activity!
          .dispatchScrollStartNotification(this, context.notificationContext);
    }
  }

  void enableScrollNotification(enable) {
    scrollNotificationEnabled = enable;
    _activity?.enableScrollNotification = true;

    didUpdateScrollPositionBy(Offset.zero);
  }

  void didUpdateScrollPositionBy(Offset value) {
    if (scrollNotificationEnabled) {
      activity!.dispatchScrollUpdateNotification(
          this, context.notificationContext, value);
    }
  }

  /// Called by [beginActivity] to report when an activity has ended.
  ///
  /// This also saves the scroll offset using [saveScrollOffset].
  void didEndScroll() {
    // scrollChangeNotifier.changeScrolling(
    //     (FlexTableScrollNotification listener) =>
    //         listener.didEndScroll(this, context.notificationContext));
    scrolling = false;
    _scrollChangeNotifier.changeScrolling(scrolling);

    _notifyChange();

    if (scrollNotificationEnabled) {
      activity!
          .dispatchScrollEndNotification(this, context.notificationContext);
    }
  }

  void didOverscrollBy(Offset value) {
    assert(() {
      if (!activity!.isScrolling) {
        debugPrint(
            'didOverscrollBy: Activity is not scrolling: value: $value activity: $activity');
      }
      return true;
    }());
    //activity.dispatchOverscrollNotification(copyWith(), context.notificationContext, value);
  }

  void didOverscrollByX(double value) {
    assert(() {
      if (!activity!.isScrolling) {
        debugPrint(
            'didOverscrollByX: Activity is not scrolling: value: $value activity: $activity');
      }
      return true;
    }());
    //activity.dispatchOverscrollNotification(copyWith(), context.notificationContext, value);
  }

  void didOverscrollByY(double value) {
    assert(() {
      if (!activity!.isScrolling) {
        debugPrint(
            'didOverscrollByY: Activity is not scrolling: value: $value activity: $activity');
      }
      return true;
    }());
    //activity.dispatchOverscrollNotification(copyWith(), context.notificationContext, value);
  }

  void didUpdateScrollDirection(
      ScrollDirection xScrollDirection, ScrollDirection yScrollDirection) {
    //UserScrollNotification(metrics: copyWith(), context: context.notificationContext, direction: direction).dispatch(context.notificationContext);
  }

  void didUpdateScrollDirectionX(ScrollDirection direction) {
    //UserScrollNotification(metrics: copyWith(), context: context.notificationContext, direction: direction).dispatch(context.notificationContext);
  }

  void didUpdateScrollDirectionY(ScrollDirection direction) {
    //UserScrollNotification(metrics: copyWith(), context: context.notificationContext, direction: direction).dispatch(context.notificationContext);
  }

  @override
  void dispose() {
    scaleChangeNotifier.removeListener(changeScale);
    _endScrollToEditCell?.cancel();

    activity
        ?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    _adjustScroll.dispose();
    _mounted = false;
    sliverScrollPosition?.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Offset setPixels(int scrollIndexX, int scrollIndexY, Offset newPixels) {
    double xDelta = 0.0;
    double yDelta = 0.0;
    double xOverscroll = 0.0;
    double yOverscroll = 0.0;

    // assert(activity!.isScrolling);
    assert(SchedulerBinding.instance.schedulerPhase.index <=
        SchedulerPhase.transientCallbacks.index);

    double pixelsX =
        getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

    // assert(pixelsX != null);

    if (newPixels.dx != pixelsX) {
      xOverscroll =
          applyBoundaryConditionsX(scrollIndexX, scrollIndexY, newPixels.dx);
      assert(() {
        final double delta = newPixels.dx - pixelsX;
        if (xOverscroll.abs() > delta.abs()) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                '$runtimeType.applyBoundaryConditions X returned invalid overscroll value.'),
            ErrorDescription(
                'setPixels() was called to change the scroll offset from $pixelsX to ${newPixels.dx}.\n'
                'That is a delta of $delta units.\n'
                '$runtimeType.applyBoundaryConditions reported an overscroll of $xOverscroll units.')
          ]);
        }
        return true;
      }());
      final double oldPixels = pixelsX;
      pixelsX = newPixels.dx - xOverscroll;
      xDelta = pixelsX - oldPixels;

      setScrollScaledX(scrollIndexX, scrollIndexY, pixelsX);
    }

    double pixelsY =
        getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

    // assert(pixelsY != null);

    if (newPixels.dy != pixelsY) {
      yOverscroll =
          applyBoundaryConditionsY(scrollIndexX, scrollIndexY, newPixels.dy);
      assert(() {
        final double delta = newPixels.dy - pixelsY;
        if (yOverscroll.abs() > delta.abs()) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                '$runtimeType.applyBoundaryConditions  Y returned invalid overscroll value.'),
            ErrorDescription(
                'setPixels() was called to change the scroll offset from $pixelsY to ${newPixels.dy}.\n'
                'That is a delta of $delta units.\n'
                '$runtimeType.applyBoundaryConditions reported an overscroll of $yOverscroll units.')
          ]);
        }
        return true;
      }());
      final double oldPixels = pixelsY;
      pixelsY = newPixels.dy - yOverscroll;

      yDelta = pixelsY - oldPixels;
      setScrollScaledY(scrollIndexX, scrollIndexY, pixelsY);
    }

    if (xDelta != 0.0 || yDelta != 0.0) {
      didUpdateScrollPositionBy(Offset(xDelta, yDelta));
      notifyListeners();
    }

    if (xOverscroll != 0.0 || yOverscroll != 0.0) {
      didOverscrollBy(Offset(xOverscroll, yOverscroll));
      return Offset(xOverscroll, yOverscroll);
    }

    return Offset.zero;
  }

  @override
  double setPixelsX(int scrollIndexX, int scrollIndexY, double newPixels) {
    double pixelsX =
        getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

    // assert(pixelsX != null);
    assert(SchedulerBinding.instance.schedulerPhase.index <=
        SchedulerPhase.transientCallbacks.index);
    if (newPixels != pixelsX) {
      final double overscroll =
          applyBoundaryConditionsX(scrollIndexX, scrollIndexY, newPixels);
      assert(() {
        final double delta = newPixels - pixelsX;
        if (overscroll.abs() > delta.abs()) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                '$runtimeType.applyBoundaryConditions returned invalid overscroll value.'),
            ErrorDescription(
                'setPixels() was called to change the scroll offset from $pixelsX to $newPixels.\n'
                'That is a delta of $delta units.\n'
                '$runtimeType.applyBoundaryConditions reported an overscroll of $overscroll units.')
          ]);
        }
        return true;
      }());
      final double oldPixels = pixelsX;
      pixelsX = newPixels - overscroll;

      if (pixelsX != oldPixels) {
        setScrollScaledX(scrollIndexX, scrollIndexY, pixelsX);
        notifyListeners();
        didUpdateScrollPositionBy(Offset(pixelsX - oldPixels, 0.0));
      }
      if (overscroll != 0.0) {
        didOverscrollByX(overscroll);
        return overscroll;
      }
    } else {
      //print('pixels gelijk $newPixels');
    }
    return 0.0;
  }

  @override
  double setPixelsY(int scrollIndexX, int scrollIndexY, double newPixels) {
    double pixelsY =
        getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

    // assert(pixelsY != null);
    assert(SchedulerBinding.instance.schedulerPhase.index <=
        SchedulerPhase.transientCallbacks.index);
    if (newPixels != pixelsY) {
      final double overscroll =
          applyBoundaryConditionsY(scrollIndexX, scrollIndexY, newPixels);
      assert(() {
        final double delta = newPixels - pixelsY;
        if (overscroll.abs() > delta.abs()) {
          throw FlutterError.fromParts(<DiagnosticsNode>[
            ErrorSummary(
                '$runtimeType.applyBoundaryConditions returned invalid overscroll value.'),
            ErrorDescription(
                'setPixels() was called to change the scroll offset from $pixelsY to $newPixels.\n'
                'That is a delta of $delta units.\n'
                '$runtimeType.applyBoundaryConditions reported an overscroll of $overscroll units.')
          ]);
        }
        return true;
      }());
      final double oldPixels = pixelsY;
      pixelsY = newPixels - overscroll;
      if (pixelsY != oldPixels) {
        setScrollScaledY(scrollIndexX, scrollIndexY, pixelsY);
        notifyListeners();
        didUpdateScrollPositionBy(Offset(0.0, pixelsY - oldPixels));
      }
      if (overscroll != 0.0) {
        didOverscrollByY(overscroll);
        return overscroll;
      }
    } else {
      //print('pixels gelijk $newPixels');
    }
    return 0.0;
  }

  @protected
  double applyBoundaryConditionsX(
      int scrollIndexX, int scrollIndexY, double value) {
    return applyBoundaryConditions(
        value,
        scrollPixelsX(scrollIndexX, scrollIndexY),
        minScrollExtentX(scrollIndexX),
        maxScrollExtentX(scrollIndexX),
        viewportDimensionX(scrollIndexX));
  }

  @protected
  double applyBoundaryConditionsY(
      int scrollIndexX, int scrollIndexY, double value) {
    return applyBoundaryConditions(
        value,
        scrollPixelsY(scrollIndexX, scrollIndexY),
        minScrollExtentY(scrollIndexY),
        maxScrollExtentY(scrollIndexY),
        viewportDimensionY(scrollIndexY));
  }

  double applyBoundaryConditions(double value, pixels, double minScrollExtent,
      double maxScrollExtent, double viewportDimension) {
    final double result = physics.applyBoundaryConditions(
        value, pixels, minScrollExtent, maxScrollExtent);
    assert(() {
      final double delta = value - pixels;
      if (result.abs() > delta.abs()) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary(
              '${physics.runtimeType}.applyBoundaryConditions X or Y returned invalid overscroll value.'),
          ErrorDescription(
              'The method was called to consider a change from $pixels to $value, which is a '
              'delta of ${delta.toStringAsFixed(1)} units. However, it returned an overscroll of '
              '${result.toStringAsFixed(1)} units, which has a greater magnitude than the delta. '
              'The applyBoundaryConditions method is only supposed to reduce the possible range '
              'of movement, not increase it.\n'
              'The scroll extents are $minScrollExtent .. $maxScrollExtent, and the '
              'viewport dimension is $viewportDimension.')
        ]);
      }
      return true;
    }());
    return result;
  }

  shouldRebuild(FtViewModel offset) {
    return this != offset;
  }

  TableScrollDirection selectScrollDirection(DragDownDetails details) {
    return tableScrollDirection;
  }

  double get devicePixelRatio =>
      MediaQuery.maybeDevicePixelRatioOf(context.storageContext) ??
      View.of(context.storageContext).devicePixelRatio;

  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    LayoutPanelIndex si = findScrollIndex(details.localPosition);

    final scrollIndexX =
        (model.stateSplitX == SplitState.freezeSplit) ? 1 : si.xIndex;
    final scrollIndexY =
        (model.stateSplitY == SplitState.freezeSplit) ? 1 : si.yIndex;

    final TableScrollDragController drag = TableScrollDragController(
        delegate: this,
        details: details,
        onDragCanceled: dragCancelCallback,
        carriedVelocityX: physics.carriedMomentum(_heldPreviousXvelocity),
        carriedVelocityY: physics.carriedMomentum(_heldPreviousYvelocity),
        motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
        scrollIndexX: scrollIndexX,
        scrollIndexY: scrollIndexY,
        adjustScroll: _adjustScroll,
        sliverDrag: sliverScrollPosition?.drag(
            DragStartDetails(
                globalPosition: details.globalPosition,
                kind: details.kind,
                localPosition: details.localPosition,
                sourceTimeStamp: details.sourceTimeStamp),
            dragCancelCallback));

    scrollToEditCell = false;

    beginActivity(TableDragScrollActivity(
        scrollIndexX, scrollIndexY, this, drag, scrollNotificationEnabled));

    assert(currentChange == null);
    currentChange = drag;
    return drag;
  }

  // Size size(int xTableIndex, int yTableIndex) {
  //   assert(_layoutX[xTableIndex] != null && _layoutY[yTableIndex] != null);
  //   return Size(_layoutX[xTableIndex].panelLength, _layoutY[yTableIndex].panelLength);
  // }

  LayoutPanelIndex findScrollIndex(Offset offset) {
    final scrollIndexX =
        layoutX[2].inUse && layoutX[2].gridPosition < offset.dx ? 1 : 0;
    final scrollIndexY =
        layoutY[2].inUse && layoutY[2].gridPosition < offset.dy ? 1 : 0;

    return LayoutPanelIndex(xIndex: scrollIndexX, yIndex: scrollIndexY);
  }

  TableDrag dragScrollBar(DragStartDetails details,
      VoidCallback dragCancelCallback, int scrollIndexX, int scrollIndexY) {
    final TableScrollBarDragController drag = TableScrollBarDragController(
        delegate: this,
        details: details,
        onDragCanceled: dragCancelCallback,
        scrollIndexX: scrollIndexX,
        scrollIndexY: scrollIndexY);

    beginActivity(TableDragScrollActivity(
        scrollIndexX, scrollIndexY, this, drag, scrollNotificationEnabled));
    assert(currentChange == null);
    currentChange = drag;
    return drag;
  }

  void updateUserScrollDirection(
      ScrollDirection xScrollDirection, ScrollDirection yScrollDirection) {
    if (userScrollDirectionX == xScrollDirection &&
        userScrollDirectionY == yScrollDirection) return;
    _userScrollDirectionX = xScrollDirection;
    _userScrollDirectionY = yScrollDirection;
    didUpdateScrollDirection(xScrollDirection, yScrollDirection);
  }

  void updateUserScrollDirectionX(ScrollDirection value) {
    if (userScrollDirectionX == value) return;
    _userScrollDirectionX = value;
    didUpdateScrollDirectionX(value);
  }

  void updateUserScrollDirectionY(ScrollDirection value) {
    if (userScrollDirectionY == value) return;
    _userScrollDirectionY = value;
    didUpdateScrollDirectionY(value);
  }

  bool get allowImplicitScrolling => physics.allowImplicitScrolling;

  Future<void> animateTo(
    int scrollIndexX,
    int scrollIndexY, {
    Offset? toScaledOffset,
    double? toScaledX,
    double? toScaledY,
    Duration? duration,
    Curve? curve,
    required bool correctOffset,
  }) {
    if (toScaledX != null && toScaledY != null) {
      toScaledOffset = Offset(toScaledX, toScaledY);
    }

    DrivenTableScrollActivity? activity;
    if (toScaledOffset != null) {
      final from = getScrollScaled(scrollIndexX, scrollIndexY, true);
      final delta = (from - toScaledOffset);
      final max = math.max(delta.dx.abs(), delta.dy.abs());
      if (max < physics.toleranceFor(devicePixelRatio).distance) {
        // Skip the animation, go straight to the position as we are already close.
        jumpTo(scrollIndexX, scrollIndexY, offset: toScaledOffset);
        return Future<void>.value();
      }
      activity = DrivenTableScrollActivity(
          scrollIndexX, scrollIndexY, this, false,
          vsync: context.vsync,
          from: from,
          to: toScaledOffset,
          duration: duration ?? const Duration(milliseconds: 200),
          curve: curve ?? Curves.ease,
          correctOffset: correctOffset,
          direction: TableScrollDirection.both);
    } else if (toScaledX != null) {
      final from =
          getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);
      final delta = (from - toScaledX);

      if (delta.abs() < physics.toleranceFor(devicePixelRatio).distance) {
        // Skip the animation, go straight to the position as we are already close.
        jumpTo(scrollIndexX, scrollIndexY, scrollX: toScaledX);
        return Future<void>.value();
      }
      activity = DrivenTableScrollActivity(
          scrollIndexX, scrollIndexY, this, false,
          vsync: context.vsync,
          from: from,
          to: toScaledX,
          duration: duration ?? const Duration(milliseconds: 200),
          curve: curve ?? Curves.ease,
          correctOffset: correctOffset,
          direction: TableScrollDirection.horizontal);
    } else if (toScaledY != null) {
      final from =
          getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);
      final delta = (from - toScaledY);

      if (delta.abs() < physics.toleranceFor(devicePixelRatio).distance) {
        // Skip the animation, go straight to the position as we are already close.
        jumpTo(scrollIndexX, scrollIndexY, scrollY: toScaledY);
        return Future<void>.value();
      }
      activity = DrivenTableScrollActivity(
          scrollIndexX, scrollIndexY, this, false,
          vsync: context.vsync,
          from: from,
          to: toScaledY,
          duration: duration ?? const Duration(milliseconds: 200),
          curve: curve ?? Curves.ease,
          correctOffset: correctOffset,
          direction: TableScrollDirection.vertical);
    }

    beginActivity(activity);

    return activity?.done ?? Future.value(null);
  }

  Future<void> animatesTo(
      {required List<AnimatedToItem> items, Duration? duration, Curve? curve}) {
    if (items.isEmpty) {
      return Future<void>.value();
    }
    final activity = DrivenMultiScrollActivity(
      items: items,
      delegate: this,
      enableScrollNotification: false,
      vsync: context.vsync,
      duration: duration ?? const Duration(milliseconds: 200),
      curve: curve ?? Curves.ease,
    );

    beginActivity(activity);

    return activity.done;
  }

  bool applyContentDimensions(double minScrollExtentX, double maxScrollExtentX,
      double minScrollExtentY, double maxScrollExtentY) {
    throw UnimplementedError();
  }

  @override
  void applyUserOffset(int scrollIndexX, int scrollIndexY, Offset delta) {
    updateUserScrollDirection(
        delta.dx > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
        delta.dy > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);

    final pixelsX =
        getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);
    final pixelsY =
        getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

    setPixels(
        scrollIndexX,
        scrollIndexY,
        Offset(
            pixelsX -
                physics.applyPhysicsToUserOffset(
                    delta.dx,
                    pixelsX,
                    minScrollExtentX(scrollIndexX),
                    maxScrollExtentX(scrollIndexX)),
            pixelsY -
                physics.applyPhysicsToUserOffset(
                    delta.dy,
                    pixelsY,
                    minScrollExtentY(scrollIndexY),
                    maxScrollExtentY(scrollIndexY))));
  }

  @override
  void applyUserOffsetX(int scrollIndexX, int scrollIndexY, double delta) {
    updateUserScrollDirectionX(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);

    final pixelsX =
        getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

    setPixelsX(
        scrollIndexX,
        scrollIndexY,
        pixelsX -
            physics.applyPhysicsToUserOffset(
                delta,
                pixelsX,
                minScrollExtentX(scrollIndexX),
                maxScrollExtentX(scrollIndexX)));
  }

  @override
  void applyUserOffsetY(int scrollIndexX, int scrollIndexY, double delta) {
    final pixelsY =
        getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

    setPixelsY(
        scrollIndexX,
        scrollIndexY,
        pixelsY -
            physics.applyPhysicsToUserOffset(
                delta,
                pixelsY,
                minScrollExtentY(scrollIndexY),
                maxScrollExtentY(scrollIndexY)));
  }

  @override
  void goBallistic(
      int scrollIndexX, int scrollIndexY, double velocityX, double velocityY) {
    final pixelsX =
        getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);
    final pixelsY =
        getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

    final pixelRatio = devicePixelRatio;

    final Simulation xSimulation = physics.createBallisticSimulation(
            pixelsX,
            minScrollExtentX(scrollIndexX),
            maxScrollExtentX(scrollIndexX),
            outOfRangeX(scrollIndexX, scrollIndexY),
            velocityX,
            pixelRatio) ??
        noBallisticSimulation;
    final Simulation ySimulation = physics.createBallisticSimulation(
            pixelsY,
            minScrollExtentY(scrollIndexY),
            maxScrollExtentY(scrollIndexY),
            outOfRangeY(scrollIndexX, scrollIndexY),
            velocityY,
            pixelRatio) ??
        noBallisticSimulation;
    if (xSimulation != noBallisticSimulation ||
        ySimulation != noBallisticSimulation) {
      // print('goBallistic');
      beginActivity(BallisticTableScrollActivity(
          scrollIndexX,
          scrollIndexY,
          this,
          xSimulation,
          ySimulation,
          context.vsync,
          scrollNotificationEnabled));
    } else {
      goIdle(scrollIndexX, scrollIndexY);
    }
  }

  @override
  void goIdle(int scrollIndexX, int scrollIndexY) {
    if (scheduleCorrectOffScroll) {
      correctOffScroll(scrollIndexX, scrollIndexY);
      scheduleCorrectOffScroll = false;
    }
    beginActivity(TableIdleScrollActivity(
        scrollIndexX, scrollIndexY, this, scrollNotificationEnabled));
  }

  @override
  void correctOffScroll(int scrollIndexX, int scrollIndexY) {
    List<ScrollSimulation> list = [];

    final pixelRatio = devicePixelRatio;

    final _SetPixels setPixelsX =
        tableScrollDirection != TableScrollDirection.vertical
            ? this.setPixelsX
            : (scrollIndexX, scrollIndexY, value) {
                //To do Aangepast is waarschijnlijk niet nodig voor CustomScrollView
                //  return tableModel.sliverScrollPosition?.setPixels(value) ?? 0.0;
                return 0.0;
              };

    final _SetPixels setPixelsY =
        tableScrollDirection != TableScrollDirection.horizontal
            ? this.setPixelsY
            : (scrollIndexX, scrollIndexY, value) {
                //To do Aangepast is waarschijnlijk niet nodig voor CustomScrollView
                // return tableModel.sliverScrollPosition?.setPixels(value) ?? 0.0;
                return 0.0;
              };

    xSimulation(int scrollIndexX, int scrollIndexY) {
      Simulation? simulation = physics.createBallisticSimulation(
          getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true),
          minScrollExtentX(scrollIndexX),
          maxScrollExtentX(scrollIndexX),
          true,
          20.0,
          pixelRatio);

      if (simulation != null) {
        list.add(ScrollSimulation(
          scrollIndexX: scrollIndexX,
          scrollIndexY: scrollIndexY,
          setPixels: setPixelsX,
          simulation: simulation,
        ));
      }
    }

    ySimulation(int scrollIndexX, int scrollIndexY) {
      Simulation? simulation = physics.createBallisticSimulation(
          getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true),
          minScrollExtentY(scrollIndexY),
          maxScrollExtentY(scrollIndexY),
          true,
          20.0,
          pixelRatio);

      if (simulation != null) {
        list.add(ScrollSimulation(
          scrollIndexX: scrollIndexX,
          scrollIndexY: scrollIndexY,
          setPixels: setPixelsY,
          simulation: simulation,
        ));
      }
    }
    // goIdle(scrollIndexX, scrollIndexY);
    // return;

    if (outOfRangeX(0, 0)) {
      xSimulation(0, 0);
    }

    if (outOfRangeY(0, 0)) {
      ySimulation(0, 0);
    }

    if (model.anyNoAutoFreezeY) {
      if (outOfRangeY(0, 1)) ySimulation(0, 1);

      if (model.stateSplitY == SplitState.split && protectedScrollUnlockX) {
        if (outOfRangeX(0, 1)) xSimulation(0, 1);

        if (model.stateSplitX == SplitState.split && outOfRangeX(1, 1)) {
          xSimulation(1, 1);
        }
      }
    }

    if (model.anyNoAutoFreezeX) {
      if (outOfRangeX(1, 0)) xSimulation(1, 0);

      if (model.stateSplitX == SplitState.split && protectedScrollUnlockY) {
        if (outOfRangeY(1, 0)) ySimulation(1, 0);

        if (model.stateSplitY == SplitState.split && outOfRangeY(1, 1)) {
          ySimulation(1, 1);
        }
      }
    }

    if (list.isEmpty) {
      goIdle(scrollIndexX, scrollIndexY);
    } else {
      beginActivity(CorrrectOffScrollActivity(scrollIndexX, scrollIndexY, this,
          list, context.vsync, scrollNotificationEnabled));
    }
  }

  ScrollHoldController hold(VoidCallback holdCancelCallback) {
    final double previousXvelocity = activity!.xVelocity;
    final double previousYvelocity = activity!.yVelocity;
    final HoldTableScrollActivity holdActivity = HoldTableScrollActivity(
      activity!.scrollIndexX,
      activity!.scrollIndexY,
      delegate: this,
      onHoldCanceled: holdCancelCallback,
    );
    beginActivity(holdActivity);
    _heldPreviousXvelocity = previousXvelocity;
    _heldPreviousYvelocity = previousYvelocity;
    return holdActivity;
  }

  @override
  AxisDirection get axisDirectionX => context.axisDirection;

  @override
  AxisDirection get axisDirectionY => context.axisDirection;

  @override
  void cancelSplit() {
    switch (stateSplitX) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
        {
          stateSplitX = SplitState.noSplit;
          break;
        }
      default:
    }

    switch (stateSplitY) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
        {
          stateSplitY = SplitState.noSplit;
          break;
        }
      default:
    }
  }

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  double spaceSplitDividerX() {
    switch (stateSplitX) {
      case SplitState.freezeSplit:
        return properties.spaceSplitFreeze * ratioFreezeChangeX;
      case SplitState.autoFreezeSplit:
        return 0.0; //autoFreezeAreaY.spaceSplit(properties.spaceSplitFreeze);
      case SplitState.split:
        return properties.spaceSplit;
      default:
        return 0.0;
    }
  }

  double spaceSplitDividerY() {
    switch (stateSplitY) {
      case SplitState.freezeSplit:
        return properties.spaceSplitFreeze * ratioFreezeChangeY;
      case SplitState.autoFreezeSplit:
        return 0.0;
      //autoFreezeAreaY.spaceSplit(properties.spaceSplitFreeze);
      case SplitState.split:
        return properties.spaceSplit;
      default:
        return 0.0;
    }
  }

  // From model
  //
  //

  @override
  SplitState get stateSplitX => model.stateSplitX;

  set stateSplitX(SplitState state) => model.stateSplitX = state;

  @override
  SplitState get stateSplitY => model.stateSplitY;

  set stateSplitY(SplitState state) => model.stateSplitY = state;

  bool get scrollUnlockX => model.scrollUnlockX;

  set scrollUnlockX(bool value) {
    model.scrollUnlockX = value;
  }

  bool get protectedScrollUnlockX => model.protectedScrollUnlockX;

  bool get scrollUnlockY => model.scrollUnlockY;

  set scrollUnlockY(bool value) {
    model.scrollUnlockY = value;
  }

  bool get protectedScrollUnlockY => model.protectedScrollUnlockY;

  bool get splitX => model.stateSplitX == SplitState.split;

  bool get splitY => model.stateSplitY == SplitState.split;

  double get tableScale => model.tableScale;

  /// Unfocus:
  /// Unfocus the textEditor if the adjust widget like a slider can take te focus, because if the textEditor becomes inside the screen
  /// the texEditor will take the focus from the slider and so on.
  ///
  setTableScale(double value, {bool unfocus = true}) {
    if (unfocus && _editCell.isIndex) {
      _editCell = const PanelCellIndex();
    }
    value =
        clampDouble(value, properties.minTableScale, properties.maxTableScale);
    scale() {
      double oldScale = tableScale;
      model.tableScale = value;

      if (sliverScrollPosition != null) {
        final scrollY = autoFreezePossibleY
            ? getScrollY(0, 0, scrollActivity: true)
            : (stateSplitY == SplitState.freezeSplit)
                ? getScrollY(0, 1) - getY(model.topLeftCellPaneRow)
                : getScrollY(0, 0);
        sliverScrollPosition!.correctPixels(sliverScrollPosition!.pixels +
            scrollY * tableScale -
            scrollY * oldScale);
      }
    }

    if (value != tableScale) {
      context.setState(scale);
      _notifyChange();
    }
  }

  set rowHeader(bool value) {
    model.rowHeader = value;
    calculateHeaderWidth();
  }

  bool get rowHeader => model.rowHeader;

  set columnHeader(bool value) {
    model.columnHeader = value;
  }

  bool get columnHeader => model.columnHeader;

  void setScrollScaledX(int horizontal, int vertical, double scrollScaledX) {
    // if (model.autoFreezePossibleX) {
    //   mainScrollX = scrollScaledX / tableScale;
    //   calculateAutoFreezeX();
    // } else if (vertical == 0 ||
    //     !protectedScrollUnlockX ||
    //     model.anyFreezeSplitY) {
    //   if (horizontal == 0) {
    //     mainScrollX = scrollX0pY0 = scrollScaledX / tableScale;
    //   } else {
    //     scrollX1pY0 = scrollScaledX / tableScale;
    //   }
    // } else {
    //   if (horizontal == 0) {
    //     scrollX0pY1 = scrollScaledX / tableScale;
    //   } else {
    //     scrollX1pY1 = scrollScaledX / tableScale;
    //   }
    // }
    setScrollX(horizontal, vertical, scrollScaledX / tableScale);
  }

  void setScrollX(int horizontal, int vertical, double scrollX) {
    /// CanceledAutFreezeSplit can only be changed with a resize.
    ///
    ///
    if (model.autoFreezePossibleX &&
        stateSplitX != SplitState.canceledAutoFreezeSplit) {
      mainScrollX = scrollX;
      calculateAutoFreezeX();
    } else if (vertical == 0 ||
        !protectedScrollUnlockX ||
        model.anyFreezeSplitY) {
      if (horizontal == 0) {
        mainScrollX = scrollX0pY0 = scrollX;
      } else {
        scrollX1pY0 = scrollX;
      }
    } else {
      if (horizontal == 0) {
        scrollX0pY1 = scrollX;
      } else {
        scrollX1pY1 = scrollX;
      }
    }
  }

  calculateAutoFreezeX({double? width}) {
    if (!model.autoFreezePossibleX) return;

    width ??= _widthMainPanel;

    scrollX0pY0 = mainScrollX;
    assert(!protectedScrollUnlockX,
        'autofreezeX and unlock scrollLockX can not used together!');

    final previousHeader = autoFreezeAreaX.header;

    if (!autoFreezeAreaX.constains(mainScrollX)) {
      autoFreezeAreaX = model.autoFreezeAreasX.firstWhere(
          (element) => element.constains(mainScrollX),
          orElse: () => autoFreezeNoRange);
    }

    // print(
    //     'mainScrollX: $mainScrollX  ${autoFreezeAreaX.freeze} ${model.stateSplitX}');

    if (_isSplitInWindowX(width, SplitState.autoFreezeSplit)) {
      if (autoFreezeAreaX.freeze) {
        if (mainScrollX < autoFreezeAreaX.d) {
          scrollX0pY0 = autoFreezeAreaX.startPosition;
          scrollX1pY0 = mainScrollX +
              (autoFreezeAreaX.freezePosition - autoFreezeAreaX.startPosition);
        } else {
          scrollX0pY0 =
              autoFreezeAreaX.startPosition + (mainScrollX - autoFreezeAreaX.d);
          scrollX1pY0 = mainScrollX +
              (autoFreezeAreaX.freezePosition - autoFreezeAreaX.startPosition) -
              (mainScrollX - autoFreezeAreaX.d);
        }

        if (model.stateSplitX != SplitState.autoFreezeSplit) {
          if (autoFreezeAreaX.header * tableScale <
              viewportDimensionX(0) / 2.0) {
            switchX();
          }
          model.stateSplitX = SplitState.autoFreezeSplit;
        }

        model.topLeftCellPaneColumn = autoFreezeAreaX.freezeIndex;
      } else {
        if (stateSplitX == SplitState.autoFreezeSplit) {
          if (previousHeader * tableScale < viewportDimensionX(0) / 2.0) {
            switchX();
          }
          stateSplitX = SplitState.noSplit;
        }
      }
    } else {
      if (stateSplitX == SplitState.autoFreezeSplit) {
        if (previousHeader * tableScale < viewportDimensionX(0) / 2.0) {
          switchX();
        }
        stateSplitX = SplitState.canceledAutoFreezeSplit;
      }
    }
  }

  double adapterOffset = 0.0;
  void setScrollWithSliver(double scaledScroll) {
    adapterOffset = scaledScroll;

    if (stateSplitY == SplitState.freezeSplit) {
      setScrollScaledY(0, 1, scaledScroll + getMinScrollScaledY(1));
    } else {
      setScrollScaledY(0, 0, scaledScroll);
    }
  }

  void setScrollScaledY(int horizontal, int vertical, double scrollScaledY) {
    // if (model.autoFreezePossibleY) {
    //   mainScrollY = scrollScaledY / tableScale;
    //   calculateAutoFreezeY();
    // } else if (horizontal == 0 ||
    //     !protectedScrollUnlockY ||
    //     model.anyFreezeSplitX) {
    //   if (vertical == 0) {
    //     mainScrollY = scrollY0pX0 = scrollScaledY / tableScale;
    //   } else {
    //     scrollY1pX0 = scrollScaledY / tableScale;
    //   }
    // } else {
    //   if (vertical == 0) {
    //     scrollY0pX1 = scrollScaledY / tableScale;
    //   } else {
    //     scrollY1pX1 = scrollScaledY / tableScale;
    //   }
    // }
    // print('scrollScaledY Ta ${scrollScaledY / tableScale}');
    setScrollY(horizontal, vertical, scrollScaledY / tableScale);
  }

  void setScrollY(int horizontal, int vertical, double scrollY) {
    /// CanceledAutFreezeSplit can only be changed with a resize.
    ///
    ///
    if (model.autoFreezePossibleY &&
        stateSplitY != SplitState.canceledAutoFreezeSplit) {
      mainScrollY = scrollY;
      calculateAutoFreezeY();
    } else if (horizontal == 0 ||
        !protectedScrollUnlockY ||
        model.anyFreezeSplitX) {
      if (vertical == 0) {
        mainScrollY = scrollY0pX0 = scrollY;
      } else {
        scrollY1pX0 = scrollY;
      }
    } else {
      if (vertical == 0) {
        scrollY0pX1 = scrollY;
      } else {
        scrollY1pX1 = scrollY;
      }
    }
  }

  calculateAutoFreezeY({double? height}) {
    if (!model.autoFreezePossibleY || firstLayout) return;

    height ??= _heightMainPanel;

    scrollY0pX0 = mainScrollY;
    assert(!protectedScrollUnlockY,
        'autofreezeY and unlock scrollLockY can not used together!');

    final previousHeader = autoFreezeAreaY.header;

    if (!autoFreezeAreaY.constains(mainScrollY)) {
      autoFreezeAreaY = model.autoFreezeAreasY.firstWhere(
          (element) => element.constains(mainScrollY),
          orElse: () => autoFreezeNoRange);
    }

    if (_isSplitInWindowY(height, SplitState.autoFreezeSplit)) {
      if (autoFreezeAreaY.freeze) {
        if (mainScrollY < autoFreezeAreaY.d) {
          scrollY0pX0 = autoFreezeAreaY.startPosition;
          scrollY1pX0 = mainScrollY +
              (autoFreezeAreaY.freezePosition - autoFreezeAreaY.startPosition);
        } else {
          scrollY0pX0 =
              autoFreezeAreaY.startPosition + (mainScrollY - autoFreezeAreaY.d);
          scrollY1pX0 = mainScrollY +
              (autoFreezeAreaY.freezePosition - autoFreezeAreaY.startPosition) -
              (mainScrollY - autoFreezeAreaY.d);
        }

        if (stateSplitY != SplitState.autoFreezeSplit) {
          if (autoFreezeAreaY.header * tableScale <
              viewportDimensionY(0) / 2.0) {
            switchY();
          }
          stateSplitY = SplitState.autoFreezeSplit;
        }

        model.topLeftCellPaneRow = autoFreezeAreaY.freezeIndex;
      } else {
        if (stateSplitY == SplitState.autoFreezeSplit) {
          if (previousHeader * tableScale < viewportDimensionY(0) / 2.0) {
            switchY();
          }
          stateSplitY = SplitState.noSplit;
        }
      }
    } else {
      if (_editCell.isIndex) {
        if (stateSplitY == SplitState.autoFreezeSplit) {
          if (autoFreezeAreaY.freeze) {
            final row = _editCell.row;
            if (row < autoFreezeAreaY.freezeIndex) {
              mainScrollY = autoFreezeAreaY.startPosition;
            }
          }
        }

        stateSplitY = SplitState.canceledAutoFreezeSplit;
      } else {
        if (stateSplitY == SplitState.autoFreezeSplit) {
          if (previousHeader * tableScale < viewportDimensionY(0) / 2.0) {
            switchY();
          }
          stateSplitY = SplitState.canceledAutoFreezeSplit;
        }
      }
    }
  }

  FreezeLine get freezeLine {
    if (stateSplitX == SplitState.freezeSplit &&
        stateSplitY == SplitState.freezeSplit) {
      return FreezeLine.both;
    } else if (stateSplitX == SplitState.freezeSplit) {
      return FreezeLine.horizontal;
    } else if (stateSplitY == SplitState.freezeSplit) {
      return FreezeLine.vertical;
    } else {
      return FreezeLine.none;
    }
  }

  double get sheetWidth {
    return model.sheetWidth;
  }

  double get sheetHeight {
    return model.sheetHeight;
  }

  double getX(int column, {int pc = 0}) {
    return model.getX(column, pc);
  }

  double getY(int row, {int pc = 0}) {
    return model.getY(row, pc);
  }

  double? get xSplit {
    switch (stateSplitX) {
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return properties.panelPadding.left +
            (getX(model.topLeftCellPaneColumn) - scrollX0pY0) * tableScale +
            leftHeaderPanelLength;
      case SplitState.split:
        return _xSplit;
      default:
        return null;
    }
  }

  double? get ySplit {
    switch (stateSplitY) {
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return properties.panelPadding.top +
            (getY(model.topLeftCellPaneRow) - scrollY0pX0) * tableScale +
            topHeaderPanelLength;
      case SplitState.split:
        return _ySplit;
      default:
        return null;
    }
  }

  void setXsplit(
      {int indexSplit = 0,
      double? sizeSplit,
      double? deltaSplit,
      double? ratioSplit,
      required SplitState splitView,
      bool animateSplit = false}) {
    if (splitView == SplitState.split) {
      assert(
          indexSplit > 0 ||
              sizeSplit != null ||
              deltaSplit != null ||
              ratioSplit != null,
          'Set a value for indexSplit > 0, sizeSplit, ratioSplit or deltaSplit to change the X split');

      if (indexSplit > 0) {
        double splitScroll = getX(indexSplit);
        double split = (splitScroll - scrollX0pY0) * tableScale;

        if (minSplitPositionLeft <= split && maxSplitPositionRight >= split) {
          scrollX0pY0 = scrollX1pY0 = scrollX1pY1 = mainScrollX;

          stateSplitX = SplitState.split;
          _xSplit = split;
        }
      } else {
        if (deltaSplit != null) {
          sizeSplit = _xSplit + deltaSplit;
        } else if (ratioSplit != null) {
          sizeSplit = widthMainPanel * ratioSplit;
        }

        _xSplit = sizeSplit!;

        if ((animateSplit ? initiateSplitLeft : minSplitPositionLeft) >=
            sizeSplit) {
          if (stateSplitX == SplitState.split) {
            mainScrollX = scrollX1pY0;
            scrollX0pY0 = scrollX1pY0;
            scrollX0pY1 = scrollX1pY1;

            if (protectedScrollUnlockY) {
              scrollY0pX0 = scrollY0pX1;
              scrollY1pX0 = scrollY1pX1;
            }

            stateSplitX = SplitState.noSplit;
            switchXSplit();

            calculateAutoFreezeX();
          }
        } else if ((animateSplit
                ? initiateSplitRight
                : maxSplitPositionRight) <=
            sizeSplit) {
          if (stateSplitX == SplitState.split) {
            stateSplitX = SplitState.noSplit;
            mainScrollX = scrollX0pY0;

            calculateAutoFreezeX();
          }
        } else if (stateSplitX != SplitState.split) {
          scrollX0pY0 = scrollX1pY0 = scrollX0pY1 = scrollX1pY1 = mainScrollX;
          stateSplitX = SplitState.split;

          switchXSplit();
          autoFreezeAreaX = AutoFreezeArea.noArea();

          if (stateSplitY == SplitState.split) {
            scrollX1pY1 = scrollX0pY1;
            scrollY1pX1 = scrollY1pX0;
          }

          scrollY0pX1 = scrollY0pX0;
        }

        if (!animateSplit) {
          ratioSizeAnimatedSplitChangeX =
              stateSplitX == SplitState.split ? 1.0 : 0.0;
        }
      }
    } else if (splitView == SplitState.freezeSplit) {
      assert(stateSplitX != SplitState.freezeSplit,
          'StateSplitX is already in FreezeSplit mode!');

      assert(indexSplit > 0 && indexSplit < model.tableColumns - 1,
          'Set indexSplit between 1 and maximumColumns - 2: {maximumColumns - 2}');

      scrollX0pY0 = mainScrollX;
      model.topLeftCellPaneColumn = indexSplit;
      scrollX1pY0 = getX(indexSplit);

      final freezeHeader = (scrollX1pY0 - scrollX0pY0) * tableScale;

      if (freezeHeader >= properties.minimalSizeDividedWindow * tableScale &&
          tableWidthFreeze - freezeHeader >=
              properties.minimalSizeDividedWindow * tableScale) {
        stateSplitX = SplitState.freezeSplit;

        switchXFreeze();
      }
    } else {
      if (stateSplitX == SplitState.freezeSplit) {
        unFreezeX();
      } else if (stateSplitX == SplitState.split) {
        switchXSplit();
        _xSplit = 0.0;
      }

      stateSplitX = SplitState.noSplit;
      ratioSizeAnimatedSplitChangeX = 0.0;
    }
  }

  void unFreezeX() {
    switchXFreeze();
    mainScrollX =
        scrollX0pY0 = scrollX1pY0 - widthLayoutList[1].panelLength / tableScale;
  }

  switchXFreeze() {
    final freezeHeader = (scrollX1pY0 - scrollX0pY0) * tableScale;

    if (freezeHeader < tableWidthFreeze - freezeHeader) {
      switchX();
    }
  }

  switchXSplit() {
    bool switchPanels = false;

    if (autoFreezeAreaX.freeze) {
      final freezeHeader = autoFreezeAreaX.header;

      if (freezeHeader < tableWidthFreeze - freezeHeader) {
        switchPanels = !switchPanels;
      }
    }

    final xSplitCorrected = _xSplit - leftHeaderPanelLength - sizeScrollBarLeft;

    if (xSplitCorrected < twoPanelViewPortDimensionX() - xSplitCorrected) {
      switchPanels = !switchPanels;
    }

    if (switchPanels) switchX();
  }

  void setYsplit(
      {int indexSplit = 0,
      double? sizeSplit,
      double? deltaSplit,
      double? ratioSplit,
      required SplitState splitView,
      bool animateSplit = false}) {
    if (splitView == SplitState.split) {
      assert(
          indexSplit > 0 ||
              sizeSplit != null ||
              deltaSplit != null ||
              ratioSplit != null,
          'Set a value for indexSplit > 0, sizeSplit, ratioSplit or deltaSplit to change the Y split');

      if (indexSplit > 0) {
        assert(stateSplitY == SplitState.split,
            'Split from index can not be set when split is already enabled');

        double splitScroll = getY(indexSplit);
        double split = (splitScroll - scrollY0pX0) * tableScale;

        if (minSplitPositionTop <= split && maxSplitPositionBottom >= split) {
          scrollY0pX0 = scrollY1pX0 = scrollY0pX1 = scrollY1pX1 = mainScrollY;
          stateSplitY = SplitState.split;
          _ySplit = split;
        }
      } else {
        if (deltaSplit != null) {
          sizeSplit = _ySplit + deltaSplit;
        } else if (ratioSplit != null) {
          sizeSplit = heightMainPanel * ratioSplit;
        }

        _ySplit = sizeSplit!;

        if ((animateSplit ? initiateSplitTop : minSplitPositionTop) >=
            sizeSplit) {
          if (stateSplitY == SplitState.split) {
            mainScrollY = scrollY1pX0;
            scrollY0pX0 = scrollY1pX0;
            scrollY0pX1 = scrollY1pX1;

            if (protectedScrollUnlockX) {
              scrollX0pY0 = scrollX0pY1;
              scrollX1pY0 = scrollX1pY1;
            }

            stateSplitY = SplitState.noSplit;

            switchY();
          }

          calculateAutoFreezeY();
        } else if ((animateSplit
                ? initiateSplitBottom
                : maxSplitPositionBottom) <=
            sizeSplit) {
          if (stateSplitY == SplitState.split) {
            stateSplitY = SplitState.noSplit;
            mainScrollY = scrollY0pX0;
            calculateAutoFreezeY();
          }
        } else if (stateSplitY != SplitState.split) {
          scrollY0pX0 = scrollY1pX0 = scrollY0pX1 = scrollY1pX1 = mainScrollY;
          stateSplitY = SplitState.split;

          switchYSplit();
          autoFreezeAreaY = AutoFreezeArea.noArea();

          if (stateSplitX == SplitState.split) {
            scrollY1pX1 = scrollY0pX1;
            scrollX1pY1 = scrollX1pY0;
          }

          scrollX0pY1 = scrollX0pY0;
        }
      }

      if (!animateSplit) {
        ratioSizeAnimatedSplitChangeY =
            stateSplitY == SplitState.split ? 1.0 : 0.0;
      }
    } else if (splitView == SplitState.freezeSplit) {
      assert(stateSplitY != SplitState.freezeSplit,
          'StateSplitY is already in FreezeSplit mode!');

      assert(indexSplit > 0 && indexSplit < model.tableRows - 1,
          'Set indexSplit between 1 and maximumRows - 2: {maximumRows - 2}');

      scrollY0pX0 = mainScrollY;
      model.topLeftCellPaneRow = indexSplit;
      scrollY1pX0 = getY(indexSplit);

      final freezeHeader = (scrollY1pX0 - scrollY0pX0) * tableScale;

      if (freezeHeader >= properties.minimalSizeDividedWindow * tableScale &&
          tableHeightFreeze - freezeHeader >=
              properties.minimalSizeDividedWindow * tableScale) {
        stateSplitY = SplitState.freezeSplit;
        switchYFreeze();
      }
    } else {
      if (stateSplitY == SplitState.freezeSplit) {
        unFreezeY();
      } else if (stateSplitY == SplitState.split) {
        switchYSplit();
        _ySplit = 0;
      }

      stateSplitY = SplitState.noSplit;

      ratioSizeAnimatedSplitChangeY = 0.0;
    }
  }

  void unFreezeY() {
    switchYFreeze();
    mainScrollY = scrollY0pX0 =
        scrollY1pX0 - heightLayoutList[1].panelLength / tableScale;
  }

  switchYFreeze() {
    final freezeHeader = (scrollY1pX0 - scrollY0pX0) * tableScale;

    if (freezeHeader < tableHeightFreeze - freezeHeader) {
      switchY();
    }
  }

  switchYSplit() {
    bool switchPanels = false;

    if (autoFreezeAreaY.freeze) {
      final freezeHeader = autoFreezeAreaY.header;

      if (freezeHeader < tableHeightFreeze - freezeHeader) {
        switchPanels = !switchPanels;
      }
    }

    final ySplitCorrected = _ySplit - topHeaderPanelLength - sizeScrollBarTop;

    if (ySplitCorrected < twoPanelViewPortDimensionY() - ySplitCorrected) {
      switchPanels = !switchPanels;
    }

    if (switchPanels) switchY();
  }

  // checkAutoScroll() {
  //   if (tfm.autoFreezePossibleX) calculateAutoScrollX();
  //   if (tfm.autoFreezePossibleY) calculateAutoScrollY();
  // }

  double get freezeMiniSizeScaledX =>
      properties.minimalSizeDividedWindow * tableScale;

  double getMinScrollScaledX(int horizontal) {
    if (model.autoFreezePossibleX) {
      return 0.0;
    } else if (stateSplitX == SplitState.freezeSplit) {
      if (horizontal == 0) {
        final width = twoPanelViewPortDimensionX();

        final positionFreeze = getX(model.topLeftCellPaneColumn) * tableScale;
        return width - freezeMiniSizeScaledX > positionFreeze
            ? 0.0
            : positionFreeze - width + freezeMiniSizeScaledX;
      } else {
        return getX(model.topLeftCellPaneColumn) * tableScale;
      }
    } else {
      return 0.0;
    }
  }

  double get freezeMiniSizeScaledY =>
      properties.minimalSizeDividedWindow * tableScale;

  double getMinScrollScaledY(int vertical) {
    if (model.autoFreezePossibleY) {
      return 0.0;
    } else if (stateSplitY == SplitState.freezeSplit) {
      if (vertical == 0) {
        final height = twoPanelViewPortDimensionY();

        final heightFreeze = getY(model.topLeftCellPaneRow) * tableScale;
        return height - freezeMiniSizeScaledY > heightFreeze
            ? 0.0
            : heightFreeze - height + freezeMiniSizeScaledY;
      } else {
        return getY(model.topLeftCellPaneRow) * tableScale;
      }
    } else {
      return 0.0;
    }
  }

  double getMaxScrollScaledX(int scrollIndex) {
    double maxScroll;

    if (model.autoFreezePossibleX) {
      double lengthPanels = twoPanelViewPortDimensionX();

      maxScroll = model.sheetWidth * tableScale - lengthPanels;
    } else {
      maxScroll = (scrollIndex == 0 && stateSplitX == SplitState.freezeSplit)
          ? (getX(model.topLeftCellPaneColumn) - freezeMiniSizeScaledX) *
                  tableScale -
              precisionMargin
          : model.sheetWidth * tableScale -
              widthLayoutList[scrollIndex + 1].panelLength;
    }

    return (maxScroll < 0.0) ? 0.0 : maxScroll;
  }

  double getMaxScrollScaledY(int scrollIndex) {
    double maxScroll;

    if (model.autoFreezePossibleY) {
      double lengthPanels = twoPanelViewPortDimensionY();

      maxScroll = model.sheetHeight * tableScale - lengthPanels;
    } else {
      maxScroll = (scrollIndex == 0 && stateSplitY == SplitState.freezeSplit)
          ? (getY(model.topLeftCellPaneRow) -
                      properties.minimalSizeDividedWindow) *
                  tableScale -
              precisionMargin
          : model.sheetHeight * tableScale -
              heightLayoutList[scrollIndex + 1].panelLength;
    }
    return (maxScroll < 0.0) ? 0.0 : maxScroll;
  }

  void setScroll(int scrollIndexX, int scrollIndexY, Offset offset) {
    setScrollScaledX(scrollIndexX, scrollIndexY, offset.dx);
    setScrollScaledY(scrollIndexX, scrollIndexY, offset.dy);
  }

  Offset getScrollScaled(
      int scrollIndexX, int scrollIndexY, bool scrollActivity) {
    return getScroll(scrollIndexX, scrollIndexY, scrollActivity) * tableScale;
  }

  @override
  Offset getScroll(int scrollIndexX, int scrollIndexY, bool scrollActivity) {
    return Offset(
        getScrollX(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity),
        getScrollY(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity));
  }

  double getScrollScaledX(int scrollIndexX, int scrollIndexY,
          {bool scrollActivity = false}) =>
      getScrollX(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity) *
      tableScale;

  double getScrollX(int scrollIndexX, int scrollIndexY,
      {bool scrollActivity = false}) {
    if (scrollActivity && model.autoFreezePossibleX) {
      return mainScrollX;
    } else if (scrollIndexY == 0 ||
        !protectedScrollUnlockX ||
        model.anyFreezeSplitY) {
      return scrollIndexX == 0 ? scrollX0pY0 : scrollX1pY0;
    } else {
      return scrollIndexX == 0 ? scrollX0pY1 : scrollX1pY1;
    }
  }

  @override
  DrawScrollBar drawHorizontalScrollBar(int scrollIndexX, int scrollIndexY) {
    if (tableScrollDirection == TableScrollDirection.vertical) {
      return DrawScrollBar.none;
    }

    if (widthLayoutList[scrollIndexX + 1].panelLength >=
        model.sheetWidth * tableScale) return DrawScrollBar.none;

    switch (stateSplitY) {
      case SplitState.split:
        return (scrollIndexY == 0 && stateSplitY == SplitState.split)
            ? (protectedScrollUnlockX ? DrawScrollBar.top : DrawScrollBar.none)
            : DrawScrollBar.bottom;
      default:
        return DrawScrollBar.bottom;
    }
  }

  @override
  DrawScrollBar drawHorizontalScrollBarTrack(
      int scrollIndexX, int scrollIndexY) {
    return scrollBarTrack
        ? drawHorizontalScrollBar(scrollIndexX, scrollIndexY)
        : DrawScrollBar.none;
  }

  double getScrollScaledY(int scrollIndexX, int scrollIndexY,
          {bool scrollActivity = false}) =>
      getScrollY(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity) *
      tableScale;

  double getScrollY(int scrollIndexX, int scrollIndexY,
      {bool scrollActivity = false}) {
    if (scrollActivity && model.autoFreezePossibleY) {
      return mainScrollY;
    } else if (scrollIndexX == 0 ||
        !protectedScrollUnlockY ||
        model.anyFreezeSplitX) {
      return scrollIndexY == 0 ? scrollY0pX0 : scrollY1pX0;
    } else {
      return scrollIndexY == 0 ? scrollY0pX1 : scrollY1pX1;
    }
  }

  @override
  DrawScrollBar drawVerticalScrollBar(int scrollIndexX, int scrollIndexY) {
    if (scrollDirectionByTable == TableScrollDirection.horizontal) {
      return DrawScrollBar.none;
    }

    if (heightLayoutList[scrollIndexY + 1].panelLength >=
        model.sheetHeight * tableScale) return DrawScrollBar.none;

    switch (stateSplitX) {
      case SplitState.split:
        {
          return (scrollIndexX == 0 && stateSplitX == SplitState.split)
              ? (protectedScrollUnlockY
                  ? DrawScrollBar.left
                  : DrawScrollBar.none)
              : DrawScrollBar.right;
        }
      default:
        {
          return DrawScrollBar.right;
        }
    }
  }

  @override
  DrawScrollBar drawVerticalScrollBarTrack(int scrollIndexX, int scrollIndexY) {
    return scrollBarTrack
        ? drawVerticalScrollBar(scrollIndexX, scrollIndexY)
        : DrawScrollBar.none;
  }

  SelectionIndex findFirstColumn(int scrollIndexX, int scrollIndexY,
      {double width = 0.0}) {
    double x = getScrollX(scrollIndexX, scrollIndexY) + width;
    return model.findSelectionIndexX(x, 0);
  }

  SelectionIndex findLastColumn(int scrollIndexX, int scrollIndexY,
      {double width = 0.0}) {
    double x = getScrollX(scrollIndexX, scrollIndexY) + width;
    return model.findSelectionIndexX(
      x,
      1,
    );
  }

  SelectionIndex findFirstRow(int scrollIndexX, int scrollIndexY,
      {double height = 0.0}) {
    double y = getScrollY(scrollIndexX, scrollIndexY);
    return model.findSelectionIndexY(
      y,
      0,
    );
  }

  SelectionIndex findLastRow(int scrollIndexX, int scrollIndexY,
      {double height = 0.0}) {
    double y = getScrollY(scrollIndexX, scrollIndexY) + height;
    return model.findSelectionIndexY(
      y,
      1,
    );
  }

  /// layout panels
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  List<GridInfo> rowInfoListX0Y0 = [];
  List<GridInfo> rowInfoListX0Y1 = [];
  List<GridInfo> rowInfoListX1Y0 = [];
  List<GridInfo> rowInfoListX1Y1 = [];
  List<GridInfo> columnInfoListX0Y0 = [];
  List<GridInfo> columnInfoListX0Y1 = [];
  List<GridInfo> columnInfoListX1Y0 = [];
  List<GridInfo> columnInfoListX1Y1 = [];

  LayoutPanelIndex layoutPanelIndex(int panelIndex) {
    return _layoutIndex[panelIndex];
  }

  int panelIndex(int row, int column) {
    return _panelIndex[column * 4 + row];
  }

  switchX() {
    for (int r = 0; r < 4; r++) {
      int firstIndex = 1 * 4 + r;
      int secondIndex = 2 * 4 + r;

      exchange(_panelIndex, firstIndex, secondIndex);
      exchange(_layoutIndex, firstIndex, secondIndex);
    }
  }

  switchY() {
    for (int c = 0; c < 4; c++) {
      int firstIndex = c * 4 + 1;
      int secondIndex = c * 4 + 2;

      exchange(_panelIndex, firstIndex, secondIndex);
      exchange(_layoutIndex, firstIndex, secondIndex);
    }
  }

  exchange(List list, firstIndex, secondIndex) {
    final temp = list[firstIndex];
    list[firstIndex] = list[secondIndex];
    list[secondIndex] = temp;
  }

  void calculate({required double width, required double height}) {
    final oldStateSplitX = stateSplitX;
    final oldStateSplitY = stateSplitY;

    final widthChanged = _widthMainPanel != width;
    final heightChanged = _heightMainPanel != height;
    final deltaWidth = _widthMainPanel - width;
    final deltaHeight = _heightMainPanel - height;

    if (widthChanged) {
      _widthMainPanel = width;
    }

    if (heightChanged) {
      _heightMainPanel = height;
    }

    if (!modifySplit &&
        tableScrollDirection != TableScrollDirection.horizontal) {
      adjustSplitStateAfterWidthResize(width);
    }

    if (!modifySplit && tableScrollDirection != TableScrollDirection.vertical) {
      adjustSplitStateAfterWidthResize(width);
    }

    if (!modifySplit) {
      adjustSplitStateAfterHeightResize(height);
    }

    final maxHeightNoSplit = computeMaxIntrinsicHeightNoSplit(width);

    _layoutY(
        maxHeightNoSplit:
            maxHeightNoSplit + sizeScrollBarBottom + bottomHeaderLayoutLength,
        height: height);

    findRowHeaderWidth();

    //findRowHeaderWidth is peformed in LayoutY

    final maxWidthNoSplit = computeMaxIntrinsicWidthNoSplit(height);

    _layoutX(
        maxWidthNoSplit:
            maxWidthNoSplit + sizeScrollBarRight + rightHeaderLayoutLength,
        width: width);

    if (firstLayout) {
      firstLayout = false;
      _checkFirstLayout(width, height);
    }

    _checkScroll(
        widthChanged: widthChanged,
        heightChanged: heightChanged,
        deltaHeight: deltaHeight,
        deltaWidth: deltaWidth);

    if (widthChanged ||
        heightChanged ||
        stateSplitX != oldStateSplitX ||
        stateSplitY != oldStateSplitY) {
      scheduleMicrotask(() {
        _notifyChange();
      });
    }

    refreshEditPanel();
  }

  PanelCellIndex currentEditCell = const PanelCellIndex();
  bool focusJump = false;

  refreshEditPanel() {
    if (!_editCell.isIndex) {
      currentEditCell = const PanelCellIndex();
      return;
    }

    final previousPanelIndexX = currentEditCell.panelIndexX;
    final previousPanelIndexY = currentEditCell.panelIndexY;

    int panelIndexX = -1;
    int panelIndexY = -1;

    switch ((stateSplitX, _editCell.panelIndexX, _editCell.column)) {
      case (SplitState.split, int panelIndexEditX, _):
        {
          panelIndexX = panelIndexEditX;
          break;
        }
      case (SplitState.freezeSplit, int panelIndexEditX, int columnEdit):
        {
          panelIndexX = determineFreezePanel(
              panelIndexEditX, model.topLeftCellPaneColumn, columnEdit);
          break;
        }
      case (SplitState.autoFreezeSplit, int panelIndexEditX, int columnEdit):
        {
          panelIndexX = determineFreezePanel(
              panelIndexEditX, autoFreezeAreaX.freezeIndex, columnEdit);

          break;
        }
      case (_, _, _):
        {
          panelIndexX = 1;
        }
    }

    switch ((stateSplitY, _editCell.panelIndexY, _editCell.row)) {
      case (SplitState.split, int panelIndexEditY, _):
        {
          panelIndexY = panelIndexEditY;
          break;
        }
      case (SplitState.freezeSplit, int panelIndexEditY, int rowEdit):
        {
          panelIndexY = determineFreezePanel(
              panelIndexEditY, model.topLeftCellPaneRow, rowEdit);

          break;
        }
      case (SplitState.autoFreezeSplit, int panelIndexEditY, int rowEdit):
        {
          panelIndexY = determineFreezePanel(
              panelIndexEditY, autoFreezeAreaY.freezeIndex, rowEdit);

          break;
        }
      case (_, _, _):
        {
          panelIndexY = 1;
          break;
        }
    }

    currentEditCell =
        _editCell.copyWith(panelIndexX: panelIndexX, panelIndexY: panelIndexY);

    if (panelIndexX != -1 &&
        previousPanelIndexX != panelIndexX &&
        previousPanelIndexY != panelIndexY) {
      focusJump = true;
    }
  }

  int determineFreezePanel(int panel, int freeze, int index) =>
      freeze <= index ? 2 : 1;

  _checkFirstLayout(double width, double height) {
    bool layout = false;
    firstLayout = false;
    switch (stateSplitY) {
      case (SplitState.noSplit ||
            SplitState.canceledFreezeSplit ||
            SplitState.autoFreezeSplit):
        {
          layout = simpleYBoundery(0, 0);
        }
      default:
        {}
    }

    if (layout) {
      final maxHeightNoSplit = computeMaxIntrinsicHeightNoSplit(width);
      _layoutY(
          maxHeightNoSplit:
              maxHeightNoSplit + sizeScrollBarBottom + bottomHeaderLayoutLength,
          height: height);

      findRowHeaderWidth();

      final maxWidthNoSplit = computeMaxIntrinsicWidthNoSplit(height);

      _layoutX(
          maxWidthNoSplit:
              maxWidthNoSplit + sizeScrollBarRight + rightHeaderLayoutLength,
          width: width);
    }
  }

  /// Simple boundery for one panel use for the first layout
  ///
  ///
  ///
  bool simpleYBoundery(int scrollIndexX, int scrollIndexY) {
    double scrollYscalled = mainScrollY * tableScale;
    const min = 0.0;
    final lengthPanels = twoPanelViewPortDimensionY();

    final max = model.sheetHeight * tableScale - lengthPanels;
    double scrollYScalledClamped = max < 0.0
        ? 0.0
        : clampDouble(
            scrollYscalled,
            min,
            max,
          );

    if (scrollYscalled != scrollYScalledClamped) {
      mainScrollY = scrollY0pX0 = scrollYScalledClamped / tableScale;
      return true;
    }
    return false;
  }

  _layoutY({required double maxHeightNoSplit, required double height}) {
    double yOffset = 0.0;

    if (maxHeightNoSplit < height) {
      /// Skip autoFreeze otherwise the noSplit will trigger SwitchX
      ///
      if (model.anyNoAutoFreezeY) {
        stateSplitY = SplitState.noSplit;
      }

      final centerY = (height - maxHeightNoSplit) / 2.0;

      yOffset = centerY + centerY * properties.alignment.y;
      height = maxHeightNoSplit;
    }

    panelLength(
        gridLayoutList: heightLayoutList,
        splitState: stateSplitY,
        panelLength: height,
        headerStartPanelLength: topHeaderPanelLength,
        headerEndPanelLength: bottomHeaderPanelLength,
        headerStartLayoutLength: topHeaderPanelLength,
        headerEndLayoutLength: bottomHeaderLayoutLength,
        splitPosition: ySplit,
        startMargin: properties.panelPadding.top,
        endMargin: properties.panelPadding.bottom,
        sizeScrollBarAtStart: sizeScrollBarTop,
        sizeScrollBarAtEnd: sizeScrollBarBottom,
        spaceSplitDivider: spaceSplitDividerY);

    position(heightLayoutList, sizeScrollBarTop + yOffset);

    _calculateRowInfoList(0, 0, rowInfoListX0Y0);

    if (stateSplitX == SplitState.split && protectedScrollUnlockY) {
      _calculateRowInfoList(1, 0, rowInfoListX1Y0);
    } else {
      rowInfoListX1Y0.clear();
    }

    if (stateSplitY != SplitState.noSplit) {
      _calculateRowInfoList(0, 1, rowInfoListX0Y1);

      if (stateSplitX == SplitState.split && protectedScrollUnlockY) {
        _calculateRowInfoList(1, 1, rowInfoListX1Y1);
      } else {
        rowInfoListX1Y1.clear();
      }
    } else {
      rowInfoListX1Y1.clear();
    }
  }

  _layoutX({required double maxWidthNoSplit, required double width}) {
    double xOffset = 0.0;

    if (maxWidthNoSplit < width) {
      /// Skip autoFreeze otherwise the noSplit will trigger SwitchX
      ///
      if (model.anyNoAutoFreezeX) {
        stateSplitX = SplitState.noSplit;
      }
      final centerX = (width - maxWidthNoSplit) / 2.0;
      xOffset = centerX + centerX * properties.alignment.x;
      width = maxWidthNoSplit;
    }

    panelLength(
        gridLayoutList: widthLayoutList,
        splitState: stateSplitX,
        panelLength: width,
        headerStartPanelLength: leftHeaderPanelLength,
        headerEndPanelLength: rightHeaderPanelLength,
        headerStartLayoutLength: leftHeaderPanelLength,
        headerEndLayoutLength: rightHeaderLayoutLength,
        splitPosition: xSplit,
        startMargin: properties.panelPadding.left,
        endMargin: properties.panelPadding.right,
        sizeScrollBarAtStart: sizeScrollBarLeft,
        sizeScrollBarAtEnd: sizeScrollBarRight,
        spaceSplitDivider: spaceSplitDividerX);

    position(widthLayoutList, sizeScrollBarLeft + xOffset);

    _calculateColumnInfoList(0, 0, columnInfoListX0Y0);

    if (stateSplitY == SplitState.split && protectedScrollUnlockX) {
      _calculateColumnInfoList(0, 1, columnInfoListX0Y1);
    } else {
      columnInfoListX0Y1.clear();
    }

    if (stateSplitX != SplitState.noSplit) {
      _calculateColumnInfoList(1, 0, columnInfoListX1Y0);

      if (stateSplitY == SplitState.split && protectedScrollUnlockX) {
        _calculateColumnInfoList(1, 1, columnInfoListX1Y1);
      } else {
        columnInfoListX1Y1.clear();
      }
    } else {
      columnInfoListX1Y1.clear();
    }
  }

  bool _isSplitInWindowX(double width, SplitState stateSplitX) {
    double minimumWidthForCell = 0.0;
    int column = -1;

    if (_editCell.isIndex) {
      column = _editCell.columns;
      final x0 = getY(_editCell.column);
      final x1 = getY(_editCell.column + _editCell.columns);

      minimumWidthForCell =
          (x1 - x0 + properties.editPadding.horizontal) * tableScale;
    }

    final minWidthPanel = properties.minimalSizeDividedWindow * tableScale;

    switch (stateSplitX) {
      case SplitState.autoFreezeSplit:
        {
          final minimumWidthPanel2 =
              (autoFreezeAreaX.freeze && column > autoFreezeAreaX.freezeIndex)
                  ? math.max(minWidthPanel, minimumWidthForCell)
                  : minWidthPanel;

          final xStartPanel =
              leftHeaderPanelLength + properties.panelPadding.left;
          final xEndPanel =
              width - sizeScrollBarTrack - properties.panelPadding.right;

          final panel2 =
              xEndPanel - xStartPanel - autoFreezeAreaX.header * tableScale;
          return minimumWidthPanel2 <= panel2;
        }
      case SplitState.freezeSplit:
        {
          final minimumWidthPanel2 = column > model.topLeftCellPaneColumn
              ? math.max(minWidthPanel, minimumWidthForCell)
              : minWidthPanel;

          final xStartPanel =
              leftHeaderPanelLength + properties.panelPadding.left;
          final xEndPanel =
              width - sizeScrollBarTrack - properties.panelPadding.right;

          double panel2 = xEndPanel -
              xStartPanel -
              (getX(model.topLeftCellPaneColumn) - scrollX0pY0) * tableScale;
          return minimumWidthPanel2 <= panel2;
        }
      case SplitState.split:
        {
          final xEnd = width -
              sizeScrollBarTrack -
              rightHeaderLayoutLength -
              properties.panelPadding.right;

          final minimumHeightPanel2 = _editCell.panelIndexX == 3
              ? math.max(minWidthPanel, minimumWidthForCell)
              : minWidthPanel;

          return minimumHeightPanel2 < xEnd - _xSplit;
        }
      default:
        {
          return false;
        }
    }
  }

  bool _isSplitInWindowY(double height, SplitState stateSplitY) {
    double minimumHeightForCell = 0.0;
    int row = -1;

    if (_editCell.isIndex) {
      row = _editCell.row;
      final y0 = getY(_editCell.row);
      final y1 = getY(_editCell.row + _editCell.rows);

      minimumHeightForCell =
          (y1 - y0 + properties.editPadding.vertical) * tableScale;
    }
    final minHeightPanel = properties.minimalSizeDividedWindow * tableScale;

    switch (stateSplitY) {
      case SplitState.autoFreezeSplit:
        {
          final minimumHeightPanel2 =
              (autoFreezeAreaY.freeze && row > autoFreezeAreaY.freezeIndex)
                  ? math.max(minHeightPanel, minimumHeightForCell)
                  : minHeightPanel;

          final yStartPanel =
              topHeaderPanelLength + properties.panelPadding.top;
          final yEndPanel =
              height - sizeScrollBarTrack - properties.panelPadding.bottom;

          final panel2 =
              yEndPanel - yStartPanel - autoFreezeAreaY.header * tableScale;

          return minimumHeightPanel2 <= panel2;
        }
      case SplitState.freezeSplit:
        {
          final minimumHeightPanel2 = row > model.topLeftCellPaneRow
              ? math.max(minHeightPanel, minimumHeightForCell)
              : minHeightPanel;

          final yStartPanel =
              topHeaderPanelLength + properties.panelPadding.top;
          final yEndPanel =
              height - sizeScrollBarTrack - properties.panelPadding.bottom;

          double panel2 = yEndPanel -
              yStartPanel -
              (getY(model.topLeftCellPaneRow) - scrollY0pX0) * tableScale;
          return minimumHeightPanel2 <= panel2;
        }
      case SplitState.split:
        {
          final yEnd = height -
              sizeScrollBarTrack -
              bottomHeaderLayoutLength -
              properties.panelPadding.bottom * tableScale;

          final minimumHeightPanel2 = _editCell.panelIndexY == 3
              ? math.max(minHeightPanel, minimumHeightForCell)
              : minHeightPanel;

          return minimumHeightPanel2 < yEnd - _ySplit;
        }
      default:
        {
          return false;
        }
    }
  }

  // bool isSplitInWindowX(double width) {
  //   final xStart = (protectedScrollUnlockY ? sizeScrollBarTrack : 0.0) +
  //       leftHeaderPanelLength +
  //       properties.panelPadding.left +
  //       properties.minimalSizeDividedWindow * tableScale;
  //   final xEnd = width -
  //       sizeScrollBarTrack -
  //       rightHeaderLayoutLength -
  //       properties.panelPadding.right -
  //       properties.minimalSizeDividedWindow * tableScale;

  //   return _xSplit >= xStart && _xSplit <= xEnd;
  // }

  // bool isSplitInWindowY(double height) {
  //   final yStart = (protectedScrollUnlockX ? sizeScrollBarTrack : 0.0) +
  //       topHeaderPanelLength +
  //       properties.panelPadding.top +
  //       properties.minimalSizeDividedWindow * tableScale;
  //   final yEnd = height -
  //       sizeScrollBarTrack -
  //       bottomHeaderLayoutLength -
  //       properties.minimalSizeDividedWindow * tableScale;

  //   return _ySplit >= yStart && _ySplit <= yEnd;
  // }

  adjustSplitStateAfterWidthResize(double width) {
    if ((_editCell.isIndex, stateSplitX)
        case (
          true,
          SplitState.canceledAutoFreezeSplit ||
              SplitState.canceledFreezeSplit ||
              SplitState.canceledSplit
        )) {
      return;
    }

    switch ((autoFreezePossibleX, stateSplitX)) {
      /// AutoFreezeSplit
      ///
      ///

      case (true, SplitState.autoFreezeSplit || SplitState.noSplit):
        {
          calculateAutoFreezeX(width: width);

          if (stateSplitX == SplitState.autoFreezeSplit &&
              previousEditCell.isIndex) {
            // showCell(previousEditCell.copyWith(row: previousEditCell.row - 1));
            previousEditCell = const PanelCellIndex();
          }
          break;
        }
      case (true, SplitState.canceledAutoFreezeSplit):
        {
          // Nothing to do
          break;
        }

      /// FreezeSplit
      ///
      ///

      case (_, SplitState.freezeSplit):
        {
          if (!_isSplitInWindowX(width, SplitState.freezeSplit)) {
            stateSplitX = SplitState.canceledFreezeSplit;

            mainScrollX =
                scrollX1pY0 - (getX(model.topLeftCellPaneColumn) - scrollX0pY0);
          }

          break;
        }
      case (_, SplitState.canceledFreezeSplit):
        {
          if (_isSplitInWindowX(width, SplitState.freezeSplit)) {
            stateSplitX = SplitState.freezeSplit;

            scrollX0pY0 = getX(model.topLeftCellPaneColumn);
            final noScrollX1pY0 =
                mainScrollX + (getX(model.topLeftCellPaneColumn) - scrollX0pY0);

            //Keep scroll unless beyound the freeze line
            if (scrollX1pY0 < noScrollX1pY0) {
              scrollX1pY0 = noScrollX1pY0;
            }
          }
          break;
        }

      /// Split
      ///
      ///

      case (_, SplitState.split):
        {
          if (!_isSplitInWindowX(width, SplitState.split)) {
            stateSplitX = SplitState.canceledSplit;
            mainScrollX = scrollX0pY0;
          }
          break;
        }

      case (_, SplitState.canceledSplit):
        {
          if (_isSplitInWindowX(width, SplitState.split)) {
            stateSplitX = SplitState.split;
            scrollX0pY0 = mainScrollX;
          }
          break;
        }

      default:
        {}
    }
  }

  RestoreScroll? restoreScroll;

  adjustSplitStateAfterHeightResize(double height) {
    if ((_editCell.isIndex, stateSplitY)
        case (
          true,
          SplitState.canceledAutoFreezeSplit ||
              SplitState.canceledFreezeSplit ||
              SplitState.canceledSplit
        )) {
      return;
    }

    switch ((autoFreezePossibleY, stateSplitY)) {
      /// AutoFreezeSplit
      ///
      ///

      case (true, SplitState.autoFreezeSplit || SplitState.noSplit):
        {
          calculateAutoFreezeY(height: height);

          break;
        }
      case (_, SplitState.canceledAutoFreezeSplit):
        {
          calculateAutoFreezeY(height: height);
          // debugPrint(
          //     'stateSplitY $stateSplitY  previousEditCell.isIndex ${previousEditCell.isIndex}');
          if (stateSplitY == SplitState.autoFreezeSplit &&
              previousEditCell.isIndex) {
            // restoreScroll = restoreScroll?.copyIf(useMainScrollY: true);
            animateRestoreScroll();
          }

          break;
        }

      /// Split
      ///
      ///

      case (_, SplitState.split):
        {
          if (!_isSplitInWindowY(height, SplitState.split)) {
            stateSplitY = SplitState.canceledSplit;
          }
          break;
        }

      case (_, SplitState.canceledSplit):
        {
          if (_isSplitInWindowY(height, SplitState.split)) {
            stateSplitY = SplitState.split;

            // restoreScroll =
            //     restoreScroll?.copyIf(useScrollY0: true, useScrollY1: true);
            animateRestoreScroll();
          }
          break;
        }

      /// FreezeSplit
      ///
      ///
      case (_, SplitState.freezeSplit):
        {
          if (!_isSplitInWindowY(height, SplitState.freezeSplit)) {
            stateSplitY = SplitState.canceledFreezeSplit;

            mainScrollY =
                scrollY1pX0 - (getY(model.topLeftCellPaneRow) - scrollY0pX0);
          }
          break;
        }
      case (_, SplitState.canceledFreezeSplit):
        {
          if (_isSplitInWindowY(height, SplitState.freezeSplit)) {
            stateSplitY = SplitState.freezeSplit;

            final noScrollY1pX0 =
                mainScrollY + (getY(model.topLeftCellPaneRow) - scrollY0pX0);

            //Keep scroll unless beyound the freeze line
            if (scrollY1pX0 < noScrollY1pX0) {
              scrollY1pX0 = noScrollY1pX0;
            }

            if (restoreScroll?.scrollY0 case double s) {
              scrollY0pX0 = s;
            }
          }
          break;
        }

      default:
        {
          // if (model.autoFreezePossibleY) {
          //   calculateAutoFreezeY();
          // }
        }
    }
  }

  _calculateRowInfoList(
      int scrollIndexX, int scrollIndexY, List<GridInfo> rowInfoList) {
    final top = getScrollY(scrollIndexX, scrollIndexY);
    final bottom =
        top + heightLayoutList[scrollIndexY + 1].panelLength / tableScale;

    if (rowInfoList.isEmpty ||
        rowInfoList.first.outside(top) ||
        rowInfoList.last.outside(bottom)) {
      model.gridInfoListY(begin: top, end: bottom, rowInfoList: rowInfoList);
    }
  }

  _calculateColumnInfoList(
      int scrollIndexX, int scrollIndexY, List<GridInfo> columnInfoList) {
    final left = getScrollX(scrollIndexX, scrollIndexY);
    final right =
        left + widthLayoutList[scrollIndexX + 1].panelLength / tableScale;

    if (columnInfoList.isEmpty ||
        columnInfoList.first.outside(left) ||
        columnInfoList.last.outside(right)) {
      model.gridInfoListX(
          begin: left, end: right, columnInfoList: columnInfoList);
    }
  }

  List<GridInfo> getRowInfoList(scrollIndexX, scrollIndexY) {
    if (scrollIndexX == 0 || !protectedScrollUnlockY || model.anyFreezeSplitX) {
      return scrollIndexY == 0 ? rowInfoListX0Y0 : rowInfoListX0Y1;
    } else {
      return scrollIndexY == 0 ? rowInfoListX1Y0 : rowInfoListX1Y1;
    }
  }

  List<GridInfo> getColumnInfoList(int scrollIndexX, int scrollIndexY) {
    if (scrollIndexY == 0 || !protectedScrollUnlockX || model.anyFreezeSplitY) {
      return scrollIndexX == 0 ? columnInfoListX0Y0 : columnInfoListX1Y0;
    } else {
      return scrollIndexX == 0 ? columnInfoListX0Y1 : columnInfoListX1Y1;
    }
  }

  calculateHeaderWidth() {
    int count = 0;
    int rowNumber = model.tableRows + 1;

    if (rowHeader) {
      while (rowNumber > 0) {
        rowNumber = rowNumber ~/ 10;
        count++;
      }

      double startPosition = 0.0;

      headerRows = List.generate(count, (listIndex) {
        int i = 1;
        int c = 0;

        while (c < listIndex + 1) {
          i *= 10;
          c++;
        }
        final position = getY(i - 1);
        final item = HeaderProperties(
            index: i - 1,
            startPosition: startPosition,
            endPosition: position,
            digits: listIndex + 1);
        startPosition = position;

        return item;
      }, growable: false);
    } else {
      headerRows = List.empty();
      leftRowHeaderProperty = noHeader;
      rightRowHeaderProperty = noHeader;
    }
  }

  findRowHeaderWidth() {
    if (rowHeader) {
      leftRowHeaderProperty = findWidthLeftHeader();
    } else {
      leftRowHeaderProperty = noHeader;
    }

    if (model.columnHeader &&
        stateSplitX == SplitState.split &&
        protectedScrollUnlockY) {
      rightRowHeaderProperty = findWidthRightHeader();
    } else {
      rightRowHeaderProperty = noHeader;
    }
  }

  HeaderProperties findWidthLeftHeader() {
    if (headerRows.isEmpty) return noHeader;

    double bottomLeftHeader =
        (heightLayoutList[1].panelLength + getScrollY(0, 0) * tableScale) /
            tableScale;

    if (model.anySplitY) {
      final bottomLeftHeaderSecond =
          (heightLayoutList[2].panelLength + getScrollY(0, 1) * tableScale) /
              tableScale;
      bottomLeftHeader = math.max(bottomLeftHeader, bottomLeftHeaderSecond);
    }

    for (HeaderProperties item in headerRows) {
      if (bottomLeftHeader < item.endPosition) {
        return item;
      }
    }

    return headerRows.last;
  }

  HeaderProperties findWidthRightHeader() {
    if (headerRows.isEmpty || !protectedScrollUnlockY) return noHeader;

    double bottomRightHeader =
        (heightLayoutList[1].panelLength + getScrollY(1, 0) * tableScale) /
            tableScale;

    if (stateSplitY == SplitState.split) {
      final bottomRightHeaderSecond =
          (heightLayoutList[2].panelLength + getScrollY(1, 1) * tableScale) /
              tableScale;
      bottomRightHeader = math.max(bottomRightHeader, bottomRightHeaderSecond);
    }

    for (HeaderProperties item in headerRows) {
      if (bottomRightHeader < item.endPosition) {
        return item;
      }
    }

    return headerRows.last;
  }

  double digitsToWidth(HeaderProperties headerProperty) =>
      (headerProperty.index != -1)
          ? tableBuilder.rowHeaderWidth(headerProperty) * scaleRowHeader
          : 0.0;

  double get sizeScrollBarLeft => (!protectedScrollUnlockY
      ? 0.0
      : sizeScrollBarTrack *
          ratioVerticalScrollBarTrack *
          ratioSizeAnimatedSplitChangeX);

  double get sizeScrollBarRight => switch (scrollDirectionByTable) {
        TableScrollDirection.horizontal => 0.0,
        (_) => sizeScrollBarTrack * ratioVerticalScrollBarTrack
      };

  double get sizeScrollBarTop => (!protectedScrollUnlockX
      ? 0.0
      : sizeScrollBarTrack *
          ratioHorizontalScrollBarTrack *
          ratioSizeAnimatedSplitChangeY);

  double get sizeScrollBarBottom =>
      sizeScrollBarTrack * ratioHorizontalScrollBarTrack;

  double get initiateSplitLeft => leftHeaderPanelLength;

  double get initiateSplitTop => topHeaderPanelLength;

  double get initiateSplitRight => _widthMainPanel - sizeScrollBarTrack;

  double get initiateSplitBottom => _heightMainPanel - sizeScrollBarTrack;

  double get tableWidthFreeze =>
      _widthMainPanel - leftHeaderPanelLength - sizeScrollBarTrack;

  double get tableHeightFreeze =>
      _heightMainPanel - topHeaderPanelLength - sizeScrollBarTrack;

  double get minFreezePositionLeft {
    return properties.panelPadding.left +
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get minFreezePositionTop {
    return properties.panelPadding.top +
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get maxFreezePositionRight {
    return _widthMainPanel -
        sizeScrollBarTrack -
        properties.panelPadding.right -
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get maxFreezePositionBottom {
    return _heightMainPanel -
        sizeScrollBarTrack -
        properties.panelPadding.bottom -
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get minSplitPositionLeft {
    return (protectedScrollUnlockY ? sizeScrollBarTrack : 0.0) +
        digitsToWidth(findWidthLeftHeader()) +
        properties.panelPadding.left +
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get minSplitPositionTop {
    return (protectedScrollUnlockY ? sizeScrollBarTrack : 0.0) +
        topHeaderPanelLength +
        properties.panelPadding.top +
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get maxSplitPositionRight {
    return _widthMainPanel -
        sizeScrollBarTrack -
        digitsToWidth(findWidthRightHeader()) -
        properties.panelPadding.right -
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get maxSplitPositionBottom {
    return _heightMainPanel -
        sizeScrollBarTrack -
        (!protectedScrollUnlockX || !model.columnHeader
            ? 0.0
            : tableBuilder.columnHeaderHeight * scaleColumnHeader) -
        properties.panelPadding.bottom -
        properties.minimalSizeDividedWindow * model.tableScale;
  }

  double get leftScrollBarHit {
    return protectedScrollUnlockY ? properties.hitScrollBarThickness : 0.0;
  }

  double get topScrollBarHit {
    return protectedScrollUnlockX ? properties.hitScrollBarThickness : 0.0;
  }

  double get rightScrollBarHit => properties.hitScrollBarThickness;

  double get bottomScrollBarHit => properties.hitScrollBarThickness;

  double get leftHeaderPanelLength => digitsToWidth(leftRowHeaderProperty);

  double get topHeaderPanelLength => model.columnHeader
      ? tableBuilder.columnHeaderHeight * scaleColumnHeader
      : 0.0;

  double get rightHeaderPanelLength =>
      rightHeaderLayoutLength * ratioSizeAnimatedSplitChangeX;

  double get rightHeaderLayoutLength => digitsToWidth(rightRowHeaderProperty);

  double get bottomHeaderPanelLength =>
      bottomHeaderLayoutLength * ratioSizeAnimatedSplitChangeY;

  double get bottomHeaderLayoutLength => model.columnHeader &&
          stateSplitY == SplitState.split &&
          protectedScrollUnlockX
      ? tableBuilder.columnHeaderHeight * scaleColumnHeader
      : 0.0;

  rowVisible(int row) => heightLayoutList[row].inUse;

  columnVisible(int column) => widthLayoutList[column].inUse;

  position(List<GridLayout> gridLengthList, double position) {
    for (var gridLength in gridLengthList) {
      gridLength.gridPosition = position;
      position += gridLength.gridLength;
    }
  }

  void panelLength(
      {required List<GridLayout> gridLayoutList,
      required SplitState splitState,
      required double panelLength,
      required double headerStartPanelLength,
      required double headerEndPanelLength,
      required double headerStartLayoutLength,
      required double headerEndLayoutLength,
      required double? splitPosition,
      required double startMargin,
      required double endMargin,
      required double sizeScrollBarAtStart,
      required double sizeScrollBarAtEnd,
      required double Function() spaceSplitDivider}) {
    if (modifySplit) {
      if (splitPosition == null) {
        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength: panelLength -
                headerStartPanelLength -
                sizeScrollBarAtStart -
                sizeScrollBarAtEnd,
            marginBegin: startMargin,
            marginEnd: endMargin);
        gridLayoutList[2].empty();
      } else {
        var halfSpace = spaceSplitDivider() / 2.0;

        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength:
                splitPosition - headerStartPanelLength - sizeScrollBarAtStart,
            marginBegin: startMargin,
            marginEnd: halfSpace);

        gridLayoutList[2].setGridLayout(
            index: 2,
            gridLength: panelLength -
                splitPosition -
                headerEndPanelLength -
                sizeScrollBarAtEnd,
            marginBegin: halfSpace,
            marginEnd: endMargin);
      }
    } else if (splitPosition == null) {
      if (panelLength < headerStartPanelLength) {
        headerStartPanelLength = 0.0;
      } else if (panelLength < 2.0 * headerStartPanelLength) {
        headerStartPanelLength = panelLength - headerStartPanelLength;
      }

      gridLayoutList[1].setGridLayout(
          index: 1,
          gridLength: panelLength -
              headerStartPanelLength -
              sizeScrollBarAtStart -
              sizeScrollBarAtEnd,
          marginBegin: startMargin,
          marginEnd: endMargin);
      gridLayoutList[2].empty();
    } else {
      var halfSpace = spaceSplitDivider() / 2.0;

      if (panelLength < splitPosition - halfSpace) {
        halfSpace = 0.0;

        double split;

        if (panelLength < headerStartPanelLength) {
          split = panelLength;
          headerStartPanelLength = 0.0;
        } else if (panelLength < 2.0 * headerStartPanelLength) {
          split = headerStartPanelLength;
          headerStartPanelLength = panelLength - split;
        } else {
          split = panelLength - headerStartPanelLength;
        }

        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength: split,
            marginBegin: startMargin,
            marginEnd: halfSpace);
        gridLayoutList[2].empty();
        headerEndPanelLength = 0.0;
      } else {
        if (splitPosition < headerStartPanelLength) {
          splitPosition = headerStartPanelLength;
        }

        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength:
                splitPosition - headerStartPanelLength - sizeScrollBarAtStart,
            marginBegin: startMargin,
            marginEnd: halfSpace);

        var second = panelLength - splitPosition - halfSpace;

        if (second < headerEndPanelLength + sizeScrollBarAtEnd) {
          if (second < sizeScrollBarAtEnd) {
            headerEndPanelLength = 0.0;
            sizeScrollBarAtEnd = second;
          } else {
            headerEndPanelLength = second - sizeScrollBarAtEnd;
            sizeScrollBarAtEnd = second;
          }
        }

        if (splitPosition >
            panelLength - headerEndPanelLength - sizeScrollBarAtEnd) {
          splitPosition =
              panelLength - headerEndPanelLength - sizeScrollBarAtEnd;
        }

        gridLayoutList[2].setGridLayout(
            index: 2,
            gridLength: panelLength -
                splitPosition -
                headerEndPanelLength -
                sizeScrollBarAtEnd,
            marginBegin: halfSpace,
            marginEnd: endMargin);
      }

      // print(
      //     'twoPanelViewPortDimensionY ${twoPanelViewPortDimensionY()} $mainScrollY');
    }

    gridLayoutList[0].setGridLayout(
        index: 0,
        gridLength: headerStartPanelLength,
        preferredGridLength: headerStartLayoutLength);
    gridLayoutList[3].setGridLayout(
        index: 3,
        gridLength: headerEndPanelLength,
        preferredGridLength: headerEndLayoutLength);
  }

  double computeMaxIntrinsicWidth(double height) {
    if (stateSplitX == SplitState.freezeSplit && !model.autoFreezePossibleX) {
      final xTopLeft = getX(model.topLeftCellPaneColumn);

      return leftHeaderPanelLength +
          (xTopLeft - scrollX0pY0) * tableScale +
          spaceSplitDividerX() +
          (model.sheetWidth - xTopLeft) * tableScale +
          sizeScrollBarTrack;
    } else {
      return computeMaxIntrinsicWidthNoSplit(height);
    }
  }

  double computeMaxIntrinsicWidthNoSplit(double height) =>
      leftHeaderPanelLength +
      model.sheetWidth * tableScale +
      sizeScrollBarTrack +
      properties.panelPadding.horizontal;

  double computeMaxIntrinsicHeight(double width) {
    if (stateSplitY == SplitState.freezeSplit && !model.autoFreezePossibleY) {
      final yTopLeft = getY(model.topLeftCellPaneRow);

      return heightLayoutList[0].gridLength +
          (yTopLeft - scrollY0pX0) * tableScale +
          spaceSplitDividerY() +
          (model.sheetHeight - yTopLeft) * tableScale +
          sizeScrollBarTrack;
    } else {
      return computeMaxIntrinsicHeightNoSplit(width);
    }
  }

  double computeMaxIntrinsicHeightNoSplit(double width) =>
      topHeaderPanelLength +
      model.sheetHeight * tableScale +
      sizeScrollBarTrack +
      properties.panelPadding.vertical;

  markNeedsLayout() {
    if (mounted) {
      notifyListeners();
      _notifyChange();
    } else {
      debugPrint(
          'Try to notifyListeners will viewModel is unMounted already (disposed)');
    }
  }

  _notifyChange() {
    for (final flexTableChangeNotifier in tableChangeNotifiers) {
      flexTableChangeNotifier.change(this);
    }
  }

  @override
  TableScrollDirection get tableScrollDirection {
    return TableScrollDirection.both;
    // if (sliverScrollPosition == null) {
    //   return TableScrollDirection.both;
    // } else {
    //   switch (sliverScrollPosition!.axisDirection) {
    //     case AxisDirection.down:
    //     case AxisDirection.up:
    //       assert(stateSplitY != SplitState.split,
    //           'Split Y (vertical split) is not possible if sliver scroll direction is also vertical');

    //       return TableScrollDirection.horizontal;
    //     case AxisDirection.left:
    //     case AxisDirection.right:
    //       assert((stateSplitX != SplitState.split),
    //           'Split X (horizontal split) is not possible if sliver scroll direction is also horizontal');
    //       return TableScrollDirection.vertical;
    //   }
    // }
  }

  TableScrollDirection get scrollDirectionByTable {
    if (sliverScrollPosition == null) {
      return TableScrollDirection.both;
    } else {
      switch (sliverScrollPosition!.axisDirection) {
        case AxisDirection.down:
        case AxisDirection.up:
          assert(stateSplitY != SplitState.split,
              'Split Y (vertical split) is not possible if sliver scroll direction is also vertical');

          return TableScrollDirection.horizontal;
        case AxisDirection.left:
        case AxisDirection.right:
          assert((stateSplitX != SplitState.split),
              'Split X (horizontal split) is not possible if sliver scroll direction is also horizontal');
          return TableScrollDirection.vertical;
      }
    }
  }

  updateHorizonScrollBarTrack(var setRatio) {
    updateScrollBarTrack(
        model.sheetWidth, widthLayoutList, stateSplitX, setRatio);
  }

  updateVerticalScrollBarTrack(var setRatio) {
    updateScrollBarTrack(
        model.sheetHeight, heightLayoutList, stateSplitY, setRatio);
  }

  void updateScrollBarTrack(
      double sheetlength, List<GridLayout> gl, SplitState split, setRatio) {
    final sheetLengthScale = sheetlength * tableScale;

    switch (split) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
      case SplitState.canceledAutoFreezeSplit:
      case SplitState.noSplit:
        {
          setRatio(gl[1].panelLength < sheetLengthScale ? 1.0 : 0.0);
          break;
        }
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        {
          setRatio(gl[2].panelLength < sheetLengthScale ? 1.0 : 0.0);
          break;
        }
      case SplitState.split:
        {
          setRatio((gl[1].panelLength < sheetLengthScale ||
                  gl[2].panelLength < sheetLengthScale)
              ? 1.0
              : 0.0);
          break;
        }
    }
  }

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  bool hitDividerX(double position, SplitState splitState) {
    if (splitState != stateSplitX) return false;

    final gridLayout2 = widthLayoutList[2];
    return gridLayout2.inUse &&
        gridLayout2.gridPosition > position - properties.hitLineRadial &&
        gridLayout2.gridPosition < position + properties.hitLineRadial;
  }

  bool hitDividerY(double position, SplitState splitState) {
    if (splitState != stateSplitY) return false;

    final gridLayout2 = heightLayoutList[2];
    return gridLayout2.inUse &&
        gridLayout2.gridPosition > position - properties.hitLineRadial &&
        gridLayout2.gridPosition < position + properties.hitLineRadial;
  }

  bool hitFreeze(
    Offset position,
  ) {
    if (hitDividerX(position.dx, SplitState.freezeSplit)) {
      return true;
    } else if (stateSplitY == SplitState.freezeSplit &&
        hitDividerY(position.dy, SplitState.freezeSplit)) {
      return true;
    } else if (!model.autoFreezePossibleX &&
        stateSplitX != SplitState.split &&
        !tableFitWidth) {
      final column = model.findIntersectionIndexX(
          distance: (position.dx +
                  getScrollX(0, 0) * tableScale -
                  widthLayoutList[1].panelPosition) /
              tableScale,
          radial: properties.hitLineRadial / tableScale);

      if ((stateSplitX != SplitState.freezeSplit && 0 < column)) {
        return true;
      }
    } else if (!model.autoFreezePossibleY &&
        stateSplitY != SplitState.split &&
        !tableFitHeight) {
      final row = model.findIntersectionIndexY(
          distance: (position.dy +
                  getScrollY(0, 0) * tableScale -
                  heightLayoutList[1].panelPosition) /
              tableScale,
          radial: properties.hitLineRadial / tableScale);

      if ((stateSplitY != SplitState.freezeSplit && 0 < row)) {
        return true;
      }
    }

    return false;
  }

  FtIndex freezeIndex(Offset position) {
    return FtIndex(
        column: model.findIntersectionIndexX(
            distance: (position.dx +
                    getScrollX(0, 0) * tableScale -
                    widthLayoutList[1].panelPosition) /
                tableScale,
            radial: properties.hitLineRadial / tableScale),
        row: model.findIntersectionIndexY(
            distance: (position.dy +
                    getScrollY(0, 0) * tableScale -
                    heightLayoutList[1].panelPosition) /
                tableScale,
            radial: properties.hitLineRadial / tableScale));
  }

  FreezeChange hitFreezeSplit(Offset position) {
    var cellIndex = freezeIndex(position);

    int column = model.noSplitX &&
            !model.autoFreezePossibleX &&
            !tableFitWidth &&
            cellIndex.column > 0 &&
            cellIndex.column < model.tableColumns - 1 &&
            position.dx > minFreezePositionLeft &&
            position.dx < maxFreezePositionRight
        ? cellIndex.column
        : -1;
    int row = model.noSplitY &&
            !model.autoFreezePossibleY &&
            !tableFitHeight &&
            cellIndex.row > 0 &&
            cellIndex.row < model.tableRows - 1 &&
            position.dy > minFreezePositionTop &&
            position.dy < maxFreezePositionBottom
        ? cellIndex.row
        : -1;

    if (column > 0 || row > 0) {
      return FreezeChange(
          action: FreezeAction.freeze,
          row: row,
          column: column,
          position: Offset(
              column > 0
                  ? (getX(column) - getScrollX(0, 0)) * tableScale +
                      widthLayoutList[1].panelPosition
                  : 0.0,
              row > 0
                  ? (getY(row) - getScrollY(0, 0)) * tableScale +
                      heightLayoutList[1].panelPosition
                  : 0.0));
    }

    // column = stateSplitX == SplitState.freezeSplit && !autoFreezePossibleX
    //     ? cellIndex.column
    //     : -1;

    // row = stateSplitY == SplitState.freezeSplit && !autoFreezePossibleY
    //     ? cellIndex.row
    //     : -1;

    column = hitDividerX(position.dx, SplitState.freezeSplit)
        ? model.topLeftCellPaneColumn
        : -1;
    row = hitDividerY(position.dy, SplitState.freezeSplit)
        ? model.topLeftCellPaneRow
        : -1;

    if (column > 0 || row > 0) {
      return FreezeChange(
          action: FreezeAction.unFreeze,
          row: row,
          column: column,
          position: Offset(widthLayoutList[1].panelEndPosition,
              heightLayoutList[1].panelEndPosition)
          // position: Offset(
          //     (getX(column) - getScrollX(0, 0)) * tableScale +
          //         widthLayoutList[1].panelPosition,
          //     (getY(row) - getScrollY(0, 0)) * tableScale +
          //         heightLayoutList[1].panelPosition)
          );
    }

    return FreezeChange();
  }

  bool get tableFitWidth =>
      !(widthLayoutList[2].panelEndPosition - widthLayoutList[1].panelPosition <
          model.sheetWidth * tableScale);

  bool get tableFitHeight => !(heightLayoutList[2].panelEndPosition -
          heightLayoutList[1].panelPosition <
      model.sheetHeight * tableScale);

  freezeByPosition(FreezeChange freezeChange) {
    if (freezeChange.column > 0 && freezeChange.action == FreezeAction.freeze) {
      setXsplit(
          indexSplit: freezeChange.column, splitView: SplitState.freezeSplit);
    } else if (freezeChange.column != -1 &&
        freezeChange.action == FreezeAction.unFreeze) {
      setXsplit(splitView: SplitState.noSplit);
    }

    if (freezeChange.row > 0 && freezeChange.action == FreezeAction.freeze) {
      if (sliverScrollPosition == null) {
        setYsplit(
            indexSplit: freezeChange.row, splitView: SplitState.freezeSplit);
      } else {
        // final correct = -getScrollY(0, 0) * tableScale;
        //  sliverScrollPosition!.correctBy(correct);

        correctSliverOffset = -getScrollY(0, 0) * tableScale;

        setYsplit(
            indexSplit: freezeChange.row, splitView: SplitState.freezeSplit);
        sliverScrollPosition!.notifyListeners();
      }
    } else if (freezeChange.row != -1 &&
        freezeChange.action == FreezeAction.unFreeze) {
      if (sliverScrollPosition != null) {
        final pixels = scrollY1pX0 - getY(model.topLeftCellPaneRow);
        setYsplit(splitView: SplitState.noSplit);
        // final correct = (scrollY0pX0 - pixels) * tableScale;
        correctSliverOffset = (scrollY0pX0 - pixels) * tableScale;
        // sliverScrollPosition!.correctBy(correct);
        sliverScrollPosition!.notifyListeners();
      } else {
        setYsplit(splitView: SplitState.noSplit);
      }
    }
  }

  //Scalled
  @override
  double clampedX(int scrollIndexX, int scrollIndexY, double pixelsX) =>
      clampDouble(pixelsX, getMinScrollScaledX(scrollIndexX),
          getMaxScrollScaledX(scrollIndexX));
  //Scalled
  @override
  double clampedY(int scrollIndexX, int scrollIndexY, double pixelsY) =>
      clampDouble(pixelsY, getMinScrollScaledY(scrollIndexY),
          getMaxScrollScaledY(scrollIndexY));
  //Scalled
  @override
  Offset clampedOffset(
          int scrollIndexX, int scrollIndexY, Offset offset) =>
      Offset(
          clampDouble(offset.dx, getMinScrollScaledX(scrollIndexX),
              getMaxScrollScaledX(scrollIndexX)),
          clampDouble(offset.dy, getMinScrollScaledY(scrollIndexY),
              getMaxScrollScaledY(scrollIndexY)));

  @override
  bool containsPositionX(int scrollIndexX, double position) =>
      widthLayoutList[scrollIndexX + 1].panelContains(position);

  @override
  bool containsPositionY(int scrollIndexY, double position) =>
      heightLayoutList[scrollIndexY + 1].panelContains(position);

  @override
  double maxScrollExtentX(int scrollIndexX) =>
      getMaxScrollScaledX(scrollIndexX);

  @override
  double maxScrollExtentY(int scrollIndexY) =>
      getMaxScrollScaledY(scrollIndexY);

  @override
  double minScrollExtentX(int scrollIndexX) =>
      getMinScrollScaledX(scrollIndexX);

  @override
  double minScrollExtentY(int scrollIndexY) =>
      getMinScrollScaledY(scrollIndexY);

  @override
  bool outOfRangeX(int scrollIndexX, int scrollIndexY) {
    final pixelsX = scrollPixelsX(scrollIndexX, scrollIndexY);

    return pixelsX < minScrollExtentX(scrollIndexX) ||
        pixelsX > maxScrollExtentX(scrollIndexX);
  }

  @override
  bool outOfRangeY(int scrollIndexX, int scrollIndexY) {
    final pixelsY = scrollPixelsY(scrollIndexX, scrollIndexY);

    return pixelsY < minScrollExtentY(scrollIndexY) ||
        pixelsY > maxScrollExtentY(scrollIndexY);
  }

  @override
  double scrollPixelsX(int scrollIndexX, int scrollIndexY) =>
      getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

  @override
  double scrollPixelsY(int scrollIndexX, int scrollIndexY) =>
      getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

  @override
  List<GridLayout> get tableLayoutX => widthLayoutList;

  @override
  List<GridLayout> get tableLayoutY => heightLayoutList;

  double twoPanelViewPortDimensionX() =>
      widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;

  double twoPanelViewPortDimensionY() =>
      heightLayoutList[1].panelLength + heightLayoutList[2].panelLength;

  @override
  double viewportDimensionX(int scrollIndexX) {
    if (model.autoFreezePossibleX) {
      return widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;
    }
    switch (stateSplitX) {
      case SplitState.canceledFreezeSplit ||
            SplitState.canceledSplit ||
            SplitState.canceledAutoFreezeSplit ||
            SplitState.noSplit:
        return widthLayoutList[1].panelLength;
      case SplitState.autoFreezeSplit:
        return widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;
      case SplitState.freezeSplit || SplitState.split:
        return widthLayoutList[scrollIndexX + 1].panelLength;
    }
  }

  @override
  double viewportDimensionY(int scrollIndexY) {
    if (model.autoFreezePossibleY) {
      return heightLayoutList[1].panelLength + heightLayoutList[2].panelLength;
    }

    switch (stateSplitY) {
      case SplitState.canceledFreezeSplit ||
            SplitState.canceledSplit ||
            SplitState.canceledAutoFreezeSplit ||
            SplitState.noSplit:
        return heightLayoutList[1].panelLength;
      case SplitState.autoFreezeSplit:
        return heightLayoutList[1].panelLength +
            heightLayoutList[2].panelLength;
      case SplitState.freezeSplit || SplitState.split:
        return heightLayoutList[scrollIndexY + 1].panelLength;
    }
  }

  @override
  double viewportPositionX(int scrollIndexX) =>
      widthLayoutList[stateSplitX != SplitState.split ? 1 : scrollIndexX + 1]
          .panelPosition;

  @override
  double viewportPositionY(int scrollIndexY) =>
      heightLayoutList[stateSplitY != SplitState.split ? 1 : scrollIndexY + 1]
          .panelPosition;

  @override
  double trackDimensionX(int scrollIndexX) {
    if (model.autoFreezePossibleX) {
      return widthLayoutList[2].gridEndPosition -
          widthLayoutList[1].gridPosition;
    }
    switch (stateSplitX) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
      case SplitState.canceledAutoFreezeSplit:
      case SplitState.noSplit:
        return widthLayoutList[1].gridLength;
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return widthLayoutList[2].gridEndPosition -
            widthLayoutList[1].gridPosition;
      case SplitState.split:
        final l = widthLayoutList[scrollIndexX + 1];
        return (scrollIndexX == 0)
            ? l.panelEndPosition - l.gridPosition
            : l.gridEndPosition - l.panelPosition;
    }
  }

  @override
  double trackDimensionY(int scrollIndexY) {
    if (model.autoFreezePossibleY) {
      return heightLayoutList[2].gridEndPosition -
          heightLayoutList[1].gridPosition;
    }
    switch (stateSplitY) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
      case SplitState.canceledAutoFreezeSplit:
      case SplitState.noSplit:
        return heightLayoutList[1].gridLength;
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return heightLayoutList[2].gridEndPosition -
            heightLayoutList[1].gridPosition;
      case SplitState.split:
        final l = heightLayoutList[scrollIndexY + 1];
        return (scrollIndexY == 0)
            ? l.panelEndPosition - l.gridPosition
            : l.gridEndPosition - l.panelPosition;
    }
  }

  @override
  double trackPositionX(int scrollIndexX) {
    switch (stateSplitX) {
      case SplitState.split:
        return (scrollIndexX == 0)
            ? widthLayoutList[1].gridPosition
            : widthLayoutList[2].panelPosition;
      default:
        {
          return widthLayoutList[1].gridPosition;
        }
    }
  }

  @override
  double trackPositionY(int scrollIndexY) {
    switch (stateSplitY) {
      case SplitState.split:
        return (scrollIndexY == 0)
            ? heightLayoutList[1].gridPosition
            : heightLayoutList[2].panelPosition;
      default:
        {
          return heightLayoutList[1].gridPosition;
        }
    }
  }

  @override
  bool get autoFreezePossibleX => model.autoFreezePossibleX;

  @override
  bool get autoFreezePossibleY => model.autoFreezePossibleY;

  @override
  bool get noSplitX => model.noSplitX;

  @override
  bool get noSplitY => model.noSplitY;

  bool get autoFreezeX => model.autoFreezeX;

  set autoFreezeX(bool value) {
    model.autoFreezeX = value;

    if (value) {
      switch (stateSplitX) {
        case SplitState.freezeSplit:
          {
            unFreezeX();
            calculateAutoFreezeX();
            break;
          }
        case SplitState.split:
          {
            break;
          }

        case SplitState.noSplit ||
              SplitState.autoFreezeSplit ||
              SplitState.canceledFreezeSplit ||
              SplitState.canceledSplit:
          {
            calculateAutoFreezeX();
            break;
          }
        default:
          {}
      }
    } else {
      if (stateSplitX == SplitState.autoFreezeSplit) {
        if (autoFreezeAreaX.header * tableScale < viewportDimensionX(0) / 2.0) {
          switchX();
        }

        stateSplitX = SplitState.noSplit;
      }
      scrollX0pY0 = scrollX0pY1 = mainScrollX;
    }
  }

  bool get autoFreezeY => model.autoFreezeY;

  set autoFreezeY(bool value) {
    model.autoFreezeY = value;

    if (value) {
      switch (stateSplitY) {
        case SplitState.freezeSplit:
          {
            unFreezeY();
            calculateAutoFreezeY();
            break;
          }
        case SplitState.split:
          {
            break;
          }

        case SplitState.noSplit ||
              SplitState.autoFreezeSplit ||
              SplitState.canceledFreezeSplit ||
              SplitState.canceledSplit:
          {
            calculateAutoFreezeY();
            break;
          }
        default:
          {}
      }
    } else {
      if (stateSplitY == SplitState.autoFreezeSplit) {
        if (autoFreezeAreaY.header * tableScale < viewportDimensionY(0) / 2.0) {
          switchY();
        }

        stateSplitY = SplitState.noSplit;
      }
      scrollY0pX0 = scrollY0pX1 = mainScrollY;
    }
  }

  /// TextEdit
  ///
  ///
  ///
  ///

  ({PanelCellIndex panelCellIndex, C? cell}) findCell(Offset offset) {
    int panelIndexX = -1;
    double correctX = 0.0;
    int panelIndexY = -1;
    double correctY = 0.0;

    for (GridLayout gl in widthLayoutList) {
      if (gl.panelContains(offset.dx)) {
        panelIndexX = gl.index;
        correctX = offset.dx - gl.panelPosition;
        break;
      }
    }
    if (panelIndexX == -1) {
      return (panelCellIndex: const PanelCellIndex(), cell: null);
    }

    for (GridLayout gl in heightLayoutList) {
      if (gl.panelContains(offset.dy)) {
        panelIndexY = gl.index;
        correctY = offset.dy - gl.panelPosition;
        break;
      }
    }
    if (panelIndexY == -1) {
      return (panelCellIndex: const PanelCellIndex(), cell: null);
    }

    ({
      FtIndex ftIndex,
      C? cell
    }) y = model.isCellEditable(model.findCellIndexFromPosition(
        correctX / tableScale +
            getScrollX(panelIndexX <= 1 ? 0 : 1, panelIndexY <= 1 ? 0 : 1),
        correctY / tableScale +
            getScrollY(panelIndexX <= 1 ? 0 : 1, panelIndexY <= 1 ? 0 : 1)));

    return y.ftIndex.isIndex
        ? (
            panelCellIndex: PanelCellIndex.from(
              panelIndexX: panelIndexX,
              panelIndexY: panelIndexY,
              ftIndex: y.ftIndex,
              cell: y.cell,
            ),
            cell: y.cell
          )
        : (panelCellIndex: const PanelCellIndex(), cell: null);
  }

  ///
  ///
  ///

  ({FtIndex ftIndex, AbstractCell? cell}) nextCell(PanelCellIndex current) =>
      model.nextCell(current);

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  bool showCellScheduled = false;

  Timer? _endScrollToEditCell;

  showCell() {
    if (scrollToEditCell) {
      if (sliverScrollPosition != null) {
        _showCellVertical();
        _showCellHorizontal();
      } else {
        _showCell(_editCell);
      }

      _endScrollToEditCell ??= Timer(const Duration(milliseconds: 300), () {
        _endScrollToEditCell = null;
        scrollToEditCell = true;
      });
    }
  }

  void _showCell(PanelCellIndex index) {
    if (!index.isIndex) {
      return;
    }

    scheduleAnimatedScroll() {
      int scrollIndexX = switch (stateSplitX) {
        (SplitState.split || SplitState.freezeSplit) => index.scrollIndexX,
        (_) => 0
      };

      int scrollIndexY = switch (stateSplitY) {
        (SplitState.split || SplitState.freezeSplit) => index.scrollIndexY,
        (_) => 0
      };

      double scrollX =
          getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);
      double scrollY =
          getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

      /// Horizontal
      ///
      ///

      double widthPanel = viewportDimensionX(scrollIndexX);

      double x0 = getX(index.column) * tableScale;
      double x1 = getX(index.column + index.columns) * tableScale;

      double widthCell = x1 - x0;
      double leftPadding =
          math.min((widthPanel - widthCell) / 2.0, properties.editPadding.left);
      double rightPadding = math.min(
          (widthPanel - widthCell) / 2.0, properties.editPadding.right);
      double xTo = scrollX;
      bool skipX = false;

      switch (stateSplitX) {
        case SplitState.autoFreezeSplit:
          {
            if (autoFreezeAreaX.freeze) {
              if (index.column >= autoFreezeAreaX.startIndex &&
                  index.column < autoFreezeAreaX.freezeIndex) {
                skipX = true;
              } else if (index.column >= autoFreezeAreaX.freezeIndex &&
                  index.column < autoFreezeAreaX.endIndex) {
                leftPadding = (autoFreezeAreaX.freezePosition -
                        autoFreezeAreaX.startPosition) *
                    tableScale;
              }
            }
            break;
          }
        case SplitState.freezeSplit:
          {
            skipX = index.column < model.topLeftCellPaneColumn;
            break;
          }
        default:
          {}
      }

      /// Vertical
      ///
      ///

      double heightPanel = viewportDimensionY(scrollIndexY);

      double y0 = getY(index.row) * tableScale;
      double y1 = getY(index.row + index.rows) * tableScale;

      double heightCell = y1 - y0;

      //  if( index.row == model.tableRows -1)

      double topPadding = math.min(
          (heightPanel - heightCell) / 2.0, properties.editPadding.top);
      double bottomPadding = math.min(
          (heightPanel - heightCell) / 2.0, properties.editPadding.bottom);

      double yTo = scrollY;

      bool adjustScrollX = false;
      bool adjustScrollY = false;
      bool skipY = false;

      switch (stateSplitY) {
        case SplitState.autoFreezeSplit:
          {
            if (autoFreezeAreaY.freeze) {
              if (index.row >= autoFreezeAreaY.startIndex &&
                  index.row < autoFreezeAreaY.freezeIndex) {
                skipY = true;
              } else if (index.row >= autoFreezeAreaY.freezeIndex &&
                  index.row <= autoFreezeAreaY.endIndex) {
                topPadding = (autoFreezeAreaY.freezePosition -
                        autoFreezeAreaY.startPosition) *
                    tableScale;
              }
            }

            break;
          }
        case SplitState.freezeSplit:
          {
            skipY = index.row < model.topLeftCellPaneRow;
            break;
          }
        default:
          {}
      }

      // debugPrint('leftPadding $leftPadding');

      if (!skipX) {
        if (x1 > scrollX + widthPanel) {
          xTo = x1 - widthPanel + rightPadding;
          // debugPrint(
          //     'x1:$x1 widthPanel:$widthPanel, horizontalPadding: $rightPadding');
          // debugPrint('scrollX $scrollX, xTo $xTo');
          adjustScrollX = true;
        } else if (x0 - leftPadding < scrollX) {
          // debugPrint(
          //     'x1:$x1 widthPanel:$widthPanel, horizontalPadding: $leftPadding');
          xTo = x0 - leftPadding;
          adjustScrollX = true;
        }
      }

      xTo = clampedX(index.scrollIndexX, index.scrollIndexY, xTo);

      if (!skipY) {
        if (y1 > scrollY + heightPanel) {
          // debugPrint(
          //     'y1:$y1 heightPanel:$heightPanel, verticalPadding: $bottomPadding');
          yTo = y1 - heightPanel + bottomPadding;
          adjustScrollY = true; // y1 + verticalPadding - yTo < 0.01;
        } else if (y0 - topPadding < scrollY) {
          adjustScrollY = true;
          yTo = y0 - topPadding;
        }
      }

      yTo = clampedY(index.scrollIndexX, index.scrollIndexY, yTo);

      if (adjustScrollX || adjustScrollY) {
        // debugPrint('scrolly $scrollY $yTo');
        final xNearEqual = nearEqual(
            scrollX, xTo, physics.toleranceFor(devicePixelRatio).distance);
        final yNearEqual = nearEqual(
            scrollY, yTo, physics.toleranceFor(devicePixelRatio).distance);

        if (xNearEqual && yNearEqual) {
          setScrollScaledX(scrollIndexX, scrollIndexY, xTo);
          setScrollScaledY(scrollIndexX, scrollIndexY, yTo);
          markNeedsLayout();
        } else {
          animateTo(scrollIndexX, scrollIndexY,
              toScaledOffset: Offset(xTo, yTo),
              correctOffset: true,
              duration: const Duration(milliseconds: 100));
        }
        return;
      }
    }

    /// Schedule animated scroll
    ///
    ///
    ///
    ///

    if (index.isIndex && !showCellScheduled) {
      scheduleMicrotask(() {
        if (mounted) {
          scheduleAnimatedScroll();
        }
        showCellScheduled = false;
      });
    }
  }

  ///
  /// C:\src\flutter\packages\flutter\lib\src\widgets\editable_text.dart
  /// Regel 4001
  ///
  ///
  ///

  _checkScroll(
      {required bool widthChanged,
      required bool heightChanged,
      required double deltaHeight,
      required double deltaWidth}) {
    if (scrollToEditCell) {
      if (sliverScrollPosition != null) {
        _showCellVertical();

        _showCellHorizontal();
      } else {
        showCell();
      }
      _endScrollToEditCell ??= Timer(const Duration(milliseconds: 400), () {
        _endScrollToEditCell = null;
        scrollToEditCell = false;

        if (scheduleCorrectOffScroll) {
          tryCorrectOffscroll();
        }
      });
    } else if (widthChanged || heightChanged) {
      tryCorrectOffscroll();
    }
  }

  tryCorrectOffscroll() {
    if (!(activity is TableDragScrollActivity ||
        activity is BallisticScrollActivity ||
        activity is DrivenMultiScrollActivity)) {
      scheduleCorrectOffScroll = false;
      correctOffScroll(0, 0);
    }
  }

  bool scheduledShowHorizontalCell = false;
  double previousToX = double.nan;
  _showCellHorizontal() {
    if (scheduledShowHorizontalCell) {
      return;
    }
    go() {
      var (fromX, toX) = calculateScrollToX();

      if (fromX == toX || previousToX == toX) {
        return;
      }

      final xNearEqual = nearEqual(
          fromX, toX, physics.toleranceFor(devicePixelRatio).distance);

      int scrollIndexX = currentEditCell.scrollIndexX;
      int scrollIndexY = currentEditCell.scrollIndexY;

      if (xNearEqual) {
        setScrollScaledX(scrollIndexX, scrollIndexY, toX);
        markNeedsLayout();
      } else {
        animateTo(scrollIndexX, scrollIndexY,
                toScaledX: toX, correctOffset: true)
            .then((_) {
          previousToX = double.nan;
        });
      }
      previousToX = toX;
    }

    scheduleMicrotask(() {
      go();
      scheduledShowHorizontalCell = false;
    });
    scheduledShowHorizontalCell = true;
  }

  double previousToY = double.nan;
  bool scheduledShowVerticalCell = false;

  _showCellVertical() {
    if (scheduledShowVerticalCell) {
      return;
    }
    go() {
      var (fromY, toY) = calculateScrollToY();

      sliverScrollPosition =
          Scrollable.of((context.vsync as State).context).position;

      final toSliverPosition = sliverScrollPosition!.pixels - fromY + toY;

      if (fromY == toY || toSliverPosition == previousToY) {
        return;
      }

      sliverScrollPosition!
          .moveTo(
        toSliverPosition,
        duration: const Duration(milliseconds: 50),
      )
          .then((_) {
        previousToY = double.nan;
      });
      previousToY = toSliverPosition;
    }

    scheduleMicrotask(() {
      go();
      scheduledShowVerticalCell = false;
    });
    scheduledShowVerticalCell = true;
  }

  (double, double) calculateScrollToX() {
    //  int scrollIndexX = switch (stateSplitX) {
    //     (SplitState.split || SplitState.freezeSplit) => index.scrollIndexX,
    //     (_) => 0
    //   };

    //   int scrollIndexY = switch (stateSplitY) {
    //     (SplitState.split || SplitState.freezeSplit) => index.scrollIndexY,
    //     (_) => 0
    //   };

    int scrollIndexX = currentEditCell.scrollIndexX;
    int scrollIndexY = currentEditCell.scrollIndexY;

    double scrollX =
        getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

    double widthPanel = viewportDimensionX(scrollIndexX);

    double x0 = getX(currentEditCell.column) * tableScale;
    double x1 =
        getX(currentEditCell.column + currentEditCell.columns) * tableScale;

    double widthCell = x1 - x0;
    double leftPadding =
        math.min((widthPanel - widthCell) / 2.0, properties.editPadding.left);
    double rightPadding =
        math.min((widthPanel - widthCell) / 2.0, properties.editPadding.right);
    double xTo = scrollX;
    bool skipX = false;

    switch (stateSplitX) {
      case SplitState.autoFreezeSplit:
        {
          if (autoFreezeAreaX.freeze) {
            if (currentEditCell.column >= autoFreezeAreaX.startIndex &&
                currentEditCell.column < autoFreezeAreaX.freezeIndex) {
              skipX = true;
            } else if (currentEditCell.column >= autoFreezeAreaX.freezeIndex &&
                currentEditCell.column < autoFreezeAreaX.endIndex) {
              leftPadding = (autoFreezeAreaX.freezePosition -
                      autoFreezeAreaX.startPosition) *
                  tableScale;
            }
          }
          break;
        }
      case SplitState.freezeSplit:
        {
          skipX = currentEditCell.column < model.topLeftCellPaneColumn;
          break;
        }
      default:
        {}
    }

    if (!skipX) {
      if (x1 > scrollX + widthPanel) {
        xTo = x1 - widthPanel + rightPadding;
      } else if (x0 - leftPadding < scrollX) {
        xTo = x0 - leftPadding;
      }
    }

    xTo = clampedX(
        currentEditCell.scrollIndexX, currentEditCell.scrollIndexY, xTo);

    return (scrollX, xTo);
  }

  (double, double) calculateScrollToY() {
//  int scrollIndexX = switch (stateSplitX) {
//         (SplitState.split || SplitState.freezeSplit) => index.scrollIndexX,
//         (_) => 0
//       };

//       int scrollIndexY = switch (stateSplitY) {
//         (SplitState.split || SplitState.freezeSplit) => index.scrollIndexY,
//         (_) => 0
//       };

    int scrollIndexX = currentEditCell.scrollIndexX;
    int scrollIndexY = currentEditCell.scrollIndexY;

    double scrollY =
        getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

    double heightPanel = viewportDimensionY(scrollIndexY);

    double y0 = getY(currentEditCell.row) * tableScale;
    double y1 = getY(currentEditCell.row + currentEditCell.rows) * tableScale;

    double heightCell = y1 - y0;

    double topPadding =
        math.min((heightPanel - heightCell) / 2.0, properties.editPadding.top);
    double bottomPadding = math.min(
        (heightPanel - heightCell) / 2.0, properties.editPadding.bottom);

    double yTo = scrollY;

    bool skipY = false;

    switch (stateSplitY) {
      case SplitState.autoFreezeSplit:
        {
          if (autoFreezeAreaY.freeze) {
            if (currentEditCell.row >= autoFreezeAreaY.startIndex &&
                currentEditCell.row < autoFreezeAreaY.freezeIndex) {
              skipY = true;
            } else if (currentEditCell.row >= autoFreezeAreaY.freezeIndex &&
                currentEditCell.row <= autoFreezeAreaY.endIndex) {
              topPadding = (autoFreezeAreaY.freezePosition -
                      autoFreezeAreaY.startPosition) *
                  tableScale;
            }
          }

          break;
        }
      case SplitState.freezeSplit:
        {
          skipY = currentEditCell.row < model.topLeftCellPaneRow;
          break;
        }
      default:
        {}
    }

    if (!skipY) {
      if (y1 > scrollY + heightPanel) {
        yTo = y1 - heightPanel + bottomPadding;
      } else if (y0 - topPadding < scrollY) {
        yTo = y0 - topPadding;
      }
    }

    yTo = clampedY(
        currentEditCell.scrollIndexX, currentEditCell.scrollIndexY, yTo);

    return (scrollY, yTo);
  }

  ///
  ///
  ///
  ///
  ///

  bool scheduledRestoreScroll = false;

  clean() {
    scheduledRestoreScroll = false;
    restoreScroll = null;
  }

  animateRestoreScroll() {
    if (restoreScroll == null || !softKeyboard) {
      return;
    }

    restore(RestoreScroll animateScroll) {
      switch (stateSplitY) {
        case SplitState.autoFreezeSplit:
          {
            if (animateScroll.mainScrollY case double restoreY) {
              if (sliverScrollPosition case ScrollPosition scrollPosition) {
                if (animateScroll.mainScrollY case double restoreY) {
                  final toSliverPosition = sliverScrollPosition!.pixels -
                      getScrollScaledY(0, 0, scrollActivity: true) +
                      restoreY * tableScale;

                  scrollPosition
                      .animateTo(toSliverPosition,
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.bounceInOut)
                      .then((_) => clean());
                }
              } else {
                animatesTo(items: [
                  AnimatedToItem(
                    scrollIndexX: 0,
                    scrollIndexY: 0,
                    fromX: mainScrollX * tableScale,
                    fromY: mainScrollY * tableScale,
                    toY: restoreY * tableScale,
                  )
                ]).then((_) {
                  clean();
                });
              }
            }
            clean();
            break;
          }
        case SplitState.split:
          {
            animatesTo(items: [
              if (animateScroll.scrollY0 case double scrollY0)
                AnimatedToItem(
                  scrollIndexX: animateScroll.scrollIndexX,
                  scrollIndexY: 0,
                  fromX: getScrollScaledX(animateScroll.scrollIndexX, 0),
                  fromY: getScrollScaledY(animateScroll.scrollIndexX, 0),
                  toY: scrollY0 * tableScale,
                ),
              if (animateScroll.scrollY1 case double scrollY1)
                AnimatedToItem(
                  scrollIndexX: animateScroll.scrollIndexX,
                  scrollIndexY: 1,
                  fromX: getScrollScaledX(animateScroll.scrollIndexX, 1),
                  fromY: getScrollScaledY(animateScroll.scrollIndexX, 1),
                  toY: scrollY1 * tableScale,
                )
            ]).then((_) {
              clean();
            });
          }
        case SplitState.freezeSplit:
          {
            if (animateScroll.scrollY0 case double scrollY0) {
              setScrollY(0, 0, scrollY0);
            }

            // TODO implement sliverPosition
            if (animateScroll.scrollY1 case double scrollY1) {
              setScrollY(0, 1, scrollY1);
            }

            clean();
          }

        default:
          {
            clean();
          }
      }
    }

    if ((restoreScroll, scheduledRestoreScroll) case (RestoreScroll r, false)) {
      scheduledRestoreScroll = true;
      scheduleMicrotask(() {
        if (mounted) {
          restore(r);
        }
      });
    }
  }

  sortRow({required Function(M model) sort, required bool keepEdit}) {
    _changeOrder(
        keepEdit: keepEdit,
        change: () {
          sort(model);
          model.reIndexUniqueRowNumber();
        });
  }

  insertRows({required int startRow, int? endRow, required bool keepEdit}) {
    _changeOrder(
        keepEdit: keepEdit,
        change: () {
          model.insertRowRange(startRow: startRow, endRow: endRow);
        });
  }

  removeRows({required int startRow, int? endRow, required bool keepEdit}) {
    _changeOrder(
        keepEdit: keepEdit,
        change: () {
          model.removeRowRange(startRow: startRow, lastRow: endRow);
        });
  }

  _changeOrder({required bool keepEdit, required VoidCallback change}) {
    FocusNode? focusChild = FocusScope.of(context.storageContext).focusedChild;

    if (focusChild case SkipFocusNode node) {
      node.safetyStop = true;
    }

    if (!keepEdit) {
      change();
      currentEditCell = const PanelCellIndex();
      return;
    }

    FtIndex? immRowIndex = model.indexToImmutableIndex(_editCell);

    change();

    if (immRowIndex case FtIndex index) {
      _editCell = _editCell.copyWith(index: model.immutableIndexToIndex(index));
    } else {
      _editCell = const PanelCellIndex();
    }
  }

  updateCell({
    required FtIndex ftIndex,
    int rows = 1,
    int columns = 1,
    required C? cell,
    C? previousCell,
  }) {
    cellsToUpdate.add(ftIndex);
    if (ftIndex == _editCell) {
      _editCell = const PanelCellIndex();
    }
    lastEditIndex = ftIndex;

    if (previousCell == cell) {
      return;
    }
    Set<FtIndex>? set = model.updateCell(
        ftIndex: ftIndex,
        cell: cell,
        rows: rows,
        columns: columns,
        previousCell: previousCell,
        user: true);

    if (set != null) {
      cellsToUpdate.addAll(set);
    }

    /// If only value is important for the user then compare the value in the function
    ///
    ///
    changedCellValue?.call(ftIndex, previousCell, cell);

    markNeedsLayout();
  }

  /// Unfocus:
  /// For scaling for example with slider which take te focus from textEditor, if textEditor is inside screen
  /// the texEditor will take the focus from the slider and so on.
  ///
  stopEditing() {
    if (_editCell.isIndex) {
      _editCell = const PanelCellIndex();
      markNeedsLayout();
    }
  }

  // requestFocus(LayoutPanelIndex index) {
  //   return ((stateSplitX == SplitState.split)
  //           ? editCell.panelIndexX == index.xIndex && editCell.column >= 0
  //           : editCell.column >= 0) &&
  //       ((stateSplitY == SplitState.split)
  //           ? editCell.panelIndexY == index.yIndex && editCell.row >= 0
  //           : editCell.row >= 0);
  // }
}

class RestoreScroll {
  final int scrollIndexX;
  final int scrollIndexY;
  final double? mainScrollY;
  final double? scrollY0;
  final double? scrollY1;

  const RestoreScroll({
    this.scrollIndexX = -1,
    this.scrollIndexY = -1,
    this.mainScrollY,
    this.scrollY0,
    this.scrollY1,
  });

  bool get isEmpty =>
      scrollIndexX == -1 &&
      scrollIndexY == -1 &&
      mainScrollY == null &&
      scrollY0 == null &&
      scrollY1 == null;

  RestoreScroll copyIf({
    bool useMainScrollY = false,
    bool useScrollY0 = false,
    bool useScrollY1 = false,
  }) {
    return RestoreScroll(
      scrollIndexX: scrollIndexX,
      scrollIndexY: scrollIndexY,
      mainScrollY: useMainScrollY ? mainScrollY : null,
      scrollY0: useScrollY0 ? scrollY0 : null,
      scrollY1: useScrollY1 ? scrollY1 : null,
    );
  }
}
