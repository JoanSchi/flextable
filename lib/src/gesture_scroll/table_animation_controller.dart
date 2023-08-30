// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class TableAnimationController extends Animation<Offset>
    with AnimationEagerListenerMixin, AnimationLocalListenersMixin {
  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;

  Duration? duration;
  Duration? reverseDuration;

  Ticker? _ticker;
  final double lowerBound;
  final double upperBound;
  final String? debugLabel;
  _AnimationDirection _direction;
  double _xValue = 0.0;
  double _yValue = 0.0;
  Simulation? _xSimulation;
  Simulation? _ySimulation;
  bool _xDone = false;
  bool _yDone = false;

  TableAnimationController.unbounded({
    double value = 0.0,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    required TickerProvider vsync,
    //this.animationBehavior = AnimationBehavior.preserve,
  })  : lowerBound = double.negativeInfinity,
        upperBound = double.infinity,
        _direction = _AnimationDirection.forward {
    _ticker = vsync.createTicker(_tick);
    // _internalSetValue_internalSetValue(value);
  }

  TickerFuture animateWith(Simulation xSimulation, Simulation ySimulation) {
    assert(
        _ticker != null,
        'AnimationController.animateWith() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    stop();
    _direction = _AnimationDirection.forward;
    return _startSimulation(xSimulation, ySimulation);
  }

  TickerFuture _startSimulation(
      Simulation xSimulation, Simulation ySimulation) {
    // assert(xSimulation != null && ySimulation != null,
    //     'xSimulation and YSimulation can not be null, use NoSimulation instead');
    assert(!isAnimating);
    _xSimulation = xSimulation;
    _ySimulation = ySimulation;
    _lastElapsedDuration = Duration.zero;

    _xValue = xSimulation.x(0.0).clamp(lowerBound, upperBound);
    _yValue = ySimulation.x(0.0).clamp(lowerBound, upperBound);

    final TickerFuture result = _ticker!.start();
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  // AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    // final newStatus = status;
    // if (_lastReportedStatus != newStatus) {
    //   _lastReportedStatus = newStatus;
    //   notifyStatusListeners(newStatus);
    // }
  }

  @override
  AnimationStatus get status => _status;
  AnimationStatus _status = AnimationStatus.dismissed;

  @override
  Offset get value => Offset(_xValue, _yValue);

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    final double elapsedInSeconds =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);

    if (!_xDone) {
      _xValue = _xSimulation!.x(elapsedInSeconds).clamp(lowerBound, upperBound);
      _xDone = _xSimulation!.isDone(elapsedInSeconds);
    }

    if (!_yDone) {
      _yValue = _ySimulation!.x(elapsedInSeconds).clamp(lowerBound, upperBound);
      _yDone = _ySimulation!.isDone(elapsedInSeconds);
    }

    if (_xDone && _yDone) {
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      stop(canceled: false);
    }
    notifyListeners();
    _checkStatusChanged();
  }

  bool get isXdone => _xDone;

  bool get isYdone => _yDone;

  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('AnimationController.dispose() called more than once.'),
          ErrorDescription(
              'A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<TableAnimationController>(
            'The following $runtimeType object was disposed multiple times',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void stop({bool canceled = true}) {
    assert(
        _ticker != null,
        'AnimationController.stop() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    _xSimulation = null;
    _ySimulation = null;
    _lastElapsedDuration = null;
    _ticker?.stop(canceled: canceled);
  }

  bool get isAnimating => _ticker?.isActive ?? false;

  //  void _internalSetValue(double newValue) {
  //   _value = newValue.clamp(lowerBound, upperBound);
  //   if (_value == lowerBound) {
  //     _status = AnimationStatus.dismissed;
  //   } else if (_value == upperBound) {
  //     _status = AnimationStatus.completed;
  //   } else {
  //     _status = (_direction == _AnimationDirection.forward) ?
  //       AnimationStatus.forward :
  //       AnimationStatus.reverse;
  //   }
  // }

  double get xVelocity {
    if (!isAnimating) return 0.0;
    return _xSimulation!.dx(lastElapsedDuration!.inMicroseconds.toDouble() /
        Duration.microsecondsPerSecond);
  }

  double get yVelocity {
    if (!isAnimating) return 0.0;
    return _ySimulation!.dx(lastElapsedDuration!.inMicroseconds.toDouble() /
        Duration.microsecondsPerSecond);
  }

  @override
  void addStatusListener(listener) {
    throw Exception('Not inplemented at AnimationLocalStatusListenersMixin');
  }

  @override
  void removeStatusListener(listener) {
    throw Exception('Not inplemented at AnimationLocalStatusListenersMixin');
  }

  double get xValue => _xValue;

  double get yValue => _yValue;
}

enum _AnimationDirection {
  forward,
  // ignore: unused_field
  reverse,
}

typedef SetPixels = Function(int scrollIndexX, int scrollIndexY, double value);

class ScrollSimulation {
  Simulation simulation;
  bool isDone = false;
  SetPixels setPixels;
  double delta = 0.0;
  final int scrollIndexX;
  final int scrollIndexY;

  ScrollSimulation({
    required this.scrollIndexX,
    required this.scrollIndexY,
    required this.simulation,
    required this.setPixels,
  });

  apply() {
    setPixels(scrollIndexX, scrollIndexY, delta);
  }
}

class TableMultiAnimationController extends Animation<ScrollSimulation>
    with AnimationEagerListenerMixin, AnimationLocalListenersMixin {
  TableMultiAnimationController.unbounded({
    double value = 0.0,
    this.duration,
    this.reverseDuration,
    this.debugLabel,
    required TickerProvider vsync,
    //this.animationBehavior = AnimationBehavior.preserve,
  })  : lowerBound = double.negativeInfinity,
        upperBound = double.infinity,
        _direction = _AnimationDirection.forward {
    _ticker = vsync.createTicker(_tick);
    // _internalSetValue_internalSetValue(value);
  }

  Duration? get lastElapsedDuration => _lastElapsedDuration;
  Duration? _lastElapsedDuration;
  Duration? duration;
  Duration? reverseDuration;
  Ticker? _ticker;
  final double lowerBound;
  final double upperBound;
  final String? debugLabel;
  _AnimationDirection _direction;
  late List<ScrollSimulation> _list = List.empty();
  int _count = 0;
  bool _scrolling = true;

  TickerFuture animateWith(List<ScrollSimulation> list) {
    assert(
        _ticker != null,
        'AnimationController.animateWith() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    stop();
    _direction = _AnimationDirection.forward;
    return _startSimulation(list);
  }

  TickerFuture _startSimulation(List<ScrollSimulation> list) {
    assert(_scrolling);
    _list = list;
    _count = list.length;

    _lastElapsedDuration = Duration.zero;

    for (var element in _list) {
      element.simulation.x(0.0).clamp(lowerBound, upperBound);
    }

    final TickerFuture result = _ticker!.start();
    _status = (_direction == _AnimationDirection.forward)
        ? AnimationStatus.forward
        : AnimationStatus.reverse;
    _checkStatusChanged();
    return result;
  }

  // AnimationStatus _lastReportedStatus = AnimationStatus.dismissed;
  void _checkStatusChanged() {
    // final newStatus = status;
    // if (_lastReportedStatus != newStatus) {
    //   _lastReportedStatus = newStatus;
    //   notifyStatusListeners(newStatus);
    // }
  }

  @override
  AnimationStatus get status => _status;
  AnimationStatus _status = AnimationStatus.dismissed;

  late ScrollSimulation _element;

  reset() {
    _count = 0;
  }

  bool next() {
    if (_count < _list.length) {
      _element = _list[_count];
      _count++;
      return (_element.isDone) ? next() : true;
    }
    return false;
  }

  @override
  ScrollSimulation get value => _element;

  void _tick(Duration elapsed) {
    _lastElapsedDuration = elapsed;
    final double elapsedInSeconds =
        elapsed.inMicroseconds.toDouble() / Duration.microsecondsPerSecond;
    assert(elapsedInSeconds >= 0.0);

    // _list.where((element) => !element.isDone).forEach((element) {
    //   element.simulation.x(elapsedInSeconds).clamp(lowerBound, upperBound);
    //   element.isDone = element.simulation.isDone(elapsedInSeconds);
    // });

    _scrolling = false;

    reset();

    while (next()) {
      _element.delta =
          _element.simulation.x(elapsedInSeconds).clamp(lowerBound, upperBound);
      final isDone = _element.simulation.isDone(elapsedInSeconds);

      if (!isDone) {
        _scrolling = true;
      }
      _element.isDone = isDone;
    }

    if (!_scrolling) {
      _status = (_direction == _AnimationDirection.forward)
          ? AnimationStatus.completed
          : AnimationStatus.dismissed;
      stop(canceled: false);
    }
    notifyListeners();
    _checkStatusChanged();
  }

  bool get isScrolling => _scrolling;

  @override
  void dispose() {
    assert(() {
      if (_ticker == null) {
        throw FlutterError.fromParts(<DiagnosticsNode>[
          ErrorSummary('AnimationController.dispose() called more than once.'),
          ErrorDescription(
              'A given $runtimeType cannot be disposed more than once.\n'),
          DiagnosticsProperty<TableMultiAnimationController>(
            'The following $runtimeType object was disposed multiple times',
            this,
            style: DiagnosticsTreeStyle.errorProperty,
          ),
        ]);
      }
      return true;
    }());
    _ticker?.dispose();
    _ticker = null;
    super.dispose();
  }

  void stop({bool canceled = true}) {
    assert(
        _ticker != null,
        'AnimationController.stop() called after AnimationController.dispose()\n'
        'AnimationController methods should not be used after calling dispose.');
    //_list = List.empty();
    _lastElapsedDuration = null;
    _ticker?.stop(canceled: canceled);
  }

  bool get isAnimating => _ticker?.isActive ?? false;

  //  void _internalSetValue(double newValue) {
  //   _value = newValue.clamp(lowerBound, upperBound);
  //   if (_value == lowerBound) {
  //     _status = AnimationStatus.dismissed;
  //   } else if (_value == upperBound) {
  //     _status = AnimationStatus.completed;
  //   } else {
  //     _status = (_direction == _AnimationDirection.forward) ?
  //       AnimationStatus.forward :
  //       AnimationStatus.reverse;
  //   }
  // }

  // double get xVelocity {
  //   if (!isAnimating) return 0.0;
  //   return _xSimulation!.dx(lastElapsedDuration!.inMicroseconds.toDouble() / Duration.microsecondsPerSecond);
  // }

  // double get yVelocity {
  //   if (!isAnimating) return 0.0;
  //   return _ySimulation!.dx(lastElapsedDuration!.inMicroseconds.toDouble() / Duration.microsecondsPerSecond);
  // }

  @override
  void addStatusListener(listener) {
    throw Exception('Not inplemented at AnimationLocalStatusListenersMixin');
  }

  @override
  void removeStatusListener(listener) {
    throw Exception('Not inplemented at AnimationLocalStatusListenersMixin');
  }
}
