import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'table_animation_controller.dart';
import 'table_multi_panel_portview.dart';
import 'table_drag_details.dart';
import 'table_model.dart';
import 'table_scroll_activity.dart';
import 'table_scroll_physics.dart';
import 'table_scrollbar.dart';
import 'adjust_table_move_freeze.dart';

enum SplitChange { start, edit, no }

typedef _SetPixels = Function(int scrollIndexX, int scrollIndexY, double value);

class TableScrollController extends ChangeNotifier {
  /// Creates a controller for a scrollable widget.
  ///
  /// The values of `initialScrollOffset` and `keepScrollOffset` must not be null.
  TableScrollController({
    double initialScrollOffset = 0.0,
    this.keepScrollOffset = true,
    this.debugLabel,
  }) : _initialScrollOffset = initialScrollOffset;

  /// The initial value to use for [scrollPosition].
  ///
  /// New [ScrollPosition] objects that are created and attached to this
  /// controller will have their offset initialized to this value
  /// if [keepScrollOffset] is false or a scroll offset hasn't been saved yet.
  ///
  /// Defaults to 0.0.
  double get initialScrollOffset => _initialScrollOffset;
  final double _initialScrollOffset;

  /// Each time a scroll completes, save the current scroll [scrollPosition] with
  /// [PageStorage] and restore it if this controller's scrollable is recreated.
  ///
  /// If this property is set to false, the scroll offset is never saved
  /// and [initialScrollOffset] is always used to initialize the scroll
  /// offset. If true (the default), the initial scroll offset is used the
  /// first time the controller's scrollable is created, since there's no
  /// scroll offset to restore yet. Subsequently the saved offset is
  /// restored and [initialScrollOffset] is ignored.
  ///
  /// See also:
  ///
  ///  * [PageStorageKey], which should be used when more than one
  ///    scrollable appears in the same route, to distinguish the [PageStorage]
  ///    locations used to save scroll offsets.
  final bool keepScrollOffset;

  /// A label that is used in the [toString] output. Intended to aid with
  /// identifying scroll controller instances in debug output.
  final String? debugLabel;

  /// The currently attached positions.
  ///
  /// This should not be mutated directly. [ScrollPosition] objects can be added
  /// and removed using [attach] and [detach].
  @protected
  Iterable<TableScrollPosition> get positions => _positions;
  final List<TableScrollPosition> _positions = <TableScrollPosition>[];

  /// Whether any [ScrollPosition] objects have attached themselves to the
  /// [ScrollController] using the [attach] method.
  ///
  /// If this is false, then members that interact with the [ScrollPosition],
  /// such as [position], [scrollPosition], [animateTo], and [jumpTo], must not be
  /// called.
  bool get hasClients => _positions.isNotEmpty;

