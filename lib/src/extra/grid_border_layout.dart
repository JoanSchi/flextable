// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class GridBorderLayout extends MultiChildRenderObjectWidget {
  const GridBorderLayout({
    Key? key,
    this.maxWidth,
    this.maxHeight,
    this.alignment = Alignment.topLeft,
    List<Widget> children = const <Widget>[],
  }) : super(key: key, children: children);

  final double? maxWidth;
  final double? maxHeight;
  final Alignment alignment;

  @override
  RenderGridBorderLayout createRenderObject(BuildContext context) {
    return RenderGridBorderLayout(
        maxWidth: maxWidth, maxHeight: maxHeight, alignment: alignment);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderGridBorderLayout renderObject) {
    renderObject
      ..maxWidth = maxWidth
      ..maxHeight = maxHeight
      ..alignment = alignment;
  }
}

class RenderGridBorderLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, BorderGridLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, BorderGridLayoutParentData>,
        DebugOverflowIndicatorMixin {
  RenderGridBorderLayout({
    this.maxWidth,
    this.maxHeight,
    required this.alignment,
    List<RenderBox>? children,
  }) {
    addAll(children);
  }

  double? maxWidth;
  double? maxHeight;
  Alignment alignment;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! BorderGridLayoutParentData) {
      child.parentData = BorderGridLayoutParentData();
    }
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
    return intrinsicLength(
        (RenderBox child) => child.getMaxIntrinsicWidth(height));
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return intrinsicLength(
        (RenderBox child) => child.getMaxIntrinsicHeight(width));
  }

  double intrinsicLength(var intrinsic) {
    RenderBox? child = firstChild;
    double lenght = 0.0;

    while (child != null) {
      final BorderGridLayoutParentData childParentData =
          child.parentData! as BorderGridLayoutParentData;
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
      final BorderGridLayoutParentData childParentData =
          child.parentData! as BorderGridLayoutParentData;
      int column = childParentData.column;
      int row = childParentData.row;
      _Grid layoutItemY = yValues[row];
      _Grid layoutItemX = xValues[column];

      layoutItemY.inUse = true;
      layoutItemX.inUse = true;
      layoutItemY.squeezeRatio = childParentData.squeezeRatio;

      if (childParentData.measureHeight) {
        final childHeigth = child.getMaxIntrinsicHeight(width);
        layoutItemY.length = childHeigth;
        layoutItemY.measured = true;
      }

      if (childParentData.measureWidth) {
        final childWidth = child.getMaxIntrinsicWidth(height);
        layoutItemX.length = childWidth;
        layoutItemX.measured = true;
      }

      child = childParentData.nextSibling;
    }

    _calculateLength(gridList: yValues, length: height, name: 'y');
    _calculateLength(gridList: xValues, length: width, name: 'x');

    child = firstChild;

    while (child != null) {
      final BorderGridLayoutParentData childParentData =
          child.parentData! as BorderGridLayoutParentData;
      childParentData.offset = Offset(
          positionX + xValues[childParentData.column].possition,
          positionY + yValues[childParentData.row].possition);

      final widthChild = xValues[childParentData.lastColumn].endPosition -
          xValues[childParentData.column].possition;

      final heightChild = yValues[childParentData.lastRow].endPosition -
          yValues[childParentData.row].possition;

      child
          .layout(BoxConstraints(maxWidth: widthChild, maxHeight: heightChild));
      child = childParentData.nextSibling;
    }
  }

  _calculateLength(
      {required List<_Grid> gridList, required double length, name = ''}) {
    double measuredLength = 0.0;
    int itemsNotMeasered = 0;
    double sumSqueezes = 0.0;
    double notMeasuredSqueenzes = 0.0;

    for (var element in gridList) {
      measuredLength += element.length;
      if (element.inUseNotMeasured) {
        itemsNotMeasered += 1;
        notMeasuredSqueenzes += element.squeezeRatio;
      }
      sumSqueezes += element.squeezeRatio;
    }

    double ratio =
        (length < measuredLength * sumSqueezes / notMeasuredSqueenzes)
            ? length / measuredLength / 2.0
            : 1.0;

    double lengthItem = (itemsNotMeasered > 0 && length > 0.0)
        ? (length - measuredLength * ratio) / itemsNotMeasered
        : 0.0;

    assert(lengthItem >= 0.0);

    double totalLenght = 0.0;
    for (var element in gridList) {
      double length = 0.0;

      if (element.measured) {
        length = element.length * ratio;
      } else if (element.inUseNotMeasured) {
        length = lengthItem;
      }

      element.possition = totalLenght;
      element.length = length;
      totalLenght += length;
    }

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

// class BorderLayoutPosition {
//   final int row;
//   final int column;
//   final int rows;
//   final int columns;
//   final bool measureHeight;
//   final bool measureWidth;
//   final double? squeezeRatio;

//   BorderLayoutPosition(
//       {required this.row,
//       required this.column,
//       this.rows = 1,
//       this.columns = 1,
//       this.measureHeight = false,
//       this.measureWidth = false,
//       this.squeezeRatio});

//   const BorderLayoutPosition.table(
//       {this.row = 1,
//       this.column = 1,
//       this.rows = 1,
//       this.columns = 1,
//       this.measureHeight = false,
//       this.measureWidth = false,
//       this.squeezeRatio = 2.0});

//   const BorderLayoutPosition.bottom(
//       {this.row = 2,
//       this.column = 1,
//       this.rows = 1,
//       this.columns = 1,
//       this.measureHeight = true,
//       this.measureWidth = false,
//       this.squeezeRatio = 1.0});

//   int get lastRow => row + rows - 1;

//   int get lastColumn => column + columns - 1;
// }

class BorderGridLayoutParentData extends ContainerBoxParentData<RenderBox> {
  BorderGridLayoutParentData(
      {this.row = 1,
      this.column = 1,
      this.rows = 1,
      this.columns = 1,
      this.measureHeight = false,
      this.measureWidth = false,
      this.squeezeRatio = 2.0});

  int row;
  int column;
  int rows;
  int columns;
  bool measureHeight;
  bool measureWidth;
  double? squeezeRatio;

  int get lastRow => row + rows - 1;

  int get lastColumn => column + columns - 1;
}

class GridBorderLayoutPosition
    extends ParentDataWidget<BorderGridLayoutParentData> {
  const GridBorderLayoutPosition({
    Key? key,
    this.row = 1,
    this.column = 1,
    this.rows = 1,
    this.columns = 1,
    this.measureHeight = false,
    this.measureWidth = false,
    this.squeezeRatio = 2.0,
    required Widget child,
  }) : super(key: key, child: child);

  final int row;
  final int column;
  final int rows;
  final int columns;
  final bool measureHeight;
  final bool measureWidth;
  final double? squeezeRatio;

  @override
  void applyParentData(RenderObject renderObject) {
    assert(renderObject.parentData is BorderGridLayoutParentData);
    final parentData = renderObject.parentData! as BorderGridLayoutParentData;
    bool needsLayout = false;

    if (parentData.row != row) {
      parentData.row = row;
      needsLayout = true;
    }
    if (parentData.rows != rows) {
      parentData.rows = rows;
      needsLayout = true;
    }

    if (parentData.column != column) {
      parentData.column = column;
      needsLayout = true;
    }

    if (parentData.columns != columns) {
      parentData.columns = columns;
      needsLayout = true;
    }

    if (parentData.measureWidth != measureWidth) {
      parentData.measureWidth = measureWidth;
      needsLayout = true;
    }

    if (parentData.measureHeight != measureHeight) {
      parentData.measureHeight = measureHeight;
      needsLayout = true;
    }

    if (parentData.squeezeRatio != squeezeRatio) {
      parentData.squeezeRatio = squeezeRatio;
      needsLayout = true;
    }

    if (needsLayout) {
      final RenderObject? targetParent = renderObject.parent;
      targetParent?.markNeedsLayout();
    }
  }

  @override
  Type get debugTypicalAncestorWidgetClass => GridBorderLayout;
}
