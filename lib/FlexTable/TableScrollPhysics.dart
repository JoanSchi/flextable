import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;

import 'TableAnimationSimulation.dart';

class TableScrollPhysics {
  /// Creates an object with the default scroll physics.
  const TableScrollPhysics({this.parent});

  final TableScrollPhysics? parent;

  @protected
  TableScrollPhysics? buildParent(TableScrollPhysics? ancestor) => parent?.applyTo(ancestor) ?? ancestor;

  TableScrollPhysics applyTo(TableScrollPhysics? ancestor) {
    return TableScrollPhysics(parent: buildParent(ancestor));
  }

  double applyPhysicsToUserOffset(double offset, double pixels, double minScrollExtent, double maxScrollExtent) {
    if (parent == null) return offset;
    return parent!.applyPhysicsToUserOffset(offset, pixels, minScrollExtent, maxScrollExtent);
  }

  bool shouldAcceptUserOffset(double pixels, double minScrollExtent, double maxScrollExtent) {
    if (parent == null) return pixels != 0.0 || minScrollExtent != maxScrollExtent;
    return parent!.shouldAcceptUserOffset(pixels, minScrollExtent, maxScrollExtent);
  }

  double applyBoundaryConditions(double value, double pixels, double minScrollExtent, double maxScrollExtent) {
    if (parent == null) return 0.0;
    return parent!.applyBoundaryConditions(value, pixels, minScrollExtent, maxScrollExtent);
  }

  Simulation? createBallisticSimulation(
      double pixels, double minScrollExtent, double maxScrollExtent, bool outOfRange, double velocity) {
    if (parent == null) return noBallisticSimulation;
    return parent!.createBallisticSimulation(pixels, minScrollExtent, maxScrollExtent, outOfRange, velocity);
  }

  static final SpringDescription _kDefaultSpring = SpringDescription.withDampingRatio(
    mass: 0.5,
    stiffness: 100.0,
    ratio: 1.1,
  );

  /// The spring to use for ballistic simulations.
  SpringDescription get spring => parent?.spring ?? _kDefaultSpring;

  /// The default accuracy to which scrolling is computed.
  static final Tolerance _kDefaultTolerance = Tolerance(
    velocity: 1.0 / (0.050 * WidgetsBinding.instance.window.devicePixelRatio), // logical pixels per second
    distance: 1.0 / WidgetsBinding.instance.window.devicePixelRatio, // logical pixels
  );

  /// The tolerance to use for ballistic simulations.
  Tolerance get tolerance => parent?.tolerance ?? _kDefaultTolerance;

  /// The minimum distance an input pointer drag must have moved to
  /// to be considered a scroll fling gesture.
  ///
  /// This value is typically compared with the distance traveled along the
  /// scrolling axis.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
  ///    of a press-drag-release gesture.
  double get minFlingDistance => parent?.minFlingDistance ?? kTouchSlop;

  /// The minimum velocity for an input pointer drag to be considered a
  /// scroll fling.
  ///
  /// This value is typically compared with the magnitude of fling gesture's
  /// velocity along the scrolling axis.
  ///
  /// See also:
  ///
  ///  * [VelocityTracker.getVelocityEstimate], which computes the velocity
  ///    of a press-drag-release gesture.
  double get minFlingVelocity => parent?.minFlingVelocity ?? kMinFlingVelocity;

  /// Scroll fling velocity magnitudes will be clamped to this value.
  double get maxFlingVelocity => parent?.maxFlingVelocity ?? kMaxFlingVelocity;

  double carriedMomentum(double existingVelocity) {
    if (parent == null) return 0.0;
    return parent!.carriedMomentum(existingVelocity);
  }

  double? get dragStartDistanceMotionThreshold => parent?.dragStartDistanceMotionThreshold;

  bool get allowImplicitScrolling => true;

  @override
  String toString() {
    if (parent == null) return runtimeType.toString();
    return '$runtimeType -> $parent';
  }
}

class TableClampingScrollPhysics extends TableScrollPhysics {
  /// Creates scroll physics that prevent the scroll offset from exceeding the
  /// bounds of the content..
  const TableClampingScrollPhysics({TableScrollPhysics? parent}) : super(parent: parent);

  @override
  TableClampingScrollPhysics applyTo(TableScrollPhysics? ancestor) {
    return TableClampingScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double applyBoundaryConditions(double value, double pixels, double minScrollExtent, double maxScrollExtent) {
    assert(() {
      if (value == pixels) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('$runtimeType.applyBoundaryConditions() was called redundantly.'),
          ErrorDescription('The proposed new position, $value, is exactly equal to the current position of the '
              'given $pixels.\n'
              'The applyBoundaryConditions method should only be called when the value is '
              'going to actually change the pixels, otherwise it is redundant.'),
          DiagnosticsProperty<TableScrollPhysics>('The physics object in question was', this,
              style: DiagnosticsTreeStyle.errorProperty),
          //DiagnosticsProperty<TableScrollMetrics>('The position object in question was', position, style: DiagnosticsTreeStyle.errorProperty)
        ]);
      }
      return true;
    }());

    if (value < pixels && pixels <= minScrollExtent) // underscroll
      return value - pixels;
    if (maxScrollExtent <= pixels && pixels < value) // overscroll
      return value - pixels;
    if (value < minScrollExtent && minScrollExtent < pixels) // hit top edge
      return value - minScrollExtent;
    if (pixels < maxScrollExtent && maxScrollExtent < value) // hit bottom edge
      return value - maxScrollExtent;
    return 0.0;
  }

  @override
  Simulation createBallisticSimulation(
      double pixels, double minScrollExtent, double maxScrollExtent, bool outOfRange, double velocity) {
    final Tolerance tolerance = this.tolerance;
    if (outOfRange) {
      double? end;
      if (pixels > maxScrollExtent) {
        end = maxScrollExtent;
      } else if (pixels < minScrollExtent) {
        end = minScrollExtent;
      } else {
        assert(end != null,
            'pixels $pixels minScrollExtent $minScrollExtent maxScrollExtent $maxScrollExtent outOfRange $outOfRange');
        return noBallisticSimulation;
      }

      return ScrollSpringSimulation(
        spring,
        pixels,
        end,
        math.min(0.0, velocity),
        tolerance: tolerance,
      );
    }
    if (velocity.abs() < tolerance.velocity) return noBallisticSimulation;
    if (velocity > 0.0 && pixels >= maxScrollExtent) return noBallisticSimulation;
    if (velocity < 0.0 && pixels <= minScrollExtent) return noBallisticSimulation;
    return ClampingScrollSimulation(
      position: pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }
}

final noBallisticSimulation = NoSimulation();
