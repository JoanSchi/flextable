// Copyright (C) 2023 Joan Schipper
//
// This file is part of flextable.
//
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import 'dart:async';
import 'package:flextable/src/listeners/scroll_change_notifier.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../listeners/scale_change_notifier.dart';
import 'table_multi_panel_viewport.dart';
import '../gesture_scroll/table_drag_details.dart';
import '../gesture_scroll/table_gesture.dart';
import '../model/model.dart';
import '../model/flextable_controller.dart';
import '../model/view_model.dart';
import 'dart:math' as math;

import '../gesture_scroll/table_scroll_physics.dart';

const Set<PointerDeviceKind> kTouchLikeDeviceTypes = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
  PointerDeviceKind.mouse,
  // The VoiceAccess sends pointer events with unknown type when scrolling
  // scrollables.
  PointerDeviceKind.unknown,
};

typedef TableViewportBuilder = Widget Function(
    BuildContext context, FlexTableViewModel viewModel);

class TableViewScrollable extends StatefulWidget {
  /// Creates a widget that scrolls.
  ///
  /// The [axisDirectionY] and [viewportBuilder] arguments must not be null.
  const TableViewScrollable({
    Key? key,
    required this.controller,
    this.physics,
    required this.viewportBuilder,
    this.excludeFromSemantics = false,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    required this.flexTableModel,
    required this.scrollChangeNotifier,
    required this.scaleChangeNotifier,
  })  : assert(semanticChildCount == null || semanticChildCount >= 0),
        super(key: key);

  final FlexTableController controller;
  final TableScrollPhysics? physics;
  final TableViewportBuilder viewportBuilder;

  final bool excludeFromSemantics;

  final int? semanticChildCount;

  final DragStartBehavior dragStartBehavior;

  final FlexTableModel flexTableModel;

  final FlexTableScrollChangeNotifier scrollChangeNotifier;

  final FlexTableScaleChangeNotifier scaleChangeNotifier;

  @override
  TableViewScrollableState createState() => TableViewScrollableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TableScrollPhysics>('physics', physics));
  }

  static TableViewScrollableState? of(BuildContext context) {
    final _ScrollableScope? widget =
        context.dependOnInheritedWidgetOfExactType<_ScrollableScope>();
    return widget?.scrollable;
  }

  /// Scrolls the scrollables that enclose the given context so as to make the
  /// given context visible.
  // static Future<void> ensureVisible(
  //   BuildContext context, {
  //   double alignment = 0.0,
  //   Duration duration = Duration.zero,
  //   Curve curve = Curves.ease,
  //   ScrollPositionAlignmentPolicy alignmentPolicy =
  //       ScrollPositionAlignmentPolicy.explicit,
  // }) {
  // final List<Future<void>> futures = <Future<void>>[];

  // TableScrollableState scrollable = TableScrollable.of(context);
  // while (scrollable != null) {
  //   futures.add(scrollable.position.ensureVisible(
  //     context.findRenderObject(),
  //     alignment: alignment,
  //     duration: duration,
  //     curve: curve,
  //     alignmentPolicy: alignmentPolicy,
  //   ));
  //   context = scrollable.context;
  //   scrollable = TableScrollable.of(context);
  // }

  // if (futures.isEmpty || duration == Duration.zero)
  //   return Future<void>.value();
  // if (futures.length == 1)
  //   return futures.single;
  // return Future.wait<void>(futures).then<void>((List<void> _) => null);
//   }
}

// Enable Scrollable.of() to work as if ScrollableState was an inherited widget.
// ScrollableState.build() always rebuilds its _ScrollableScope.
class _ScrollableScope extends InheritedWidget {
  const _ScrollableScope({
    Key? key,
    required this.scrollable,
    required this.flexTableViewModel,
    required Widget child,
  }) : super(key: key, child: child);

  final TableViewScrollableState scrollable;
  final FlexTableViewModel flexTableViewModel;

  @override
  bool updateShouldNotify(_ScrollableScope old) {
    return flexTableViewModel != old.flexTableViewModel;
  }
}