  /// Returns the attached [ScrollPosition], from which the actual scroll offset
  /// of the [ScrollView] can be obtained.
  ///
  /// Calling this is only valid when only a single position is attached.
  TableScrollPosition get position {
    assert(_positions.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    assert(_positions.length == 1,
        'ScrollController attached to multiple scroll views.');
    return _positions.single;
  }

  /// The current scroll offset of the scrollable widget.
  ///
  /// Requires the controller to be controlling exactly one scrollable widget.
  //Offset get offset => position.pixelsTable;

  /// Animates the position from its current value to the given value.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// The returned [Future] will complete when the animation ends, whether it
  /// completed successfully or whether it was interrupted prematurely.
  ///
  /// An animation will be interrupted whenever the user attempts to scroll
  /// manually, or whenever another activity is started, or whenever the
  /// animation reaches the edge of the viewport and attempts to overscroll. (If
  /// the [ScrollPosition] does not overscroll but instead allows scrolling
  /// beyond the extents, then going beyond the extents will not interrupt the
  /// animation.)
  ///
  /// The animation is indifferent to changes to the viewport or content
  /// dimensions.
  ///
  /// Once the animation has completed, the scroll position will attempt to
  /// begin a ballistic activity in case its value is not stable (for example,
  /// if it is scrolled beyond the extents and in that situation the scroll
  /// position would normally bounce back).
  ///
  /// The duration must not be zero. To jump to a particular value without an
  /// animation, use [jumpTo].
  // Future<void> animateTo(
  //   double offset, {
  //   @required Duration duration,
  //   @required Curve curve,
  // }) {
  //   assert(_positions.isNotEmpty, 'ScrollController not attached to any scroll views.');
  //   final List<Future<void>> animations = List<Future<void>>(_positions.length);
  //   for (int i = 0; i < _positions.length; i += 1)
  //     animations[i] = _positions[i].animateTo(offset, duration: duration, curve: curve);
  //   return Future.wait<void>(animations).then<void>((List<void> _) => null);
  // }

  /// Jumps the scroll position from its current value to the given value,
  /// without animation, and without checking if the new value is in range.
  ///
  /// Any active animation is canceled. If the user is currently scrolling, that
  /// action is canceled.
  ///
  /// If this method changes the scroll position, a sequence of start/update/end
  /// scroll notifications will be dispatched. No overscroll notifications can
  /// be generated by this method.
  ///
  /// Immediately after the jump, a ballistic activity is started, in case the
  /// value was out of range.
  void jumpTo(double value) {
    assert(_positions.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    for (ScrollPosition position in List<ScrollPosition>.from(_positions))
      position.jumpTo(value);
  }

  /// Register the given position with this controller.
  ///
  /// After this function returns, the [animateTo] and [jumpTo] methods on this
  /// controller will manipulate the given position.
  void attach(TableScrollPosition position) {
    assert(!_positions.contains(position));
    _positions.add(position);
    position.addListener(notifyListeners);
  }

  /// Unregister the given position with this controller.
  ///
  /// After this function returns, the [animateTo] and [jumpTo] methods on this
  /// controller will not manipulate the given position.
  void detach(TableScrollPosition position) {
    assert(_positions.contains(position));
    position.removeListener(notifyListeners);
    _positions.remove(position);
  }

  @override
  void dispose() {
    for (TableScrollPosition position in _positions)
      position.removeListener(notifyListeners);
    super.dispose();
  }

  /// Creates a [ScrollPosition] for use by a [Scrollable] widget.
  ///
  /// Subclasses can override this function to customize the [ScrollPosition]
  /// used by the scrollable widgets they control. For example, [PageController]
  /// overrides this function to return a page-oriented scroll position
  /// subclass that keeps the same page visible when the scrollable widget
  /// resizes.
  ///
  /// By default, returns a [ScrollPositionWithSingleContext].
  ///
  /// The arguments are generally passed to the [ScrollPosition] being created:
  ///
  ///  * `physics`: An instance of [ScrollPhysics] that determines how the
  ///    [ScrollPosition] should react to user interactions, how it should
  ///    simulate scrolling when released or flung, etc. The value will not be
  ///    null. It typically comes from the [ScrollView] or other widget that
  ///    creates the [Scrollable], or, if none was provided, from the ambient
  ///    [ScrollConfiguration].
  ///  * `context`: A [ScrollContext] used for communicating with the object
  ///    that is to own the [ScrollPosition] (typically, this is the
  ///    [Scrollable] itself).
  ///  * `oldPosition`: If this is not the first time a [ScrollPosition] has
  ///    been created for this [Scrollable], this will be the previous instance.
  ///    This is used when the environment has changed and the [Scrollable]
  ///    needs to recreate the [ScrollPosition] object. It is null the first
  ///    time the [ScrollPosition] is created.
  TableScrollPosition createScrollPosition(
      TableScrollPhysics physics,
      ScrollContext context,
      TableScrollPosition? oldPosition,
      TableModel sheetModelDelegate) {
    return TableScrollPositionWithSingleContext(
      physics: physics,
      context: context,
      oldPosition: oldPosition,
      tableModel: sheetModelDelegate,
      debugLabel: debugLabel,
    );
  }

  @override
  String toString() {
    final List<String> description = <String>[];
    debugFillDescription(description);
    return '${describeIdentity(this)}(${description.join(", ")})';
  }

  /// Add additional information to the given description for use by [toString].
  ///
  /// This method makes it easier for subclasses to coordinate to provide a
  /// high-quality [toString] implementation. The [toString] implementation on
  /// the [ScrollController] base class calls [debugFillDescription] to collect
  /// useful information from subclasses to incorporate into its return value.
  ///
  /// If you override this, make sure to start your method with a call to
  /// `super.debugFillDescription(description)`.
  @mustCallSuper
  void debugFillDescription(List<String> description) {
    // if (debugLabel != null)
    //   description.add(debugLabel);
    // if (initialScrollOffset != 0.0)
    //   description.add('initialScrollOffset: ${initialScrollOffset.toStringAsFixed(1)}, ');
    // if (_positions.isEmpty) {
    //   description.add('no clients');
    // } else if (_positions.length == 1) {
    //   // Don't actually list the client itself, since its toString may refer to us.
    //   description.add('one client, offset ${offset?.toStringAsFixed(1)}');
    // } else {
    //   description.add('${_positions.length} clients');
    // }
  }
}

abstract class TableScrollPosition extends ChangeNotifier
    implements TableScrollActivityDelegate {
  final ScrollContext context;
  final TableScrollPhysics physics;
  final TableModel tableModel;
  final ValueNotifier<bool> isScrollingNotifier = ValueNotifier<bool>(false);
  bool gridIndexAvailable = false;
  bool scrollNotificationEnabled = false;

  TableScrollPosition(
      {required this.context,
      required this.physics,
      required this.tableModel}) {
    context.setCanDrag(true);
  }

  TableScrollActivity? get activity => _activity;
  TableScrollActivity? _activity;

  // bool applyTableDimensions({List<GridLayout> layoutX, List<GridLayout> layoutY}) {
  //   _layoutX = layoutX;
  //   _layoutY = layoutY;
  //   context.setCanDrag(true);
  //   return true;
  // }

  List<GridLayout> get layoutX => tableModel.widthLayoutList;

  List<GridLayout> get layoutY => tableModel.heightLayoutList;

  TableScrollDirection get tableScrollDirection =>
      tableModel.tableScrollDirection;

  bool applyContentDimensions(double minScrollExtentX, double maxScrollExtentX,
      double minScrollExtentY, double maxScrollExtentY);

  void correctBy(Offset value);

  void jumpTo(Offset value);

  Future<void> animateTo(
    Offset to, {
    required Duration duration,
    required Curve curve,
  });

  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback);

  TableDrag dragScrollBar(DragStartDetails details,
      VoidCallback dragCancelCallback, int scrollIndexX, int scrollIndexY);

  /// Calls [jumpTo] if duration is null or [Duration.zero], otherwise
  /// [animateTo] is called.
  ///
  /// If [animateTo] is called then [curve] defaults to [Curves.ease]. The
  /// [clamp] parameter is ignored by this stub implementation but subclasses
  /// like [ScrollPosition] handle it by adjusting [to] to prevent over or
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

  /// Whether a viewport is allowed to change [pixelsTable] implicitly to respond to
  /// a call to [RenderObject.showOnScreen].
  ///
  /// [RenderObject.showOnScreen] is for example used to bring a text field
  /// fully on screen after it has received focus. This property controls
  /// whether the viewport associated with this offset is allowed to change the
  /// offset's [pixelsTable] value to fulfill such a request.
  bool get allowImplicitScrolling;

  @mustCallSuper
  void debugFillDescription(List<String> description) {
    // description.add('offset: $pixelsY');
  }

  void beginActivity(TableScrollActivity? newActivity) {
    if (newActivity == null) return;
    bool wasScrolling, oldIgnorePointer;
    if (_activity != null) {
      oldIgnorePointer = _activity!.shouldIgnorePointer;
      wasScrolling = _activity!.isScrolling;
      if (wasScrolling && !newActivity.isScrolling)
        didEndScroll(); // notifies and then saves the scroll offset
      _activity!.dispose();
    } else {
      oldIgnorePointer = false;
      wasScrolling = false;
    }
    _activity = newActivity;

    // print('TableScroll Activity');

    if (oldIgnorePointer != activity!.shouldIgnorePointer)
      context.setIgnorePointer(activity!.shouldIgnorePointer);

    isScrollingNotifier.value = activity!.isScrolling;

    if (!wasScrolling && _activity!.isScrolling) didStartScroll();
  }

  TableDrag? currentDrag;

  double _heldPreviousXvelocity = 0.0;
  double _heldPreviousYvelocity = 0.0;

  /// Called by [beginActivity] to report when an activity has started.
  void didStartScroll() {
    tableModel.notifyScrollListeners('start');
    if (scrollNotificationEnabled)
      activity!.dispatchScrollStartNotification(
          tableModel, context.notificationContext);
  }

  void enableScrollNotification(enable) {
    scrollNotificationEnabled = enable;
    _activity?.enableScrollNotification = true;

    didUpdateScrollPositionBy(Offset.zero);
  }

  void didUpdateScrollPositionBy(Offset value) {
    tableModel.notifyScrollListeners('update');
    if (scrollNotificationEnabled)
      activity!.dispatchScrollUpdateNotification(
          tableModel, context.notificationContext, value);
  }

  /// Called by [beginActivity] to report when an activity has ended.
  ///
  /// This also saves the scroll offset using [saveScrollOffset].
  void didEndScroll() {
    tableModel.notifyScrollListeners('end');
    if (scrollNotificationEnabled)
      activity!.dispatchScrollEndNotification(
          tableModel, context.notificationContext);
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

  ScrollHoldController hold(VoidCallback holdCancelCallback);

  @override
  void dispose() {
    activity
        ?.dispose(); // it will be null if it got absorbed by another ScrollPosition
    _activity = null;
    super.dispose();
  }

  Offset setPixels(int scrollIndexX, int scrollIndexY, Offset newPixels) {
    double xDelta = 0.0;
    double yDelta = 0.0;
    double xOverscroll = 0.0;
    double yOverscroll = 0.0;

    assert(activity!.isScrolling);
    assert(SchedulerBinding.instance.schedulerPhase.index <=
        SchedulerPhase.transientCallbacks.index);

    double pixelsX = tableModel.getScrollScaledX(scrollIndexX, scrollIndexY,
        scrollActivity: true);

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

      tableModel.setScrollScaledX(scrollIndexX, scrollIndexY, pixelsX);
    }

    double pixelsY = tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

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
      tableModel.setScrollScaledY(scrollIndexX, scrollIndexY, pixelsY);
    }

    if (xDelta != 0.0 || yDelta != 0.0) {
      didUpdateScrollPositionBy(Offset(xDelta, yDelta));
      tableModel.notifyListeners();
    }

    if (xOverscroll != 0.0 || yOverscroll != 0.0) {
      didOverscrollBy(Offset(xOverscroll, yOverscroll));
      return Offset(xOverscroll, yOverscroll);
    }

    return Offset.zero;
  }

