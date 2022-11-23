import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'hit_and_drag.dart';
import 'table_drag_details.dart';
import 'table_model.dart';
import 'table_scroll.dart';
import 'table_scroll_activity.dart';

class AdjustTableSplit extends StatefulWidget {
  final TableScrollPosition tableScrollPosition;
  final TableModel tableModel;
  final SplitPositionProperties properties;

  const AdjustTableSplit({
    Key? key,
    required this.tableScrollPosition,
    required this.tableModel,
    required this.properties,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => AdjustTableSplitState();
}

class AdjustTableSplitState extends State<AdjustTableSplit> {
  late SplitPosition _splitPosition;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _splitPosition = SplitPosition(
      tableScrollPosition: widget.tableScrollPosition,
      tableModel: widget.tableModel,
      properties: widget.properties,
    );
  }

  @override
  void didUpdateWidget(AdjustTableSplit oldWidget) {
    super.didUpdateWidget(oldWidget);

    _splitPosition
      ..tableScrollPosition = widget.tableScrollPosition
      ..tableModel = widget.tableModel
      ..properties = widget.properties;
  }

  @override
  Widget build(BuildContext context) {
    return HitAndDrag(
      hitAndDragDelegate: _splitPosition,
    );
  }
}

class SplitPositionProperties {
  final bool useSplitPosition;
  final SelectArea xSplitSelectArea;
  final SelectArea ySplitSelectArea;
  final double marginSplit;

  const SplitPositionProperties(
      {this.useSplitPosition: true,
      this.xSplitSelectArea: const SelectArea(
          width: 50.0, height: 100.0, horizontalAlignment: HitAlignment.start),
      this.ySplitSelectArea: const SelectArea(
          width: 100.0, height: 50.0, horizontalAlignment: HitAlignment.start),
      this.marginSplit: 20.0});
}

class SplitPosition implements HitAndDragDelegate {
  TableModel _tableModel;
  SplitPositionProperties properties;
  TableScrollPosition tableScrollPosition;
  SplitPositionProperties? adjust;

  SplitPosition(
      {required this.tableScrollPosition,
      required TableModel tableModel,
      required this.properties})
      : _tableModel = tableModel;

  dispose() {}

  TableModel get tableModel => _tableModel;

  set tableModel(TableModel value) {
    if (value != _tableModel) {
      _tableModel = value;
    }
  }

  List<GridLayout> get _layoutX => tableModel.widthLayoutList;

  List<GridLayout> get _layoutY => tableModel.heightLayoutList;

  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback) {
    var hitSplit = (
        {required SplitState splitState,
        required GridLayout layout2,
        required SelectArea area,
        required Offset position,
        required Function(Offset) splitPosition}) {
      if ((noSplit(splitState) || splitState == SplitState.AUTO_FREEZE_SPLIT) &&
          area.contains(tableModel, position)) {
        return SplitChange.start;
      } else if (splitState == SplitState.SPLIT &&
          hitExistingSplit(layout2, splitPosition(position))) {
        return SplitChange.edit;
      } else {
        return SplitChange.no;
      }
    };

    final localPosition = details.localPosition;

    SplitChange xSplitChange = hitSplit(
        splitState: tableModel.stateSplitX,
        layout2: _layoutX[2],
        area: properties.xSplitSelectArea,
        position: localPosition,
        splitPosition: (position) => localPosition.dx);

    SplitChange ySplitChange = hitSplit(
        splitState: tableModel.stateSplitY,
        layout2: _layoutY[2],
        area: properties.ySplitSelectArea,
        position: localPosition,
        splitPosition: (position) => localPosition.dy);

    final SplitDragController drag = SplitDragController(
      delegate: tableScrollPosition,
      details: details,
      onDragCanceled: dragCancelCallback,
      xSplitchanger:
          tableModel.tableScrollDirection == TableScrollDirection.vertical
              ? SplitHandler()
              : SplitChanger(
                  position: localPosition.dx,
                  change: xSplitChange,
                  vsync: tableScrollPosition.context.vsync,
                  setSplit: applySplitX,
                  startTable: () => tableModel.initiateSplitLeft,
                  endTable: () => tableModel.initiateSplitRight,
                  initiateSplitAtBegin: tableModel.minimalSplitPositionFromLeft,
                  initiateSplitAtEnd: tableModel.minimalSplitPositionFromRight,
                  changeRatioSize: (double ratio) =>
                      tableModel.ratioSizeAnimatedSplitChangeX = ratio,
                  split: () => tableModel.splitX),
      ySplitchanger:
          tableModel.tableScrollDirection == TableScrollDirection.horizontal
              ? SplitHandler()
              : SplitChanger(
                  position: localPosition.dy,
                  change: ySplitChange,
                  vsync: tableScrollPosition.context.vsync,
                  setSplit: applySplitY,
                  startTable: () => tableModel.initiateSplitTop,
                  endTable: () => tableModel.initiateSplitBottom,
                  initiateSplitAtBegin: tableModel.minimalSplitPositionFromTop,
                  initiateSplitAtEnd: tableModel.minimalSplitPositionFromBottom,
                  changeRatioSize: (double ratio) =>
                      tableModel.ratioSizeAnimatedSplitChangeY = ratio,
                  split: () => tableModel.splitY),
      tableModel: tableModel,
    );

    tableScrollPosition
        .beginActivity(DragTableSplitActivity(tableScrollPosition));

    assert(tableScrollPosition.currentDrag == null);
    tableScrollPosition.currentDrag = drag;

    return drag;
  }

