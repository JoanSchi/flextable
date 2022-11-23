import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'table_drag_details.dart';
import 'table_animation_controller.dart';
import 'table_scroll.dart';
import 'table_scroll_notification.dart';
import 'dart:math' as math;

class TableIdleScrollActivity extends TableScrollActivity {
  /// Creates a scroll activity that does nothing.

  TableIdleScrollActivity(int scrollIndexX, int scrollIndexY,
      TableScrollActivityDelegate delegate, enableScrollNotification)
      : super(scrollIndexX, scrollIndexY, delegate, enableScrollNotification);

  @override
  void applyNewDimensions() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, 0.0, 0.0);
  }

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get xVelocity => 0.0;

  @override
  double get yVelocity => 0.0;
}

abstract class TableScrollActivityDelegate {
  /// The direction in which the scroll view scrolls.
  AxisDirection get axisDirectionX;

  AxisDirection get axisDirectionY;

  /// Update the scroll position to the given pixel value.
  ///
  /// Returns the overscroll, if any. See [ScrollPosition.setPixels] for more
  /// information.
  Offset setPixels(int scrollIndexX, int scrollIndexY, Offset pixels);

  double setPixelsX(int scrollIndexX, int scrollIndexY, double pixels);

  double setPixelsY(int scrollIndexX, int scrollIndexY, double pixels);

  /// Updates the scroll position by the given amount.
  ///
  /// Appropriate for when the user is directly manipulating the scroll
  /// position, for example by dragging the scroll view. Typically applies
  /// [ScrollPhysics.applyPhysicsToUserOffset] and other transformations that
  /// are appropriate for user-driving scrolling.

  void applyUserOffset(int scrollIndexX, int scrollIndexY, Offset delta);

  void applyUserOffsetX(int scrollIndexX, int scrollIndexY, double delta);

  void applyUserOffsetY(int scrollIndexX, int scrollIndexY, double delta);

  /// Terminate the current activity and start an idle activity.
  void goIdle(int scrollIndexX, int scrollIndexY);

  /// Terminate the current activity and start a ballistic activity with the
  /// given velocity.
  void goBallistic(
      int scrollIndexX, int scrollIndexY, double velocityX, double velocityY);

  void correctOffScroll(
    int scrollIndexX,
    int scrollIndexY,
  );

  alignCells(
    int scrollIndexX,
    int scrollIndexY,
    bool alignX,
    bool alignY,
  );
}

class HoldTableScrollActivity extends TableScrollActivity
    implements ScrollHoldController {
  /// Creates a scroll activity that does nothing.
  HoldTableScrollActivity(int scrollIndexX, int scrollIndexY,
      {required TableScrollActivityDelegate delegate,
      this.onHoldCanceled,
      enableScrollNotification = false})
      : super(scrollIndexX, scrollIndexY, delegate, enableScrollNotification);

  /// Called when [dispose] is called.
  final VoidCallback? onHoldCanceled;

  @override
  bool get shouldIgnorePointer => false;

  @override
  bool get isScrolling => false;

  @override
  double get xVelocity => 0.0;

  @override
  double get yVelocity => 0.0;

  @override
  void cancel() {
    delegate.correctOffScroll(scrollIndexX, scrollIndexY);
  }

  @override
  void dispose() {
    if (onHoldCanceled != null) onHoldCanceled!();
    super.dispose();
  }
}

abstract class TableScrollActivity {
  /// Initializes [delegate] for subclasses.
  final int scrollIndexX;
  final int scrollIndexY;

  TableScrollActivity(this.scrollIndexX, this.scrollIndexY,
      TableScrollActivityDelegate delegate, this.enableScrollNotification)
      : _delegate = delegate;

  bool enableScrollNotification;
  TableScrollActivityDelegate get delegate => _delegate;
  TableScrollActivityDelegate _delegate;