  @override
  double setPixelsX(int scrollIndexX, int scrollIndexY, double newPixels) {
    double pixelsX = tableModel.getScrollScaledX(scrollIndexX, scrollIndexY,
        scrollActivity: true);

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
        tableModel.setScrollScaledX(scrollIndexX, scrollIndexY, pixelsX);
        tableModel.notifyListeners();
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
    double pixelsY = tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

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
        tableModel.setScrollScaledY(scrollIndexX, scrollIndexY, pixelsY);
        tableModel.notifyListeners();
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
        tableModel.minScrollExtentX(scrollIndexX),
        tableModel.maxScrollExtentX(scrollIndexX),
        tableModel.viewportDimensionX(scrollIndexX));
  }

  @protected
  double applyBoundaryConditionsY(
      int scrollIndexX, int scrollIndexY, double value) {
    return applyBoundaryConditions(
        value,
        scrollPixelsY(scrollIndexX, scrollIndexY),
        tableModel.minScrollExtentY(scrollIndexY),
        tableModel.maxScrollExtentY(scrollIndexY),
        tableModel.viewportDimensionY(scrollIndexY));
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

  shouldRebuild(TableScrollPosition offset) {
    return tableModel.shouldRebuild((offset.tableModel));
  }

  TableScrollDirection selectScrollDirection(DragDownDetails details) {
    return tableScrollDirection;
  }

  double scrollPixelsX(int scrollIndexX, int scrollIndexY) => tableModel
      .getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

  double scrollPixelsY(int scrollIndexX, int scrollIndexY) => tableModel
      .getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);
}

