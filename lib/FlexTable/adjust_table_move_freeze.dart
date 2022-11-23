import 'package:flutter/widgets.dart';

import 'adjust_table_split.dart';
import 'hit_and_drag.dart';
import 'table_drag_details.dart';
import 'table_model.dart';
import 'table_scroll.dart';
import 'table_scroll_activity.dart';

class TableMoveFreeze extends StatefulWidget {
  final TableScrollPosition tableScrollPosition;
  final MoveFreezePositionProperties moveFreezePositionProperties;
  final TableModel tableModel;

  const TableMoveFreeze({
    Key? key,
    required this.tableScrollPosition,
    required this.moveFreezePositionProperties,
    required this.tableModel,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TableMoveFreezeState();
}

class TableMoveFreezeState extends State<TableMoveFreeze> {
  late MoveFreeze _moveFreeze;

  @override
  void didChangeDependencies() {
    _moveFreeze = MoveFreeze(
        tableScrollPosition: widget.tableScrollPosition,
        tableModel: widget.tableModel,
        moveFreezePositionProperties: widget.moveFreezePositionProperties);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableMoveFreeze oldWidget) {
    _moveFreeze
      ..tableScrollPosition = widget.tableScrollPosition
      ..tableModel = widget.tableModel
      ..moveFreezePositionProperties = widget.moveFreezePositionProperties;

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _moveFreeze.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HitAndDrag(
      hitAndDragDelegate: _moveFreeze,
    );
  }
}

class MoveFreezePositionProperties {
  final bool useMoveFreezePosition;
  final double sizeMoveFreezeButton;

  const MoveFreezePositionProperties(
      {this.useMoveFreezePosition: true, this.sizeMoveFreezeButton: 50.0});
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

    if ((tableModel.stateSplitX == SplitState.FREEZE_SPLIT &&
            tableModel.stateSplitY == SplitState.FREEZE_SPLIT) &&
        contains(
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
  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
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