  void applySplitX({double? split, double? delta}) {
    tableModel.setXsplit(
        sizeSplit: split,
        deltaSplit: delta,
        splitView: SplitState.SPLIT,
        animateSplit: true);
    tableModel.markNeedsLayout();
    _tableModel.notifyScrollBarListeners();
  }

  void applySplitY({double? split, double? delta}) {
    tableModel.setYsplit(
        sizeSplit: split,
        deltaSplit: delta,
        splitView: SplitState.SPLIT,
        animateSplit: true);
    tableModel.markNeedsLayout();
    _tableModel.notifyScrollBarListeners();
  }

  bool hit(Offset position) {
    var hitSplit = (
        {required SplitState splitState,
        required GridLayout layout2,
        required SelectArea area,
        required Offset position,
        required Function(Offset) splitPosition,
        required double changeStart,
        required double changeEnd}) {
      final p = splitPosition(position);
      if ((noSplit(splitState) || splitState == SplitState.AUTO_FREEZE_SPLIT) &&
          area.contains(tableModel, position)) {
        return true;
      } else if (splitState == SplitState.SPLIT &&
          p > changeStart &&
          p < changeEnd &&
          hitExistingSplit(layout2, p)) {
        return true;
      } else {
        return false;
      }
    };

    tableModel.minimalSplitPositionFromLeft;
    tableModel.minimalSplitPositionFromRight;

    bool hit = hitSplit(
            splitState: tableModel.stateSplitX,
            layout2: _layoutX[2],
            area: properties.xSplitSelectArea,
            position: position,
            splitPosition: (position) => position.dx,
            changeStart: tableModel.minimalSplitPositionFromLeft,
            changeEnd: tableModel.minimalSplitPositionFromRight) ||
        hitSplit(
            splitState: tableModel.stateSplitY,
            layout2: _layoutY[2],
            area: properties.ySplitSelectArea,
            position: position,
            splitPosition: (position) => position.dy,
            changeStart: tableModel.minimalSplitPositionFromTop,
            changeEnd: tableModel.minimalSplitPositionFromBottom);

    // print('hit split $hit');

    return hit;
  }

  bool hitExistingSplit(GridLayout gridLayout2, double position) {
    return (gridLayout2.inUse &&
        gridLayout2.gridPosition - 25 < position &&
        gridLayout2.gridPosition + 25 > position);
  }

  @override
  down(DragDownDetails details) {}
}

enum HitAlignment { start, center, end }

class SelectArea {
  final double _width;
  final double _height;
  final HitAlignment horizontalAlignment;
  final HitAlignment verticalAlignment;

  const SelectArea(
      {required double width,
      required double height,
      this.horizontalAlignment: HitAlignment.end,
      this.verticalAlignment: HitAlignment.start})
      : _width = width,
        _height = height;