class TableScrollPositionWithSingleContext extends TableScrollPosition {
  ScrollDirection get userScrollDirectionY => _userScrollDirectionY;
  ScrollDirection _userScrollDirectionY = ScrollDirection.idle;

  ScrollDirection get userScrollDirectionX => _userScrollDirectionX;
  ScrollDirection _userScrollDirectionX = ScrollDirection.idle;
  late AdjustScroll _adjustScroll;
  // TableDragDecision dragDecision;

  TableScrollPositionWithSingleContext({
    required TableScrollPhysics physics,
    required ScrollContext context,
    TableScrollPosition? oldPosition,
    required TableModel tableModel,
    String? debugLabel,
  }) : super(
          physics: physics,
          context: context,
          //  oldPosition: oldPosition,
          tableModel: tableModel,
          //  debugLabel: debugLabel,
        ) {
    // If oldPosition is not null, the superclass will first call absorb(),
    // which may set _pixels and _activity.

    if (activity == null) goIdle(0, 0);

    assert(activity != null);

    _adjustScroll = AdjustScroll(
        tableScrollPosition: this,
        scrollIndexX: 0,
        scrollIndexY: 0,
        direction: tableScrollDirection,
        vsync: context.vsync);
  }

  @override
  void beginActivity(TableScrollActivity? newActivity) {
    _heldPreviousXvelocity = 0.0;
    if (newActivity == null) return;
    assert(newActivity.delegate == this);
    super.beginActivity(newActivity);
    //print('_currentDrag is $_currentDrag');
    currentDrag?.dispose();
    currentDrag = null;
    // if (!activity!.isScrolling) {
    //   updateUserScrollDirectionY(ScrollDirection.idle);
    // }
  }