/// State object for a [TableViewScrollable] widget.
///
/// To manipulate a [TableViewScrollable] widget's scroll position, use the object
/// obtained from the [viewModel] property.
///
/// To be informed of when a [TableViewScrollable] widget is scrolling, use a
/// [NotificationListener] to listen for [ScrollNotification] notifications.
///
/// This class is not intended to be subclassed. To specialize the behavior of a
/// [TableViewScrollable], provide it with a [ScrollPhysics].
class TableViewScrollableState extends State<TableViewScrollable>
    with TickerProviderStateMixin
    implements ScrollContext, FlexTableScaleNotification {
  /// The manager for this [TableViewScrollable] widget's viewport position.
  ///
  /// To control what kind of [ScrollPosition] is created for a [TableViewScrollable],
  /// provide it with custom [ScrollController] that creates the appropriate
  /// [ScrollPosition] in its [ScrollController.createScrollPosition] method.
  FlexTableViewModel get viewModel => _viewModel!;
  FlexTableViewModel? _viewModel;
  FlexTableScaleChangeNotifier? _scaleChangeNotifier;

  @override
  AxisDirection get axisDirection => AxisDirection.down;

  late TableScrollBehavior _configuration;
  TableScrollPhysics? _physics;
  DeviceGestureSettings? _mediaQueryGestureSettings;

  // Only call this from places that will definitely trigger a rebuild.
  void _updatePosition() {
    _configuration = const TableScrollBehavior();
    _physics = _configuration.getScrollPhysics(context);
    if (widget.physics != null) _physics = widget.physics!.applyTo(_physics);
    final FlexTableController controller = widget.controller;
    final FlexTableViewModel? oldViewModel = _viewModel;
    if (oldViewModel != null) {
      controller.detach(oldViewModel);
      // It's important that we not dispose the old position until after the
      // viewport has had a chance to unregister its listeners from the old
      // position. So, schedule a microtask to do it.
      scheduleMicrotask(oldViewModel.dispose);
    }

    if (_scaleChangeNotifier != widget.scaleChangeNotifier) {
      _scaleChangeNotifier?.removeListener(this);
      _scaleChangeNotifier = widget.scaleChangeNotifier..addListener(this);
    }

    _viewModel = controller.createScrollPosition(
        _physics!,
        this,
        oldViewModel,
        widget.flexTableModel,
        widget.scrollChangeNotifier,
        _scaleChangeNotifier!);
    assert(_viewModel != null);

    controller.attach(viewModel);
  }

  @override
  void didChangeDependencies() {
    _mediaQueryGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    super.didChangeDependencies();
    _updatePosition();
  }

  bool _shouldUpdatePosition(TableViewScrollable oldWidget) {
    TableScrollPhysics? newPhysics = widget.physics;
    TableScrollPhysics? oldPhysics = oldWidget.physics;

    do {
      if (newPhysics?.runtimeType != oldPhysics?.runtimeType) return true;
      newPhysics = newPhysics?.parent;
      oldPhysics = oldPhysics?.parent;
    } while (newPhysics != null || oldPhysics != null);

    if (widget.flexTableModel != oldWidget.flexTableModel ||
        widget.scrollChangeNotifier != oldWidget.scrollChangeNotifier ||
        widget.scaleChangeNotifier != oldWidget.scaleChangeNotifier) {
      return true;
    }

    return widget.controller.runtimeType != oldWidget.controller.runtimeType;
  }

  @override
  void didUpdateWidget(TableViewScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.detach(viewModel);
      widget.controller.attach(viewModel);
    }

    if (_shouldUpdatePosition(oldWidget)) {
      _updatePosition();
    }
  }

  @override
  void dispose() {
    _scaleChangeNotifier?.removeListener(this);
    widget.controller.detach(viewModel);
    viewModel.dispose();
    super.dispose();
  }

  // SEMANTICS

  //final GlobalKey _scrollSemanticsKey = GlobalKey();

  @override
  @protected
  void setSemanticsActions(Set<SemanticsAction> actions) {
    if (_gestureDetectorKey.currentState != null) {
      _gestureDetectorKey.currentState!.replaceSemanticsActions(actions);
    }
  }

  // GESTURE RECOGNITION AND POINTER IGNORING

  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey =
      GlobalKey<RawGestureDetectorState>();
  final GlobalKey _ignorePointerKey = GlobalKey();

  // This field is set during layout, and then reused until the next time it is set.
  Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};
  bool _shouldIgnorePointer = false;

  bool? _lastCanDrag;

  // @override
  // @protected
  // void setCanDrag(bool canDrag) {
  //   if (canDrag == _lastCanDrag && (!canDrag || widget.axis == _lastAxisDirection))
  //     return;
  //   if (!canDrag) {
  //     _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
  //   } else {
  //     switch (widget.axis) {
  //       case Axis.vertical:
  //         _gestureRecognizers = <Type, GestureRecognizerFactory>{
  //           VerticalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
  //             () => VerticalDragGestureRecognizer(),
  //             (VerticalDragGestureRecognizer instance) {
  //               instance
  //                 ..onDown = _handleDragDown
  //                 ..onStart = _handleDragStart
  //                 ..onUpdate = _handleDragUpdate
  //                 ..onEnd = _handleDragEnd
  //                 ..onCancel = _handleDragCancel
  //                 ..minFlingDistance = _physics?.minFlingDistance
  //                 ..minFlingVelocity = _physics?.minFlingVelocity
  //                 ..maxFlingVelocity = _physics?.maxFlingVelocity
  //                 ..dragStartBehavior = widget.dragStartBehavior;
  //             },
  //           ),
  //         };
  //         break;
  //       case Axis.horizontal:
  //         _gestureRecognizers = <Type, GestureRecognizerFactory>{
  //           HorizontalDragGestureRecognizer: GestureRecognizerFactoryWithHandlers<HorizontalDragGestureRecognizer>(
  //             () => HorizontalDragGestureRecognizer(),
  //             (HorizontalDragGestureRecognizer instance) {
  //               instance
  //                 ..onDown = _handleDragDown
  //                 ..onStart = _handleDragStart
  //                 ..onUpdate = _handleDragUpdate
  //                 ..onEnd = _handleDragEnd
  //                 ..onCancel = _handleDragCancel
  //                 ..minFlingDistance = _physics?.minFlingDistance
  //                 ..minFlingVelocity = _physics?.minFlingVelocity
  //                 ..maxFlingVelocity = _physics?.maxFlingVelocity
  //                 ..dragStartBehavior = widget.dragStartBehavior;
  //             },
  //           ),
  //         };
  //         break;
  //     }
  //   }
  //   _lastCanDrag = canDrag;
  //   _lastAxisDirection = widget.axis;
  //   if (_gestureDetectorKey.currentState != null)
  //     _gestureDetectorKey.currentState.replaceGestureRecognizers(_gestureRecognizers);
  // }

  @override
  void setCanDrag(bool canDrag) {
    if (canDrag == _lastCanDrag) return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
    } else {
      _gestureRecognizers = <Type, GestureRecognizerFactory>{
        TableGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TableGestureRecognizer>(
          () => TableGestureRecognizer(
              supportedDevices: _configuration.dragDevices),
          (TableGestureRecognizer instance) {
            instance
              ..onDown = _handleDragDown
              ..selectionDragDirection = _selectDragDirection
              ..onStart = _handleDragStart
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd
              ..onCancel = _handleDragCancel
              ..gestureSettings = _mediaQueryGestureSettings;

            // ..minFlingDistance = _physics?.minFlingDistance
            // ..minFlingVelocity = _physics?.minFlingVelocity
            // ..maxFlingVelocity = _physics?.maxFlingVelocity;
          },
        ),
      };
    }

    _lastCanDrag = canDrag;

    if (_gestureDetectorKey.currentState != null) {
      _gestureDetectorKey.currentState!
          .replaceGestureRecognizers(_gestureRecognizers);
    }
  }

  @override
  TickerProvider get vsync => this;

  @override
  @protected
  void setIgnorePointer(bool value) {
    if (_shouldIgnorePointer == value) return;
    _shouldIgnorePointer = value;
    if (_ignorePointerKey.currentContext != null) {
      // print('ignorepointer $_shouldIgnorePointer');
      final RenderIgnorePointer renderBox = _ignorePointerKey.currentContext!
          .findRenderObject()! as RenderIgnorePointer;
      renderBox.ignoring = _shouldIgnorePointer;
    }
  }

  @override
  BuildContext? get notificationContext => _gestureDetectorKey.currentContext;

  @override
  BuildContext get storageContext => context;

  // TOUCH HANDLERS

  TableDrag? _drag;
  ScrollHoldController? _hold;

  void _handleDragDown(DragDownDetails details) {
    assert(_drag == null);
    assert(_hold == null);
    _hold = viewModel.hold(_disposeHold);
  }

  TableScrollDirection _selectDragDirection(DragDownDetails details) =>
      viewModel.selectScrollDirection(details);

  void _handleDragStart(DragStartDetails details) {
    // It's possible for _hold to become null between _handleDragDown and
    // _handleDragStart, for example if some user code calls jumpTo or otherwise
    // triggers a new activity to begin.

    assert(_drag == null);

    _drag = viewModel.drag(details, _disposeDrag);
    assert(_drag != null);
    assert(_hold == null);
  }

  void _handleDragUpdate(TableDragUpdateDetails details) {
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);
    _drag?.update(details);
  }

  void _handleDragEnd(TableDragEndDetails details) {
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);
    _drag?.end(details);
    assert(_drag == null);
  }

  void _handleDragCancel() {
    // _hold might be null if the drag started.
    // _drag might be null if the drag activity ended and called _disposeDrag.
    assert(_hold == null || _drag == null);
    _hold?.cancel();
    _drag?.cancel();
    assert(_hold == null);
    assert(_drag == null);
  }

  void _disposeHold() {
    _hold = null;
  }

  void _disposeDrag() {
    _drag = null;
  }

  // SCROLL WHEEL

  // Returns the offset that should result from applying [event] to the current
  // position, taking min/max scroll extent into account.
  // double _targetScrollOffsetForPointerScroll(PointerScrollEvent event) {
  //   double delta = widget.axis == Axis.horizontal
  //       ? event.scrollDelta.dx
  //       : event.scrollDelta.dy;

  //   if (axisDirectionIsReversed(widget.axisDirection)) {
  //     delta *= -1;
  //   }

  //   return math.min(math.max(position.pixels + delta, position.minScrollExtent),
  //       position.maxScrollExtent);
  // }

  // void _receivedPointerSignal(PointerSignalEvent event) {
  //   if (event is PointerScrollEvent && position != null) {
  //     final double targetScrollOffset = _targetScrollOffsetForPointerScroll(event);
  //     // Only express interest in the event if it would actually result in a scroll.
  //     if (targetScrollOffset != position.pixels) {
  //       GestureBinding.instance.pointerSignalResolver.register(event, _handlePointerScroll);
  //     }
  //   }
  // }

  // void _handlePointerScroll(PointerEvent event) {
  //   assert(event is PointerScrollEvent);
  //   if (_physics != null && !_physics.shouldAcceptUserOffset(position)) {
  //     return;
  //   }
  //   final double targetScrollOffset = _targetScrollOffsetForPointerScroll(event);
  //   if (targetScrollOffset != position.pixels) {
  //     position.jumpTo(targetScrollOffset);
  //   }
  // }

  // DESCRIPTION

  @override
  Widget build(BuildContext context) {
    Widget result = _ScrollableScope(
        scrollable: this,
        flexTableViewModel: viewModel,
        child: Listener(
          onPointerSignal: _receivedPointerSignal,
          child: RawGestureDetector(
            key: _gestureDetectorKey,
            gestures: _gestureRecognizers,
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: widget.excludeFromSemantics,
            child: Semantics(
              explicitChildNodes: !widget.excludeFromSemantics,
              child: IgnorePointer(
                key: _ignorePointerKey,
                ignoring: _shouldIgnorePointer,
                ignoringSemantics: false,
                child: widget.viewportBuilder(context, viewModel),
              ),
            ),
          ),
          // ),
        ));

    // if (!widget.excludeFromSemantics) {
    //   result = _ScrollSemantics(
    //     key: _scrollSemanticsKey,
    //     child: result,
    //     position: position,
    //     allowImplicitScrolling: widget?.physics?.allowImplicitScrolling ?? _physics.allowImplicitScrolling,
    //     semanticChildCount: widget.semanticChildCount,
    //   );
    // }

    //return _configuration.buildViewportChrome(context, result, widget.axisDirection);
    return result;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<FlexTableViewModel>('position', _viewModel));
  }

  @override
  void saveOffset(double offset) {}

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _viewModel != null) {
      // if (_physics != null && !_physics!.shouldAcceptUserOffset(_tablePosition)) {
      //   return;
      // }

      if (_viewModel!.tableScrollDirection != TableScrollDirection.horizontal) {
        final double delta = _pointerSignalEventDelta(event);
        // final double targetScrollOffset = _targetScrollOffsetForPointerScroll(delta);
        // Only express interest in the event if it would actually result in a scroll.

        if (delta != 0.0) {
          GestureBinding.instance.pointerSignalResolver
              .register(event, _handlePointerScroll);
        }
      }
    }
  }

  void _handlePointerScroll(PointerEvent event) {
    assert(event is PointerScrollEvent);
    final double delta = _pointerSignalEventDelta(event as PointerScrollEvent);

    TablePanelLayoutIndex si = viewModel.findScrollIndex(event.localPosition);

    final scrollIndexX =
        viewModel.stateSplitX == SplitState.freezeSplit ? 1 : si.xIndex;
    final scrollIndexY =
        viewModel.stateSplitY == SplitState.freezeSplit ? 1 : si.yIndex;

    final double targetScrollOffset =
        _targetScrollOffsetForPointerScroll(delta, scrollIndexX, scrollIndexY);

    viewModel.setPixelsY(
        scrollIndexX,
        scrollIndexY,
        viewModel.getScrollScaledY(scrollIndexX, scrollIndexY,
                scrollActivity: true) +
            delta);

    final pixelsY = viewModel.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

    if (delta != 0.0 && targetScrollOffset != pixelsY) {
      viewModel.setPixelsY(
          scrollIndexX,
          scrollIndexY,
          _viewModel!.getScrollScaledY(scrollIndexX, scrollIndexY,
                  scrollActivity: true) +
              delta);
    }
  }

  double _pointerSignalEventDelta(PointerScrollEvent event) {
    // double delta = false ? event.scrollDelta.dx : event.scrollDelta.dy;

    // if (axisDirectionIsReversed(widget.axisDirection)) {
    //   delta *= -1;
    // }
    return event.scrollDelta.dy;
  }

  double _targetScrollOffsetForPointerScroll(
      double delta, int scrollIndexX, int scrollIndexY) {
    return math.min(
      math.max(
          viewModel.getScrollScaledY(scrollIndexX, scrollIndexY,
                  scrollActivity: true) +
              delta,
          viewModel.minScrollExtentY(scrollIndexY)),
      viewModel.maxScrollExtentY(scrollIndexY),
    );
  }

  @override
  scaleChange(FlexTableModel flexTableModel) {
    setState(() {});
  }
}

