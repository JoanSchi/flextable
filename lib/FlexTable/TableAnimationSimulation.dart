import 'dart:math' as math;
import 'package:flutter/physics.dart';

abstract class TableSimulation {
  /// Initializes the [tolerance] field for subclasses.
  TableSimulation({this.tolerance = Tolerance.defaultTolerance});

  /// The position of the object in the simulation at the given time.
  double x(double time);

  /// The velocity of the object in the simulation at the given time.
  double dx(double time);

  /// The position of the object in the simulation at the given time.
  double y(double time);

  /// The velocity of the object in the simulation at the given time.
  double dy(double time);

  /// Whether the simulation is "done" at the given time.
  bool isDone(double time);

  /// How close to the actual end of the simulation a value at a particular time
  /// must be before [isDone] considers the simulation to be "done".
  ///
  /// A simulation with an asymptotic curve would never technically be "done",
  /// but once the difference from the value at a particular time and the
  /// asymptote itself could not be seen, it would be pointless to continue. The
  /// tolerance defines how to determine if the difference could not be seen.
  Tolerance tolerance;

  @override
  String toString() => '$runtimeType';
}

class TableClampingScrollSimulation extends TableSimulation {
  /// Creates a scroll physics simulation that matches Android scrolling.
  TableClampingScrollSimulation({
    required this.xPosition,
    required this.yPosition,
    required this.xVelocity,
    required this.yVelocity,
    double xyVelocity = 0.0,
    this.friction = 0.015,
    Tolerance tolerance = Tolerance.defaultTolerance,
  })  : assert(_flingVelocityPenetration(0.0) == _initialVelocityPenetration),
        super(tolerance: tolerance) {
    _duration = _flingDuration(xyVelocity);
    _distanceX = (xVelocity * _duration / _initialVelocityPenetration).abs();
    _distanceY = (yVelocity * _duration / _initialVelocityPenetration).abs();
  }

  /// The position of the particle at the beginning of the simulation.
  final double xPosition;
  final double yPosition;

  /// The velocity at which the particle is traveling at the beginning of the
  /// simulation.
  final double xVelocity;
  final double yVelocity;

  /// The amount of friction the particle experiences as it travels.
  ///
  /// The more friction the particle experiences, the sooner it stops.
  final double friction;

  late double _duration;
  late double _distanceX;
  late double _distanceY;

  // See DECELERATION_RATE.
  static final double _kDecelerationRate = math.log(0.78) / math.log(0.9);

  // See computeDeceleration().
  static double _decelerationForFriction(double friction) {
    return friction * 61774.04968;
  }

  // See getSplineFlingDuration(). Returns a value in seconds.
  double _flingDuration(double velocity) {
    // See mPhysicalCoeff
    final double scaledFriction = friction * _decelerationForFriction(0.84);

    // See getSplineDeceleration().
    final double deceleration = math.log(0.35 * velocity.abs() / scaledFriction);

    return math.exp(deceleration / (_kDecelerationRate - 1.0));
  }

  // Based on a cubic curve fit to the Scroller.computeScrollOffset() values
  // produced for an initial velocity of 4000. The value of Scroller.getDuration()
  // and Scroller.getFinalY() were 686ms and 961 pixels respectively.
  //
  // Algebra courtesy of Wolfram Alpha.
  //
  // f(x) = scrollOffset, x is time in milliseconds
  // f(x) = 3.60882×10^-6 x^3 - 0.00668009 x^2 + 4.29427 x - 3.15307
  // f(x) = 3.60882×10^-6 x^3 - 0.00668009 x^2 + 4.29427 x, so f(0) is 0
  // f(686ms) = 961 pixels
  // Scale to f(0 <= t <= 1.0), x = t * 686
  // f(t) = 1165.03 t^3 - 3143.62 t^2 + 2945.87 t
  // Scale f(t) so that 0.0 <= f(t) <= 1.0
  // f(t) = (1165.03 t^3 - 3143.62 t^2 + 2945.87 t) / 961.0
  //      = 1.2 t^3 - 3.27 t^2 + 3.065 t
  static const double _initialVelocityPenetration = 3.065;
  static double _flingDistancePenetration(double t) {
    return (1.2 * t * t * t) - (3.27 * t * t) + (_initialVelocityPenetration * t);
  }

  // The derivative of the _flingDistancePenetration() function.
  static double _flingVelocityPenetration(double t) {
    return (3.6 * t * t) - (6.54 * t) + _initialVelocityPenetration;
  }

  @override
  double x(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return xPosition + _distanceX * _flingDistancePenetration(t) * xVelocity.sign;
  }

  @override
  double dx(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return _distanceX * _flingVelocityPenetration(t) * xVelocity.sign / _duration;
  }

  @override
  bool isDone(double time) {
    return time >= _duration;
  }

  @override
  double y(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return yPosition + _distanceY * _flingDistancePenetration(t) * yVelocity.sign;
  }

  @override
  double dy(double time) {
    final double t = (time / _duration).clamp(0.0, 1.0);
    return _distanceY * _flingVelocityPenetration(t) * yVelocity.sign / _duration;
  }
}

class NoSimulation extends Simulation {
  final double position;

  NoSimulation({this.position = 0.0});

  @override
  double dx(double time) {
    return 0.0;
  }

  @override
  bool isDone(double time) {
    return true;
  }

  @override
  double x(double time) {
    return position;
  }
}