  @override
  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    TablePanelLayoutIndex si = findScrollIndex(details.localPosition);

    final scrollIndexX =
        (tableModel.stateSplitX == SplitState.FREEZE_SPLIT) ? 1 : si.xIndex;
    final scrollIndexY =
        (tableModel.stateSplitY == SplitState.FREEZE_SPLIT) ? 1 : si.yIndex;

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

  @override
  bool get allowImplicitScrolling => physics.allowImplicitScrolling;

  @override
  Future<void> animateTo(Offset to, {Duration? duration, Curve? curve}) {
    throw UnimplementedError();
  }

  @override
  bool applyContentDimensions(double minScrollExtentX, double maxScrollExtentX,
      double minScrollExtentY, double maxScrollExtentY) {
    throw UnimplementedError();
  }

  @override
  void applyUserOffset(int scrollIndexX, int scrollIndexY, Offset delta) {
    updateUserScrollDirection(
        delta.dx > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse,
        delta.dy > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);

    final pixelsX = tableModel.getScrollScaledX(scrollIndexX, scrollIndexY,
        scrollActivity: true);
    final pixelsY = tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

    setPixels(
        scrollIndexX,
        scrollIndexY,
        Offset(
            pixelsX -
                physics.applyPhysicsToUserOffset(
                    delta.dx,
                    pixelsX,
                    tableModel.minScrollExtentX(scrollIndexX),
                    tableModel.maxScrollExtentX(scrollIndexX)),
            pixelsY -
                physics.applyPhysicsToUserOffset(
                    delta.dy,
                    pixelsY,
                    tableModel.minScrollExtentY(scrollIndexY),
                    tableModel.maxScrollExtentY(scrollIndexY))));
  }