  /// Updates the activity's link to the [ScrollActivityDelegate].
  ///
  /// This should only be called when an activity is being moved from a defunct
  /// (or about-to-be defunct) [ScrollActivityDelegate] object to a new one.
  void updateDelegate(TableScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  /// Called by the [ScrollActivityDelegate] when it has changed type (for
  /// example, when changing from an Android-style scroll position to an
  /// iOS-style scroll position). If this activity can differ between the two
  /// modes, then it should tell the position to restart that activity
  /// appropriately.
  ///
  /// For example, [BallisticTableScrollActivity]'s implementation calls
  /// [ScrollActivityDelegate.goBallistic].
  void resetActivity() {}

  // Dispatch a [ScrollStartNotification] with the given metrics.
  void dispatchScrollStartNotification(
      TableScrollMetrics metrics, BuildContext? context) {
    if (enableScrollNotification)
      TableScrollStartNotification(metrics: metrics, context: context)
          .dispatch(context);
  }

  /// Dispatch a [ScrollUpdateNotification] with the given metrics and scroll delta.
  void dispatchScrollUpdateNotification(
      TableScrollMetrics metrics, BuildContext? context, Offset scrollDelta) {
    if (enableScrollNotification)
      TableScrollUpdateNotification(
              metrics: metrics, context: context, scrollDelta: scrollDelta)
          .dispatch(context);
  }

  // /// Dispatch an [OverscrollNotification] with the given metrics and overscroll.
  // void dispatchOverscrollNotification(TableScrollMetrics metrics, BuildContext context, Offset overscroll) {
  //   //OverscrollNotification(metrics: metrics, context: context, overscroll: overscroll).dispatch(context);
  // }

  // /// Dispatch a [ScrollEndNotification] with the given metrics and overscroll.
  void dispatchScrollEndNotification(
      TableScrollMetrics metrics, BuildContext? context) {
    if (enableScrollNotification)
      TableScrollEndNotification(metrics: metrics, context: context)
          .dispatch(context);
  }

  /// Called when the scroll view that is performing this activity changes its metrics.
  void applyNewDimensions() {}

  /// Whether the scroll view should ignore pointer events while performing this
  /// activity.
  bool get shouldIgnorePointer;

  /// Whether performing this activity constitutes scrolling.
  ///
  /// Used, for example, to determine whether the user scroll direction is
  /// [ScrollDirection.idle].
  bool get isScrolling;

  /// If applicable, the velocity at which the scroll offset is currently
  /// independently changing (i.e. without external stimuli such as a dragging
  /// gestures) in logical pixels per second for this activity.
  double get xVelocity;

  double get yVelocity;

  /// Called when the scroll view stops performing this activity.
  @mustCallSuper
  void dispose() {}

  @override
  String toString() => describeIdentity(this);
}

class TableDragScrollActivity extends TableScrollActivity {
  /// Creates an activity for when the user drags their finger across the
  /// screen.
  TableDragScrollActivity(
    int scrollIndexX,
    int scrollIndexY,
    TableScrollActivityDelegate delegate,
    TableDrag controller,
    enableScrollNotification,
  )   : _controller = controller,
        super(scrollIndexX, scrollIndexY, delegate, enableScrollNotification);

  TableDrag? _controller;

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  // DragScrollActivity is not independently changing velocity yet
  // until the drag is ended.

  @override
  double get xVelocity => 0.0;

  @override
  double get yVelocity => 0.0;

