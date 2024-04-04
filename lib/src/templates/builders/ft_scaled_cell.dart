// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class FtScaledCell extends StatelessWidget {
  /// Creates a scale transition.
  ///
  /// The [scale] argument must not be null. The [alignment] argument defaults
  /// to [Alignment.center].
  const FtScaledCell({
    super.key,
    required this.scale,
    this.alignment = Alignment.center,
    this.child,
  });

  /// The animation that controls the scale of the child.
  ///
  /// If the current value of the scale animation is v, the child will be
  /// painted v times its normal size.
  final double scale;

  /// The alignment of the origin of the coordinate system in which the scale
  /// takes place, relative to the size of the box.
  ///
  /// For example, to set the origin of the scale to bottom middle, you can use
  /// an alignment of (0.0, 1.0).
  final Alignment alignment;

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final double scaleValue = scale;
    final Matrix4 transform = Matrix4.identity()
      ..scale(scaleValue, scaleValue, 1.0);

    return _ScaledSize(
      scale: scaleValue,
      child: Transform(
        transform: transform,
        alignment: alignment,
        child: child,
      ),
    );
  }
}

class _ScaledSize extends SingleChildRenderObjectWidget {
  const _ScaledSize({
    super.child,
    required this.scale,
  });

  final double scale;

  @override
  _ScaleResizedRender createRenderObject(BuildContext context) {
    return _ScaleResizedRender(scale: scale);
  }

  @override
  void updateRenderObject(
      BuildContext context, _ScaleResizedRender renderObject) {
    renderObject.scale = scale;
  }
}

class _ScaleResizedRender extends RenderShiftedBox {
  _ScaleResizedRender({
    RenderBox? child,
    required double scale,
  })  : _scale = scale,
        super(child);

  double _scale;

  double get scale => _scale;

  set scale(double value) {
    if (_scale == value) return;
    _scale = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! BoxParentData) child.parentData = BoxParentData();
  }

  @override
  void performLayout() {
    if (child != null) {
      Size sizeParent = constraints.biggest;

      Size originalSize =
          Size(sizeParent.width / scale, sizeParent.height / scale);

      child!.layout(BoxConstraints.tight(originalSize), parentUsesSize: true);

      final BoxParentData parentData = child!.parentData as BoxParentData;

      size = sizeParent;

      final offset = center(Offset(sizeParent.width - originalSize.width,
          sizeParent.height - originalSize.height));

      parentData.offset = offset;
    } else {
      size = Size.zero;
    }
  }

  Offset center(Offset other) {
    final double centerX = other.dx / 2.0;
    final double centerY = other.dy / 2.0;
    return Offset(centerX, centerY);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    if (child != null) {
      return child!.getDryLayout(constraints);
    } else {
      return Size.zero;
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<double>('scale', scale));
  }
}
