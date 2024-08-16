// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'dart:ui';
import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../../gesture_scroll/table_gesture.dart';
import '../../gesture_scroll/table_scale_gesture.dart';

class TableMouseScaleProperties {
  TableMouseScaleProperties({
    this.lineWidth = 1.0,
    this.lineColor = Colors.black38,
    this.pointerSize = 48.0,
    this.centerSize = 12.0,
    this.pointerColor = Colors.black38,
    this.pointerColorActive = Colors.black38,
    this.fraction = 0.25,
  });

  double lineWidth;
  Color lineColor;
  double pointerSize;
  double centerSize;
  Color pointerColor;
  Color pointerColorActive;
  double fraction;
}

class TableScaleTouch extends StatefulWidget {
  const TableScaleTouch({super.key, required this.viewModel});

  final FtViewModel viewModel;

  @override
  State<StatefulWidget> createState() => TableScaleTouchState();
}

class TableScaleTouchState extends State<TableScaleTouch> {
  double tableScale = 1.0;
  DeviceGestureSettings? _mediaQueryGestureSettings;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _mediaQueryGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableScaleTouch oldWidget) {
    _mediaQueryGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: <Type, GestureRecognizerFactory>{
        TableScaleGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TableScaleGestureRecognizer>(
          () => TableScaleGestureRecognizer(),
          (TableScaleGestureRecognizer instance) {
            instance
              ..onStart = _onScaleStart
              ..onUpdate = _onScaleUpdate
              ..onEnd = _onScaleEnd
              ..gestureSettings = _mediaQueryGestureSettings;
          },
        ),
      },
      behavior: HitTestBehavior.translucent,
      child: Container(),
    );
  }

  void _onScaleStart(ScaleStartDetails scaleStartDetails) {
    tableScale = widget.viewModel.tableScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails scaleUpdateDetails) {
    widget.viewModel.scaleChangeNotifier
        .changeScale(scaleValue: scaleUpdateDetails.scale * tableScale);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.viewModel.scaleChangeNotifier.changeScale(scaleEnd: true);

    // _tableModel.notifyScrollBarListeners();
  }
}

// TODO Reimplement TableScaleMouse

// class TableScaleMouse extends StatefulWidget {
//   const TableScaleMouse(
//       {super.key,
//       required this.viewModel,
//       required this.properties,
//       required this.combiKeyNotification});

//   final FtViewModel viewModel;
//   final TableMouseScaleProperties properties;
//   final CombiKeyNotification combiKeyNotification;

//   @override
//   State<StatefulWidget> createState() => TableScaleMouseState();
// }

// class TableScaleMouseState extends State<TableScaleMouse> {
//   late TableScaleMouseNotifier _tableScaleMouseNotifier;
//   late TableMouseScaleProperties _properties;
//   late CombiKeyNotification _combiKeyNotification;

//   @override
//   void initState() {
//     final ftProperties = widget.viewModel.properties;
//     _tableScaleMouseNotifier = TableScaleMouseNotifier(
//         minTableScale: ftProperties.minTableScale,
//         maxTableScale: ftProperties.maxTableScale);
//     _properties = widget.properties;
//     _combiKeyNotification = widget.combiKeyNotification..addListener(keyUpdate);
//     super.initState();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//   }

//   @override
//   void didUpdateWidget(TableScaleMouse oldWidget) {
//     super.didUpdateWidget(oldWidget);

//     if (widget.properties != _properties) {
//       _properties = widget.properties;
//     }
//     if (widget.combiKeyNotification != _combiKeyNotification) {
//       _combiKeyNotification.removeListener(keyUpdate);
//       _combiKeyNotification = widget.combiKeyNotification
//         ..addListener(keyUpdate);
//     }
//   }

//   keyUpdate() {
//     _tableScaleMouseNotifier.active = _combiKeyNotification.control;
//   }