// class _ScrollSemantics extends SingleChildRenderObjectWidget {
//   const _ScrollSemantics({
//     Key key,
//     @required this.position,
//     @required this.allowImplicitScrolling,
//     @required this.semanticChildCount,
//     Widget child,
//   })  : assert(position != null),
//         assert(semanticChildCount == null || semanticChildCount >= 0),
//         super(key: key, child: child);

//   final ScrollPosition position;
//   final bool allowImplicitScrolling;
//   final int semanticChildCount;

//   @override
//   _RenderScrollSemantics createRenderObject(BuildContext context) {
//     return _RenderScrollSemantics(
//       position: position,
//       allowImplicitScrolling: allowImplicitScrolling,
//       semanticChildCount: semanticChildCount,
//     );
//   }

//   @override
//   void updateRenderObject(BuildContext context, _RenderScrollSemantics renderObject) {
//     renderObject
//       ..allowImplicitScrolling = allowImplicitScrolling
//       ..position = position
//       ..semanticChildCount = semanticChildCount;
//   }
// }

// class _RenderScrollSemantics extends RenderProxyBox {
//   _RenderScrollSemantics({
//     @required ScrollPosition position,
//     @required bool allowImplicitScrolling,
//     @required int semanticChildCount,
//     RenderBox child,
//   })  : _position = position,
//         _allowImplicitScrolling = allowImplicitScrolling,
//         _semanticChildCount = semanticChildCount,
//         assert(position != null),
//         super(child) {
//     position.addListener(markNeedsSemanticsUpdate);
//   }

