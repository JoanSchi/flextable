// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/widgets.dart';
import '../../gesture_scroll/table_drag_details.dart';
import '../../gesture_scroll/table_scroll_activity.dart';
import '../../hit_test/hit_and_drag.dart';
import '../../model/model.dart';
import '../split/adjust_table_split.dart';
import 'adjust_freeze_properties.dart';

class TableMoveFreeze extends StatefulWidget {
  const TableMoveFreeze({
    super.key,
    required this.viewModel,
  });

  final FtViewModel viewModel;

  @override
  State<StatefulWidget> createState() => TableMoveFreezeState();
}

class TableMoveFreezeState extends State<TableMoveFreeze> {
  late MoveFreeze _moveFreeze;

  @override
  void didChangeDependencies() {
    _moveFreeze = MoveFreeze(
      viewModel: widget.viewModel,
    );
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableMoveFreeze oldWidget) {
    _moveFreeze.viewModel = widget.viewModel;

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

class MoveFreeze extends ChangeNotifier implements HitAndDragDelegate {
  MoveFreeze({
    required FtViewModel viewModel,
  }) : _viewModel = viewModel;

  FtViewModel _viewModel;
  AdjustFreezeProperties? adjustFreezeProperties;
  late FreezeLine freezeLine;

  FtViewModel get viewModel => _viewModel;

  set viewModel(FtViewModel value) {
    if (_viewModel == value) return;

    _viewModel = value;
  }

  @override
  bool hit(Offset position) {
    if (viewModel.stateSplitX == SplitState.freezeSplit ||
        viewModel.stateSplitY == SplitState.freezeSplit) {
      return hitFreezeLine(position) != FreezeLine.none;
    }
    return false;
  }

  FreezeLine hitFreezeLine(Offset position) {
    final xEnd = viewModel.widthLayoutList[1].panelEndPosition;
    final yEnd = viewModel.heightLayoutList[1].panelEndPosition;

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

    final size =
        viewModel.properties.adjustFreeze?.sizeMoveFreezeButton ?? 50.0;

    if ((viewModel.stateSplitX == SplitState.freezeSplit &&
            viewModel.stateSplitY == SplitState.freezeSplit) &&
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
        delegate: viewModel,
        details: details,
        onDragCanceled: dragCancelCallback,
        freezeLine: freezeLine);

    viewModel.beginActivity(DragTableSplitActivity(viewModel));
    assert(viewModel.currentChange == null);
    viewModel.currentChange = drag;
    return drag;
  }

  @override
  down(DragDownDetails details) {
    freezeLine = hitFreezeLine(details.localPosition);
  }
}

class FreezeDragController implements TableDrag {
  FreezeDragController(
      {required TableScrollActivityDelegate delegate,
      required DragStartDetails details,
      this.onDragCanceled,
      required this.freezeLine})
      : _delegate = delegate;

  final VoidCallback? onDragCanceled;
  final TableScrollActivityDelegate _delegate;
  FreezeLine freezeLine;

  bool dragEnd = false;

  @override
  void cancel() {
    _delegate
      ..cancelSplit()
      ..correctOffScroll(0, 0);
  }

  @override
  void end(TableDragEndDetails details) {
    dragEnd = true;

    _delegate
      ..cancelSplit()
      ..correctOffScroll(0, 0);
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