  bool contains(TableModel tableModel, Offset offset) {
    double left, top, bottom, right;

    switch (horizontalAlignment) {
      case HitAlignment.start:
        left = tableModel.sizeScrollBarLeft;
        break;
      case HitAlignment.center:
        left = tableModel.sizeScrollBarLeft +
            (tableModel.widthMainPanel -
                    _width -
                    tableModel.sizeScrollBarLeft -
                    tableModel.sizeScrollBarRight) /
                2.0;
        break;
      case HitAlignment.end:
        left = (tableModel.widthMainPanel -
            tableModel.sizeScrollBarRight -
            _width);
        break;
    }
    right = left + _width;

    switch (verticalAlignment) {
      case HitAlignment.start:
        top = tableModel.sizeScrollBarTop;
        break;
      case HitAlignment.center:
        top = tableModel.sizeScrollBarTop +
            (tableModel.heightMainPanel -
                    _height -
                    tableModel.sizeScrollBarTop -
                    tableModel.sizeScrollBarBottom) /
                2.0;
        break;
      case HitAlignment.end:
        top = (tableModel.heightMainPanel -
            _height -
            tableModel.sizeScrollBarBottom);
        break;
    }
    bottom = top + _height;

    return offset.dx >= left &&
        offset.dx < right &&
        offset.dy >= top &&
        offset.dy < bottom;
  }
}

class DragTableSplitActivity extends TableScrollActivity {
  /// Initializes [delegate] for subclasses.

  DragTableSplitActivity(TableScrollActivityDelegate delegate)
      : super(0, 0, delegate, false);

  void dispose() {
    super.dispose();
  }

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
  final onDragCanceled;
  final TableScrollActivityDelegate _delegate;
  final TableModel tableModel;
  var _lastDetails;
  SplitHandler? xSplitchanger;
  SplitHandler? ySplitchanger;
  bool dragEnd = false;

  SplitDragController({
    required TableScrollActivityDelegate delegate,
    required this.tableModel,
    required DragStartDetails details,
    this.onDragCanceled,
    this.xSplitchanger,
    this.ySplitchanger,
  }) : _delegate = delegate {
    xSplitchanger?.evaluateEnd = evaluateEnd;
    ySplitchanger?.evaluateEnd = evaluateEnd;
    tableModel.changeSplit = true;
  }

  @override
  void cancel() {
    _delegate.correctOffScroll(0, 0);
    tableModel.changeSplit = false;
  }

  @override
  void end(TableDragEndDetails details) {
    dragEnd = true;
    _delegate.correctOffScroll(0, 0);
    tableModel.changeSplit = false;
  }

  void evaluateEnd() {
    // if (dragEnd && !(xSplitchanger?.isAnimating() ?? false) && !(ySplitchanger?.isAnimating() ?? false)) {
    //   _delegate.correctOffScroll(0, 0);
    // }
  }

  @override
  void update(TableDragUpdateDetails details) {
    Offset delta = details.delta;
    Offset position = details.globalPosition;

    xSplitchanger?.update(position.dx, delta.dx, tableModel.xSplit);
    ySplitchanger?.update(position.dy, delta.dy, tableModel.ySplit);
  }

  @mustCallSuper
  void dispose() {
    if (onDragCanceled != null) onDragCanceled();
    xSplitchanger?.dispose();
    ySplitchanger?.dispose();
    tableModel.changeSplit = false;
  }

  @override
  get lastDetails => _lastDetails;
}

enum AnimateSplit { FromBegin, GoToBegin, FromEnd, GoToEnd, NoAnimation }

typedef SetSplit = void Function({double split, double delta});

class SplitHandler {
  VoidCallback evaluateEnd = () => {};

  update(double updatePosition, double updateDelta, double split) {}

  go() {}

  isAnimating() => false;

  dispose() {}
}

class SplitChanger extends SplitHandler {
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
  AnimateSplit animationStatus = AnimateSplit.NoAnimation;
  AnimateSplit lastToNoSplit = AnimateSplit.NoAnimation;
  final changeRatioSize;
  final split;
  double oldAnimationValue = 0.0;