//   /// Whether this render object is excluded from the semantic tree.
//   ScrollPosition get position => _position;
//   ScrollPosition _position;
//   set position(ScrollPosition value) {
//     assert(value != null);
//     if (value == _position) return;
//     _position.removeListener(markNeedsSemanticsUpdate);
//     _position = value;
//     _position.addListener(markNeedsSemanticsUpdate);
//     markNeedsSemanticsUpdate();
//   }

//   /// Whether this node can be scrolled implicitly.
//   bool get allowImplicitScrolling => _allowImplicitScrolling;
//   bool _allowImplicitScrolling;
//   set allowImplicitScrolling(bool value) {
//     if (value == _allowImplicitScrolling) return;
//     _allowImplicitScrolling = value;
//     markNeedsSemanticsUpdate();
//   }

//   int get semanticChildCount => _semanticChildCount;
//   int _semanticChildCount;
//   set semanticChildCount(int value) {
//     if (value == semanticChildCount) return;
//     _semanticChildCount = value;
//     markNeedsSemanticsUpdate();
//   }

//   @override
//   void describeSemanticsConfiguration(SemanticsConfiguration config) {
//     super.describeSemanticsConfiguration(config);
//     config.isSemanticBoundary = true;
//     if (position.haveDimensions) {
//       config
//         ..hasImplicitScrolling = allowImplicitScrolling
//         ..scrollPosition = _position.pixels
//         ..scrollExtentMax = _position.maxScrollExtent
//         ..scrollExtentMin = _position.minScrollExtent
//         ..scrollChildCount = semanticChildCount;
//     }
//   }

