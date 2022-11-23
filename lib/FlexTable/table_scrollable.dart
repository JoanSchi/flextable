import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'table_gesture.dart';
import 'table_drag_details.dart';
import 'table_model.dart';
import 'table_multi_panel_portview.dart';
import 'table_scroll.dart';
import 'table_scroll_physics.dart';
import 'dart:math' as math;

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
    BuildContext context, TableScrollPosition position);

class TableScrollable extends StatefulWidget {
  /// Creates a widget that scrolls.
  ///
  /// The [axisDirectionY] and [viewportBuilder] arguments must not be null.
  const TableScrollable({
    Key? key,
    this.controller,
    this.physics,
    required this.viewportBuilder,
    this.excludeFromSemantics = false,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    required this.tableModel,
  })  : assert(semanticChildCount == null || semanticChildCount >= 0),
        super(key: key);

  final TableScrollController? controller;
  final TableScrollPhysics? physics;
  final TableViewportBuilder viewportBuilder;

  final bool excludeFromSemantics;

  final int? semanticChildCount;

  final DragStartBehavior dragStartBehavior;

  final TableModel tableModel;

  @override
  TableScrollableState createState() => TableScrollableState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TableScrollPhysics>('physics', physics));
  }

  static TableScrollableState? of(BuildContext context) {
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
    required this.position,
    required Widget child,
  }) : super(key: key, child: child);

  final TableScrollableState scrollable;
  final TableScrollPosition position;

  @override
  bool updateShouldNotify(_ScrollableScope old) {
    return position != old.position;
  }
}