  SplitChanger({
    required this.position,
    required this.startTable,
    required this.endTable,
    required this.initiateSplitAtBegin,
    required this.initiateSplitAtEnd,
    required this.vsync,
    required this.setSplit,
    required this.change,
    required this.changeRatioSize,
    required this.split,
  }) {
    animationController = AnimationController(
        value: split() ? 1.0 : 0.0,
        vsync: vsync,
        duration: Duration(milliseconds: 300))
      ..addListener(go)
      ..addListener(() {
        final value = animationController.value;

        changeRatioSize(value);
      });

    oldAnimationValue = split() ? 1.0 : 0.0;
  }

  update(double updatePosition, double updateDelta, double split) {
    position += updateDelta;

    double delta = 0.0;
    final startTable = this.startTable();
    final endTable = this.endTable();

    switch (change) {
      case SplitChange.start:
        {
          if (position > initiateSplitAtBegin &&
              position < initiateSplitAtEnd) {
            if (position < startTable + (endTable - startTable) / 2.0) {
              animationStatus = AnimateSplit.FromBegin;
              from = startTable;
            } else {
              animationStatus = AnimateSplit.FromEnd;
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
          // print(' V ${animationController.value} ${splitState()}  $splitStatus');
          // print('from $from to $to start $_startTable $_endTable $_startSplit $_endSplit');

          if (position < initiateSplitAtBegin &&
              animationStatus != AnimateSplit.GoToBegin) {
            to = split;
            from = startTable;
            lastToNoSplit = animationStatus = AnimateSplit.GoToBegin;
            animationController.reverse();
          } else if (position > initiateSplitAtEnd &&
              animationStatus != AnimateSplit.GoToEnd) {
            from = endTable;
            to = position;
            lastToNoSplit = animationStatus = AnimateSplit.GoToEnd;
            animationController.reverse();
          } else if (position >= initiateSplitAtBegin &&
              lastToNoSplit == AnimateSplit.GoToBegin &&
              !(animationStatus == AnimateSplit.FromBegin ||
                  animationStatus == AnimateSplit.FromEnd)) {
            from = split > startTable && split < position ? split : startTable;
            to = position;
            animationController.forward();
            animationStatus = AnimateSplit.FromBegin;
            delta = 0;
          } else if (position <= initiateSplitAtEnd &&
              lastToNoSplit == AnimateSplit.GoToEnd &&
              !(animationStatus == AnimateSplit.FromBegin ||
                  animationStatus == AnimateSplit.FromEnd)) {
            from =
                (1.0 < split && split > initiateSplitAtEnd) ? split : endTable;
            to = position;
            animationController.forward();
            animationStatus = AnimateSplit.FromEnd;
            delta = 0;
          } else if (animationController.isAnimating) {
            switch (animationStatus) {
              case AnimateSplit.FromBegin:
                {
                  delta += updateDelta;
                  from = startTable + (delta > 0.0 ? delta : 0.0);
                  to += updateDelta;
                  break;
                }
              case AnimateSplit.FromEnd:
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

  go() {
    final deltaAnimationValue = oldAnimationValue - animationController.value;

    if (deltaAnimationValue != 0.0 && deltaAnimationValue == 1.0) {
      final differents =
          (deltaAnimationValue / animationController.value).abs();
      assert(
          differents < 0.1, 'Differents in animation value > is $differents');
    }

    oldAnimationValue = animationController.value;

    switch (animationStatus) {
      case AnimateSplit.GoToBegin:
        {
          from = startTable();
          break;
        }
      case AnimateSplit.GoToEnd:
        {
          from = endTable();
          break;
        }
      default:
        {}
    }

    setSplit(split: from + (to - from) * animationController.value);

    if (animationController.isCompleted || animationController.isDismissed) {
      animationStatus = AnimateSplit.NoAnimation;
      evaluateEnd();
    }
  }

  isAnimating() => animationController.isAnimating;

  dispose() {
    final status = animationController.status;

    if (status == AnimationStatus.forward) {
      changeRatioSize(1.0);
    } else if (status == AnimationStatus.reverse) {
      changeRatioSize(0.0);
    }

    animationController.dispose();
  }
}
