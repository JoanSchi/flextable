import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

enum TableScrollDirection {
  unknown,
  horizontal,
  vertical,
  both,
}

typedef GestureTableDragUpdateCallback = void Function(TableDragUpdateDetails details);
typedef GestureTableDragEndCallback = void Function(TableDragEndDetails details);
typedef GestureDragDirection = TableScrollDirection Function(DragDownDetails details);

class TableDragEndDetails {
  /// Creates details for a [GestureDragEndCallback].
  ///
  /// The [velocity] argument must not be null.
  TableDragEndDetails({
    this.velocity = Velocity.zero,
    this.xVelocity,
    this.yVelocity,
    this.xyVelocity,
  }) : assert((xyVelocity == null || xyVelocity == velocity.pixelsPerSecond.distance) &&
            (xVelocity == null || xVelocity == velocity.pixelsPerSecond.dx) &&
            (yVelocity == null || yVelocity == velocity.pixelsPerSecond.dy));

  /// The velocity the pointer was moving when it stopped contacting the screen.
  ///
  /// Defaults to zero if not specified in the constructor.
  final Velocity velocity;

  /// The velocity the pointer was moving along the primary axis when it stopped
  /// contacting the screen, in logical pixels per second.
  ///
  /// If the [GestureDragEndCallback] is for a one-dimensional drag (e.g., a
  /// horizontal or vertical drag), then this value contains the component of
  /// [velocity] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureDragEndCallback] is for a
  /// two-dimensional drag (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double? xVelocity;

  final double? yVelocity;

  final double? xyVelocity;

  @override
  String toString() => '$runtimeType($velocity)';
}

class TableDragUpdateDetails {
  /// Creates details for a [DragUpdateDetails].
  ///
  /// The [delta] argument must not be null.
  ///
  /// If [primaryDelta] is non-null, then its value must match one of the
  /// coordinates of [delta] and the other coordinate must be zero.
  ///
  /// The [globalPosition] argument must be provided and must not be null.
  TableDragUpdateDetails({
    this.sourceTimeStamp,
    this.delta = Offset.zero,
    this.primaryDelta,
    required this.globalPosition,
    Offset? localPosition,
  }) : localPosition = localPosition ?? globalPosition;

  /// Recorded timestamp of the source pointer event that triggered the drag
  /// event.
  ///
  /// Could be null if triggered from proxied events such as accessibility.
  final Duration? sourceTimeStamp;

  /// The amount the pointer has moved in the coordinate space of the event
  /// receiver since the previous update.
  ///
  /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this offset contains only the delta
  /// in that direction (i.e., the coordinate in the other direction is zero).
  ///
  /// Defaults to zero if not specified in the constructor.
  final Offset delta;

  /// The amount the pointer has moved along the primary axis in the coordinate
  /// space of the event receiver since the previous
  /// update.
  ///
  /// If the [GestureDragUpdateCallback] is for a one-dimensional drag (e.g.,
  /// a horizontal or vertical drag), then this value contains the component of
  /// [delta] along the primary axis (e.g., horizontal or vertical,
  /// respectively). Otherwise, if the [GestureDragUpdateCallback] is for a
  /// two-dimensional drag (e.g., a pan), then this value is null.
  ///
  /// Defaults to null if not specified in the constructor.
  final double? primaryDelta;

  /// The pointer's global position when it triggered this update.
  ///
  /// See also:
  ///
  ///  * [localPosition], which is the [globalPosition] transformed to the
  ///    coordinate space of the event receiver.
  final Offset globalPosition;

  /// The local position in the coordinate system of the event receiver at
  /// which the pointer contacted the screen.
  ///
  /// Defaults to [globalPosition] if not specified in the constructor.
  final Offset localPosition;

  @override
  String toString() => '$runtimeType($delta)';
}