  @override
  void dispose() {
    _controller = null;
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}

// class AlwaysScrollableScrollPhysics extends ScrollPhysics {
//   /// Creates scroll physics that always lets the user scroll.
//   const AlwaysScrollableScrollPhysics({ ScrollPhysics parent }) : super(parent: parent);

//   @override
//   AlwaysScrollableScrollPhysics applyTo(ScrollPhysics ancestor) {
//     return AlwaysScrollableScrollPhysics(parent: buildParent(ancestor));
//   }

//   @override
//   bool shouldAcceptUserOffset(ScrollMetrics position) => true;
// }

class TableScrollDragController implements TableDrag {
  /// Creates an object that scrolls a scroll view as the user drags their
  /// finger across the screen.
  ///
  /// The [delegate] and `details` arguments must not be null.
  TableScrollDragController(
      {required TableScrollActivityDelegate delegate,
      required DragStartDetails details,
      this.onDragCanceled,
      this.carriedVelocityX,
      this.carriedVelocityY,
      this.motionStartDistanceThreshold,
      required this.scrollIndexX,
      required this.scrollIndexY,
      required this.adjustScroll})
      : assert(
            motionStartDistanceThreshold == null ||
                motionStartDistanceThreshold > 0.0,
            'motionStartDistanceThreshold must be a positive number or null'),
        _delegate = delegate,
        _lastDetails = details,
        _retainMomentumX = carriedVelocityX != null && carriedVelocityX != 0.0,
        _retainMomentumY = carriedVelocityY != null && carriedVelocityY != 0.0,
        _lastNonStationaryTimestamp = details.sourceTimeStamp,
        _offsetSinceLastStop =
            motionStartDistanceThreshold == null ? null : 0.0 {
    adjustScroll.start(details: details);
  }

  /// The object that will actuate the scroll view as the user drags.
  TableScrollActivityDelegate get delegate => _delegate;
  TableScrollActivityDelegate _delegate;
  AdjustScroll adjustScroll;

  final int scrollIndexX, scrollIndexY;

  /// Called when [dispose] is called.
  final VoidCallback? onDragCanceled;

  /// Velocity that was present from a previous [ScrollActivity] when this drag
  /// began.
  final double? carriedVelocityX;
  final double? carriedVelocityY;

  /// Amount of pixels in either direction the drag has to move by to start
  /// scroll movement again after each time scrolling came to a stop.
  final double? motionStartDistanceThreshold;

  Duration? _lastNonStationaryTimestamp;
  bool _retainMomentumX;
  bool _retainMomentumY;

  /// Null if already in motion or has no [motionStartDistanceThreshold].
  double? _offsetSinceLastStop;

  /// Maximum amount of time interval the drag can have consecutive stationary
  /// pointer update events before losing the momentum carried from a previous
  /// scroll activity.
  static const Duration momentumRetainStationaryDurationThreshold =
      Duration(milliseconds: 20);

  /// Maximum amount of time interval the drag can have consecutive stationary
  /// pointer update events before needing to break the
  /// [motionStartDistanceThreshold] to start motion again.
  static const Duration motionStoppedDurationThreshold =
      Duration(milliseconds: 50);

  /// The drag distance past which, a [motionStartDistanceThreshold] breaking
  /// drag is considered a deliberate fling.
  // static const double _bigThresholdBreakDistance = 24.0;

  bool get _reversedX => axisDirectionIsReversed(delegate.axisDirectionX);

  bool get _reversedY => axisDirectionIsReversed(delegate.axisDirectionY);