//   SemanticsNode _innerNode;

//   @override
//   void assembleSemanticsNode(SemanticsNode node, SemanticsConfiguration config, Iterable<SemanticsNode> children) {
//     if (children.isEmpty || !children.first.isTagged(RenderViewport.useTwoPaneSemantics)) {
//       super.assembleSemanticsNode(node, config, children);
//       return;
//     }

//     _innerNode ??= SemanticsNode(showOnScreen: showOnScreen);
//     _innerNode
//       ..isMergedIntoParent = node.isPartOfNodeMerging
//       ..rect = Offset.zero & node.rect.size;

//     int firstVisibleIndex;
//     final List<SemanticsNode> excluded = <SemanticsNode>[_innerNode];
//     final List<SemanticsNode> included = <SemanticsNode>[];
//     for (SemanticsNode child in children) {
//       assert(child.isTagged(RenderViewport.useTwoPaneSemantics));
//       if (child.isTagged(RenderViewport.excludeFromScrolling)) {
//         excluded.add(child);
//       } else {
//         if (!child.hasFlag(SemanticsFlag.isHidden)) firstVisibleIndex ??= child.indexInParent;
//         included.add(child);
//       }
//     }
//     config.scrollIndex = firstVisibleIndex;
//     node.updateWith(config: null, childrenInInversePaintOrder: excluded);
//     _innerNode.updateWith(config: config, childrenInInversePaintOrder: included);
//   }

