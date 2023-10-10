// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class FlexTableToSliverBox extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.

  const FlexTableToSliverBox({
    super.key,
    super.child,
    required this.ftController,
    this.maxOverlap,
  });

  final FtController ftController;
  final double? maxOverlap;

  @override
  void updateRenderObject(
      BuildContext context, RenderFlexTableToSliverBox renderObject) {
    renderObject
      ..flexTableController = ftController
      ..maxOverlap = maxOverlap;
  }

  @override
  RenderFlexTableToSliverBox createRenderObject(BuildContext context) =>
      RenderFlexTableToSliverBox(
          flexTableController: ftController, maxOverlap: maxOverlap);
}

class RenderFlexTableToSliverBox extends RenderSliverSingleBoxAdapter {
  RenderFlexTableToSliverBox(
      {super.child, required this.flexTableController, double? maxOverlap})
      : _maxOverlap = maxOverlap;

  FtController flexTableController;
  double? _maxOverlap;

  set maxOverlap(double? value) {
    if (value != _maxOverlap) {
      _maxOverlap = value;
      markNeedsLayout();
    }
  }

  double get _overlap {
    final m = _maxOverlap;

    return (m != null && m < constraints.overlap) ? m : constraints.overlap;
  }

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    // assert(
    //     flexTableController.viewModels.length == 1,
    //     'Only one viewModel should be present in flexTableController, ${flexTableController.viewModels.length} found.'
    //     ' It is however possible that the dettach of the previous is delayed by the microschedule task!');

    final viewModel = flexTableController.lastViewModel();

    if (viewModel.correctSliverOffset != null &&
        viewModel.correctSliverOffset != 0.0) {
      geometry =
          SliverGeometry(scrollOffsetCorrection: viewModel.correctSliverOffset);
      viewModel.correctSliverOffset = null;
      return;
    }

    final SliverConstraints constraints = this.constraints;
    // double min = child!.getMinIntrinsicHeight(0);

    double overlap = _overlap;

    double maxExtent = child!.getMaxIntrinsicHeight(0);

    final double childExtent = maxExtent;

    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);

    // debugPrint(
    //     'maxExtent ${maxExtent.toInt()}paintedChildSize ${paintedChildSize.toInt()}');

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);

    viewModel.setScrollWithSliver(constraints.scrollOffset + overlap);

    // debugPrint(
    //     'constraints.overlap ${constraints.overlap.toInt()} constraints.scrollOffset ${constraints.scrollOffset.toInt()}');

    child!.layout(
        constraints.asBoxConstraints(
            maxExtent:
                clampDouble(paintedChildSize - overlap, 0.0, paintedChildSize)),
        parentUsesSize: true);

    SliverPhysicalParentData childParent =
        child!.parentData as SliverPhysicalParentData;

    childParent.paintOffset = Offset(0.0, overlap);

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
    double delta = _overlap; //childMainAxisPosition(child);
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