  void updateDelegate(TableScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  @override
  void update(TableDragUpdateDetails details) {
    //print('update to delegate');
    Offset offset = details.delta;

    _lastDetails = details;

    adjustScroll.update(details);

    if (offset != Offset.zero) {
      _lastNonStationaryTimestamp = details.sourceTimeStamp;
    }

    if (_reversedY) // e.g. an AxisDirection.up scrollable
      offset = -offset;

    if (!adjustScroll.scrollX) {
      delegate.applyUserOffsetY(scrollIndexX, scrollIndexY, offset.dy);
    } else if (!adjustScroll.scrollY) {
      delegate.applyUserOffsetX(scrollIndexX, scrollIndexY, offset.dx);
    } else {
      delegate.applyUserOffset(scrollIndexX, scrollIndexY, offset);
    }
  }

  @override
  void end(TableDragEndDetails details) {
    assert(details.xVelocity != null || details.yVelocity != null);
    // We negate the velocity here because if the touch is moving downwards,
    // the scroll has to move upwards. It's the same reason that update()
    // above negates the delta before applying it to the scroll offset.
    double xVelocity = -details.xVelocity!;
    double yVelocity = -details.yVelocity!;

    if (_reversedX) xVelocity = -xVelocity;

    if (_reversedY) yVelocity = -yVelocity;

    // print('xVelocity $xVelocity yVelocity $yVelocity');

    _lastDetails = details;

    // Build momentum only if dragging in the same direction.
    if (adjustScroll.scrollX) {
      if (_retainMomentumX && xVelocity.sign == carriedVelocityX!.sign)
        xVelocity += carriedVelocityX!;
    } else {
      xVelocity = 0.0;
    }

    if (adjustScroll.scrollY) {
      if (_retainMomentumY && yVelocity.sign == carriedVelocityY!.sign)
        yVelocity += carriedVelocityY!;
    } else {
      yVelocity = 0.0;
    }

    delegate.goBallistic(scrollIndexX, scrollIndexY, xVelocity, yVelocity);

    adjustScroll.end();
  }

  @override
  void cancel() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, 0.0, 0.0);
  }

  /// Called by the delegate when it is no longer sending events to this object.
  @mustCallSuper
  void dispose() {
    _lastDetails = null;
    if (onDragCanceled != null) onDragCanceled!();
  }

  /// The most recently observed [DragStartDetails], [DragUpdateDetails], or
  /// [DragEndDetails] object.
  dynamic get lastDetails => _lastDetails;
  dynamic _lastDetails;

  @override
  String toString() => describeIdentity(this);
}

class TableScrollBarDragController implements TableDrag {
  /// Creates an object that scrolls a scroll view as the user drags their
  /// finger across the screen.
  ///
  /// The [delegate] and `details` arguments must not be null.
  TableScrollBarDragController({
    required TableScrollActivityDelegate delegate,
    required DragStartDetails details,
    this.onDragCanceled,
    required this.scrollIndexX,
    required this.scrollIndexY,
  })  : _delegate = delegate,
        _lastDetails = details;

  /// The object that will actuate the scroll view as the user drags.
  TableScrollActivityDelegate get delegate => _delegate;
  TableScrollActivityDelegate _delegate;
  final int scrollIndexX, scrollIndexY;

  /// Called when [dispose] is called.
  final VoidCallback? onDragCanceled;

  void updateDelegate(TableScrollActivityDelegate value) {
    assert(_delegate != value);
    _delegate = value;
  }

  @override
  void update(TableDragUpdateDetails details) {
    //print('update to delegate');
    Offset offset = details.delta;
    delegate.applyUserOffset(scrollIndexX, scrollIndexY, offset);
  }

  @override
  void end(TableDragEndDetails details) {
    delegate.goBallistic(scrollIndexX, scrollIndexY, 0, 0);
  }

  @override
  void cancel() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, 0.0, 0.0);
  }

  /// Called by the delegate when it is no longer sending events to this object.
  @mustCallSuper
  void dispose() {
    _lastDetails = null;
    if (onDragCanceled != null) onDragCanceled!();
  }

  /// The most recently observed [DragStartDetails], [DragUpdateDetails], or
  /// [DragEndDetails] object.
  dynamic get lastDetails => _lastDetails;
  dynamic _lastDetails;

  @override
  String toString() => describeIdentity(this);
}

