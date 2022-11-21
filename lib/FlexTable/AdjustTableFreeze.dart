import 'dart:async';

import 'package:flextable/FlexTable/MultiHitStack.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'AdjustTableSplit.dart';
import 'HitAndDrag.dart';
import 'TableDragDetails.dart';
import 'TableModel.dart';
import 'TableScroll.dart';
import 'TableScrollActivity.dart';

class TableFreeze extends StatefulWidget {
  final TableScrollPosition tableScrollPosition;
  final FreezePositionProperties freezePositionProperties;
  final MoveFreezePositionProperties moveFreezePositionProperties;
  final TableModel tableModel;

  const TableFreeze({
    Key? key,
    required this.tableScrollPosition,
    required this.freezePositionProperties,
    required this.moveFreezePositionProperties,
    required this.tableModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TableFreezeState();
}

class TableFreezeState extends State<TableFreeze>
    with SingleTickerProviderStateMixin {
  late MoveFreeze _moveFreeze;
  late FreezePosition _freezePosition;
  Offset positionStartLongPress = Offset.zero;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _moveFreeze = MoveFreeze(
        tableScrollPosition: widget.tableScrollPosition,
        tableModel: widget.tableModel,
        moveFreezePositionProperties: widget.moveFreezePositionProperties);

    _freezePosition = FreezePosition(
      vsync: this,
      tableModel: widget.tableModel,
      freezePositionProperties: widget.freezePositionProperties,
      tableScrollPosition: widget.tableScrollPosition,
    );
  }

  @override
  void didUpdateWidget(TableFreeze oldWidget) {
    super.didUpdateWidget(oldWidget);

    _moveFreeze
      ..tableScrollPosition = widget.tableScrollPosition
      ..tableModel = widget.tableModel
      ..moveFreezePositionProperties = widget.moveFreezePositionProperties;

    _freezePosition
      ..tableScrollPosition = widget.tableScrollPosition
      ..tableModel = widget.tableModel
      ..freezePositionProperties = widget.freezePositionProperties;
  }

  @override
  void dispose() {
    super.dispose();

    _moveFreeze.dispose();
    _freezePosition.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiHitStack(
      children: [
        HitAndDrag(
          hitAndDragDelegate: _moveFreeze,
        ),
        GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: (LongPressStartDetails details) =>
                {positionStartLongPress = details.localPosition},
            onLongPress: () =>
                _freezePosition.changeFreeze(positionStartLongPress),
            child: FreezePaint(
              position: _freezePosition,
            ))
      ],
    );
  }
}

class FreezePositionProperties {
  final bool useFreezePosition;
  final double freezeSlope;

  const FreezePositionProperties({
    this.useFreezePosition: true,
    this.freezeSlope: kTouchSlop,
  });
}

class MoveFreezePositionProperties {
  final bool useMoveFreezePosition;
  final double sizeMoveFreezeButton;

  const MoveFreezePositionProperties(
      {this.useMoveFreezePosition: true, this.sizeMoveFreezeButton: 50.0});
}

class FreezePosition extends ChangeNotifier {
  TickerProvider vsync;
  TableModel _tableModel;
  FreezeChange freezeChange = FreezeChange();
  late AnimationController _controller;
  FreezePositionProperties freezePositionProperties;
  TableScrollPosition tableScrollPosition;

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

  void changeFreeze(Offset position) {
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

  bool hit(Offset position) {
    bool hit =
        tableModel.hitFreeze(position, freezePositionProperties.freezeSlope);
    // print('freeze hit $hit');
    return hit;
  }
}

class FreezePaint extends SingleChildRenderObjectWidget {
  final FreezePosition position;

  FreezePaint({required this.position, Widget? child}) : super(child: child);

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderFreezePaint(freezePosition: position);

  void updateRenderObject(
      BuildContext context, RenderFreezePaint renderObject) {
    renderObject.freezePosition = position;
  }
}

class RenderFreezePaint extends RenderProxyBox {
  FreezePosition _freezePosition;
  late Paint _paint;
  late double lineWidth;
  late Color freezeColor;
  late Color unFreezeColor;

  RenderFreezePaint({required FreezePosition freezePosition})
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

class MoveFreeze extends ChangeNotifier implements HitAndDragDelegate {
  TableScrollPosition tableScrollPosition;
  TableModel _tableModel;
  MoveFreezePositionProperties moveFreezePositionProperties;

  late FreezeLine freezeLine;

  MoveFreeze(
      {required this.tableScrollPosition,
      required TableModel tableModel,
      required this.moveFreezePositionProperties})
      : _tableModel = tableModel;

  TableModel get tableModel => _tableModel;

  set tableModel(TableModel value) {
    if (_tableModel == value) return;

    _tableModel = value;
  }

  bool hit(Offset position) {
    if (tableModel.stateSplitX == SplitState.FREEZE_SPLIT ||
        tableModel.stateSplitY == SplitState.FREEZE_SPLIT) {
      return hitFreezeLine(position) != FreezeLine.none;
    }
    return false;
  }

