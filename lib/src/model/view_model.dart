// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/listeners/scroll_change_notifier.dart';
import 'package:flextable/src/model/model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import '../adjust/adjust_table_move_freeze.dart';
import '../data_model/flextable_data_model.dart';
import '../gesture_scroll/table_animation_controller.dart';
import '../gesture_scroll/table_drag_details.dart';
import '../gesture_scroll/table_scroll_activity.dart';
import '../gesture_scroll/table_scroll_physics.dart';
import '../listeners/scale_change_notifier.dart';
import '../panels/panel_viewport.dart';
import '../panels/table_multi_panel_viewport.dart';
import 'flextable_scroll_metrics.dart';
import 'properties/flextable_autofreeze_area.dart';
import 'properties/flextable_freeze_change.dart';
import 'properties/flextable_grid_info.dart';
import 'properties/flextable_grid_layout.dart';
import 'properties/flextable_header_properties.dart';
import 'properties/flextable_range_properties.dart';
import 'properties/flextable_selection_index.dart';
import 'dart:math' as math;

enum SplitChange { start, edit, no }

const int keepSearching = -5;

typedef _SetPixels = Function(int scrollIndexX, int scrollIndexY, double value);

enum DrawScrollBar { left, top, right, bottom, multiple, none }

ScrollDirection get userScrollDirectionY => _userScrollDirectionY;
ScrollDirection _userScrollDirectionY = ScrollDirection.idle;

ScrollDirection get userScrollDirectionX => _userScrollDirectionX;
ScrollDirection _userScrollDirectionX = ScrollDirection.idle;

// TableDragDecision dragDecision;