//   @override
//   void dispose() {
//     _combiKeyNotification.removeListener(keyUpdate);
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MouseRegion(
//       onHover: onHover,
//       child: RawGestureDetector(
//           gestures: <Type, GestureRecognizerFactory>{
//             TableScaleMouseGestureRecognizer:
//                 GestureRecognizerFactoryWithHandlers<
//                     TableScaleMouseGestureRecognizer>(
//               () => TableScaleMouseGestureRecognizer(),
//               (TableScaleMouseGestureRecognizer instance) {
//                 instance
//                   ..onStart = onStart
//                   ..onUpdate = onUpdate
//                   ..onEnd = onEnd
//                   ..tableScaleMouseNotifier = _tableScaleMouseNotifier
//                   ..dragDirection = TableScrollDirection.both;
//               },
//             ),
//           },
//           behavior: HitTestBehavior.translucent,
//           child: MouseScalePaint(
//             properties: _properties,
//             tableScaleMouseNotifier: _tableScaleMouseNotifier,
//             child: Container(),
//           )),
//     );
//   }

//   onStart(DragStartDetails details) {
//     _tableScaleMouseNotifier
//       ..isScaling = true
//       ..scale = widget.viewModel.tableScale;
//   }

//   onHover(PointerHoverEvent event) {
//     _tableScaleMouseNotifier
//       ..scale = widget.viewModel.tableScale
//       ..position = event.localPosition;
//     _tableScaleMouseNotifier.active = RawKeyboard.instance.keysPressed
//         .contains(LogicalKeyboardKey.controlLeft);
//   }

//   onUpdate(TableDragUpdateDetails details) {
//     _tableScaleMouseNotifier.position = details.localPosition;
//     widget.viewModel
//         .setTableScale(_tableScaleMouseNotifier.scale, unfocus: false);
//   }

//   onEnd(TableDragEndDetails details) {
//     _tableScaleMouseNotifier.isScaling = false;

//     _tableScaleMouseNotifier.active = RawKeyboard.instance.keysPressed
//         .contains(LogicalKeyboardKey.controlLeft);

//     widget.viewModel.correctOffScroll(0, 0);
//     // _tableModel.notifyScrollBarListeners();
//   }
// }

class TableScaleMouseGestureRecognizer extends MyDragGestureRecognizer {
  TableScaleMouseNotifier? tableScaleMouseNotifier;
  TableScaleMouseGestureRecognizer({
    super.debugOwner,
    super.supportedDevices,
  });

  @override
  bool isFlingGesture(VelocityEstimate estimate, PointerDeviceKind kind) =>
      false;

  @override
  String get debugDescription => 'both drag';

  @override
  Offset getDeltaForDetails(Offset delta) => delta;

  @override
  double? getPrimaryValueFromOffset(Offset value) => value.dy;

  @override
  Velocity getPrimaryVelocity(Velocity value) =>
      Velocity(pixelsPerSecond: value.pixelsPerSecond);

  @override
  bool hasSufficientGlobalDistanceToAccept(
          PointerDeviceKind pointerDeviceKind) =>
      tableScaleMouseNotifier?.active ?? false;
}

class TableScaleMouseNotifier extends ChangeNotifier {
  TableScaleMouseNotifier(
      {required this.minTableScale, required this.maxTableScale});

  bool _active = false;
  bool _isScaling = false;
  double _scale = 0.0;
  double minTableScale;
  double maxTableScale;
  Offset startPosition = Offset.zero;
  Offset _position = Offset.zero;
  double distanceRatio = 0.0;

  set position(Offset value) {
    _position = value;

    if (!(_active || _isScaling)) {
      startPosition = value;
    }

    if (!_isScaling) {
      distanceRatio = _scale / delta.distance;
    }

    if (_active || _isScaling) {
      notifyListeners();
    }
  }

  Offset get delta => _position - startPosition;

  Offset get position => _position;

  set active(bool value) {
    final oldActive = _active || _isScaling;

    _active = value;

    if (oldActive != _active || _isScaling) {
      notifyListeners();
    }
  }

  bool get visible => _active && distanceRatio > 0.0;

  bool get active => _active;

  set isScaling(bool value) {
    final oldDraw = _active || _isScaling;

    _isScaling = value;

    if (oldDraw != _active || _isScaling) {
      notifyListeners();
    }
  }

  set scale(double value) {
    if (value != _scale) {
      _scale = value;
      distanceRatio = value / delta.distance;
    }
  }

  double get scale => delta.distance * distanceRatio;

  bool get isScaling => _isScaling;

  bool get draw => _active || _isScaling;

  notify() {
    notifyListeners();
  }

  double get minDistance => minTableScale / distanceRatio;

  double get maxDistance => maxTableScale / distanceRatio;
}

class MouseScalePaint extends StatefulWidget {
  const MouseScalePaint(
      {super.key,
      required this.tableScaleMouseNotifier,
      required this.child,
      required this.properties});

  final TableScaleMouseNotifier tableScaleMouseNotifier;
  final Widget child;
  final TableMouseScaleProperties properties;

  @override
  State<MouseScalePaint> createState() => _MouseScalePaintState();
}

class _MouseScalePaintState extends State<MouseScalePaint> {
  late TableScaleMouseNotifier tableScaleMouseNotifier;

  @override
  void initState() {
    tableScaleMouseNotifier = widget.tableScaleMouseNotifier
      ..addListener(notify);
    super.initState();
  }

  @override
  void didUpdateWidget(MouseScalePaint oldWidget) {
    if (tableScaleMouseNotifier != widget.tableScaleMouseNotifier) {
      tableScaleMouseNotifier.removeListener(notify);
      tableScaleMouseNotifier = widget.tableScaleMouseNotifier
        ..addListener(notify);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  dispose() {
    tableScaleMouseNotifier.removeListener(notify);
    super.dispose();
  }

  notify() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: MouseScalePainter(
            position: tableScaleMouseNotifier.position,
            startPostion: tableScaleMouseNotifier.startPosition,
            draw: tableScaleMouseNotifier.draw,
            properties: widget.properties,
            minDistance: tableScaleMouseNotifier.minDistance,
            maxDistance: tableScaleMouseNotifier.maxDistance),
        child: widget.child);
  }
}

class MouseScalePainter extends CustomPainter {
  MouseScalePainter({
    required this.position,
    required this.startPostion,
    required this.draw,
    required this.properties,
    required this.minDistance,
    required this.maxDistance,
  });

  final Offset position;
  final Offset startPostion;
  final bool draw;
  final double minDistance;
  final double maxDistance;
  final TableMouseScaleProperties properties;

  @override
  void paint(Canvas canvas, Size size) {
    if (!draw) return;
    final delta = position - startPostion;
    final r = math.atan2(delta.dy, delta.dx);

    final paint = Paint();

    line(double radial, double d) {
      canvas.drawArc(
          startPostion - Offset(d, d) & Size(d * 2.0, d * 2.0),
          r - properties.fraction / 2.0 * math.pi + radial,
          properties.fraction * math.pi,
          false,
          paint
            ..color = properties.lineColor
            ..style = PaintingStyle.stroke);
    }

    line(0.0, minDistance);
    line(math.pi, minDistance);
    line(0.0, maxDistance);
    line(math.pi, maxDistance);

    canvas.drawCircle(
        startPostion,
        properties.centerSize / 2.0,
        paint
          ..color = properties.lineColor
          ..style = PaintingStyle.fill);

    canvas.drawCircle(
        position,
        properties.pointerSize / 2.0,
        paint
          ..color = properties.pointerColor
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
