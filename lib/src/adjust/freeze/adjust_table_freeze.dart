// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../../flextable.dart';
import '../../gesture_scroll/table_drag_details.dart';
import '../../gesture_scroll/table_scroll_activity.dart';
import '../../hit_test/hit_box.dart';
import '../../model/model.dart';
import '../../model/properties/flextable_freeze_change.dart';

class TableFreeze extends StatefulWidget {
  const TableFreeze({
    super.key,
    required this.viewModel,
  });

  final FtViewModel viewModel;

  @override
  State<TableFreeze> createState() => _TableFreezeState();
}

class _TableFreezeState extends State<TableFreeze> {
  late FtViewModel viewModel = widget.viewModel;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(TableFreeze oldWidget) {
    if (viewModel != widget.viewModel) {
      viewModel = widget.viewModel;
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool isFrozen() {
    final model = widget.viewModel.model;
    return model.stateSplitX == SplitState.freezeSplit ||
        model.stateSplitY == SplitState.freezeSplit;
  }

  @override
  Widget build(BuildContext context) {
    return HitBox(
        hit: (Offset position) => widget.viewModel.hitFreeze(
              position,
            ),
        child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPressStart: longPressStart));
  }

  void longPressStart(LongPressStartDetails details) {
    final FreezeChange freezeChange =
        widget.viewModel.hitFreezeSplit(details.localPosition);

    if (freezeChange.action != FreezeAction.noAction) {
      final controller = FreezeController(
          onCanceled: () {}, viewModel: viewModel, freezeChange: freezeChange);
      viewModel.beginActivity(TableFreezeActivity(viewModel, controller));
      assert(viewModel.currentChange == null);

      viewModel.currentChange = controller;
    }
  }
}

class FreezeController implements TableChange {
  FreezeController({
    required this.onCanceled,
    required this.viewModel,
    required this.freezeChange,
  }) {
    switch (freezeChange.action) {
      case FreezeAction.freeze:
        {
          viewModel
            ..freezeByPosition(freezeChange)
            ..markNeedsLayout();
          _controller = AnimationController(
              vsync: viewModel.context.vsync,
              duration: const Duration(milliseconds: 200))
            ..addListener(_animatedChange)
            ..forward();

          _animation =
              CurveTween(curve: Curves.easeInOut).animate(_controller!.view);

          _end = 1.0;
          break;
        }
      case FreezeAction.unFreeze:
        {
          _controller = AnimationController(
              value: 1.0,
              vsync: viewModel.context.vsync,
              duration: const Duration(milliseconds: 200))
            ..addListener(_animatedChange)
            ..reverse().then((value) {
              viewModel
                ..freezeByPosition(freezeChange)
                ..markNeedsLayout();
            });

          _animation =
              CurveTween(curve: Curves.easeInOut).animate(_controller!.view);

          _end = 0.0;
          break;
        }
      case FreezeAction.noAction:
        {}
    }
  }

  final VoidCallback? onCanceled;
  final FtViewModel viewModel;
  final FreezeChange freezeChange;
  AnimationController? _controller;
  late Animation<double> _animation;
  double _end = 0.0;

  void _animatedChange() {
    _change(_animation.value);
    viewModel.markNeedsLayout();
  }

  void endChange() {
    if (!(_controller?.isAnimating ?? false)) {
      return;
    }

    //MarkNeedsLayout probably not needed because activity is pushed out by another activity which will tricker the layout
    _change(_end);

    if (_end == 0.0) {
      viewModel.freezeByPosition(freezeChange);
    }
  }

  void _change(double value) {
    if (freezeChange.row != -1) {
      viewModel.ratioFreezeChangeY = value;
    }

    if (freezeChange.column != -1) {
      viewModel.ratioFreezeChangeX = value;
    }
  }

  @override
  @mustCallSuper
  void dispose() {
    _controller?.dispose();
    onCanceled?.call();
  }
}

class TableFreezeActivity extends TableScrollActivity {
  /// Initializes [delegate] for subclasses.

  TableFreezeActivity(
      TableScrollActivityDelegate delegate, this.freezeController)
      : super(0, 0, delegate, false);

  FreezeController freezeController;

  @override
  bool get isScrolling => false;

  @override
  bool get shouldIgnorePointer => false;

  @override
  double get xVelocity => 0.0;

  @override
  double get yVelocity => 0.0;

  @override
  void dispose() {
    freezeController.endChange();
    super.dispose();
  }
}