class FlexTableViewModel extends ChangeNotifier
    with TableScrollMetrics
    implements TableScrollActivityDelegate {
  FlexTableViewModel({
    required this.physics,
    required this.context,
    FlexTableViewModel? oldPosition,
    required this.ftm,
    String? debugLabel,
    required this.scaleChangeNotifier,
    required this.scrollChangeNotifier,
  }) {
    // Scroll
    //
    //
    //
    //
    context.setCanDrag(true);

    if (activity == null) goIdle(0, 0);

    assert(activity != null);

    _adjustScroll = AdjustScroll(
        flexTableViewModel: this,
        scrollIndexX: 0,
        scrollIndexY: 0,
        direction: tableScrollDirection,
        vsync: context.vsync);

    sliverScrollPosition = context.storageContext
        .findAncestorStateOfType<ScrollableState>()
        ?.position;

    if (sliverScrollPosition != null &&
        sliverScrollPosition?.axis != Axis.vertical) {
      sliverScrollPosition = null;
    }

    sliverScrollPosition?.addListener(notifyListeners);

    // ViewModel
    //
    //
    //
    //

    ratioSizeAnimatedSplitChangeX = stateSplitX != SplitState.split ? 0.0 : 1.0;
    ratioSizeAnimatedSplitChangeY = stateSplitY != SplitState.split ? 0.0 : 1.0;

    // if (stateSplitX == SplitState.FREEZE_SPLIT && ftm.freezeColumns > 0) {
    //   scrollX0pY0 = getX(freezeColumns);

    //   topLeftCellPaneColumn = freezeColumns + 1;
    //   scrollX1pY0 = getX(topLeftCellPaneColumn);
    // }

    // if (stateSplitY == SplitState.FREEZE_SPLIT && freezeRows > 0) {
    //   scrollY0pX0 = getY(freezeRows);

    //   topLeftCellPaneRow = freezeRows + 1;
    //   scrollY1pX0 = getY(topLeftCellPaneRow);
    // }

    calculateHeaderWidth();

    for (var element in ftm.autoFreezeAreasX) {
      element.setPosition(getX);
    }
    for (var element in ftm.autoFreezeAreasY) {
      element.setPosition(getY);
    }

    _layoutIndex = List.generate(16, (int index) {
      int r = index % 4;
      int c = index ~/ 4;
      return TablePanelLayoutIndex(xIndex: c, yIndex: r);
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
  }

  // Scroll
  //
  //
  //
  //
  //
  late AdjustScroll _adjustScroll;
  final ScrollContext context;
  final TableScrollPhysics physics;
  final FlexTableModel ftm;
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);
  bool gridIndexAvailable = false;
  bool scrollNotificationEnabled = false;
  ScrollPosition? sliverScrollPosition;

  // ViewModel
  //
  //
  //
  //
  //

  AbstractFlexTableDataModel get dataTable => ftm.dataTable;
  double _widthMainPanel = 0.0;
  double _heightMainPanel = 0.0;

  double get widthMainPanel => _widthMainPanel;

  double get heightMainPanel => _heightMainPanel;

  List<GridLayout> widthLayoutList =
      List.generate(4, (i) => GridLayout(), growable: false);
  List<GridLayout> heightLayoutList =
      List.generate(4, (i) => GridLayout(), growable: false);

  double get scrollX0pY0 => ftm.scrollX0pY0;
  set scrollX0pY0(value) => ftm.scrollX0pY0 = value;

  double get scrollX1pY0 => ftm.scrollX1pY0;
  set scrollX1pY0(value) => ftm.scrollX1pY0 = value;

  double get scrollY0pX0 => ftm.scrollY0pX0;
  set scrollY0pX0(value) => ftm.scrollY0pX0 = value;

  double get scrollY1pX0 => ftm.scrollY1pX0;
  set scrollY1pX0(value) => ftm.scrollY1pX0 = value;

  double get scrollX0pY1 => ftm.scrollX0pY1;
  set scrollX0pY1(value) => ftm.scrollX0pY1 = value;

  double get scrollX1pY1 => ftm.scrollX1pY1;
  set scrollX1pY1(value) => ftm.scrollX1pY1 = value;

  double get scrollY0pX1 => ftm.scrollY0pX1;
  set scrollY0pX1(value) => ftm.scrollY0pX1 = value;

  double get scrollY1pX1 => ftm.scrollY1pX1;
  set scrollY1pX1(value) => ftm.scrollY1pX1 = value;

  double get mainScrollX => ftm.mainScrollX;
  set mainScrollX(value) => ftm.mainScrollX = value;

  double get mainScrollY => ftm.mainScrollY;
  set mainScrollY(value) => ftm.mainScrollY = value;

  double get _xSplit => ftm.xSplit;
  set _xSplit(value) => ftm.xSplit = value;

  double get _ySplit => ftm.ySplit;
  set _ySplit(value) => ftm.ySplit = value;

  bool modifySplit = false;

  final autoFreezeNoRange = AutoFreezeArea.noArea();
  AutoFreezeArea autoFreezeAreaX = AutoFreezeArea.noArea();
  AutoFreezeArea autoFreezeAreaY = AutoFreezeArea.noArea();

  late List<TablePanelLayoutIndex> _layoutIndex;
  late List<int> _panelIndex;

  double ratioVerticalScrollBarTrack = 1.0;
  double ratioHorizontalScrollBarTrack = 1.0;
  double ratioSizeAnimatedSplitChangeX = 1.0;
  double ratioSizeAnimatedSplitChangeY = 1.0;

  List<HeaderProperties> headerRows = List.empty();
  HeaderProperties rightRowHeaderProperty = noHeader;
  HeaderProperties leftRowHeaderProperty = noHeader;

  FlexTableScrollChangeNotifier scrollChangeNotifier;
  FlexTableScaleChangeNotifier scaleChangeNotifier;

  bool scrollBarTrack = false;
  double sizeScrollBarTrack = 0.0;
  double thumbSize = 6.0;
  double paddingOutside = 2.0;
  double paddingInside = 2.0;

  bool scheduleCorrectOffScroll = false;
  double? correctSliverOffset;

  TableScrollActivity? get activity => _activity;
  TableScrollActivity? _activity;

  // bool applyTableDimensions({List<GridLayout> layoutX, List<GridLayout> layoutY}) {
  //   _layoutX = layoutX;
  //   _layoutY = layoutY;
  //   context.setCanDrag(true);
  //   return true;
  // }

  List<GridLayout> get layoutX => widthLayoutList;

  List<GridLayout> get layoutY => heightLayoutList;

  void correctBy(Offset value) {}

  void jumpTo(Offset value) {}

  /// underscroll.
  Future<void> moveTo(
    Offset to, {
    Duration? duration,
    Curve? curve,
    bool? clamp,
  }) {
    if (duration == null || duration == Duration.zero) {
      jumpTo(to);
      return Future<void>.value();
    } else {
      return animateTo(to, duration: duration, curve: curve ?? Curves.ease);
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

    currentDrag?.dispose();
    currentDrag = null;
  }

  TableDrag? currentDrag;

  double _heldPreviousXvelocity = 0.0;
  double _heldPreviousYvelocity = 0.0;

  /// Called by [beginActivity] to report when an activity has started.
  void didStartScroll() {
    scrollChangeNotifier.notify((FlexTableScrollNotification listener) =>
        listener.didStartScroll(this, context.notificationContext));
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
    scrollChangeNotifier.notify((FlexTableScrollNotification listener) =>
        listener.didEndScroll(this, context.notificationContext));

    if (scrollNotificationEnabled) {
      activity!
          .dispatchScrollEndNotification(this, context.notificationContext);
    }
  }

  void didOverscrollBy(Offset value) {
    assert(activity!.isScrolling);
    //activity.dispatchOverscrollNotification(copyWith(), context.notificationContext, value);
  }

  void didOverscrollByX(double value) {
    assert(activity!.isScrolling);
    //activity.dispatchOverscrollNotification(copyWith(), context.notificationContext, value);
  }

  void didOverscrollByY(double value) {
    assert(activity!.isScrolling);
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
    activity
        ?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    _adjustScroll.dispose();
    sliverScrollPosition?.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  Offset setPixels(int scrollIndexX, int scrollIndexY, Offset newPixels) {
    double xDelta = 0.0;
    double yDelta = 0.0;
    double xOverscroll = 0.0;
    double yOverscroll = 0.0;

    assert(activity!.isScrolling);
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
        //didOverscrollByX(overscroll);
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

  shouldRebuild(FlexTableViewModel offset) {
    return this != offset;
  }

  TableScrollDirection selectScrollDirection(DragDownDetails details) {
    return tableScrollDirection;
  }

  double get devicePixelRatio =>
      MediaQuery.maybeDevicePixelRatioOf(context.storageContext) ??
      View.of(context.storageContext).devicePixelRatio;

  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    TablePanelLayoutIndex si = findScrollIndex(details.localPosition);

    final scrollIndexX =
        (ftm.stateSplitX == SplitState.freezeSplit) ? 1 : si.xIndex;
    final scrollIndexY =
        (ftm.stateSplitY == SplitState.freezeSplit) ? 1 : si.yIndex;

    final TableScrollDragController drag = TableScrollDragController(
        delegate: this,
        details: details,
        onDragCanceled: dragCancelCallback,
        carriedVelocityX: physics.carriedMomentum(_heldPreviousXvelocity),
        carriedVelocityY: physics.carriedMomentum(_heldPreviousYvelocity),
        motionStartDistanceThreshold: physics.dragStartDistanceMotionThreshold,
        scrollIndexX: scrollIndexX,
        scrollIndexY: scrollIndexY,
        adjustScroll: _adjustScroll);

    beginActivity(TableDragScrollActivity(
        scrollIndexX, scrollIndexY, this, drag, scrollNotificationEnabled));
    assert(currentDrag == null);
    currentDrag = drag;
    return drag;
  }

  // Size size(int xTableIndex, int yTableIndex) {
  //   assert(_layoutX[xTableIndex] != null && _layoutY[yTableIndex] != null);
  //   return Size(_layoutX[xTableIndex].panelLength, _layoutY[yTableIndex].panelLength);
  // }

  TablePanelLayoutIndex findScrollIndex(Offset offset) {
    final scrollIndexX =
        layoutX[2].inUse && layoutX[2].gridPosition < offset.dx ? 1 : 0;
    final scrollIndexY =
        layoutY[2].inUse && layoutY[2].gridPosition < offset.dy ? 1 : 0;

    return TablePanelLayoutIndex(xIndex: scrollIndexX, yIndex: scrollIndexY);
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
    assert(currentDrag == null);
    currentDrag = drag;
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

  Future<void> animateTo(Offset to, {Duration? duration, Curve? curve}) {
    throw UnimplementedError();
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
      debugPrint('idle');
      goIdle(scrollIndexX, scrollIndexY);
    }
  }

  @override
  void goIdle(int scrollIndexX, int scrollIndexY) {
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

    if (ftm.anySplitY) {
      if (outOfRangeY(0, 1)) ySimulation(0, 1);

      if (ftm.stateSplitY == SplitState.split && !ftm.scrollLockX) {
        if (outOfRangeX(0, 1)) xSimulation(0, 1);

        if (ftm.stateSplitX == SplitState.split && outOfRangeX(1, 1)) {
          xSimulation(1, 1);
        }
      }
    }

    if (ftm.anySplitX) {
      if (outOfRangeX(1, 0)) xSimulation(1, 0);

      if (ftm.stateSplitX == SplitState.split && !ftm.scrollLockY) {
        if (outOfRangeY(1, 0)) ySimulation(1, 0);

        if (ftm.stateSplitY == SplitState.split && outOfRangeY(1, 1)) {
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
  void alignCells(
      int scrollIndexX, int scrollIndexY, bool alignX, bool alignY) {
    final scrollX = getScrollScaledX(scrollIndexX, scrollIndexY);
    final scrollY = getScrollScaledY(scrollIndexX, scrollIndexY);
    double suggestedScrollX = scrollX;
    double suggestedScrollY = scrollY;

    assert(scrollIndexX == 0 && scrollIndexY == 0,
        'AlignCells only implements scrollIndexX == 0 and scrollIndexY == 0');

    if (alignX) {
      suggestedScrollX = moveFreezeToStartColumnScaled(10);
    }

    if (alignY) {
      suggestedScrollY = moveFreezeToStartRowScaled(10);
    }

    if (suggestedScrollX != scrollX || suggestedScrollY != scrollY) {
      beginActivity(TableDragScrollActivity(
          scrollIndexX,
          scrollIndexY,
          this,
          FreezeMoveController(
              delegate: this,
              scrollX: scrollX,
              moveToScrollX: suggestedScrollX,
              scrollY: scrollY,
              moveToScrollY: suggestedScrollY,
              vsync: context.vsync),
          false));
    } else {
      goIdle(scrollIndexX, scrollIndexY);
    }
  }

  ////
  ////
  ////
  ////
  ////
  ////
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

  double horizontalSplitFreeze(SplitState split) {
    switch (split) {
      case SplitState.freezeSplit:
        return ftm.spaceSplitFreeze;
      case SplitState.autoFreezeSplit:
        return autoFreezeAreaY.spaceSplit(ftm.spaceSplitFreeze);
      case SplitState.split:
        return ftm.spaceSplit;
      default:
        return 0.0;
    }
  }

  double verticalSplitFreeze(SplitState split) {
    switch (split) {
      case SplitState.freezeSplit:
        return ftm.spaceSplitFreeze;
      case SplitState.autoFreezeSplit:
        return autoFreezeAreaY.spaceSplit(ftm.spaceSplitFreeze);
      case SplitState.split:
        return ftm.spaceSplit;
      default:
        return 0.0;
    }
  }

  // From model
  //
  //

  @override
  SplitState get stateSplitX => ftm.stateSplitX;

  set stateSplitX(SplitState state) => ftm.stateSplitX = state;

  @override
  SplitState get stateSplitY => ftm.stateSplitY;

  set stateSplitY(SplitState state) => ftm.stateSplitY = state;

  bool get scrollLockX => ftm.scrollLockX;

  bool get scrollLockY => ftm.scrollLockY;

  bool get splitX => ftm.stateSplitX == SplitState.split;

  bool get splitY => ftm.stateSplitY == SplitState.split;

  double get tableScale => ftm.tableScale;

  set tableScale(value) {
    ftm.tableScale = value;
  }

  set rowHeader(value) {
    ftm.rowHeader = value;
    calculateHeaderWidth();
  }

  get rowHeader => ftm.rowHeader;

  void setScrollScaledX(int horizontal, int vertical, double scrollScaledX) {
    if (ftm.autoFreezePossibleX) {
      mainScrollX = scrollScaledX / tableScale;
      calculateAutoScrollX();
    } else if (vertical == 0 || ftm.scrollLockX || ftm.anyFreezeSplitY) {
      if (horizontal == 0) {
        mainScrollX = scrollX0pY0 = scrollScaledX / tableScale;
      } else {
        scrollX1pY0 = scrollScaledX / tableScale;
      }
    } else {
      if (horizontal == 0) {
        scrollX0pY1 = scrollScaledX / tableScale;
      } else {
        scrollX1pY1 = scrollScaledX / tableScale;
      }
    }
  }

  calculateAutoScrollX() {
    if (!ftm.autoFreezePossibleX) return;

    scrollX0pY0 = mainScrollX;
    assert(ftm.scrollLockX,
        'autofreezeX and unlock scrollLockX can not used together!');

    final previousHeader = autoFreezeAreaX.header;

    if (!autoFreezeAreaX.constains(mainScrollX)) {
      autoFreezeAreaX = ftm.autoFreezeAreasX.firstWhere(
          (element) => element.constains(mainScrollX),
          orElse: () => autoFreezeNoRange);
    }

    if (autoFreezeAreaX.freeze &&
        _isFreezeSplitInWindowX(
            _widthMainPanel, autoFreezeAreaX.header * tableScale)) {
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

      if (ftm.stateSplitX != SplitState.autoFreezeSplit) {
        if (autoFreezeAreaX.header * tableScale < viewportDimensionX(0) / 2.0) {
          switchX();
        }
        ftm.stateSplitX = SplitState.autoFreezeSplit;
      }

      ftm.topLeftCellPaneColumn = autoFreezeAreaX.freezeIndex;
    } else {
      if (stateSplitX == SplitState.autoFreezeSplit) {
        if (previousHeader * tableScale < viewportDimensionX(0) / 2.0) {
          switchX();
        }
        stateSplitX = SplitState.noSplit;
      }
    }
  }

  void setScrollWithSliver(double scaledScroll) {
    if (stateSplitY == SplitState.freezeSplit) {
      setScrollScaledY(0, 1, scaledScroll + getMinScrollScaledY(1));
    } else {
      setScrollScaledY(0, 0, scaledScroll);
    }
  }

  void setScrollScaledY(int horizontal, int vertical, double scrollScaledY) {
    if (ftm.autoFreezePossibleY) {
      mainScrollY = scrollScaledY / tableScale;
      calculateAutoScrollY();
    } else if (horizontal == 0 || scrollLockY || ftm.anyFreezeSplitX) {
      if (vertical == 0) {
        mainScrollY = scrollY0pX0 = mainScrollY = scrollScaledY / tableScale;
      } else {
        scrollY1pX0 = scrollScaledY / tableScale;
      }
    } else {
      if (vertical == 0) {
        scrollY0pX1 = scrollScaledY / tableScale;
      } else {
        scrollY1pX1 = scrollScaledY / tableScale;
      }
    }
  }

  calculateAutoScrollY() {
    if (!ftm.autoFreezePossibleY) return;

    scrollY0pX0 = mainScrollY;
    assert(scrollLockY,
        'autofreezeY and unlock scrollLockY can not used together!');

    final previousHeader = autoFreezeAreaY.header;

    if (!autoFreezeAreaY.constains(mainScrollY)) {
      autoFreezeAreaY = ftm.autoFreezeAreasY.firstWhere(
          (element) => element.constains(mainScrollY),
          orElse: () => autoFreezeNoRange);
    }

    if (autoFreezeAreaY.freeze &&
        _isFreezeSplitInWindowY(
            _heightMainPanel, autoFreezeAreaY.header * tableScale)) {
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
        if (autoFreezeAreaY.header * tableScale < viewportDimensionY(0) / 2.0) {
          switchY();
        }
        stateSplitY = SplitState.autoFreezeSplit;
      }

      ftm.topLeftCellPaneRow = autoFreezeAreaY.freezeIndex;
    } else {
      if (stateSplitY == SplitState.autoFreezeSplit) {
        if (previousHeader * tableScale < viewportDimensionY(0) / 2.0) {
          switchY();
        }
        stateSplitY = SplitState.noSplit;
      }
    }
  }

  // bool setScrollLock(bool lock) {
  //   scrollLockX = lock;
  //   scrollLockY = lock;

  //   if (!lock) {
  //     scrollY0pX1 = scrollY0pX0;
  //     scrollX0pY1 = scrollX0pY0;
  //     scrollX1pY1 = scrollX1pY0;
  //     scrollY1pX1 = scrollY1pX0;
  //   }

  //   return lock;
  // }

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
    return ftm.getSheetLength(ftm.specificWidth);
  }

  double get sheetHeight {
    return ftm.getSheetLength(ftm.specificHeight);
  }

  double getX(int column, {int pc = 0}) {
    return ftm.getX(column, pc);
  }

  double getY(int row, {int pc = 0}) {
    return ftm.getY(row, pc);
  }

  double? get xSplit {
    switch (stateSplitX) {
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return ftm.leftPanelMargin +
            (getX(ftm.topLeftCellPaneColumn) - scrollX0pY0) * tableScale +
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
        return ftm.topPanelMargin +
            (getY(ftm.topLeftCellPaneRow) - scrollY0pX0) * tableScale +
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
      required SplitState splitView,
      bool animateSplit = false}) {
    if (splitView == SplitState.split) {
      assert(indexSplit > 0 || sizeSplit != null || deltaSplit != null,
          'Set a value for indexSplit > 0, sizeSplit or deltaSplit to change the X split');

      if (indexSplit > 0) {
        double splitScroll = getX(indexSplit);
        double split = (splitScroll - scrollX0pY0) * tableScale;

        if (minimalSplitPositionFromLeft <= split &&
            minimalSplitPositionFromRight >= split) {
          scrollX0pY0 = scrollX1pY0 = scrollX1pY1 = mainScrollX;

          stateSplitX = SplitState.split;
          _xSplit = split;
        }
      } else {
        if (deltaSplit != null) {
          sizeSplit = _xSplit + deltaSplit;
        }

        _xSplit = sizeSplit!;

        if ((animateSplit
                ? initiateSplitLeft + 0.1
                : minimalSplitPositionFromLeft) >=
            sizeSplit) {
          if (stateSplitX == SplitState.split) {
            mainScrollX = scrollX1pY0;
            scrollX0pY0 = scrollX1pY0;
            scrollX0pY1 = scrollX1pY1;

            if (!scrollLockY) {
              scrollY0pX0 = scrollY0pX1;
              scrollY1pX0 = scrollY1pX1;
            }

            stateSplitX = SplitState.noSplit;
            switchX();

            calculateAutoScrollX();
          }
        } else if ((animateSplit
                ? initiateSplitRight - 0.1
                : minimalSplitPositionFromRight) <=
            sizeSplit) {
          if (stateSplitX == SplitState.split) {
            stateSplitX = SplitState.noSplit;
            mainScrollX = scrollX0pY0;

            calculateAutoScrollX();
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
      }
    } else if (splitView == SplitState.freezeSplit) {
      assert(stateSplitX != SplitState.freezeSplit,
          'StateSplitX is already in FreezeSplit mode!');

      assert(indexSplit > 0 && indexSplit < ftm.maximumColumns - 1,
          'Set indexSplit between 1 and maximumColumns - 2: {maximumColumns - 2}');

      scrollX0pY0 = mainScrollX;
      ftm.topLeftCellPaneColumn = indexSplit;
      scrollX1pY0 = getX(indexSplit);

      final freezeHeader = (scrollX1pY0 - scrollX0pY0) * tableScale;

      if (freezeHeader >= ftm.freezePadding * tableScale &&
          tableWidthFreeze - freezeHeader >= ftm.freezePadding * tableScale) {
        stateSplitX = SplitState.freezeSplit;

        switchXFreeze();
      }
    } else {
      if (stateSplitX == SplitState.freezeSplit) {
        mainScrollX = scrollX0pY0 =
            scrollX1pY0 - widthLayoutList[1].panelLength / tableScale;

        switchXFreeze();
      } else if (stateSplitX == SplitState.split) {
        switchXSplit();
        _xSplit = 0;
      }

      stateSplitX = SplitState.noSplit;
    }
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

    if (_xSplit - initiateSplitLeft < initiateSplitRight - _xSplit) {
      switchPanels = !switchPanels;
    }

    if (switchPanels) switchX();
  }

  void setYsplit(
      {int indexSplit = 0,
      double? sizeSplit,
      double? deltaSplit,
      required SplitState splitView,
      bool animateSplit = false}) {
    if (splitView == SplitState.split) {
      assert(indexSplit > 0 || sizeSplit != null || deltaSplit != null,
          'Set a value for indexSplit > 0, sizeSplit or deltaSplit to change the Y split');

      if (indexSplit > 0) {
        assert(stateSplitY == SplitState.split,
            'Split from index can not be set when split is already enabled');

        double splitScroll = getY(indexSplit);
        double split = (splitScroll - scrollY0pX0) * tableScale;

        if (minimalSplitPositionFromTop <= split &&
            minimalSplitPositionFromBottom >= split) {
          scrollY0pX0 = scrollY1pX0 = scrollY0pX1 = scrollY1pX1 = mainScrollY;
          stateSplitY = SplitState.split;
          _ySplit = split;
        }
      } else {
        if (deltaSplit != null) {
          sizeSplit = _ySplit + deltaSplit;
        }

        _ySplit = sizeSplit!;

        if ((animateSplit
                ? initiateSplitTop + 0.1
                : minimalSplitPositionFromTop) >=
            sizeSplit) {
          if (stateSplitY == SplitState.split) {
            mainScrollY = scrollY1pX0;
            scrollY0pX0 = scrollY1pX0;
            scrollY0pX1 = scrollY1pX1;

            if (!scrollLockX) {
              scrollX0pY0 = scrollX0pY1;
              scrollX1pY0 = scrollX1pY1;
            }

            stateSplitY = SplitState.noSplit;

            switchY();
          }

          calculateAutoScrollY();
        } else if ((animateSplit
                ? initiateSplitBottom - 0.1
                : minimalSplitPositionFromBottom) <=
            sizeSplit) {
          if (stateSplitY == SplitState.split) {
            stateSplitY = SplitState.noSplit;
            mainScrollY = scrollY0pX0;
            calculateAutoScrollY();
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
    } else if (splitView == SplitState.freezeSplit) {
      assert(stateSplitY != SplitState.freezeSplit,
          'StateSplitY is already in FreezeSplit mode!');

      assert(indexSplit > 0 && indexSplit < ftm.maximumRows - 1,
          'Set indexSplit between 1 and maximumRows - 2: {maximumRows - 2}');

      scrollY0pX0 = mainScrollY;
      ftm.topLeftCellPaneRow = indexSplit;
      scrollY1pX0 = getY(indexSplit);

      final freezeHeader = (scrollY1pX0 - scrollY0pX0) * tableScale;

      if (freezeHeader >= ftm.freezePadding * tableScale &&
          tableHeightFreeze - freezeHeader >= ftm.freezePadding * tableScale) {
        stateSplitY = SplitState.freezeSplit;
        switchYFreeze();
      }
    } else {
      if (stateSplitY == SplitState.freezeSplit) {
        mainScrollY = scrollY0pX0 =
            scrollY1pX0 - heightLayoutList[1].panelLength / tableScale;

        switchYFreeze();
      } else if (stateSplitY == SplitState.split) {
        switchYSplit();
        _ySplit = 0;
      }

      stateSplitY = SplitState.noSplit;
    }
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

    if (_ySplit - initiateSplitTop < initiateSplitBottom - _ySplit) {
      switchPanels = !switchPanels;
    }

    if (switchPanels) switchY();
  }

  // checkAutoScroll() {
  //   if (tfm.autoFreezePossibleX) calculateAutoScrollX();
  //   if (tfm.autoFreezePossibleY) calculateAutoScrollY();
  // }

  double get freezeMiniSizeScaledX => ftm.freezeMinimumSize * tableScale;

  double getMinScrollScaledX(int horizontal) {
    if (ftm.autoFreezePossibleX) {
      return 0.0;
    } else if (stateSplitX == SplitState.freezeSplit) {
      if (horizontal == 0) {
        final width =
            widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;

        final positionFreeze = getX(ftm.topLeftCellPaneColumn) * tableScale;
        return width - freezeMiniSizeScaledX > positionFreeze
            ? 0.0
            : positionFreeze - width + freezeMiniSizeScaledX;
      } else {
        return getX(ftm.topLeftCellPaneColumn) * tableScale;
      }
    } else {
      return 0;
    }
  }

  double get freezeMiniSizeScaledY => ftm.freezeMinimumSize * tableScale;

  double getMinScrollScaledY(int vertical) {
    if (ftm.autoFreezePossibleY) {
      return 0.0;
    } else if (stateSplitY == SplitState.freezeSplit) {
      if (vertical == 0) {
        final height =
            heightLayoutList[1].panelLength + heightLayoutList[2].panelLength;

        final heightFreeze = getY(ftm.topLeftCellPaneRow) * tableScale;
        return height - freezeMiniSizeScaledY > heightFreeze
            ? 0.0
            : heightFreeze - height + freezeMiniSizeScaledY;
      } else {
        return getY(ftm.topLeftCellPaneRow) * tableScale;
      }
    } else {
      return 0;
    }
  }

  double getMaxScrollScaledX(int scrollIndex) {
    double maxScroll;

    if (ftm.autoFreezePossibleX) {
      double lengthPanels = widthLayoutList[2].panelEndPosition -
          widthLayoutList[1].panelPosition;

      maxScroll = sheetWidth * tableScale - lengthPanels;
    } else {
      maxScroll = (scrollIndex == 0 && stateSplitX == SplitState.freezeSplit)
          ? (getX(ftm.topLeftCellPaneColumn) - ftm.freezeMinimumSize) *
              tableScale
          : sheetWidth * tableScale -
              widthLayoutList[scrollIndex + 1].panelLength;
    }

    return (maxScroll < 0.0) ? 0.0 : maxScroll;
  }

  double getMaxScrollScaledY(int scrollIndex) {
    double maxScroll;

    if (ftm.autoFreezePossibleY) {
      double lengthPanels = heightLayoutList[2].panelEndPosition -
          heightLayoutList[1].panelPosition;

      maxScroll = sheetHeight * tableScale - lengthPanels;
    } else {
      maxScroll = (scrollIndex == 0 && stateSplitY == SplitState.freezeSplit)
          ? (getY(ftm.topLeftCellPaneRow) - ftm.freezeMinimumSize) * tableScale
          : sheetHeight * tableScale -
              heightLayoutList[scrollIndex + 1].panelLength;
    }
    return (maxScroll < 0.0) ? 0.0 : maxScroll;
  }

  void setScroll(int scrollIndexX, int scrollIndexY, Offset offset) {
    setScrollScaledX(scrollIndexX, scrollIndexY, offset.dx);
    setScrollScaledY(scrollIndexX, scrollIndexY, offset.dy);
  }

  Offset getScroll(int scrollIndexX, int scrollIndexY) {
    return Offset(getScrollX(scrollIndexX, scrollIndexY),
        getScrollY(scrollIndexX, scrollIndexY));
  }

  double getScrollScaledX(int scrollIndexX, int scrollIndexY,
          {bool scrollActivity = false}) =>
      getScrollX(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity) *
      tableScale;

  double getScrollX(int scrollIndexX, int scrollIndexY,
      {bool scrollActivity = false}) {
    if (scrollActivity && ftm.autoFreezePossibleX) {
      return mainScrollX;
    } else if (scrollIndexY == 0 || scrollLockX || ftm.anyFreezeSplitY) {
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
        sheetWidth * tableScale) return DrawScrollBar.none;

    switch (stateSplitY) {
      case SplitState.split:
        return (scrollIndexY == 0 && stateSplitY == SplitState.split)
            ? (scrollLockX ? DrawScrollBar.none : DrawScrollBar.top)
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

  double getScrollY(scrollIndexX, scrollIndexY, {bool scrollActivity = false}) {
    if (scrollActivity && ftm.autoFreezePossibleY) {
      return mainScrollY;
    } else if (scrollIndexX == 0 || scrollLockY || ftm.anyFreezeSplitX) {
      return scrollIndexY == 0 ? scrollY0pX0 : scrollY1pX0;
    } else {
      return scrollIndexY == 0 ? scrollY0pX1 : scrollY1pX1;
    }
  }

  @override
  DrawScrollBar drawVerticalScrollBar(int scrollIndexX, int scrollIndexY) {
    if (tableScrollDirection == TableScrollDirection.horizontal) {
      return DrawScrollBar.none;
    }

    if (heightLayoutList[scrollIndexY + 1].panelLength >=
        sheetHeight * tableScale) return DrawScrollBar.none;

    switch (stateSplitX) {
      case SplitState.split:
        {
          return (scrollIndexX == 0 && stateSplitX == SplitState.split)
              ? (scrollLockY ? DrawScrollBar.none : DrawScrollBar.left)
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

  SelectionIndex findIndex(
      double distance,
      List<RangeProperties> specificLength,
      int plusOne,
      int maximumCells,
      double defaultLength) {
    int found = keepSearching;

    if (specificLength.isEmpty) {
      found = distance ~/ defaultLength;
    } else {
      double length = 0;
      int findIndex = 0;

      for (RangeProperties cp in specificLength) {
        if (findIndex < cp.min) {
          double lengthDefaultSection = (cp.min - findIndex) * defaultLength;

          if (distance < length + lengthDefaultSection) {
            findIndex += (distance - length) ~/ defaultLength;
            found = findIndex;
            break;
          } else {
            length += lengthDefaultSection;
            findIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double l = cp.length ?? defaultLength;
          double lengthCostumSection = (cp.max - cp.min + 1) * l;

          if (distance < length + lengthCostumSection) {
            findIndex += (distance - length) ~/ l;
            found = findIndex;
            break;
          } else {
            length += lengthCostumSection;
            findIndex += cp.max - cp.min + 1;
          }
        } else {
          findIndex = cp.max + 1;
        }
      }

      if (found == keepSearching) {
        findIndex += (distance - length) ~/ defaultLength;
        found = findIndex;
      }
    }

    found += plusOne;

    if (found < 0) {
      found = 0;
    } else if (found > maximumCells) {
      found = maximumCells;
    }

    return findSelectionIndex(specificLength, found);
  }

  SelectionIndex findSelectionIndex(
      List<RangeProperties> specificLength, int found) {
    bool firstFound = false, secondFound = false;
    int hiddenStartIndex = -1, maximumHiddenStartIndex = 0;

    int hiddenLastIndex = -1;

    for (RangeProperties cp in specificLength) {
      /* Find start_screen index
             *
             */
      if (!firstFound) {
        if (found > cp.max) {
          if (cp.hidden || cp.collapsed) {
            if (hiddenStartIndex == -1 ||
                maximumHiddenStartIndex + 1 < cp.min) {
              hiddenStartIndex = cp.min;
            }
            maximumHiddenStartIndex = cp.max;
          } else {
            hiddenStartIndex = -1;
          }
        } else {
          firstFound = true;
        }
      }

      /* Find last index
             *
             */
      if (!secondFound) {
        if (cp.min > found &&
            hiddenLastIndex != -1 &&
            hiddenLastIndex < cp.min) {
          secondFound = true;
        } else if (cp.hidden || cp.collapsed) {
          if (cp.min == found || hiddenLastIndex == cp.min) {
            hiddenLastIndex = cp.max + 1;
          }
        }
      }

      if (firstFound && secondFound) {
        break;
      }
    }

    /* Find start_screen index
         *
         */
    if (hiddenStartIndex != -1 && maximumHiddenStartIndex + 1 != found) {
      hiddenStartIndex = -1;
    }

    return SelectionIndex(
        indexStart: hiddenStartIndex != -1 ? hiddenStartIndex : found,
        indexLast: hiddenLastIndex != -1 ? hiddenLastIndex : found);
  }

  SelectionIndex findFirstColumn(int scrollIndexX, int scrollIndexY,
      {double width = 0.0}) {
    double x = getScrollX(scrollIndexX, scrollIndexY) + width;
    return findIndex(
        x, ftm.specificWidth, 0, ftm.maximumColumns, ftm.defaultWidthCell);
  }

  SelectionIndex findLastColumn(int scrollIndexX, int scrollIndexY,
      {double width = 0.0}) {
    double x = getScrollX(scrollIndexX, scrollIndexY) + width;
    return findIndex(
        x, ftm.specificWidth, 1, ftm.maximumColumns, ftm.defaultWidthCell);
  }

  SelectionIndex findFirstRow(int scrollIndexX, int scrollIndexY,
      {double height = 0.0}) {
    double y = getScrollY(scrollIndexX, scrollIndexY);
    return findIndex(
        y, ftm.specificHeight, 0, ftm.maximumRows, ftm.defaultHeightCell);
  }

  SelectionIndex findLastRow(int scrollIndexX, int scrollIndexY,
      {double height = 0.0}) {
    double y = getScrollY(scrollIndexX, scrollIndexY) + height;
    return findIndex(
        y, ftm.specificHeight, 1, ftm.maximumRows, ftm.defaultHeightCell);
  }

  gridInfoList(
      {required List<RangeProperties> specificLength,
      required double begin,
      required double end,
      required double defaultLength,
      required int size,
      required List<GridInfo> infoGridList}) {
    var index = 0;
    var currentLength = 0.0;

    infoGridList.clear();

    bool find(max, double length, bool visible, int listIndex) {
      if (visible) {
        var lengthAtEnd = currentLength + (max - index) * length;

        if (begin > lengthAtEnd) {
          currentLength = lengthAtEnd;
          index = max;
        } else {
          if (currentLength < begin) {
            var delta = (begin - currentLength) ~/ length;
            index += delta;
            currentLength += delta * length;
          }

          if (end <= currentLength + (max - index) * length) {
            var endDeltaIndex = index + (end - currentLength) ~/ length + 1;

            if (endDeltaIndex > max) {
              endDeltaIndex = max;
            }

            for (var i = index; i < endDeltaIndex; i++) {
              infoGridList.add(GridInfo(
                  index: i,
                  length: length,
                  position: currentLength,
                  listIndex: listIndex));
              currentLength += length;
            }

            return true;
          } else {
            for (var i = index; i < max; i++) {
              infoGridList.add(GridInfo(
                  index: i,
                  length: length,
                  position: currentLength,
                  listIndex: listIndex));
              currentLength += length;
            }

            index = max;
          }
        }
      } else {
        index = max;
      }

      return false;
    }

    int listLength = specificLength.length;

    for (int i = 0; i < listLength; i++) {
      final cp = specificLength[i];

      if (index < cp.min) {
        if (find(cp.min, defaultLength, true, i)) {
          return;
        }
      }

      if (index == cp.min) {
        if (find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed), i)) {
          return;
        }
      } else {
        assert(index <= cp.max,
            'Index $index should be equal or smaller then max ${cp.max}');
      }
    }

    find(size, defaultLength, true, listLength);
  }

  GridInfo findGridInfoRow(int toIndex) {
    return _findGridInfo(
        specificLength: ftm.specificHeight,
        defaultLength: ftm.defaultHeightCell,
        toIndex: toIndex,
        maxGrids: ftm.maximumRows);
  }

  GridInfo findGridInfoColumn(int toIndex) {
    return _findGridInfo(
        specificLength: ftm.specificWidth,
        defaultLength: ftm.defaultWidthCell,
        toIndex: toIndex,
        maxGrids: ftm.maximumColumns);
  }

  GridInfo _findGridInfo(
      {required List<RangeProperties> specificLength,
      required int toIndex,
      required double defaultLength,
      required int maxGrids}) {
    var listIndex = 0;
    var index = 0;
    var nextPosition = 0.0;

    assert(index <= toIndex, 'lastIndex should be larger then ...');

    GridInfo? find(max, double length, bool visible) {
      final last = toIndex < max ? toIndex + 1 : max;
      length = visible ? length : 0.0;
      var position = nextPosition;

      if (visible) {
        position += (last - index - 1) * length;
        nextPosition = position + length;
      }

      index = last;

      return (toIndex == last - 1)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    final lengthList = specificLength.length;

    while (listIndex < lengthList) {
      final cp = specificLength[listIndex];

      if (index < cp.min) {
        final t = find(cp.min, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.min) {
        final t = find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }

      listIndex++;
    }

    return find(toIndex + 1, defaultLength, true)!;
  }

  GridInfo findGridInfoRowForward(
      {required int toIndex, required GridInfo startingPoint}) {
    return findGridInfoForward(
        specificLength: ftm.specificHeight,
        defaultLength: ftm.defaultHeightCell,
        toIndex: toIndex,
        maxGrids: ftm.maximumRows,
        startingPoint: startingPoint);
  }

  GridInfo findGridInfoRowReverse(
      {required int toIndex, required GridInfo startingPoint}) {
    return findGridInfoReverse(
        specificLength: ftm.specificHeight,
        defaultLength: ftm.defaultHeightCell,
        toIndex: toIndex,
        startingPoint: startingPoint);
  }

  GridInfo findGridInfoForward(
      {required List<RangeProperties> specificLength,
      required int toIndex,
      required double defaultLength,
      required int maxGrids,
      required GridInfo startingPoint}) {
    int listIndex = startingPoint.listIndex;
    var index = startingPoint.index + 1;
    var nextPosition = startingPoint.position + startingPoint.length;

    assert(index <= toIndex, 'lastIndex should be larger then ...');

    GridInfo? find(max, double length, bool visible) {
      final last = toIndex < max ? toIndex + 1 : max;
      length = visible ? length : 0.0;
      var position = nextPosition;

      if (visible) {
        position += (last - index - 1) * length;
        nextPosition = position + length;
      }

      index = last;

      return (toIndex == last - 1)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    final lengthList = specificLength.length;

    while (listIndex < lengthList) {
      final cp = specificLength[listIndex];

      if (index < cp.min) {
        final t = find(cp.min, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.min) {
        final t = find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }

      listIndex++;
    }

    return find(toIndex + 1, defaultLength, true)!;
  }

  GridInfo findGridInfoReverse(
      {required List<RangeProperties> specificLength,
      required int toIndex,
      required double defaultLength,
      required GridInfo startingPoint}) {
    int listIndex = startingPoint.listIndex;
    var index = startingPoint.index;
    var position = startingPoint.position;

    GridInfo? find(min, double length, bool visible) {
      final first = toIndex > min ? toIndex : min;
      length = visible ? length : 0.0;

      if (visible) {
        position -= (index - first) * length;
      }
      index = first;

      return (toIndex >= min)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    if (listIndex == specificLength.length) {
      listIndex--;
    }

    while (0 <= listIndex) {
      final cp = specificLength[listIndex];

      if (index > cp.max + 1) {
        final t = find(cp.max + 1, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.max + 1) {
        final t = find(
            cp.min, cp.length ?? defaultLength, !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }
      listIndex--;
    }

    return find(0, defaultLength, true)!;
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

  TablePanelLayoutIndex layoutIndex(int panelIndex) {
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
    if (!modifySplit &&
        tableScrollDirection != TableScrollDirection.horizontal) {
      adjustSplitStateAfterWidthResize(width);
    }

    if (!modifySplit && tableScrollDirection != TableScrollDirection.vertical) {
      adjustSplitStateAfterWidthResize(width);
    }

    if (!modifySplit &&
        tableScrollDirection != TableScrollDirection.horizontal) {
      adjustSplitStateAfterHeightResize(height);
    }

    final maxHeightNoSplit = computeMaxIntrinsicHeightNoSplit(width);
    final maxWidthNoSplit = computeMaxIntrinsicWidthNoSplit(height);

    if (maxHeightNoSplit <= height && maxWidthNoSplit <= width) {
      stateSplitX = SplitState.noSplit;
      stateSplitY = SplitState.noSplit;
    }

    _layoutY(
        maxHeightNoSplit:
            maxHeightNoSplit + sizeScrollBarBottom + bottomHeaderLayoutLength,
        height: height);
    _layoutX(
        maxWidthNoSplit:
            maxWidthNoSplit + sizeScrollBarRight + rightHeaderLayoutLength,
        width: width);

    if (_widthMainPanel != width ||
        _heightMainPanel != height ||
        scheduleCorrectOffScroll) {
      _widthMainPanel = width;
      _heightMainPanel = height;
      scheduleCorrectOffScroll = false;
      correctOffScroll(0, 0);
    }
  }

  _layoutY({required double maxHeightNoSplit, required double height}) {
    double yOffset = 0.0;

    if (maxHeightNoSplit < height) {
      stateSplitY = SplitState.noSplit;

      final centerY = (height - maxHeightNoSplit) / 2.0;

      yOffset = centerY + centerY * ftm.alignment.y;
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
        startMargin: ftm.topPanelMargin,
        endMargin: ftm.bottomPanelMargin,
        sizeScrollBarAtStart: sizeScrollBarTop,
        sizeScrollBarAtEnd: sizeScrollBarBottom,
        spaceSplitFreeze: horizontalSplitFreeze);

    position(heightLayoutList, sizeScrollBarTop + yOffset);

    _calculateRowInfoList(0, 0, rowInfoListX0Y0);

    if (stateSplitX == SplitState.split && !scrollLockY) {
      _calculateRowInfoList(1, 0, rowInfoListX1Y0);
    } else {
      rowInfoListX1Y0.clear();
    }

    if (stateSplitY != SplitState.noSplit) {
      _calculateRowInfoList(0, 1, rowInfoListX0Y1);

      if (stateSplitX == SplitState.split && !scrollLockY) {
        _calculateRowInfoList(1, 1, rowInfoListX1Y1);
      } else {
        rowInfoListX1Y1.clear();
      }
    } else {
      rowInfoListX1Y1.clear();
    }

    findRowHeaderWidth();
  }

  _layoutX({required double maxWidthNoSplit, required double width}) {
    double xOffset = 0.0;

    if (maxWidthNoSplit < width) {
      stateSplitX = SplitState.noSplit;
      final centerX = (width - maxWidthNoSplit) / 2.0;
      xOffset = centerX + centerX * ftm.alignment.x;
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
        startMargin: ftm.leftPanelMargin,
        endMargin: ftm.rightPanelMargin,
        sizeScrollBarAtStart: sizeScrollBarLeft,
        sizeScrollBarAtEnd: sizeScrollBarRight,
        spaceSplitFreeze: verticalSplitFreeze);

    position(widthLayoutList, sizeScrollBarLeft + xOffset);

    _calculateColumnInfoList(0, 0, columnInfoListX0Y0);

    if (stateSplitY == SplitState.split && !scrollLockX) {
      _calculateColumnInfoList(0, 1, columnInfoListX0Y1);
    } else {
      columnInfoListX0Y1.clear();
    }

    if (stateSplitX != SplitState.noSplit) {
      _calculateColumnInfoList(1, 0, columnInfoListX1Y0);

      if (stateSplitY == SplitState.split && !scrollLockX) {
        _calculateColumnInfoList(1, 1, columnInfoListX1Y1);
      } else {
        columnInfoListX1Y1.clear();
      }
    } else {
      columnInfoListX1Y1.clear();
    }
  }

  bool _isFreezeSplitInWindowX(double width, double widthFreezedPanel) {
    final xStartPanel = leftHeaderPanelLength + ftm.leftPanelMargin;
    final xEndPanel = width - sizeScrollBarTrack - ftm.rightPanelMargin;

    final xStartTable = ftm.splitChangeInsets * tableScale;
    final xEndTable =
        xEndPanel - xStartPanel - ftm.splitChangeInsets * tableScale;

    return widthFreezedPanel > xStartTable && widthFreezedPanel < xEndTable;
  }

  bool _isFreezeSplitInWindowY(double height, double heightFreezedPanel) {
    final yStartPanel = topHeaderPanelLength + ftm.topPanelMargin;
    final yEndPanel = height - sizeScrollBarTrack - ftm.bottomPanelMargin;
    final yStartTable = ftm.splitChangeInsets * tableScale;
    final yEndTable =
        yEndPanel - yStartPanel - ftm.splitChangeInsets * tableScale;

    return heightFreezedPanel > yStartTable && heightFreezedPanel < yEndTable;
  }

  isSplitInWindowX(double width) {
    final xStart = (scrollLockY ? 0.0 : sizeScrollBarTrack) +
        leftHeaderPanelLength +
        ftm.leftPanelMargin +
        ftm.splitChangeInsets;
    final xEnd = width -
        sizeScrollBarTrack -
        rightHeaderLayoutLength -
        ftm.rightPanelMargin -
        ftm.splitChangeInsets * tableScale;

    return _xSplit >= xStart && _xSplit <= xEnd;
  }

  isSplitInWindowY(double height) {
    final yStart = (scrollLockX ? 0.0 : sizeScrollBarTrack) +
        topHeaderPanelLength +
        ftm.topPanelMargin +
        ftm.splitChangeInsets;
    final yEnd = height -
        sizeScrollBarTrack -
        bottomHeaderLayoutLength -
        ftm.splitChangeInsets * tableScale;

    return _ySplit >= yStart && _ySplit <= yEnd;
  }

  adjustSplitStateAfterWidthResize(double width) {
    switch (stateSplitX) {
      case SplitState.canceledFreezeSplit:
        {
          if (_isFreezeSplitInWindowX(width,
              (getX(ftm.topLeftCellPaneColumn) - scrollX0pY0) * tableScale)) {
            stateSplitX = SplitState.freezeSplit;

            scrollX1pY0 =
                mainScrollX + (getX(ftm.topLeftCellPaneColumn) - scrollX0pY0);
          }
          break;
        }
      case SplitState.freezeSplit:
        {
          if (!_isFreezeSplitInWindowX(width,
              (getX(ftm.topLeftCellPaneColumn) - scrollX0pY0) * tableScale)) {
            stateSplitX = SplitState.canceledFreezeSplit;

            mainScrollX =
                scrollX1pY0 - (getX(ftm.topLeftCellPaneColumn) - scrollX0pY0);
          }
          break;
        }
      case SplitState.canceledSplit:
        {
          if (isSplitInWindowX(width)) {
            stateSplitX = SplitState.split;
            scrollX0pY0 = mainScrollX;
          }
          break;
        }
      case SplitState.split:
        {
          if (!isSplitInWindowX(width)) {
            stateSplitX = SplitState.canceledSplit;
            mainScrollX = scrollX0pY0;
          }
          break;
        }

      default:
        {
          if (ftm.autoFreezePossibleX) {
            calculateAutoScrollX();
          }
        }
    }
  }

  adjustSplitStateAfterHeightResize(double height) {
    switch (stateSplitY) {
      case SplitState.canceledFreezeSplit:
        {
          if (_isFreezeSplitInWindowY(height,
              (getY(ftm.topLeftCellPaneRow) - scrollY0pX0) * tableScale)) {
            stateSplitY = SplitState.freezeSplit;

            scrollY1pX0 =
                mainScrollY + (getY(ftm.topLeftCellPaneRow) - scrollY0pX0);
          }
          break;
        }
      case SplitState.freezeSplit:
        {
          if (!_isFreezeSplitInWindowY(height,
              (getY(ftm.topLeftCellPaneRow) - scrollY0pX0) * tableScale)) {
            stateSplitY = SplitState.canceledFreezeSplit;

            mainScrollY =
                scrollY1pX0 - (getY(ftm.topLeftCellPaneRow) - scrollY0pX0);
          }
          break;
        }
      case SplitState.canceledSplit:
        {
          if (isSplitInWindowY(height)) {
            stateSplitY = SplitState.split;
          }
          break;
        }
      case SplitState.split:
        {
          if (!isSplitInWindowY(height)) {
            stateSplitY = SplitState.canceledSplit;
          }
          break;
        }
      default:
        {
          if (ftm.autoFreezePossibleY) {
            calculateAutoScrollY();
          }
        }
    }
  }

  _calculateRowInfoList(int scrollIndexX, int scrollIndexY, rowInfoList) {
    final top = getScrollY(scrollIndexX, scrollIndexY);
    final bottom =
        top + heightLayoutList[scrollIndexY + 1].panelLength / tableScale;

    if (rowInfoList.length == 0 ||
        rowInfoList.first.outside(top) ||
        rowInfoList.last.outside(bottom)) {
      gridInfoList(
          specificLength: ftm.specificHeight,
          begin: top,
          end: bottom,
          defaultLength: ftm.defaultHeightCell,
          size: ftm.maximumRows,
          infoGridList: rowInfoList);
    }
  }

  _calculateColumnInfoList(int scrollIndexX, int scrollIndexY, columnInfoList) {
    final left = getScrollX(scrollIndexX, scrollIndexY);
    final right =
        left + widthLayoutList[scrollIndexX + 1].panelLength / tableScale;

    if (columnInfoList.length == 0 ||
        columnInfoList.first.outside(left) ||
        columnInfoList.last.outside(right)) {
      gridInfoList(
          specificLength: ftm.specificWidth,
          begin: left,
          end: right,
          defaultLength: ftm.defaultWidthCell,
          size: ftm.maximumColumns,
          infoGridList: columnInfoList);
    }
  }

  List<GridInfo> getRowInfoList(scrollIndexX, scrollIndexY) {
    if (scrollIndexX == 0 || scrollLockY || ftm.anyFreezeSplitX) {
      return scrollIndexY == 0 ? rowInfoListX0Y0 : rowInfoListX0Y1;
    } else {
      return scrollIndexY == 0 ? rowInfoListX1Y0 : rowInfoListX1Y1;
    }
  }

  List<GridInfo> getColumnInfoList(int scrollIndexX, int scrollIndexY) {
    if (scrollIndexY == 0 || scrollLockX || ftm.anyFreezeSplitY) {
      return scrollIndexX == 0 ? columnInfoListX0Y0 : columnInfoListX1Y0;
    } else {
      return scrollIndexX == 0 ? columnInfoListX0Y1 : columnInfoListX1Y1;
    }
  }

  calculateHeaderWidth() {
    int count = 0;
    int rowNumber = ftm.maximumRows + 1;

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

    if (ftm.columnHeader && stateSplitX == SplitState.split && !scrollLockY) {
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

    if (ftm.anySplitY) {
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
    if (headerRows.isEmpty || scrollLockY) return noHeader;

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
          ? (headerProperty.digits * 10.0 + 6.0) * ftm.scaleRowHeader
          : 0.0;

  double get sizeScrollBarLeft => (scrollLockY
      ? 0.0
      : sizeScrollBarTrack *
          ratioVerticalScrollBarTrack *
          ratioSizeAnimatedSplitChangeX);

  double get sizeScrollBarRight =>
      sizeScrollBarTrack * ratioVerticalScrollBarTrack;

  double get sizeScrollBarTop => (scrollLockX
      ? 0.0
      : sizeScrollBarTrack *
          ratioHorizontalScrollBarTrack *
          ratioSizeAnimatedSplitChangeY);

  double get sizeScrollBarBottom =>
      sizeScrollBarTrack * ratioHorizontalScrollBarTrack;

  double get initiateSplitLeft => leftHeaderPanelLength - ftm.spaceSplit;

  double get initiateSplitTop => topHeaderPanelLength - ftm.spaceSplit;

  double get initiateSplitRight => _widthMainPanel - sizeScrollBarTrack;

  double get initiateSplitBottom => _heightMainPanel - sizeScrollBarTrack;

  double get tableWidthFreeze =>
      _widthMainPanel - leftHeaderPanelLength - sizeScrollBarTrack;

  double get tableHeightFreeze =>
      _heightMainPanel - topHeaderPanelLength - sizeScrollBarTrack;

  double get minimalSplitPositionFromLeft {
    final minFromTheLeft = (scrollLockY ? 0.0 : sizeScrollBarTrack) +
        digitsToWidth(findWidthLeftHeader()) +
        ftm.leftPanelMargin +
        ftm.splitChangeInsets;

    return minFromTheLeft < ftm.minSplitSpaceFromSide
        ? ftm.minSplitSpaceFromSide
        : minFromTheLeft;
  }

  double get minimalSplitPositionFromTop {
    final minFromTheTop = (scrollLockY ? 0.0 : sizeScrollBarTrack) +
        topHeaderPanelLength +
        ftm.topPanelMargin +
        ftm.splitChangeInsets;

    return minFromTheTop < ftm.minSplitSpaceFromSide
        ? ftm.minSplitSpaceFromSide
        : minFromTheTop;
  }

  double get minimalSplitPositionFromRight {
    final minFromTheRight = sizeScrollBarTrack -
        digitsToWidth(findWidthRightHeader()) -
        ftm.rightPanelMargin -
        ftm.splitChangeInsets;

    return _widthMainPanel -
        (minFromTheRight < ftm.minSplitSpaceFromSide
            ? ftm.minSplitSpaceFromSide
            : minFromTheRight);
  }

  double get minimalSplitPositionFromBottom {
    final minFromTheBottom = sizeScrollBarTrack -
        (scrollLockX || !ftm.columnHeader
            ? 0.0
            : ftm.headerHeight * ftm.scaleColumnHeader) -
        ftm.bottomPanelMargin -
        ftm.splitChangeInsets;

    return _heightMainPanel -
        (minFromTheBottom < ftm.minSplitSpaceFromSide
            ? ftm.minSplitSpaceFromSide
            : minFromTheBottom);
  }

  double get leftScrollBarHit {
    return scrollLockY ? 0.0 : ftm.hitScrollBarThickness;
  }

  double get topScrollBarHit {
    return scrollLockX ? 0.0 : ftm.hitScrollBarThickness;
  }

  double get rightScrollBarHit => ftm.hitScrollBarThickness;

  double get bottomScrollBarHit => ftm.hitScrollBarThickness;

  double get leftHeaderPanelLength => digitsToWidth(leftRowHeaderProperty);

  double get topHeaderPanelLength =>
      ftm.columnHeader ? ftm.headerHeight * ftm.scaleColumnHeader : 0.0;

  double get rightHeaderPanelLength =>
      rightHeaderLayoutLength * ratioSizeAnimatedSplitChangeX;

  double get rightHeaderLayoutLength => digitsToWidth(rightRowHeaderProperty);

  double get bottomHeaderPanelLength =>
      bottomHeaderLayoutLength * ratioSizeAnimatedSplitChangeY;

  double get bottomHeaderLayoutLength =>
      ftm.columnHeader && stateSplitY == SplitState.split && !scrollLockX
          ? ftm.headerHeight * ftm.scaleColumnHeader
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
      required spaceSplitFreeze}) {
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
        var halfSpace = spaceSplitFreeze(splitState) / 2.0;

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
      var halfSpace = spaceSplitFreeze(splitState) / 2.0;

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
    if (stateSplitX == SplitState.freezeSplit && !ftm.autoFreezePossibleX) {
      final xTopLeft = getX(ftm.topLeftCellPaneColumn);

      return leftHeaderPanelLength +
          (xTopLeft - scrollX0pY0) * tableScale +
          verticalSplitFreeze(stateSplitX) +
          (sheetWidth - xTopLeft) * tableScale +
          sizeScrollBarTrack;
    } else {
      return computeMaxIntrinsicWidthNoSplit(height);
    }
  }

  double computeMaxIntrinsicWidthNoSplit(double height) =>
      leftHeaderPanelLength +
      sheetWidth * tableScale +
      sizeScrollBarTrack +
      ftm.leftPanelMargin +
      ftm.rightPanelMargin;

  double computeMaxIntrinsicHeight(double width) {
    if (stateSplitY == SplitState.freezeSplit && !ftm.autoFreezePossibleY) {
      final yTopLeft = getY(ftm.topLeftCellPaneRow);

      return heightLayoutList[0].gridLength +
          (yTopLeft - scrollY0pX0) * tableScale +
          horizontalSplitFreeze(stateSplitY) +
          (sheetHeight - yTopLeft) * tableScale +
          sizeScrollBarTrack;
    } else {
      return computeMaxIntrinsicHeightNoSplit(width);
    }
  }

  double computeMaxIntrinsicHeightNoSplit(double width) =>
      topHeaderPanelLength +
      sheetHeight * tableScale +
      sizeScrollBarTrack +
      ftm.topPanelMargin +
      ftm.bottomPanelMargin;

  markNeedsLayout() {
    notifyListeners();
  }

  @override
  TableScrollDirection get tableScrollDirection {
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
    updateScrollBarTrack(sheetWidth, widthLayoutList, stateSplitX, setRatio);
  }

  updateVerticalScrollBarTrack(var setRatio) {
    updateScrollBarTrack(sheetHeight, heightLayoutList, stateSplitY, setRatio);
  }

  void updateScrollBarTrack(
      double sheetlength, List<GridLayout> gl, SplitState split, setRatio) {
    final sheetLengthScale = sheetlength * tableScale;

    switch (split) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
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

  bool hitFreeze(Offset position, {double? kSlope}) {
    kSlope ??= 32.0;
    bool inArea(double padding) =>
        position.dx >= widthLayoutList[1].panelPosition + padding &&
        position.dx <= widthLayoutList[2].panelEndPosition - padding &&
        position.dy >= heightLayoutList[1].panelPosition + padding &&
        position.dy <= heightLayoutList[2].panelEndPosition - padding;

    bool inFreezeArea = inArea(ftm.freezePadding * tableScale);

    bool inUnfreezeArea = (ftm.freezePadding == ftm.unfreezePadding)
        ? inFreezeArea
        : inArea(ftm.unfreezePadding * tableScale);

    if (!ftm.autoFreezePossibleX &&
        stateSplitX != SplitState.split &&
        !tableFitWidth) {
      final column = findIntersectionIndex(
          (position.dx +
                  getScrollX(0, 0) * tableScale -
                  widthLayoutList[1].panelPosition) /
              tableScale,
          ftm.specificWidth,
          ftm.maximumColumns,
          ftm.defaultWidthCell,
          kSlope: kSlope);

      if ((stateSplitX != SplitState.freezeSplit &&
              0 < column &&
              inFreezeArea) ||
          (stateSplitX == SplitState.freezeSplit &&
              column == ftm.topLeftCellPaneColumn &&
              inUnfreezeArea)) {
        return true;
      }
    }
    if (!ftm.autoFreezePossibleY &&
        stateSplitY != SplitState.split &&
        !tableFitHeight) {
      final row = findIntersectionIndex(
          (position.dy +
                  getScrollY(0, 0) * tableScale -
                  heightLayoutList[1].panelPosition) /
              tableScale,
          ftm.specificHeight,
          ftm.maximumRows,
          ftm.defaultHeightCell,
          kSlope: kSlope);

      if ((stateSplitY != SplitState.freezeSplit && 0 < row && inFreezeArea) ||
          (stateSplitY == SplitState.freezeSplit &&
              row == ftm.topLeftCellPaneRow &&
              inUnfreezeArea)) {
        return true;
      }
    }

    return false;
  }

  TableCellIndex freezeIndex(Offset position, double kSlope) {
    return TableCellIndex(
        column: findIntersectionIndex(
            (position.dx +
                    getScrollX(0, 0) * tableScale -
                    widthLayoutList[1].panelPosition) /
                tableScale,
            ftm.specificWidth,
            ftm.maximumColumns,
            ftm.defaultWidthCell,
            kSlope: kSlope),
        row: findIntersectionIndex(
            (position.dy +
                    getScrollY(0, 0) * tableScale -
                    heightLayoutList[1].panelPosition) /
                tableScale,
            ftm.specificHeight,
            ftm.maximumRows,
            ftm.defaultHeightCell,
            kSlope: kSlope));
  }

  FreezeChange hitFreezeSplit(Offset position, double kSlope) {
    var cellIndex = freezeIndex(position, kSlope);

    int column = ftm.noSplitX &&
            !ftm.autoFreezePossibleX &&
            !tableFitWidth &&
            cellIndex.column > 0 &&
            cellIndex.column < ftm.maximumColumns - 1
        ? cellIndex.column
        : -1;
    int row = ftm.noSplitY &&
            !ftm.autoFreezePossibleY &&
            !tableFitHeight &&
            cellIndex.row > 0 &&
            cellIndex.row < ftm.maximumRows - 1
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

    column = stateSplitX == SplitState.freezeSplit && !autoFreezePossibleX
        ? cellIndex.column
        : -1;
    row = stateSplitY == SplitState.freezeSplit && !autoFreezePossibleY
        ? cellIndex.row
        : -1;

    if (column > 0 || row > 0) {
      return FreezeChange(
          action: FreezeAction.unFreeze,
          row: ftm.topLeftCellPaneRow == cellIndex.row
              ? ftm.topLeftCellPaneRow
              : -1,
          column: ftm.topLeftCellPaneColumn == cellIndex.column
              ? ftm.topLeftCellPaneColumn
              : -1,
          position: Offset(
              (getX(cellIndex.column) - getScrollX(0, 0)) * tableScale +
                  widthLayoutList[1].panelPosition,
              (getY(cellIndex.row) - getScrollY(0, 0)) * tableScale +
                  heightLayoutList[1].panelPosition));
    }

    return FreezeChange();
  }

  bool get tableFitWidth =>
      !(widthLayoutList[2].panelEndPosition - widthLayoutList[1].panelPosition <
          sheetWidth * tableScale);

  bool get tableFitHeight => !(heightLayoutList[2].panelEndPosition -
          heightLayoutList[1].panelPosition <
      sheetHeight * tableScale);

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
        final pixels = scrollY1pX0 - getY(ftm.topLeftCellPaneRow);
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

  void setScaleTable(double scale) {
    if (scale != tableScale) {
      double oldScale = tableScale;
      tableScale = scale;

      if (sliverScrollPosition != null) {
        final scrollY = autoFreezePossibleY
            ? getScrollY(0, 0, scrollActivity: true)
            : (stateSplitY == SplitState.freezeSplit)
                ? getScrollY(0, 1) - getY(ftm.topLeftCellPaneRow)
                : getScrollY(0, 0);
        sliverScrollPosition!.correctPixels(sliverScrollPosition!.pixels +
            scrollY * tableScale -
            scrollY * oldScale);
      }

      scaleChangeNotifier.notify((FlexTableScaleNotification listener) {
        listener.scaleChange(ftm);
      });
    }
  }

  moveFreezeToStartColumnScaled(double decisionInset) =>
      _moveFreezeToStart(getScrollX(0, 0), ftm.specificWidth,
          ftm.maximumColumns, ftm.defaultWidthCell, decisionInset) *
      tableScale;

  moveFreezeToStartRowScaled(double decisionInset) =>
      _moveFreezeToStart(getScrollY(0, 0), ftm.specificHeight, ftm.maximumRows,
          ftm.defaultHeightCell, decisionInset) *
      tableScale;

  double _moveFreezeToStart(
      double distance,
      List<RangeProperties> specificLength,
      int maximumCells,
      double defaultLength,
      double decisionInset) {
    GridInfo gi = findStartEndOfCell(
        distance, specificLength, maximumCells, defaultLength);

    final begin = gi.position;
    final end = gi.endPosition;
    final half = gi.length / 2;

    if (half < decisionInset) {
      decisionInset = half;
    }

    if (gi.index > 0 && distance < begin + decisionInset) {
      distance = begin;
    } else if (distance > end - decisionInset) {
      distance = end;
    }

    return distance;
  }

  GridInfo findStartEndOfCell(
      double distance,
      List<RangeProperties> specificLength,
      int maximumCells,
      double defaultLength) {
    //Function
    //
    GridInfo find(
        int lastIndex, double distance, double lengthEvaluated, double length) {
      final deltaIndex = (distance - lengthEvaluated) ~/ length;

      final position = lengthEvaluated + deltaIndex * length;

      return GridInfo(
          index: lastIndex + deltaIndex, position: position, length: length);
    }

    if (specificLength.isEmpty) {
      return find(0, distance, 0.0, defaultLength);
    } else {
      double lengthEvaluated = 0;
      int currentIndex = 0;

      for (RangeProperties cp in specificLength) {
        if (currentIndex < cp.min) {
          double lengthDefaultArea = (cp.min - currentIndex) * defaultLength;

          if (distance <= lengthEvaluated + lengthDefaultArea) {
            return find(currentIndex, distance, lengthEvaluated, defaultLength);
          } else {
            lengthEvaluated += lengthDefaultArea;
            currentIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double customLength = cp.length ?? defaultLength;
          double lengthCostumArea = (cp.max - cp.min + 1) * customLength;

          if (distance <= lengthEvaluated + lengthCostumArea) {
            return find(currentIndex, distance, lengthEvaluated, customLength);
          } else {
            lengthEvaluated += lengthCostumArea;
            currentIndex += cp.max - cp.min + 1;
          }
        } else {
          currentIndex = cp.max + 1;
        }
      }

      return find(currentIndex, distance, lengthEvaluated, defaultLength);
    }
  }

  int findIntersectionIndex(
      double distance,
      List<RangeProperties> specificLength,
      int maximumCells,
      double defaultLength,
      {double kSlope = 18.0}) {
    int findIndexWitinRadial(int currentIndex, double distance,
        double lengthEvaluated, double length) {
      if ((distance - lengthEvaluated + kSlope / 2.0) % length <= kSlope) {
        return currentIndex +
            (distance - lengthEvaluated + kSlope / 2.0) ~/ length;
      } else {
        return -1;
      }
    }

    if (specificLength.isEmpty) {
      return findIndexWitinRadial(0, distance, 0.0, defaultLength);
    } else {
      double lengthEvaluated = 0;
      int currentIndex = 0;

      for (RangeProperties cp in specificLength) {
        if (currentIndex < cp.min) {
          double lengthDefaultArea = (cp.min - currentIndex) * defaultLength;

          if (distance <= lengthEvaluated + lengthDefaultArea + kSlope / 2.0) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, defaultLength);
          } else {
            lengthEvaluated += lengthDefaultArea;
            currentIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double customLength = cp.length ?? defaultLength;
          double lengthCostumArea = (cp.max - cp.min + 1) * customLength;

          if (distance <= lengthEvaluated + lengthCostumArea + kSlope / 2.0) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, customLength);
          } else {
            lengthEvaluated += lengthCostumArea;
            currentIndex += cp.max - cp.min + 1;
          }
        } else {
          currentIndex = cp.max + 1;
        }
      }

      return findIndexWitinRadial(
          currentIndex, distance, lengthEvaluated, defaultLength);
    }
  }

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

  @override
  double viewportDimensionX(int scrollIndexX) {
    if (ftm.autoFreezePossibleX) {
      return widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;
    }
    switch (stateSplitX) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
      case SplitState.noSplit:
        return widthLayoutList[1].panelLength;
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;
      case SplitState.split:
        return widthLayoutList[scrollIndexX + 1].panelLength;
    }
  }

  @override
  double viewportDimensionY(int scrollIndexY) {
    if (ftm.autoFreezePossibleY) {
      return heightLayoutList[1].panelLength + heightLayoutList[2].panelLength;
    }

    switch (stateSplitY) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
      case SplitState.noSplit:
        return heightLayoutList[1].panelLength;
      case SplitState.autoFreezeSplit:
      case SplitState.freezeSplit:
        return heightLayoutList[1].panelLength +
            heightLayoutList[2].panelLength;
      case SplitState.split:
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
    if (ftm.autoFreezePossibleX) {
      return widthLayoutList[2].gridEndPosition -
          widthLayoutList[1].gridPosition;
    }
    switch (stateSplitX) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
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
    if (ftm.autoFreezePossibleY) {
      return heightLayoutList[2].gridEndPosition -
          heightLayoutList[1].gridPosition;
    }
    switch (stateSplitY) {
      case SplitState.canceledFreezeSplit:
      case SplitState.canceledSplit:
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
  bool get autoFreezePossibleX => ftm.autoFreezePossibleX;

  @override
  bool get autoFreezePossibleY => ftm.autoFreezePossibleY;

  @override
  bool get noSplitX => ftm.noSplitX;

  @override
  bool get noSplitY => ftm.noSplitY;
}