  @override
  void applyUserOffsetX(int scrollIndexX, int scrollIndexY, double delta) {
    updateUserScrollDirectionX(
        delta > 0.0 ? ScrollDirection.forward : ScrollDirection.reverse);

    final pixelsX = tableModel.getScrollScaledX(scrollIndexX, scrollIndexY,
        scrollActivity: true);

    setPixelsX(
        scrollIndexX,
        scrollIndexY,
        pixelsX -
            physics.applyPhysicsToUserOffset(
                delta,
                pixelsX,
                tableModel.minScrollExtentX(scrollIndexX),
                tableModel.maxScrollExtentX(scrollIndexX)));
  }

  @override
  void applyUserOffsetY(int scrollIndexX, int scrollIndexY, double delta) {
    final pixelsY = tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

    setPixelsY(
        scrollIndexX,
        scrollIndexY,
        pixelsY -
            physics.applyPhysicsToUserOffset(
                delta,
                pixelsY,
                tableModel.minScrollExtentY(scrollIndexY),
                tableModel.maxScrollExtentY(scrollIndexY)));
  }

  @override
  void correctBy(Offset value) {}

  @override
  void goBallistic(
      int scrollIndexX, int scrollIndexY, double velocityX, double velocityY) {
    final pixelsX = tableModel.getScrollScaledX(scrollIndexX, scrollIndexY,
        scrollActivity: true);
    final pixelsY = tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
        scrollActivity: true);

