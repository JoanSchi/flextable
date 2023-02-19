// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'combi_key.dart';
import 'table_scroll.dart';
import 'table_drag_details.dart';
import 'table_gesture.dart';
import 'table_model.dart';
import 'table_scale_gesture.dart';

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
  final TableModel tableModel;
  final TableScrollPosition tableScrollPosition;

  TableZoomTouch(
      {Key? key, required this.tableModel, required this.tableScrollPosition})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => TableZoomTouchState();
}

class TableZoomTouchState extends State<TableZoomTouch> {
  double zoom = 1.0;
  late TableModel _tableModel;

  @override
  void initState() {
    _tableModel = widget.tableModel;
    super.initState();
  }

  @override
  void didUpdateWidget(TableZoomTouch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tableModel != _tableModel) _tableModel = widget.tableModel;
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
              ..onEnd = _onScaleEnd;
          },
        ),
      },
      behavior: HitTestBehavior.translucent,
      child: Container(),
    );
  }

  void _onScaleStart(ScaleStartDetails scaleStartDetails) {
    zoom = widget.tableModel.tableScale;
  }

  void _onScaleUpdate(ScaleUpdateDetails scaleUpdateDetails) {
    if (_tableModel.setScaleTable(scaleUpdateDetails.scale * zoom)) {
      _tableModel.notifyListeners();
      _tableModel.notifyTableScaleListeners(_tableModel.tableScale);
      _tableModel.notifyScrollBarListeners();
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.tableScrollPosition.correctOffScroll(0, 0);
    _tableModel.notifyScrollBarListeners();
  }
}

class TableZoomMouse extends StatefulWidget {
  final TableModel tableModel;
  final TableScrollPosition tableScrollPosition;
  final TableZoomProperties zoomProperties;
  final CombiKeyNotification combiKeyNotification;

  TableZoomMouse(
      {Key? key,
      required this.tableModel,
      required this.tableScrollPosition,
      required this.zoomProperties,
      required this.combiKeyNotification})
      : super(key: key);
  @override
  State<StatefulWidget> createState() => TableZoomMouseState();
}

class TableZoomMouseState extends State<TableZoomMouse> {
  double zoom = 1.0;
  late TableModel _tableModel = widget.tableModel;
  late TableZoomMouseNotifier _tableZoomMouseNotifier;
  late TableZoomProperties _zoomProperties;
  late CombiKeyNotification _combiKeyNotification;

  @override
  void initState() {
    _tableZoomMouseNotifier = TableZoomMouseNotifier(
        minTableScale: _tableModel.minTableScale,
        maxTableScale: _tableModel.maxTableScale);
    _zoomProperties = widget.zoomProperties;
    _combiKeyNotification = widget.combiKeyNotification..addListener(keyUpdate);
    super.initState();
  }

  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableZoomMouse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tableModel != _tableModel) _tableModel = widget.tableModel;
    if (widget.zoomProperties != _zoomProperties)
      _zoomProperties = widget.zoomProperties;
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
                  ..tableZoomMouseNotifier = _tableZoomMouseNotifier;
              },
            ),
          },
          behavior: HitTestBehavior.translucent,
          child: MouseScalePaint(
            zoomProperties: _zoomProperties,
            child: Container(),
            tableZoomMouseNotifier: _tableZoomMouseNotifier,
          )),
    );
  }

  onStart(DragStartDetails details) {
    _tableZoomMouseNotifier
      ..isScaling = true
      ..scale = _tableModel.tableScale;
  }

  onHover(PointerHoverEvent event) {
    _tableZoomMouseNotifier
      ..scale = _tableModel.tableScale
      ..position = event.localPosition;
    _tableZoomMouseNotifier.active = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.controlLeft);
  }

  onUpdate(TableDragUpdateDetails details) {
    _tableZoomMouseNotifier.position = details.localPosition;

    // if (!_tableZoomMouseNotifier.active) return;

    final scale = _tableZoomMouseNotifier.scale;

    if (_tableModel.setScaleTable(scale)) {
      _tableModel.notifyListeners();
      _tableModel.notifyTableScaleListeners(_tableModel.tableScale);
      _tableModel.notifyScrollBarListeners();
    }
  }

  onEnd(TableDragEndDetails details) {
    _tableZoomMouseNotifier.isScaling = false;

    _tableZoomMouseNotifier.active = RawKeyboard.instance.keysPressed
        .contains(LogicalKeyboardKey.controlLeft);

    widget.tableScrollPosition.correctOffScroll(0, 0);
    _tableModel.notifyScrollBarListeners();
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

  TableScrollDirection dragDirection = TableScrollDirection.both;

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
    print('active ${tableZoomMouseNotifier.active}');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
        child: widget.child,
        painter: MouseZoomPainter(
            position: tableZoomMouseNotifier.position,
            startPostion: tableZoomMouseNotifier.startPosition,
            draw: tableZoomMouseNotifier.draw,
            zoomProperties: widget.zoomProperties,
            minDistance: tableZoomMouseNotifier.minDistance,
            maxDistance: tableZoomMouseNotifier.maxDistance));
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