  FreezeLine hitFreezeLine(Offset position) {
    final xEnd = tableModel.widthLayoutList[1].panelEndPosition;
    final yEnd = tableModel.heightLayoutList[1].panelEndPosition;

    bool contains(
        {required Offset offset,
        required double left,
        required double top,
        required double right,
        required double bottom}) {
      return offset.dx >= left &&
          offset.dx < right &&
          offset.dy >= top &&
          offset.dy < bottom;
    }

    final size = moveFreezePositionProperties.sizeMoveFreezeButton;

    if (contains(
        offset: position,
        left: xEnd - size,
        top: yEnd - size,
        right: xEnd,
        bottom: yEnd)) {
      return FreezeLine.both;
    } else if (contains(
        offset: position,
        left: xEnd - size,
        top: 0.0,
        right: xEnd,
        bottom: size)) {
      return FreezeLine.vertical;
    } else if (contains(
        offset: position,
        left: 0,
        top: yEnd - size,
        right: size,
        bottom: yEnd)) {
      return FreezeLine.horizontal;
    } else {
      return FreezeLine.none;
    }
  }

  @override
  TableDrag dragSplit(
      DragStartDetails details, VoidCallback dragCancelCallback) {
    final FreezeDragController drag = FreezeDragController(
        delegate: tableScrollPosition,
        details: details,
        onDragCanceled: dragCancelCallback,
        freezeLine: freezeLine);

    tableScrollPosition
        .beginActivity(DragTableSplitActivity(tableScrollPosition));
    assert(tableScrollPosition.currentDrag == null);
    tableScrollPosition.currentDrag = drag;
    return drag;
  }

  @override
  down(DragDownDetails details) {
    freezeLine = hitFreezeLine(details.localPosition);
    print('move freeze down $freezeLine');
  }
}

class FreezeDragController implements TableDrag {
  final onDragCanceled;
  final TableScrollActivityDelegate _delegate;
  var _lastDetails;
  FreezeLine freezeLine;

  bool dragEnd = false;

  FreezeDragController(
      {required TableScrollActivityDelegate delegate,
      required DragStartDetails details,
      this.onDragCanceled,
      required this.freezeLine})
      : _delegate = delegate;

  @override
  void cancel() {
    _delegate.goIdle(0, 0);
  }

  @override
  void end(TableDragEndDetails details) {
    dragEnd = true;

    bool alignX = false;
    bool alignY = false;

    switch (freezeLine) {
      case FreezeLine.both:
        {
          alignX = true;
          alignY = true;
          break;
        }
      case FreezeLine.horizontal:
        {
          alignY = true;
          break;
        }
      case FreezeLine.vertical:
        {
          alignX = true;
          break;
        }
      default:
        {
          _delegate.goIdle(0, 0);
          return;
        }
    }

    _delegate.alignCells(0, 0, alignX, alignY);
  }

  @override
  void update(TableDragUpdateDetails details) {
    Offset delta = details.delta;

    switch (freezeLine) {
      case FreezeLine.horizontal:
        {
          delta = Offset(0.0, details.delta.dy);
          break;
        }
      case FreezeLine.vertical:
        {
          delta = Offset(details.delta.dx, 0.0);
          break;
        }
      default:
        {
          delta = details.delta;
        }
    }

    _delegate.applyUserOffset(0, 0, delta);
  }

  @mustCallSuper
  void dispose() {
    if (onDragCanceled != null) onDragCanceled();
  }

  @override
  get lastDetails => _lastDetails;
}

class FreezeMoveController implements TableDrag {
  final onDragCanceled;
  final TableScrollActivityDelegate _delegate;
  final double scrollX;
  final double scrollY;
  final double moveToScrollX;
  final double moveToScrollY;
  bool dragEnd = false;
  late AnimationController _controller;
  late Animation _animation;

  FreezeMoveController(
      {required TableScrollActivityDelegate delegate,
      this.onDragCanceled,
      required this.scrollX,
      required this.moveToScrollX,
      required this.scrollY,
      required this.moveToScrollY,
      required TickerProvider vsync})
      : _delegate = delegate {
    _controller = AnimationController(
        vsync: vsync, duration: Duration(milliseconds: 200));
    _animation = _controller.drive(CurveTween(curve: Curves.ease));
    _animation.addListener(_tick);
    _controller.forward();
  }

  @override
  void cancel() {
    _delegate.goIdle(0, 0);
  }

  @override
  void end(TableDragEndDetails details) {
    dragEnd = true;
    _delegate.goIdle(0, 0);
  }

  @override
  void update(TableDragUpdateDetails details) {}

  @mustCallSuper
  void dispose() {
    if (onDragCanceled != null) onDragCanceled();
    _controller.dispose();
  }

  _tick() {
    final x = scrollX + (moveToScrollX - scrollX) * _animation.value;
    final y = scrollY + (moveToScrollY - scrollY) * _animation.value;
    _delegate.setPixels(0, 0, Offset(x, y));
  }

  @override
  get lastDetails => null;
}
