// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../../model/view_model.dart';
import 'package:flutter/material.dart';
import '../../gesture_scroll/table_drag_details.dart';
import '../../gesture_scroll/table_scroll_activity.dart';
import '../../hit_test/hit_and_drag.dart';
import '../../model/model.dart';
import 'adjust_split_properties.dart';

class AdjustTableSplit extends StatefulWidget {
  const AdjustTableSplit({
    super.key,
    required this.viewModel,
    required this.properties,
  });

  final FtViewModel viewModel;
  final AdjustSplitProperties properties;

  @override
  State<StatefulWidget> createState() => AdjustTableSplitState();
}

class AdjustTableSplitState extends State<AdjustTableSplit> {
  late SplitPosition _splitPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _splitPosition = SplitPosition(
      viewModel: widget.viewModel,
      properties: widget.properties,
    );
  }

  @override
  void didUpdateWidget(AdjustTableSplit oldWidget) {
    super.didUpdateWidget(oldWidget);

    _splitPosition
      ..viewModel = widget.viewModel
      ..properties = widget.properties;
  }

  @override
  Widget build(BuildContext context) {
    return HitAndDrag(
      hitAndDragDelegate: _splitPosition,
    );
  }
}

class SplitPosition implements HitAndDragDelegate {
  SplitPosition({required this.viewModel, required this.properties});

  FtViewModel viewModel;
  AdjustSplitProperties properties;
  AdjustSplitProperties? adjust;

  dispose() {}

  @override
  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    final localPosition = details.localPosition;

    SplitChange xSplitChange = SplitChange.no;

    if (noManualSplit(viewModel.stateSplitX) &&
        contains(properties.xSplitSelectArea, localPosition)) {
      xSplitChange = SplitChange.start;
    } else if (viewModel.hitDividerX(localPosition.dx, SplitState.split)) {
      xSplitChange = SplitChange.edit;
    }

    SplitChange ySplitChange = SplitChange.no;

    if (noManualSplit(viewModel.stateSplitY) &&
        contains(properties.ySplitSelectArea, localPosition)) {
      ySplitChange = SplitChange.start;
    } else if (viewModel.hitDividerY(localPosition.dy, SplitState.split)) {
      ySplitChange = SplitChange.edit;
    }

    final SplitDragController drag = SplitDragController(
      viewModel: viewModel,
      details: details,
      onDragCanceled: dragCancelCallback,
      xSplitchanger:
          viewModel.scrollDirectionByTable == TableScrollDirection.vertical
              ? SplitHandler()
              : SplitChanger(
                  position: localPosition.dx,
                  change: xSplitChange,
                  vsync: viewModel.context.vsync,
                  setSplit: applySplitX,
                  startTable: () => viewModel.initiateSplitLeft,
                  endTable: () => viewModel.initiateSplitRight,
                  initiateSplitAtBegin: viewModel.minSplitPositionLeft,
                  initiateSplitAtEnd: viewModel.maxSplitPositionRight,
                  changeRatioSizeHeader: (double ratio) =>
                      viewModel.ratioSizeAnimatedSplitChangeX = ratio,
                  split: () => viewModel.splitX),
      ySplitchanger:
          viewModel.scrollDirectionByTable == TableScrollDirection.horizontal
              ? SplitHandler()
              : SplitChanger(
                  position: localPosition.dy,
                  change: ySplitChange,
                  vsync: viewModel.context.vsync,
                  setSplit: applySplitY,
                  startTable: () => viewModel.initiateSplitTop,
                  endTable: () => viewModel.initiateSplitBottom,
                  initiateSplitAtBegin: viewModel.minSplitPositionTop,
                  initiateSplitAtEnd: viewModel.maxSplitPositionBottom,
                  changeRatioSizeHeader: (double ratio) =>
                      viewModel.ratioSizeAnimatedSplitChangeY = ratio,
                  split: () => viewModel.splitY),
    );

    viewModel.beginActivity(DragTableSplitActivity(viewModel));

    assert(viewModel.currentChange == null);
    viewModel.currentChange = drag;