    final Simulation xSimulation = physics.createBallisticSimulation(
            pixelsX,
            tableModel.minScrollExtentX(scrollIndexX),
            tableModel.maxScrollExtentX(scrollIndexX),
            tableModel.outOfRangeX(scrollIndexX, scrollIndexY),
            velocityX) ??
        noBallisticSimulation;
    final Simulation ySimulation = physics.createBallisticSimulation(
            pixelsY,
            tableModel.minScrollExtentY(scrollIndexY),
            tableModel.maxScrollExtentY(scrollIndexY),
            tableModel.outOfRangeY(scrollIndexX, scrollIndexY),
            velocityY) ??
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
      print('idle');
      goIdle(scrollIndexX, scrollIndexY);
    }
  }

  @override
  void goIdle(int scrollIndexX, int scrollIndexY) {
    beginActivity(TableIdleScrollActivity(
        scrollIndexX, scrollIndexY, this, scrollNotificationEnabled));
  }

  void correctOffScroll(int scrollIndexX, int scrollIndexY) {
    List<ScrollSimulation> list = [];

    final _SetPixels setPixelsX =
        tableModel.tableScrollDirection != TableScrollDirection.vertical
            ? this.setPixelsX
            : (scrollIndexX, scrollIndexY, value) {
                //To do Aangepast is waarschijnlijk niet nodig voor CustomScrollView
                //  return tableModel.sliverScrollPosition?.setPixels(value) ?? 0.0;
                return 0.0;
              };

    final _SetPixels setPixelsY =
        tableModel.tableScrollDirection != TableScrollDirection.horizontal
            ? this.setPixelsY
            : (scrollIndexX, scrollIndexY, value) {
                //To do Aangepast is waarschijnlijk niet nodig voor CustomScrollView
                // return tableModel.sliverScrollPosition?.setPixels(value) ?? 0.0;
                return 0.0;
              };

    var xSimulation = (int scrollIndexX, int scrollIndexY) {
      Simulation? simulation = physics.createBallisticSimulation(
          tableModel.getScrollScaledX(scrollIndexX, scrollIndexY,
              scrollActivity: true),
          tableModel.minScrollExtentX(scrollIndexX),
          tableModel.maxScrollExtentX(scrollIndexX),
          true,
          20.0);

      if (simulation != null)
        list.add(ScrollSimulation(
          scrollIndexX: scrollIndexX,
          scrollIndexY: scrollIndexY,
          setPixels: setPixelsX,
          simulation: simulation,
        ));
    };

    var ySimulation = (int scrollIndexX, int scrollIndexY) {
      Simulation? simulation = physics.createBallisticSimulation(
          tableModel.getScrollScaledY(scrollIndexX, scrollIndexY,
              scrollActivity: true),
          tableModel.minScrollExtentY(scrollIndexY),
          tableModel.maxScrollExtentY(scrollIndexY),
          true,
          20.0);

      if (simulation != null)
        list.add(ScrollSimulation(
          scrollIndexX: scrollIndexX,
          scrollIndexY: scrollIndexY,
          setPixels: setPixelsY,
          simulation: simulation,
        ));
    };
    // goIdle(scrollIndexX, scrollIndexY);
    // return;

    if (tableModel.outOfRangeX(0, 0)) {
      xSimulation(0, 0);
    }

    if (tableModel.outOfRangeY(0, 0)) {
      ySimulation(0, 0);
    }

    if (tableModel.anySplitY) {
      if (tableModel.outOfRangeY(0, 1)) ySimulation(0, 1);

      if (tableModel.stateSplitY == SplitState.SPLIT &&
          !tableModel.scrollLockX) {
        if (tableModel.outOfRangeX(0, 1)) xSimulation(0, 1);

        if (tableModel.stateSplitX == SplitState.SPLIT &&
            tableModel.outOfRangeX(1, 1)) xSimulation(1, 1);
      }
    }

    if (tableModel.anySplitX) {
      if (tableModel.outOfRangeX(1, 0)) xSimulation(1, 0);

      if (tableModel.stateSplitX == SplitState.SPLIT &&
          !tableModel.scrollLockY) {
        if (tableModel.outOfRangeY(1, 0)) ySimulation(1, 0);

        if (tableModel.stateSplitY == SplitState.SPLIT &&
            tableModel.outOfRangeY(1, 1)) ySimulation(1, 1);
      }
    }

    if (list.isEmpty) {
      goIdle(scrollIndexX, scrollIndexY);
    } else {
      beginActivity(CorrrectOffScrollActivity(scrollIndexX, scrollIndexY, this,
          list, context.vsync, scrollNotificationEnabled));
    }
  }

  @override
  void jumpTo(Offset value) {}

  @override
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
    final scrollX = tableModel.getScrollScaledX(scrollIndexX, scrollIndexY);
    final scrollY = tableModel.getScrollScaledY(scrollIndexX, scrollIndexY);
    double suggestedScrollX = scrollX;
    double suggestedScrollY = scrollY;

    assert(scrollIndexX == 0 && scrollIndexY == 0,
        'AlignCells only implements scrollIndexX == 0 and scrollIndexY == 0');

    if (alignX) {
      suggestedScrollX = tableModel.moveFreezeToStartColumnScaled(10);
    }

    if (alignY) {
      suggestedScrollY = tableModel.moveFreezeToStartRowScaled(10);
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

  @override
  void dispose() {
    _adjustScroll.dispose();
    super.dispose();
  }
}

abstract class TableDrag {
  /// The pointer has moved.
  void update(TableDragUpdateDetails details);

  /// The pointer is no longer in contact with the screen.
  ///
  /// The velocity at which the pointer was moving when it stopped contacting
  /// the screen is available in the `details`.
  void end(TableDragEndDetails details);

