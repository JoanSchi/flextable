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

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;
import 'dart:ui';
import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'combi_key.dart';
import '../../gesture_scroll/table_drag_details.dart';
import '../../gesture_scroll/table_gesture.dart';
import '../../gesture_scroll/table_scale_gesture.dart';

class TableZoomProperties {
  double lineWidth;
  Color lineColor;
  double pointerSize;
  double centerSize;
  Color pointerColor;
  Color pointerColorActive;
  double fraction;

  TableZoomProperties({
    this.lineWidth = 1.0,
    this.lineColor = Colors.black38,
    this.pointerSize = 48.0,
    this.centerSize = 12.0,
    this.pointerColor = Colors.black38,
    this.pointerColorActive = Colors.black38,
    this.fraction = 0.25,
  });
}

class TableZoomTouch extends StatefulWidget {
  final FlexTableViewModel flexTableViewModel;

  const TableZoomTouch({Key? key, required this.flexTableViewModel})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => TableZoomTouchState();
}

class TableZoomTouchState extends State<TableZoomTouch> {
  double zoom = 1.0;
  DeviceGestureSettings? _mediaQueryGestureSettings;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TableZoomTouch oldWidget) {
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
    zoom = widget.flexTableViewModel.tableScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails scaleUpdateDetails) {
    widget.flexTableViewModel.setScaleTable(scaleUpdateDetails.scale * zoom);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.flexTableViewModel.correctOffScroll(0, 0);
    // _tableModel.notifyScrollBarListeners();
  }
}

class TableZoomMouse extends StatefulWidget {
  final FlexTableViewModel flexTableViewModel;
  final TableZoomProperties zoomProperties;
  final CombiKeyNotification combiKeyNotification;

  const TableZoomMouse(
      {Key? key,
      required this.flexTableViewModel,
      required this.zoomProperties,
      required this.combiKeyNotification})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => TableZoomMouseState();
}

class TableZoomMouseState extends State<TableZoomMouse> {
  double zoom = 1.0;
  late TableZoomMouseNotifier _tableZoomMouseNotifier;
  late TableZoomProperties _zoomProperties;
  late CombiKeyNotification _combiKeyNotification;

  @override
  void initState() {
    final ftm = widget.flexTableViewModel.ftm;
    _tableZoomMouseNotifier = TableZoomMouseNotifier(
        minTableScale: ftm.minTableScale, maxTableScale: ftm.maxTableScale);
    _zoomProperties = widget.zoomProperties;
    _combiKeyNotification = widget.combiKeyNotification..addListener(keyUpdate);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableZoomMouse oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.zoomProperties != _zoomProperties) {
      _zoomProperties = widget.zoomProperties;
    }
    if (widget.combiKeyNotification != _combiKeyNotification) {
      _combiKeyNotification.removeListener(keyUpdate);
      _combiKeyNotification = widget.combiKeyNotification
        ..addListener(keyUpdate);
    }
  }

  keyUpdate() {
    _tableZoomMouseNotifier.active = _combiKeyNotification.control;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onHover: onHover,
      child: RawGestureDetector(
          gestures: <Type, GestureRecognizerFactory>{
            TableZoomGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                TableZoomGestureRecognizer>(
              () => TableZoomGestureRecognizer(),
              (TableZoomGestureRecognizer instance) {
                instance
                  ..onStart = onStart
                  ..onUpdate = onUpdate
                  ..onEnd = onEnd
                  ..tableZoomMouseNotifier = _tableZoomMouseNotifier
                  ..dragDirection = TableScrollDirection.both;
              },
            ),
          },
          behavior: HitTestBehavior.translucent,
          child: MouseScalePaint(
            zoomProperties: _zoomProperties,
            tableZoomMouseNotifier: _tableZoomMouseNotifier,
            child: Container(),
          )),
    );
  }

  onStart(DragStartDetails details) {
    _tableZoomMouseNotifier
      ..isScaling = true
      ..scale = widget.flexTableViewModel.tableScale;
  }

  onHover(PointerHoverEvent event) {
    _tableZoomMouseNotifier
      ..scale = widget.flexTableViewModel.tableScale
      ..position = event.localPosition;
    _tableZoomMouseNotifier.active = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.controlLeft);
  }

  onUpdate(TableDragUpdateDetails details) {
    _tableZoomMouseNotifier.position = details.localPosition;
    widget.flexTableViewModel.setScaleTable(_tableZoomMouseNotifier.scale);
  }

  onEnd(TableDragEndDetails details) {
    _tableZoomMouseNotifier.isScaling = false;

    _tableZoomMouseNotifier.active = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.controlLeft);

    widget.flexTableViewModel.correctOffScroll(0, 0);
    // _tableModel.notifyScrollBarListeners();
  }
}