    return drag;
  }

  void applySplitX({double? split, double? delta}) {
    viewModel.setXsplit(
        sizeSplit: split,
        deltaSplit: delta,
        splitView: SplitState.split,
        animateSplit: true);
    viewModel.markNeedsLayout();
    // _tableModel.notifyScrollBarListeners();
  }

  void applySplitY({double? split, double? delta}) {
    viewModel.setYsplit(
        sizeSplit: split,
        deltaSplit: delta,
        splitView: SplitState.split,
        animateSplit: true);
    viewModel.markNeedsLayout();
  }

  @override
  bool hit(Offset position) {
    return (noManualSplit(viewModel.stateSplitX) &&
            contains(properties.xSplitSelectArea, position)) ||
        viewModel.hitDividerX(position.dx, SplitState.split) ||
        (noManualSplit(viewModel.stateSplitY) &&
            contains(properties.ySplitSelectArea, position)) ||
        viewModel.hitDividerY(position.dy, SplitState.split);
  }

  @override
  down(DragDownDetails details) {}

  bool contains(SelectArea selectArea, Offset offset) {
    double left, top, bottom, right;

    switch (selectArea.horizontalAlignment) {
      case HitAlignment.start:
        left = viewModel.sizeScrollBarLeft;
        break;
      case HitAlignment.center:
        left = viewModel.sizeScrollBarLeft +
            (viewModel.widthMainPanel -
                    selectArea.width -
                    viewModel.sizeScrollBarLeft -
                    viewModel.sizeScrollBarRight) /
                2.0;
        break;
      case HitAlignment.end:
        left = (viewModel.widthMainPanel -
            viewModel.sizeScrollBarRight -
            selectArea.width);
        break;
    }
    right = left + selectArea.width;

    switch (selectArea.verticalAlignment) {
      case HitAlignment.start:
        top = viewModel.sizeScrollBarTop;
        break;
      case HitAlignment.center:
        top = viewModel.sizeScrollBarTop +
            (viewModel.heightMainPanel -
                    selectArea.height -
                    viewModel.sizeScrollBarTop -
                    viewModel.sizeScrollBarBottom) /
                2.0;
        break;
      case HitAlignment.end:
        top = (viewModel.heightMainPanel -
            selectArea.height -
            viewModel.sizeScrollBarBottom);
        break;
    }
    bottom = top + selectArea.height;

    return offset.dx >= left &&
        offset.dx < right &&
        offset.dy >= top &&
        offset.dy < bottom;
  }
}

enum HitAlignment { start, center, end }

class DragTableSplitActivity extends TableScrollActivity {
  /// Initializes [delegate] for subclasses.

  DragTableSplitActivity(TableScrollActivityDelegate delegate)
      : super(0, 0, delegate, false);

  @override
  bool get isScrolling => true;

  @override
  bool get shouldIgnorePointer => false;

  @override
  double get xVelocity => 0.0;

  @override
  double get yVelocity => 0.0;
}

class SplitDragController implements TableDrag {
  SplitDragController({
    required this.viewModel,
    required DragStartDetails details,
    this.onDragCanceled,
    this.xSplitchanger,
    this.ySplitchanger,
  }) {
    xSplitchanger?.evaluateEnd = evaluateEnd;
    ySplitchanger?.evaluateEnd = evaluateEnd;
    viewModel.modifySplit = true;
  }

  final VoidCallback? onDragCanceled;
  final FtViewModel viewModel;
  SplitHandler? xSplitchanger;
  SplitHandler? ySplitchanger;
  bool dragEnd = false;

  @override
  void cancel() {
    viewModel
      ..correctOffScroll(0, 0)
      ..modifySplit = false;
  }

  @override
  void end(TableDragEndDetails details) {
    dragEnd = true;
    viewModel
      ..correctOffScroll(0, 0)
      ..modifySplit = false;
  }

  void evaluateEnd() {
    if (dragEnd &&
        !(xSplitchanger?.isAnimating() ?? false) &&
        !(ySplitchanger?.isAnimating() ?? false)) {
      viewModel.correctOffScroll(0, 0);
    }
  }

  @override
  void update(TableDragUpdateDetails details) {
    Offset delta = details.delta;
    Offset position = details.globalPosition;

    xSplitchanger?.update(position.dx, delta.dx, viewModel.xSplit);
    ySplitchanger?.update(position.dy, delta.dy, viewModel.ySplit);
  }

  @override
  @mustCallSuper
  void dispose() {
    onDragCanceled?.call();
    xSplitchanger?.dispose();
    ySplitchanger?.dispose();
    viewModel.modifySplit = false;
  }

  @override
  get lastDetails => null;
}

enum AnimateSplit { fromBegin, goToBegin, fromEnd, goToEnd, noAnimation }

typedef SetSplit = void Function({double split, double delta});