//   @override
//   void clearSemantics() {
//     super.clearSemantics();
//     _innerNode = null;
//   }
// }

const Color _kDefaultGlowColor = Color(0xFFFFFFFF);

class TableScrollBehavior {
  /// Creates a description of how [Scrollable] widgets should behave.
  const TableScrollBehavior();

  /// The platform whose scroll physics should be implemented.
  ///
  /// Defaults to the current platform.
  TargetPlatform getPlatform(BuildContext context) => defaultTargetPlatform;

  /// Wraps the given widget, which scrolls in the given [AxisDirection].
  ///
  /// For example, on Android, this method wraps the given widget with a
  /// [GlowingOverscrollIndicator] to provide visual feedback when the user
  /// overscrolls.
  Widget buildViewportChrome(
      BuildContext context, Widget child, AxisDirection axisDirection) {
    // When modifying this function, consider modifying the implementation in
    // _MaterialScrollBehavior as well.
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
        return child;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
        return GlowingOverscrollIndicator(
          axisDirection: axisDirection,
          color: _kDefaultGlowColor,
          child: child,
        );
    }
  }

  Set<PointerDeviceKind> get dragDevices => kTouchLikeDeviceTypes;

  /// The scroll physics to use for the platform given by [getPlatform].
  ///
  /// Defaults to [BouncingScrollPhysics] on iOS and [ClampingScrollPhysics] on
  /// Android.
  TableScrollPhysics getScrollPhysics(BuildContext context) {
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        return const TableClampingScrollPhysics();
    }
  }

  /// Called whenever a [ScrollConfiguration] is rebuilt with a new
  /// [ScrollBehavior] of the same [runtimeType].
  ///
  /// If the new instance represents different information than the old
  /// instance, then the method should return true, otherwise it should return
  /// false.
  ///
  /// If this method returns true, all the widgets that inherit from the
  /// [ScrollConfiguration] will rebuild using the new [ScrollBehavior]. If this
  /// method returns false, the rebuilds might be optimized away.
  bool shouldNotify(covariant ScrollBehavior oldDelegate) => false;

  @override
  String toString() => '$runtimeType';
}
