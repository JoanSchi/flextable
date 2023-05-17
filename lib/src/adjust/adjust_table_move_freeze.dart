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

import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/widgets.dart';

import 'adjust_table_split.dart';
import '../gesture_scroll/table_drag_details.dart';
import '../gesture_scroll/table_scroll_activity.dart';
import '../hit_test/hit_and_drag.dart';
import '../model/model.dart';

class TableMoveFreeze extends StatefulWidget {
  final FlexTableViewModel flexTableViewModel;
  final MoveFreezePositionProperties moveFreezePositionProperties;

  const TableMoveFreeze({
    Key? key,
    required this.flexTableViewModel,
    required this.moveFreezePositionProperties,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TableMoveFreezeState();
}

class TableMoveFreezeState extends State<TableMoveFreeze> {
  late MoveFreeze _moveFreeze;

  @override
  void didChangeDependencies() {
    _moveFreeze = MoveFreeze(
        flexTableViewModel: widget.flexTableViewModel,
        moveFreezePositionProperties: widget.moveFreezePositionProperties);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableMoveFreeze oldWidget) {
    _moveFreeze
      ..flexTableViewModel = widget.flexTableViewModel
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
      {this.useMoveFreezePosition = true, this.sizeMoveFreezeButton = 50.0});
}

class MoveFreeze extends ChangeNotifier implements HitAndDragDelegate {
  FlexTableViewModel _flexTableViewModel;
  MoveFreezePositionProperties moveFreezePositionProperties;

  late FreezeLine freezeLine;

  MoveFreeze(
      {required FlexTableViewModel flexTableViewModel,
      required this.moveFreezePositionProperties})
      : _flexTableViewModel = flexTableViewModel;

  FlexTableViewModel get flexTableViewModel => _flexTableViewModel;

  set flexTableViewModel(FlexTableViewModel value) {
    if (_flexTableViewModel == value) return;

    _flexTableViewModel = value;
  }

  @override
  bool hit(Offset position) {
    if (flexTableViewModel.stateSplitX == SplitState.freezeSplit ||
        flexTableViewModel.stateSplitY == SplitState.freezeSplit) {
      return hitFreezeLine(position) != FreezeLine.none;
    }
    return false;
  }

  FreezeLine hitFreezeLine(Offset position) {
    final xEnd = flexTableViewModel.widthLayoutList[1].panelEndPosition;
    final yEnd = flexTableViewModel.heightLayoutList[1].panelEndPosition;

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

    if ((flexTableViewModel.stateSplitX == SplitState.freezeSplit &&
            flexTableViewModel.stateSplitY == SplitState.freezeSplit) &&
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
        delegate: flexTableViewModel,
        details: details,
        onDragCanceled: dragCancelCallback,
        freezeLine: freezeLine);

    flexTableViewModel
        .beginActivity(DragTableSplitActivity(flexTableViewModel));
    assert(flexTableViewModel.currentDrag == null);
    flexTableViewModel.currentDrag = drag;
    return drag;
  }

  @override
  down(DragDownDetails details) {
    freezeLine = hitFreezeLine(details.localPosition);
  }
}

class FreezeDragController implements TableDrag {
  final VoidCallback? onDragCanceled;
  final TableScrollActivityDelegate _delegate;
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

  @override
  @mustCallSuper
  void dispose() {
    onDragCanceled?.call();
  }

  @override
  get lastDetails => null;
}

class FreezeMoveController implements TableDrag {
  final VoidCallback? onDragCanceled;
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
        vsync: vsync, duration: const Duration(milliseconds: 200));
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

  @override
  @mustCallSuper
  void dispose() {
    onDragCanceled?.call();
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
