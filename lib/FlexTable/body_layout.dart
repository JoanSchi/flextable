import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class FlexTableLayout extends MultiChildRenderObjectWidget {
  final double? maxWidth;
  final double? maxHeight;
  final Alignment alignment;

  FlexTableLayout({
    Key? key,
    this.maxWidth,
    this.maxHeight,
    this.alignment = Alignment.topLeft,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  @override
  RenderFlexTableLayout createRenderObject(BuildContext context) {
    return RenderFlexTableLayout(maxWidth: maxWidth, maxHeight: maxHeight, alignment: alignment);
  }

  @override
  void updateRenderObject(BuildContext context, covariant RenderFlexTableLayout renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight
      ..alignment = alignment;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}

class RenderFlexTableLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableLayoutParentData>,
        DebugOverflowIndicatorMixin {
  double? maxWidth;
  double? maxHeight;
  Alignment alignment;

  RenderFlexTableLayout({
    this.maxWidth,
    this.maxHeight,
    required this.alignment,
    List<RenderBox>? children,
  }) {
    addAll(children);
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TableLayoutParentData) child.parentData = TableLayoutParentData();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return intrinsicLength((RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return intrinsicLength((RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  double intrinsicLength(var intrinsic) {
    RenderBox? child = firstChild;
    double lenght = 0.0;

    while (child != null) {
      final TableLayoutParentData childParentData = child.parentData! as TableLayoutParentData;
      lenght += intrinsic(child);
      child = childParentData.nextSibling;
    }
    return lenght;
  }

  // @override
  // Size computeDryLayout(BoxConstraints constraints) {
  //   if (!_canComputeIntrinsics) {
  //     assert(debugCannotComputeDryLayout(
  //       reason: 'Dry layout cannot be computed for CrossAxisAlignment.baseline, which requires a full layout.'
  //     ));
  //     return Size.zero;
  //   }
  //   FlutterError? constraintsError;
  //   assert(() {
  //     constraintsError = _debugCheckConstraints(
  //       constraints: constraints,
  //       reportParentConstraints: false,
  //     );
  //     return true;
  //   }());
  //   if (constraintsError != null) {
  //     assert(debugCannotComputeDryLayout(error: constraintsError));
  //     return Size.zero;
  //   }

  //   final _LayoutSizes sizes = _computeSizes(
  //     layoutChild: ChildLayoutHelper.dryLayoutChild,
  //     constraints: constraints,
  //   );

  //   switch (_direction) {
  //     case Axis.horizontal:
  //       return constraints.constrain(Size(sizes.mainSize, sizes.crossSize));
  //     case Axis.vertical:
  //       return constraints.constrain(Size(sizes.crossSize, sizes.mainSize));
  //   }
  // }

  @override
  void performLayout() {
    RenderBox? child = firstChild;
    size = constraints.biggest;

    List<_Grid> xValues = List.generate(3, (index) => _Grid(), growable: false);
    List<_Grid> yValues = List.generate(3, (index) => _Grid(), growable: false);

    child = firstChild;

    double width = size.width;
    double centerX;

    if (maxWidth != null && maxWidth! < width) {
      centerX = (width - maxWidth!) / 2.0;
      width = maxWidth!;
    } else {
      centerX = 0.0;
    }
    double positionX = centerX + centerX * alignment.x;

    double height = size.height;
    double centerY;

    if (maxHeight != null && maxHeight! < height) {
      centerY = (height - maxHeight!) / 2.0;
      height = maxHeight!;
    } else {
      centerY = 0.0;
    }

    double positionY = centerY = centerY + centerY * alignment.y;

    while (child != null) {
      final TableLayoutParentData childParentData = child.parentData! as TableLayoutParentData;
      int column = childParentData.layout.column;
      int row = childParentData.layout.row;
      _Grid layoutItemY = yValues[row];
      _Grid layoutItemX = xValues[column];

      layoutItemY.inUse = true;
      layoutItemX.inUse = true;
      layoutItemY.squeezeRatio = childParentData.layout.squeezeRatio;

      if (childParentData.layout.measureHeight) {
        final childHeigth = child.getMaxIntrinsicHeight(width);
        layoutItemY.length = childHeigth;
        layoutItemY.measured = true;
      }

      if (childParentData.layout.measureWidth) {
        final childWidth = child.getMaxIntrinsicWidth(height);
        layoutItemX.length = childWidth;
        layoutItemX.measured = true;
      }

      child = childParentData.nextSibling;
    }

    calculateLength(gridList: yValues, length: height, name: 'y');
    calculateLength(gridList: xValues, length: width, name: 'x');

    child = firstChild;

    while (child != null) {
      final TableLayoutParentData childParentData = child.parentData! as TableLayoutParentData;
      childParentData.offset = Offset(positionX + xValues[childParentData.layout.column].possition,
          positionY + yValues[childParentData.layout.row].possition);

      final widthChild =
          xValues[childParentData.layout.lastColumn].endPosition - xValues[childParentData.layout.column].possition;

      final heightChild =
          yValues[childParentData.layout.lastRow].endPosition - yValues[childParentData.layout.row].possition;

      child.layout(BoxConstraints(maxWidth: widthChild, maxHeight: heightChild));
      child = childParentData.nextSibling;
    }
  }

  calculateLength({required List<_Grid> gridList, required double length, name = ''}) {
    double measuredLength = 0.0;
    int itemsNotMeasered = 0;
    double sumSqueezes = 0.0;
    double notMeasuredSqueenzes = 0.0;

    gridList.forEach((element) {
      measuredLength += element.length;
      if (element.inUseNotMeasured) {
        itemsNotMeasered += 1;
        notMeasuredSqueenzes += element.squeezeRatio;
      }
      sumSqueezes += element.squeezeRatio;
    });

    double ratio = (length < measuredLength * sumSqueezes / notMeasuredSqueenzes) ? length / measuredLength / 2.0 : 1.0;

    double lengthItem =
        (itemsNotMeasered > 0 && length > 0.0) ? (length - measuredLength * ratio) / itemsNotMeasered : 0.0;

    assert(lengthItem >= 0.0);

    double totalLenght = 0.0;
    gridList.forEach((element) {
      double length = 0.0;

      if (element.measured) {
        length = element.length * ratio;
      } else if (element.inUseNotMeasured) {
        length = lengthItem;
      }

      element.possition = totalLenght;
      element.length = length;
      totalLenght += length;
    });

    // print('$name layoutList $gridList');

    return totalLenght;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (size.isEmpty) return;

    defaultPaint(context, offset);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}

class _Grid {
  double possition = 0.0;
  double length = 0.0;
  bool inUse = false;
  bool measured = false;
  double? _squeezeRatio;

  get inUseNotMeasured => inUse && !measured;

  double get endPosition => possition + length;

  set squeezeRatio(double? value) {
    if (value != null && value >= (_squeezeRatio ?? 0.0)) {
      _squeezeRatio = value;
    }
  }

  double get squeezeRatio => _squeezeRatio ?? 1.0;

  @override
  String toString() {
    return '_LayoutValues(possition: $possition, length: $length, inUse: $inUse, measured: $measured)';
  }
}

class FlexTableLayoutPosition {
  final int row;
  final int column;
  final int rows;
  final int columns;
  final bool measureHeight;
  final bool measureWidth;
  final double? squeezeRatio;

  FlexTableLayoutPosition(
      {required this.row,
      required this.column,
      this.rows = 1,
      this.columns = 1,
      this.measureHeight = false,
      this.measureWidth = false,
      this.squeezeRatio});

  const FlexTableLayoutPosition.table(
      {this.row = 1,
      this.column = 1,
      this.rows = 1,
      this.columns = 1,
      this.measureHeight = false,
      this.measureWidth = false,
      this.squeezeRatio = 2.0});

  const FlexTableLayoutPosition.bottom(
      {this.row = 2,
      this.column = 1,
      this.rows = 1,
      this.columns = 1,
      this.measureHeight = true,
      this.measureWidth = false,
      this.squeezeRatio = 1.0});

  int get lastRow => row + rows - 1;

  int get lastColumn => column + columns - 1;
}

class TableLayoutParentData extends ContainerBoxParentData<RenderBox> {
  FlexTableLayoutPosition layout = FlexTableLayoutPosition.table();

  @override
  String toString() => '${super.toString()}';
}

class FlexTableLayoutParentDataWidget extends ParentDataWidget<TableLayoutParentData> {
  const FlexTableLayoutParentDataWidget({
    Key? key,
    this.tableLayoutPosition = const FlexTableLayoutPosition.table(),
    required Widget child,
  }) : super(key: key, child: child);

  final FlexTableLayoutPosition tableLayoutPosition;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is TableLayoutParentData);
    final parentData = renderObject.parentData! as TableLayoutParentData;
    bool needsLayout = false;

    if (parentData.layout != tableLayoutPosition) {
      parentData.layout = tableLayoutPosition;
      needsLayout = true;
    }

    if (needsLayout) {
      final AbstractNode? targetParent = renderObject.parent;
      if (targetParent is RenderObject) targetParent.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => Flex;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('FlexTableLayoutPosition', tableLayoutPosition));
  }
}
