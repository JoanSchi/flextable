import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../flextable.dart';
import 'panel_viewport.dart';
import 'dart:math' as math;

class SliverToTableAdapter extends SingleChildRenderObjectWidget {
  /// Creates a sliver that contains a single box widget.
  const SliverToTableAdapter({
    super.key,
    super.child,
    required this.viewModel,
  });

  final FtViewModel viewModel;

  @override
  void updateRenderObject(
      BuildContext context, RenderSliverToTableAdapter renderObject) {
    renderObject.viewModel = viewModel;
  }

  @override
  RenderSliverToTableAdapter createRenderObject(BuildContext context) =>
      RenderSliverToTableAdapter(viewModel: viewModel);
}

class RenderSliverToTableAdapter extends RenderSliverSingleBoxAdapter {
  /// Creates a [RenderSliver] that wraps a [RenderBox].
  RenderSliverToTableAdapter({
    super.child,
    required this.viewModel,
  });

  FtViewModel viewModel;

  @override
  void performLayout() {
    if (child == null) {
      geometry = SliverGeometry.zero;
      return;
    }

    invokeLayoutCallback((constraints) {
      deepVisit(RenderObject r) {
        r.markNeedsLayout();
        if (r is! TablePanelRenderViewport) {
          r.visitChildren((child) {
            deepVisit(child);
          });
        }
      }

      visitChildren((child) {
        deepVisit(child);
      });
    });

    final SliverConstraints constraints = this.constraints;

    viewModel.setAdapterOffset(constraints.scrollOffset);
    double maxExtent = child!.getMaxIntrinsicHeight(0);

    child!.layout(constraints.asBoxConstraints(maxExtent: maxExtent),
        parentUsesSize: true);
    final double childExtent;
    switch (constraints.axis) {
      case Axis.horizontal:
        childExtent = child!.size.width;
      case Axis.vertical:
        childExtent = child!.size.height;
    }
    final double paintedChildSize =
        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent =
        calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    assert(paintedChildSize.isFinite);
    assert(paintedChildSize >= 0.0);
    geometry = SliverGeometry(
      scrollExtent: childExtent,
      paintExtent: paintedChildSize,
      cacheExtent: cacheExtent,
      maxPaintExtent: childExtent,
      hitTestExtent: paintedChildSize,
      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
          constraints.scrollOffset > 0.0,
    );
    setChildParentData(child!, constraints, geometry!);
  }
}

class VisibleTableArea extends SingleChildRenderObjectWidget {
  const VisibleTableArea({
    super.key,
    required this.viewModel,
    super.child,
  });

  final FtViewModel viewModel;

  @override
  RenderVisibleTableArea createRenderObject(BuildContext context) {
    return RenderVisibleTableArea(
      viewModel: viewModel,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderVisibleTableArea renderObject) {
    renderObject.viewModel = viewModel;
  }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);

  // }
}

class RenderVisibleTableArea extends RenderShiftedBox {
  RenderVisibleTableArea({
    required FtViewModel viewModel,
    RenderBox? child,
  })  : _viewModel = viewModel,
        super(child);

  FtViewModel get viewModel => _viewModel;
  FtViewModel _viewModel;

  set viewModel(FtViewModel value) {
    if (_viewModel == value) {
      return;
    }
    _viewModel = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    if (child != null) {
      return child!.getMinIntrinsicWidth(height);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    if (child != null) {
      return child!.getMaxIntrinsicWidth(height);
    }
    return 0.0;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    if (child != null) {
      return child!.getMinIntrinsicHeight(width);
    }
    return 0.0;
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    if (child != null) {
      return child!.getMaxIntrinsicHeight(width);
    }
    return 0.0;
  }

  @override
  @protected
  Size computeDryLayout(covariant BoxConstraints constraints) {
    if (child == null) {
      return Size.zero;
    }
    final BoxConstraints innerConstraints = constraints;
    final Size childSize = child!.getDryLayout(innerConstraints);
    return constraints.constrain(Size(
      childSize.width,
      childSize.height,
    ));
  }

  @override
  void performLayout() {
    if (child == null) {
      return;
    }
    final BoxConstraints constraints = this.constraints;

    final maxExtent = constraints.maxHeight; // child!.getMaxIntrinsicHeight(0);

    child!.layout(
        BoxConstraints(
            maxWidth: constraints.maxWidth,
            maxHeight: math.max(maxExtent - _viewModel.adapterOffset, 0.0)),
        parentUsesSize: true);
    final BoxParentData childParentData = child!.parentData! as BoxParentData;
    childParentData.offset = Offset(0.0, _viewModel.adapterOffset);
    size = constraints.constrain(Size(constraints.maxWidth, maxExtent));
  }

  // @override
  // void debugPaintSize(PaintingContext context, Offset offset) {
  //   super.debugPaintSize(context, offset);
  //   assert(() {
  //     final Rect outerRect = offset & size;
  //     debugPaintPadding(context.canvas, outerRect,
  //         child != null ? _resolvedPadding!.deflateRect(outerRect) : null);
  //     return true;
  //   }());
  // }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties
  //       .add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', viewModel));
  //   properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
  //       defaultValue: null));
  // }
}
