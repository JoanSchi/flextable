// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'table_model.dart';
import 'table_scroll.dart';

class TableFreeze extends StatefulWidget {
  final TableScrollPosition tableScrollPosition;
  final TableModel tableModel;
  final FreezePositionProperties freezePositionProperties;

  const TableFreeze({
    Key? key,
    required this.tableModel,
    required this.tableScrollPosition,
    required this.freezePositionProperties,
  }) : super(key: key);

  @override
  State<TableFreeze> createState() => _TableFreezeState();
}

class _TableFreezeState extends State<TableFreeze>
    with SingleTickerProviderStateMixin {
  late FreezePosition _freezePosition;

  @override
  void initState() {
    _freezePosition = FreezePosition(
      vsync: this,
      tableModel: widget.tableModel,
      freezePositionProperties: widget.freezePositionProperties,
      tableScrollPosition: widget.tableScrollPosition,
    );
    super.initState();
  }

  @override
  void didUpdateWidget(TableFreeze oldWidget) {
    super.didUpdateWidget(oldWidget);

    _freezePosition
      ..tableScrollPosition = widget.tableScrollPosition
      ..tableModel = widget.tableModel
      ..freezePositionProperties = widget.freezePositionProperties;
  }

  @override
  void dispose() {
    _freezePosition.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (LongPressStartDetails details) =>
          {_freezePosition.position = details.localPosition},
      onLongPress: () => _freezePosition.changeFreeze(),
      child: FreezePanel(
        position: _freezePosition,
      ),
    );
  }
}

class FreezePositionProperties {
  final bool useFreezePosition;
  final double freezeSlope;

  const FreezePositionProperties({
    this.useFreezePosition: true,
    this.freezeSlope: 32.0,
  });
}

class FreezePosition extends ChangeNotifier {
  TickerProvider vsync;
  TableModel _tableModel;
  FreezeChange freezeChange = FreezeChange();
  late AnimationController _controller;
  FreezePositionProperties freezePositionProperties;
  TableScrollPosition tableScrollPosition;
  Offset position = Offset.zero;

  double get animationValue {
    switch (freezeChange.action) {
      case FreezeAction.FREEZE:
        {
          return _controller.value;
        }
      case FreezeAction.UNFREEZE:
        {
          return (1.0 - _controller.value);
        }
      case FreezeAction.NOACTION:
        {
          return 0.0;
        }
      default:
        {
          return 0.0;
        }
    }
  }

  FreezePosition(
      {required this.vsync,
      required TableModel tableModel,
      required this.freezePositionProperties,
      required this.tableScrollPosition})
      : _tableModel = tableModel {
    _controller =
        AnimationController(vsync: vsync, duration: Duration(milliseconds: 200))
          ..addListener(() {
            notifyListeners();
          })
          ..addStatusListener(statusListener);
  }

  void statusListener(status) {
    if (status == AnimationStatus.completed) {
      _tableModel.freezeByPosition(freezeChange);

      if (freezeChange.action == FreezeAction.UNFREEZE) {
        tableModel.scheduleCorrectOffScroll = true;
      }
      tableModel.notifyListeners();

      freezeChange = FreezeChange();
    }
    notifyListeners();
  }

  TableModel get tableModel => _tableModel;

  set tableModel(TableModel value) {
    if (value != _tableModel) {
      _tableModel = value;
      freezeChange = FreezeChange();
    }
  }

  void changeFreeze() {
    freezeChange = tableModel.hitFreezeSplit(
        position, freezePositionProperties.freezeSlope);

    switch (freezeChange.action) {
      case FreezeAction.FREEZE:
        {
          _controller.value = 0.0;
          _controller.forward();
          break;
        }
      case FreezeAction.UNFREEZE:
        {
          _controller.value = 0.0;
          _controller.forward();
          break;
        }
      default:
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool hit(Offset position) => tableModel.hitFreeze(position,
      kSlope: freezePositionProperties.freezeSlope);
}

class FreezePanel extends SingleChildRenderObjectWidget {
  final FreezePosition position;

  FreezePanel({required this.position, Widget? child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderFreezePanel(freezePosition: position);

  void updateRenderObject(
      BuildContext context, RenderFreezePanel renderObject) {
    renderObject.freezePosition = position;
  }
}

class RenderFreezePanel extends RenderProxyBox {
  FreezePosition _freezePosition;
  late Paint _paint;
  late double lineWidth;
  late Color freezeColor;
  late Color unFreezeColor;

  RenderFreezePanel({required FreezePosition freezePosition})
      : _freezePosition = freezePosition {
    _paint = Paint();
    updatePaint();
  }

  FreezePosition get freezePosition => _freezePosition;

  set freezePosition(FreezePosition value) {
    if (_freezePosition != value) {
      _freezePosition = value;
      updatePaint();
      markNeedsPaint();
    }
  }

  updatePaint() {
    lineWidth = freezePosition.tableModel.spaceSplitFreeze;
    freezeColor = Colors.blue[700]!;
    unFreezeColor = Colors.blueGrey[100]!;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    freezePosition.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    super.detach();
    freezePosition.removeListener(markNeedsPaint);
  }

  @override
  void performLayout() {
    if (child != null) {
      final Constraints tight = BoxConstraints.tight(constraints.biggest);
      child!.layout(tight, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.biggest;
    }
  }

  bool hitTestSelf(Offset position) => freezePosition.hit(position);

  performResize() {
    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final freezeChange = freezePosition.freezeChange;
    final position = freezeChange.position;

    final animationValue = freezePosition.animationValue;

    if (position == Offset.zero) return;

    Canvas canvas = context.canvas;
    canvas.save();

    if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);

    if (freezeChange.row > 0) {
      double left = position.dx - position.dx * animationValue;
      double right = position.dx + (size.width - position.dx) * animationValue;
      double top = position.dy - lineWidth / 2.0;
      double bottom = top + lineWidth;

      switch (freezeChange.action) {
        case FreezeAction.FREEZE:
          {
            _paint.color = freezeColor;
            canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), _paint);
            break;
          }
        case FreezeAction.UNFREEZE:
          {
            _paint.color = unFreezeColor;
            canvas.drawRect(Rect.fromLTRB(0.0, top, left, bottom), _paint);
            canvas.drawRect(
                Rect.fromLTRB(right, top, size.width, bottom), _paint);
            break;
          }
        default:
      }
    }

    if (freezeChange.column > 0) {
      double top = position.dy - position.dy * animationValue;
      double bottom =
          position.dy + (size.height - position.dy) * animationValue;
      double left = position.dx - lineWidth / 2.0;
      double right = left + lineWidth;

      switch (freezeChange.action) {
        case FreezeAction.FREEZE:
          {
            _paint.color = freezeColor;
            canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), _paint);
            break;
          }
        case FreezeAction.UNFREEZE:
          {
            _paint.color = unFreezeColor;
            canvas.drawRect(Rect.fromLTRB(left, 0.0, right, top), _paint);
            canvas.drawRect(
                Rect.fromLTRB(left, bottom, right, size.height), _paint);
            break;
          }
        default:
      }
    }

    canvas.restore();
  }
}
