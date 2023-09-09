// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../../model/view_model.dart';
import 'package:flutter/material.dart';
import '../../gesture_scroll/table_drag_details.dart';
import '../../gesture_scroll/table_scroll_activity.dart';
import '../../hit_test/hit_and_drag.dart';
import '../../model/model.dart';
import '../../model/properties/flextable_grid_layout.dart';
import 'split_options.dart';

class AdjustTableSplit extends StatefulWidget {
  const AdjustTableSplit({
    Key? key,
    required this.flexTableViewModel,
    required this.properties,
  }) : super(key: key);

  final FlexTableViewModel flexTableViewModel;
  final SplitOptions properties;

  @override
  State<StatefulWidget> createState() => AdjustTableSplitState();
}

class AdjustTableSplitState extends State<AdjustTableSplit> {
  late SplitPosition _splitPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _splitPosition = SplitPosition(
      flexTableViewModel: widget.flexTableViewModel,
      properties: widget.properties,
    );
  }

  @override
  void didUpdateWidget(AdjustTableSplit oldWidget) {
    super.didUpdateWidget(oldWidget);

    _splitPosition
      ..flexTableViewModel = widget.flexTableViewModel
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
  SplitPosition({required this.flexTableViewModel, required this.properties});

  FlexTableViewModel flexTableViewModel;
  SplitOptions properties;
  SplitOptions? adjust;

  dispose() {}

  @override
  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    SplitChange hitSplit(
        {required SplitState splitState,
        required GridLayout layout2,
        required SelectArea area,
        required Offset position,
        required Function(Offset) splitPosition}) {
      if ((noSplit(splitState) || splitState == SplitState.autoFreezeSplit) &&
          contains(area, position)) {
        return SplitChange.start;
      } else if (splitState == SplitState.split &&
          hitExistingSplit(layout2, splitPosition(position))) {
        return SplitChange.edit;
      } else {
        return SplitChange.no;
      }
    }

    final localPosition = details.localPosition;

    SplitChange xSplitChange = hitSplit(
        splitState: flexTableViewModel.stateSplitX,
        layout2: flexTableViewModel.layoutX[2],
        area: properties.xSplitSelectArea,
        position: localPosition,
        splitPosition: (position) => localPosition.dx);

    SplitChange ySplitChange = hitSplit(
        splitState: flexTableViewModel.stateSplitY,
        layout2: flexTableViewModel.layoutY[2],
        area: properties.ySplitSelectArea,
        position: localPosition,
        splitPosition: (position) => localPosition.dy);

    final SplitDragController drag = SplitDragController(
      flexTableViewModel: flexTableViewModel,
      details: details,
      onDragCanceled: dragCancelCallback,
      xSplitchanger: flexTableViewModel.tableScrollDirection ==
              TableScrollDirection.vertical
          ? SplitHandler()
          : SplitChanger(
              position: localPosition.dx,
              change: xSplitChange,
              vsync: flexTableViewModel.context.vsync,
              setSplit: applySplitX,
              startTable: () => flexTableViewModel.initiateSplitLeft,
              endTable: () => flexTableViewModel.initiateSplitRight,
              initiateSplitAtBegin:
                  flexTableViewModel.minimalSplitPositionFromLeft,
              initiateSplitAtEnd:
                  flexTableViewModel.minimalSplitPositionFromRight,
              changeRatioSizeHeader: (double ratio) =>
                  flexTableViewModel.ratioSizeAnimatedSplitChangeX = ratio,
              split: () => flexTableViewModel.splitX),
      ySplitchanger: flexTableViewModel.tableScrollDirection ==
              TableScrollDirection.horizontal
          ? SplitHandler()
          : SplitChanger(
              position: localPosition.dy,
              change: ySplitChange,
              vsync: flexTableViewModel.context.vsync,
              setSplit: applySplitY,
              startTable: () => flexTableViewModel.initiateSplitTop,
              endTable: () => flexTableViewModel.initiateSplitBottom,
              initiateSplitAtBegin:
                  flexTableViewModel.minimalSplitPositionFromTop,
              initiateSplitAtEnd:
                  flexTableViewModel.minimalSplitPositionFromBottom,
              changeRatioSizeHeader: (double ratio) =>
                  flexTableViewModel.ratioSizeAnimatedSplitChangeY = ratio,
              split: () => flexTableViewModel.splitY),
    );

    flexTableViewModel
        .beginActivity(DragTableSplitActivity(flexTableViewModel));

    assert(flexTableViewModel.currentDrag == null);
    flexTableViewModel.currentDrag = drag;

    return drag;
  }

  void applySplitX({double? split, double? delta}) {
    flexTableViewModel.setXsplit(
        sizeSplit: split,
        deltaSplit: delta,
        splitView: SplitState.split,
        animateSplit: true);
    flexTableViewModel.markNeedsLayout();
    // _tableModel.notifyScrollBarListeners();
  }

  void applySplitY({double? split, double? delta}) {
    flexTableViewModel.setYsplit(
        sizeSplit: split,
        deltaSplit: delta,
        splitView: SplitState.split,
        animateSplit: true);
    flexTableViewModel.markNeedsLayout();
    // flexTableViewModel.notifyScrollBarListeners();
  }

  @override
  bool hit(Offset position) {
    bool hitSplit(
        {required SplitState splitState,
        required GridLayout layout2,
        required SelectArea area,
        required Offset position,
        required Function(Offset) splitPosition,
        required Function(Offset) oppositeSplitPosition,
        required double oppositeStartPosition,
        required double oppositeEndPosition}) {
      if ((noSplit(splitState) || splitState == SplitState.autoFreezeSplit) &&
          contains(area, position)) {
        return true;
      } else if (splitState == SplitState.split &&
          oppositeSplitPosition(position) > oppositeStartPosition &&
          oppositeSplitPosition(position) < oppositeEndPosition &&
          hitExistingSplit(layout2, splitPosition(position))) {
        return true;
      } else {
        return false;
      }
    }

    bool hit = hitSplit(
            splitState: flexTableViewModel.stateSplitX,
            layout2: flexTableViewModel.layoutX[2],
            area: properties.xSplitSelectArea,
            position: position,
            splitPosition: (position) => position.dx,
            oppositeSplitPosition: (position) => position.dy,
            oppositeStartPosition:
                flexTableViewModel.minimalSplitPositionFromTop,
            oppositeEndPosition:
                flexTableViewModel.minimalSplitPositionFromBottom) ||
        hitSplit(
            splitState: flexTableViewModel.stateSplitY,
            layout2: flexTableViewModel.layoutY[2],
            area: properties.ySplitSelectArea,
            position: position,
            splitPosition: (position) => position.dy,
            oppositeSplitPosition: (position) => position.dx,
            oppositeStartPosition:
                flexTableViewModel.minimalSplitPositionFromLeft,
            oppositeEndPosition:
                flexTableViewModel.minimalSplitPositionFromRight);

    return hit;
  }

  bool hitExistingSplit(GridLayout gridLayout2, double position) {
    return (gridLayout2.inUse &&
        gridLayout2.gridPosition - 25 < position &&
        gridLayout2.gridPosition + 25 > position);
  }

  @override
  down(DragDownDetails details) {}

  bool contains(SelectArea selectArea, Offset offset) {
    double left, top, bottom, right;

    switch (selectArea.horizontalAlignment) {
      case HitAlignment.start:
        left = flexTableViewModel.sizeScrollBarLeft;
        break;
      case HitAlignment.center:
        left = flexTableViewModel.sizeScrollBarLeft +
            (flexTableViewModel.widthMainPanel -
                    selectArea.width -
                    flexTableViewModel.sizeScrollBarLeft -
                    flexTableViewModel.sizeScrollBarRight) /
                2.0;
        break;
      case HitAlignment.end:
        left = (flexTableViewModel.widthMainPanel -
            flexTableViewModel.sizeScrollBarRight -
            selectArea.width);
        break;
    }
    right = left + selectArea.width;

    switch (selectArea.verticalAlignment) {
      case HitAlignment.start:
        top = flexTableViewModel.sizeScrollBarTop;
        break;
      case HitAlignment.center:
        top = flexTableViewModel.sizeScrollBarTop +
            (flexTableViewModel.heightMainPanel -
                    selectArea.height -
                    flexTableViewModel.sizeScrollBarTop -
                    flexTableViewModel.sizeScrollBarBottom) /
                2.0;
        break;
      case HitAlignment.end:
        top = (flexTableViewModel.heightMainPanel -
            selectArea.height -
            flexTableViewModel.sizeScrollBarBottom);
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
    required this.flexTableViewModel,
    required DragStartDetails details,
    this.onDragCanceled,
    this.xSplitchanger,
    this.ySplitchanger,
  }) {
    xSplitchanger?.evaluateEnd = evaluateEnd;
    ySplitchanger?.evaluateEnd = evaluateEnd;
    flexTableViewModel.modifySplit = true;
  }

  final VoidCallback? onDragCanceled;
  final FlexTableViewModel flexTableViewModel;
  SplitHandler? xSplitchanger;
  SplitHandler? ySplitchanger;
  bool dragEnd = false;

  @override
  void cancel() {
    flexTableViewModel
      ..correctOffScroll(0, 0)
      ..modifySplit = false;
  }

  @override
  void end(TableDragEndDetails details) {
    dragEnd = true;
    flexTableViewModel
      ..correctOffScroll(0, 0)
      ..modifySplit = false;
  }

  void evaluateEnd() {
    if (dragEnd &&
        !(xSplitchanger?.isAnimating() ?? false) &&
        !(ySplitchanger?.isAnimating() ?? false)) {
      flexTableViewModel.correctOffScroll(0, 0);
    }
  }

  @override
  void update(TableDragUpdateDetails details) {
    Offset delta = details.delta;
    Offset position = details.globalPosition;

    xSplitchanger?.update(position.dx, delta.dx, flexTableViewModel.xSplit);
    ySplitchanger?.update(position.dy, delta.dy, flexTableViewModel.ySplit);
  }

  @override
  @mustCallSuper
  void dispose() {
    onDragCanceled?.call();
    xSplitchanger?.dispose();
    ySplitchanger?.dispose();
    flexTableViewModel.modifySplit = false;
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