  /// The input from the pointer is no longer directed towards this receiver.
  ///
  /// For example, the user might have been interrupted by a system-modal dialog
  /// in the middle of the drag.
  void cancel();

  void dispose();

  dynamic get lastDetails;
}

abstract class TableScrollMetrics {
  List<GridLayout> get tableLayoutX;

  List<GridLayout> get tableLayoutY;

  DrawScrollBar drawVerticalScrollBar(int scrollIndexX, int scrollIndexY);

  DrawScrollBar drawHorizontalScrollBar(int scrollIndexX, int scrollIndexY);

  DrawScrollBar drawVerticalScrollBarTrack(int scrollIndexX, int scrollIndexY);

  DrawScrollBar drawHorizontalScrollBarTrack(
      int scrollIndexX, int scrollIndexY);

  double scrollPixelsX(int scrollIndexX, int scrollIndexY);

  double scrollPixelsY(int scrollIndexX, int scrollIndexY);

  double maxScrollExtentX(int scrollIndexX);

  double minScrollExtentX(int scrollIndexX);

  double maxScrollExtentY(int scrollIndexY);

  double minScrollExtentY(int scrollIndexY);

  double viewportDimensionX(int scrollIndexX);

  double viewportDimensionY(int scrollIndexY);

  double viewportPositionX(int scrollIndexX);

  double viewportPositionY(int scrollIndexY);

  bool containsPositionX(int scrollIndexX, double position);

  bool containsPositionY(int scrollIndexY, double position);

  bool outOfRangeX(int scrollIndexX, int scrollIndexY);

  bool outOfRangeY(int scrollIndexX, int scrollIndexY);

  double trackDimensionX(int scrollIndexX);

  double trackDimensionY(int scrollIndexY);

  double trackPositionX(int scrollIndexX);

  double trackPositionY(int scrollIndexY);

  bool atEdgeX(int scrollIndexX, int scrollIndexY) {
    final pixelsX = scrollPixelsX(scrollIndexX, scrollIndexY);

    return pixelsX == minScrollExtentX(scrollIndexX) ||
        pixelsX == maxScrollExtentX(scrollIndexX);
  }

  bool atEdgeY(int scrollIndexX, int scrollIndexY) {
    final pixelsY = scrollPixelsY(scrollIndexX, scrollIndexY);

    return pixelsY == minScrollExtentY(scrollIndexY) ||
        pixelsY == maxScrollExtentY(scrollIndexY);
  }

  TableScrollDirection get tableScrollDirection;

  SplitState get stateSplitX;

  SplitState get stateSplitY;

  bool get autoFreezePossibleX;

  bool get autoFreezePossibleY;

  bool get noSplitX;

  bool get noSplitY;

  // /// The quantity of content conceptually "above" the viewport in the scrollable.
  // /// This is the content above the content described by [extentInside].
  // double get extentBeforeY => math.max(pixelsY - minScrollExtentY, 0.0);

  // /// The quantity of content conceptually "inside" the viewport in the scrollable.
  // ///
  // /// The value is typically the height of the viewport when [outOfRangeY] is false.
  // /// It could be less if there is less content visible than the size of the
  // /// viewport, such as when overscrolling.
  // ///
  // /// The value is always non-negative, and less than or equal to [viewportDimensionY].
  // double get extentInsideY {
  //   assert(minScrollExtentY <= maxScrollExtentY);
  //   return viewportDimensionY
  //       // "above" overscroll value
  //       -
  //       (minScrollExtentY - pixelsY).clamp(0, viewportDimensionY)
  //       // "below" overscroll value
  //       -
  //       (pixelsY - maxScrollExtentY).clamp(0, viewportDimensionY);
  // }

  // /// The quantity of content conceptually "below" the viewport in the scrollable.
  // /// This is the content below the content described by [extentInside].
  // double get extentAfter => math.max(maxScrollExtentY - pixelsY, 0.0);
}