/// State object for a [TableScrollable] widget.
///
/// To manipulate a [TableScrollable] widget's scroll position, use the object
/// obtained from the [tablePosition] property.
///
/// To be informed of when a [TableScrollable] widget is scrolling, use a
/// [NotificationListener] to listen for [ScrollNotification] notifications.
///
/// This class is not intended to be subclassed. To specialize the behavior of a
/// [TableScrollable], provide it with a [ScrollPhysics].
class TableScrollableState extends State<TableScrollable>
    with TickerProviderStateMixin
    implements ScrollContext {
  /// The manager for this [TableScrollable] widget's viewport position.
  ///
  /// To control what kind of [ScrollPosition] is created for a [TableScrollable],
  /// provide it with custom [ScrollController] that creates the appropriate
  /// [ScrollPosition] in its [ScrollController.createScrollPosition] method.
  TableScrollPosition get tablePosition => _tablePosition!;
  TableScrollPosition? _tablePosition;

  @override
  AxisDirection get axisDirection => AxisDirection.down;

  late TableScrollBehavior _configuration;
  TableScrollPhysics? _physics;

  // Only call this from places that will definitely trigger a rebuild.
  void _updatePosition() {
    _configuration = TableScrollBehavior();
    _physics = _configuration.getScrollPhysics(context);
    if (widget.physics != null) _physics = widget.physics!.applyTo(_physics);
    final TableScrollController? controller = widget.controller;
    final TableScrollPosition? oldPosition = _tablePosition;
    if (oldPosition != null) {
      controller?.detach(oldPosition);
      // It's important that we not dispose the old position until after the
      // viewport has had a chance to unregister its listeners from the old
      // position. So, schedule a microtask to do it.
      scheduleMicrotask(oldPosition.dispose);
    }

    _tablePosition = controller?.createScrollPosition(
            _physics!, this, oldPosition, widget.tableModel) ??
        TableScrollPositionWithSingleContext(
            physics: _physics!,
            context: this,
            oldPosition: oldPosition,
            tableModel: widget.tableModel);
    assert(_tablePosition != null);

    controller?.attach(tablePosition);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updatePosition();
  }

  bool _shouldUpdatePosition(TableScrollable oldWidget) {
    TableScrollPhysics? newPhysics = widget.physics;
    TableScrollPhysics? oldPhysics = oldWidget.physics;

    TableModel newTableModel = widget.tableModel;
    TableModel oldTableModel = oldWidget.tableModel;

    do {
      if (newPhysics?.runtimeType != oldPhysics?.runtimeType) return true;
      newPhysics = newPhysics?.parent;
      oldPhysics = oldPhysics?.parent;
    } while (newPhysics != null || oldPhysics != null);

    if (newTableModel != oldTableModel) {
      return true;
    }

    return widget.controller?.runtimeType != oldWidget.controller?.runtimeType;
  }

  @override
  void didUpdateWidget(TableScrollable oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(tablePosition);
      widget.controller?.attach(tablePosition);
    }

    if (_shouldUpdatePosition(oldWidget)) {
      _updatePosition();
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(tablePosition);
    tablePosition.dispose();
    super.dispose();
  }

  // SEMANTICS

  //final GlobalKey _scrollSemanticsKey = GlobalKey();

  @override
  @protected
  void setSemanticsActions(Set<SemanticsAction> actions) {
    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState!.replaceSemanticsActions(actions);
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
              ..onCancel = _handleDragCancel;
            // ..minFlingDistance = _physics?.minFlingDistance
            // ..minFlingVelocity = _physics?.minFlingVelocity
            // ..maxFlingVelocity = _physics?.maxFlingVelocity;
          },
        ),
      };
    }

    _lastCanDrag = canDrag;

    if (_gestureDetectorKey.currentState != null)
      _gestureDetectorKey.currentState!
          .replaceGestureRecognizers(_gestureRecognizers);
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
    _hold = tablePosition.hold(_disposeHold);
  }

  TableScrollDirection _selectDragDirection(DragDownDetails details) =>
      tablePosition.selectScrollDirection(details);

  void _handleDragStart(DragStartDetails details) {
    // It's possible for _hold to become null between _handleDragDown and
    // _handleDragStart, for example if some user code calls jumpTo or otherwise
    // triggers a new activity to begin.

    assert(_drag == null);

    _drag = tablePosition.drag(details, _disposeDrag);
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
        position: tablePosition,
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
                child: widget.viewportBuilder(context, tablePosition),
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
    properties.add(
        DiagnosticsProperty<TableScrollPosition>('position', _tablePosition));
  }

  @override
  void saveOffset(double offset) {}

  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent && _tablePosition != null) {
      // if (_physics != null && !_physics!.shouldAcceptUserOffset(_tablePosition)) {
      //   return;
      // }

      if (_tablePosition!.tableModel.tableScrollDirection !=
          TableScrollDirection.horizontal) {
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
    final position = _tablePosition as TableScrollPositionWithSingleContext?;

    if (position == null) {
      return;
    }

    TablePanelLayoutIndex si = position.findScrollIndex(event.localPosition);

    final model = position.tableModel;

    final scrollIndexX =
        model.stateSplitX == SplitState.FREEZE_SPLIT ? 1 : si.xIndex;
    final scrollIndexY =
        model.stateSplitY == SplitState.FREEZE_SPLIT ? 1 : si.yIndex;

    final double targetScrollOffset =
        _targetScrollOffsetForPointerScroll(delta, scrollIndexX, scrollIndexY);

    _tablePosition?.setPixelsY(
        scrollIndexX,
        scrollIndexY,
        _tablePosition!.tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
                scrollActivity: true) +
            delta);

    final pixelsY = model.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

    if (delta != 0.0 && targetScrollOffset != pixelsY) {
      _tablePosition?.setPixelsY(
          scrollIndexX,
          scrollIndexY,
          _tablePosition!.tableModel.getScrollScaledY(
                  scrollIndexX, scrollIndexY,
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
    final model = _tablePosition!.tableModel;

    return math.min(
      math.max(
          model.getScrollScaledY(scrollIndexX, scrollIndexY,
                  scrollActivity: true) +
              delta,
          model.minScrollExtentY(scrollIndexY)),
      model.maxScrollExtentY(scrollIndexY),
    );
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
          child: child,
          axisDirection: axisDirection,
          color: _kDefaultGlowColor,
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
      case TargetPlatform.windows:
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