class TableZoomGestureRecognizer extends MyDragGestureRecognizer {
  TableZoomMouseNotifier? tableZoomMouseNotifier;
  TableZoomGestureRecognizer({
    Object? debugOwner,
    Set<PointerDeviceKind>? supportedDevices,
  }) : super(
          debugOwner: debugOwner,
          supportedDevices: supportedDevices,
        );

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
      tableZoomMouseNotifier?.active ?? false;
}

class TableZoomMouseNotifier extends ChangeNotifier {
  bool _active = false;
  bool _isScaling = false;
  double _scale = 0.0;
  double minTableScale;
  double maxTableScale;
  Offset startPosition = Offset.zero;
  Offset _position = Offset.zero;
  double distanceRatio = 0.0;

  TableZoomMouseNotifier(
      {required this.minTableScale, required this.maxTableScale});

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
  final TableZoomMouseNotifier tableZoomMouseNotifier;
  final Widget child;
  final TableZoomProperties zoomProperties;

  const MouseScalePaint(
      {Key? key,
      required this.tableZoomMouseNotifier,
      required this.child,
      required this.zoomProperties})
      : super(key: key);

  @override
  State<MouseScalePaint> createState() => _MouseScalePaintState();
}

class _MouseScalePaintState extends State<MouseScalePaint> {
  late TableZoomMouseNotifier tableZoomMouseNotifier;

  @override
  void initState() {
    tableZoomMouseNotifier = widget.tableZoomMouseNotifier..addListener(notify);
    super.initState();
  }

  @override
  void didUpdateWidget(MouseScalePaint oldWidget) {
    if (tableZoomMouseNotifier != widget.tableZoomMouseNotifier) {
      tableZoomMouseNotifier.removeListener(notify);
      tableZoomMouseNotifier = widget.tableZoomMouseNotifier
        ..addListener(notify);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  dispose() {
    tableZoomMouseNotifier.removeListener(notify);
    super.dispose();
  }

  notify() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        painter: MouseZoomPainter(
            position: tableZoomMouseNotifier.position,
            startPostion: tableZoomMouseNotifier.startPosition,
            draw: tableZoomMouseNotifier.draw,
            zoomProperties: widget.zoomProperties,
            minDistance: tableZoomMouseNotifier.minDistance,
            maxDistance: tableZoomMouseNotifier.maxDistance),
        child: widget.child);
  }
}

class MouseZoomPainter extends CustomPainter {
  final Offset position;
  final Offset startPostion;
  final bool draw;
  final double minDistance;
  final double maxDistance;
  TableZoomProperties zoomProperties;

  MouseZoomPainter({
    required this.position,
    required this.startPostion,
    required this.draw,
    required this.zoomProperties,
    required this.minDistance,
    required this.maxDistance,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!draw) return;
    final delta = position - startPostion;
    final r = math.atan2(delta.dy, delta.dx);

    final paint = Paint();

    line(double radial, double d) {
      canvas.drawArc(
          startPostion - Offset(d, d) & Size(d * 2.0, d * 2.0),
          r - zoomProperties.fraction / 2.0 * math.pi + radial,
          zoomProperties.fraction * math.pi,
          false,
          paint
            ..color = zoomProperties.lineColor
            ..style = PaintingStyle.stroke);
    }

    line(0.0, minDistance);
    line(math.pi, minDistance);
    line(0.0, maxDistance);
    line(math.pi, maxDistance);

    canvas.drawCircle(
        startPostion,
        zoomProperties.centerSize / 2.0,
        paint
          ..color = zoomProperties.lineColor
          ..style = PaintingStyle.fill);

    canvas.drawCircle(
        position,
        zoomProperties.pointerSize / 2.0,
        paint
          ..color = zoomProperties.pointerColor
          ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