class BallisticTableScrollActivity extends TableScrollActivity {
  /// Creates an activity that animates a scroll view based on a [simulation].
  ///
  /// The [delegate], [simulation], and [vsync] arguments must not be null.
  BallisticTableScrollActivity(
      int scrollIndexX,
      int scrollIndexY,
      TableScrollActivityDelegate delegate,
      Simulation xSimulation,
      Simulation ySimulation,
      TickerProvider vsync,
      enableScrollNotification)
      : super(scrollIndexX, scrollIndexY, delegate, enableScrollNotification) {
    // _controllerX = AnimationController.unbounded(
    //   debugLabel: kDebugMode ? '$runtimeType' : null,
    //   vsync: vsync,
    // )
    //   ..addListener(_tickX)
    //   ..animateWith(simulation)
    //    .whenComplete((){
    //      _endX = true;
    //      _end();
    //      });

    _controller = TableAnimationController.unbounded(
      debugLabel: kDebugMode ? '$runtimeType' : null,
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(xSimulation, ySimulation).whenComplete(() {
        _end();
      }); // won't trigger if we dispose _controller first
  }

  late TableAnimationController _controller;

  @override
  double get xVelocity => _controller.xVelocity;

  @override
  double get yVelocity => _controller.yVelocity;

  @override
  void resetActivity() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, xVelocity, yVelocity);
  }

  @override
  void applyNewDimensions() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, xVelocity, yVelocity);
  }

  void _tick() {
    //print('tick');
    if (!applyMoveTo(_controller.value)) {
      //print('tick IDLE');
      delegate.goIdle(scrollIndexX, scrollIndexY);
    }
  }

  /// Move the position to the given location.
  ///
  /// If the new position was fully applied, returns true. If there was any
  /// overflow, returns false.
  ///
  /// The default implementation calls [ScrollActivityDelegate.setPixels]
  /// and returns true if the overflow was zero.
  @protected
  bool applyMoveTo(Offset value) {
    if (!_controller.isXdone && !_controller.isYdone) {
      final pixels = delegate.setPixels(scrollIndexX, scrollIndexY, value);
      return pixels.dx == 0.0 || pixels.dy == 0.0;
    } else if (!_controller.isXdone) {
      final pixels = delegate.setPixelsX(scrollIndexX, scrollIndexY, value.dx);
      return pixels == 0.0;
    } else if (!_controller.isYdone) {
      final pixels = delegate.setPixelsY(scrollIndexX, scrollIndexY, value.dy);
      return pixels == 0.0;
    } else {
      return false;
    }
  }

  void _end() {
    delegate.goIdle(scrollIndexX, scrollIndexY);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}

class CorrrectOffScrollActivity extends TableScrollActivity {
  /// Creates an activity that animates a scroll view based on a [simulation].
  ///
  /// The [delegate], [simulation], and [vsync] arguments must not be null.
  CorrrectOffScrollActivity(
      int scrollIndexX,
      int scrollIndexY,
      TableScrollActivityDelegate delegate,
      List<ScrollSimulation> list,
      TickerProvider vsync,
      enableScrollNotification)
      : super(scrollIndexX, scrollIndexY, delegate, enableScrollNotification) {
    // _controllerX = AnimationController.unbounded(
    //   debugLabel: kDebugMode ? '$runtimeType' : null,
    //   vsync: vsync,
    // )
    //   ..addListener(_tickX)
    //   ..animateWith(simulation)
    //    .whenComplete((){
    //      _endX = true;
    //      _end();
    //      });

    _controller = TableMultiAnimationController.unbounded(
      debugLabel: kDebugMode ? '$runtimeType' : null,
      vsync: vsync,
    )
      ..addListener(_tick)
      ..animateWith(list).whenComplete(() {
        _end();
      }); // won't trigger if we dispose _controller first
  }

  late TableMultiAnimationController _controller;

  @override
  double get xVelocity => 0;

  @override
  double get yVelocity => 0;