class SplitHandler {
  VoidCallback evaluateEnd = () => {};

  update(double updatePosition, double updateDelta, double? split) {}

  go() {}

  isAnimating() => false;

  dispose() {}
}

class SplitChanger extends SplitHandler {
  SplitChanger({
    required this.position,
    required this.startTable,
    required this.endTable,
    required this.initiateSplitAtBegin,
    required this.initiateSplitAtEnd,
    required this.vsync,
    required this.setSplit,
    required this.change,
    required this.changeRatioSizeHeader,
    required this.split,
  }) {
    animationController = AnimationController(
        value: split() ? 1.0 : 0.0,
        vsync: vsync,
        duration: const Duration(milliseconds: 300))
      ..addListener(go);
  }

  SplitChange change;
  double Function() startTable;
  double Function() endTable;
  double initiateSplitAtBegin;
  double initiateSplitAtEnd;
  double position;
  TickerProvider vsync;
  late AnimationController animationController;
  SetSplit setSplit;
  double from = 0.0;
  double to = 0.0;
  AnimateSplit animationStatus = AnimateSplit.noAnimation;
  final Function(double value) changeRatioSizeHeader;
  final bool Function() split;

  @override
  void update(double updatePosition, double updateDelta, double? split) {
    position += updateDelta;

    double delta = 0.0;
    final startTable = this.startTable();
    final endTable = this.endTable();
    final closertoStart = position < startTable + (endTable - startTable) / 2.0;

    switch (change) {
      case SplitChange.start:
        {
          if (position > initiateSplitAtBegin &&
              position < initiateSplitAtEnd) {
            if (closertoStart) {
              animationStatus = AnimateSplit.fromBegin;
              from = startTable;
            } else {
              animationStatus = AnimateSplit.fromEnd;
              from = endTable;
            }
            to = position;
            setSplit(split: from);
            animationController.forward();
            change = SplitChange.edit;
          }
          break;
        }
      case SplitChange.edit:
        {
          if (position < initiateSplitAtBegin &&
              animationStatus != AnimateSplit.goToBegin) {
            to = split ?? 0.0;
            from = startTable;

            animationStatus = AnimateSplit.goToBegin;
            animationController.reverse();
          } else if (position > initiateSplitAtEnd &&
              animationStatus != AnimateSplit.goToEnd) {
            from = endTable;
            to = position;
            animationStatus = AnimateSplit.goToEnd;
            animationController.reverse();
          } else if (closertoStart &&
              position >= initiateSplitAtBegin &&
              !(animationStatus == AnimateSplit.fromBegin ||
                  animationStatus == AnimateSplit.fromEnd)) {
            from = split ?? startTable;
            to = position;
            animationController.forward();
            animationStatus = AnimateSplit.fromBegin;
            delta = 0;
          } else if (!closertoStart &&
              position <= initiateSplitAtEnd &&
              !(animationStatus == AnimateSplit.fromBegin ||
                  animationStatus == AnimateSplit.fromEnd)) {
            from = split ?? endTable;
            to = position;
            animationController.forward();
            animationStatus = AnimateSplit.fromEnd;
            delta = 0;
          } else if (animationController.isAnimating) {
            switch (animationStatus) {
              case AnimateSplit.fromBegin:
                {
                  delta += updateDelta;
                  from = startTable + (delta > 0.0 ? delta : 0.0);
                  to += updateDelta;
                  break;
                }
              case AnimateSplit.fromEnd:
                {
                  delta += updateDelta;
                  from = endTable - (delta < 0.0 ? delta : 0.0);
                  to += updateDelta;
                  break;
                }
              default:
                {}
            }
          } else if (position > initiateSplitAtBegin &&
              position < initiateSplitAtEnd) {
            to = position;
            setSplit(delta: updateDelta);
          }

          break;
        }
      default:
        {}
    }
  }

  @override
  void go() {
    final value = animationController.value;
    setSplit(split: from + (to - from) * value);

    if (animationController.isCompleted || animationController.isDismissed) {
      animationStatus = AnimateSplit.noAnimation;
      evaluateEnd();
    }

    changeRatioSizeHeader(value);
  }

  @override
  bool isAnimating() => animationController.isAnimating;

  @override
  void dispose() {
    final status = animationController.status;

    if (status == AnimationStatus.forward) {
      changeRatioSizeHeader(1.0);
    } else if (status == AnimationStatus.reverse) {
      changeRatioSizeHeader(0.0);
    }

    animationController.dispose();
  }
}
