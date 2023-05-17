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

import 'package:flextable/flextable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FlexTableToSliverBox extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.

  const FlexTableToSliverBox({
    super.key,
    super.child,
    required this.flexTableController,
  });

  final FlexTableController flexTableController;

  @override
  void updateRenderObject(
      BuildContext context, RenderFlexTableToSliverBox renderObject) {
    renderObject.flexTableController = flexTableController;
  }

  @override
  RenderFlexTableToSliverBox createRenderObject(BuildContext context) =>
      RenderFlexTableToSliverBox(flexTableController: flexTableController);
}

class RenderFlexTableToSliverBox extends RenderSliverSingleBoxAdapter {
  FlexTableController flexTableController;

  RenderFlexTableToSliverBox({
    super.child,
    required this.flexTableController,
  });

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    assert(
        flexTableController.viewModels.length == 1,
        'Only one viewModel should be present in flexTableController, ${flexTableController.viewModels.length} found.'
        ' It is however possible that the dettach of the previous is delayed by the microschedule task!');

    final viewModel = flexTableController.viewModels.length > 1
        ? flexTableController.viewModels.last
        : flexTableController.viewModel;

    if (viewModel.correctSliverOffset != null &&
        viewModel.correctSliverOffset != 0.0) {
      geometry =
          SliverGeometry(scrollOffsetCorrection: viewModel.correctSliverOffset);
      viewModel.correctSliverOffset = null;
      return;
    }

    final SliverConstraints constraints = this.constraints;
    // double min = child!.getMinIntrinsicHeight(0);
    double maxExtent = child!.getMaxIntrinsicHeight(0);
    final double childExtent = maxExtent;

    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    flexTableController.viewModel.setScrollWithSliver(constraints.scrollOffset);

    child!.layout(constraints.asBoxConstraints(maxExtent: paintedChildSize),
        parentUsesSize: true);

    SliverPhysicalParentData childParent =
        child!.parentData as SliverPhysicalParentData;

    childParent.paintOffset = Offset.zero;

    geometry = SliverGeometry(
      scrollExtent: maxExtent,
      paintExtent: paintedChildSize,
      cacheExtent: paintedChildSize,
      maxPaintExtent: maxExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow:
          childExtent > maxExtent || constraints.scrollOffset > 0.0,
    );

    //Do not apply setChildParentData, by default child is layout at scrollOffset!!
    // setChildParentData(child!, constraints, geometry!);
  }

  @override
  bool hitTestChildren(SliverHitTestResult result,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    assert(geometry!.hitTestExtent > 0.0);
    if (child != null) {
      return simplyfiedHitTestBoxChild(BoxHitTestResult.wrap(result), child!,
          mainAxisPosition: mainAxisPosition,
          crossAxisPosition: crossAxisPosition);
    }
    return true;
  }

  // Simplified hitTestBoxChild
  bool simplyfiedHitTestBoxChild(BoxHitTestResult result, RenderBox child,
      {required double mainAxisPosition, required double crossAxisPosition}) {
    double delta = 0.0; //childMainAxisPosition(child);
    final double crossAxisDelta = childCrossAxisPosition(child);
    double absolutePosition = mainAxisPosition - delta;
    final double absoluteCrossAxisPosition = crossAxisPosition - crossAxisDelta;
    Offset paintOffset, transformedPosition;

    paintOffset = Offset(crossAxisDelta, delta);
    transformedPosition = Offset(absoluteCrossAxisPosition, absolutePosition);

    return result.addWithOutOfBandPosition(
      paintOffset: paintOffset,
      hitTest: (BoxHitTestResult result) {
        return child.hitTest(result, position: transformedPosition);
      },
    );
  }
}