  @override
  void resetActivity() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, xVelocity, yVelocity);
  }

  @override
  void applyNewDimensions() {
    delegate.goBallistic(scrollIndexX, scrollIndexY, xVelocity, yVelocity);
  }

  void _tick() {
    //print('tick');
    if (!applyMoveTo()) {
      //print('tick IDLE');
      delegate.goIdle(scrollIndexX, scrollIndexY);
    }
  }

  /// Move the position to the given location.
  ///
  /// If the new position was fully applied, returns true. If there was any
  /// overflow, returns false.
  ///
  /// The default implementation calls [ScrollActivityDelegate.setPixels]
  /// and returns true if the overflow was zero.
  @protected
  bool applyMoveTo() {
    _controller.reset();

    while (_controller.next()) {
      _controller.value.apply();
      // print('ticker!!');
    }

    return _controller.isScrolling;
  }

  void _end() {
    delegate.goIdle(scrollIndexX, scrollIndexY);
  }

  @override
  bool get shouldIgnorePointer => true;

  @override
  bool get isScrolling => true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String toString() {
    return '${describeIdentity(this)}($_controller)';
  }
}

class AdjustScroll {
  final TableScrollPosition tableScrollPosition;
  TableScrollDirection direction = TableScrollDirection.both;
  TickerProvider vsync;
  int scrollIndexX;
  int scrollIndexY;
  late Offset _startPosition;
  bool scrollX = false;
  bool scrollY = false;
  late AnimationController _controller;
  late Animation _animation;
  late Tween tween;
  double startX = 0.0;
  double startY = 0.0;
  bool stop = false;

  AdjustScroll(
      {required this.tableScrollPosition,
      required this.direction,
      required this.scrollIndexX,
      required this.scrollIndexY,
      required this.vsync}) {
    tween = Tween();
    _controller = AnimationController(
        vsync: vsync,
        duration: Duration(
          milliseconds: 200,
        ))
      ..addListener(() {
        if (!scrollX)
          tableScrollPosition.setPixelsX(
              scrollIndexX, scrollIndexY, _animation.value);
        if (!scrollY)
          tableScrollPosition.setPixelsY(
              scrollIndexX, scrollIndexY, _animation.value);
      });
    _animation = _controller.drive(CurveTween(curve: Curves.ease)).drive(tween);
  }

  start({required DragStartDetails details}) {
    if (_controller.status != AnimationStatus.forward) {
      _startPosition = details.localPosition;
      startX = tableScrollPosition.scrollPixelsX(scrollIndexX, scrollIndexY);
      startY = tableScrollPosition.scrollPixelsY(scrollIndexX, scrollIndexY);

      switch (direction) {
        case TableScrollDirection.horizontal:
          {
            scrollX = true;
            scrollY = false;
            break;
          }
        case TableScrollDirection.vertical:
          {
            scrollX = false;
            scrollY = true;
            break;
          }
        default:
          scrollX = true;
          scrollY = true;
      }

      stop = false;
    }
  }

  update(TableDragUpdateDetails details) {
    if (stop) return;

    Offset position = details.localPosition;

    final delta = position - _startPosition;

    // sin(α) = overstaande rechthoeks / zijdeschuine zijde
    // sin(α)    = opposite / hypotenuse

    double hypotenuse = 30.0;
    double degrees = 22.5;

    switch (direction) {
      case TableScrollDirection.both:
        {
          final distance = delta.distance;

          if (distance > hypotenuse) {
            stop = true;

            final opposite =
                math.sin(math.pi * 2.0 / 360.0 * degrees) * distance;

            if (delta.dx.abs() < opposite) {
              scrollX = false;

              final end =
                  tableScrollPosition.scrollPixelsX(scrollIndexX, scrollIndexY);

              tween
                ..begin = end
                ..end = startX;
              _controller.value = 0.0;
              _controller.forward();
            } else if (delta.dy.abs() < opposite) {
              scrollY = false;
              // print('No scrollY $delta');
              final end =
                  tableScrollPosition.scrollPixelsY(scrollIndexX, scrollIndexY);

              tween
                ..begin = end
                ..end = startY;
              _controller.value = 0.0;
              _controller.forward();
            }
          }

          break;
        }
      case TableScrollDirection.vertical:
        {
          break;
        }
      case TableScrollDirection.horizontal:
        {
          break;
        }
      default:
        {}
    }
  }

  end() {}

  dispose() {
    _controller.dispose();
  }
}