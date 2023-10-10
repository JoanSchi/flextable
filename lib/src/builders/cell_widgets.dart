// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

enum CellAttr {
  textStyle,
  alignment,
  background,
  percentagBackground,
  rotate,
  textAlign
}

class PercentagePainter extends CustomPainter {
  final PercentageBackground percentageBackground;

  PercentagePainter(this.percentageBackground);

  @override
  void paint(Canvas canvas, Size size) {
    double position = 0.0;
    Paint paint = Paint();

    int length = percentageBackground._values.length;
    int colorLength = percentageBackground.colors.length;

    for (int i = 0; i < length; i++) {
      final ratio = percentageBackground._values[i];
      paint.color = percentageBackground.colors[i % colorLength];

      double left, top, right, bottom;

      switch (percentageBackground.axis) {
        case AxisDirection.right:
          {
            left = position;
            position = position + size.width * ratio;
            right = position;
            top = 0.0;
            bottom = size.height;
            break;
          }

        case AxisDirection.left:
          {
            right = size.width - position;
            position = position + size.width * ratio;
            left = size.width - position;
            top = 0.0;
            bottom = size.height;
            break;
          }

        case AxisDirection.up:
          {
            left = 0.0;
            right = size.width;
            bottom = size.height - position;
            position = position + size.height * ratio;
            top = size.height - position;
            break;
          }
        case AxisDirection.down:
          {
            left = 0.0;
            right = size.width;
            top = position;
            position = position + size.height * ratio;
            bottom = position;
            break;
          }
      }
      final rect = Rect.fromLTRB(left, top, right, bottom);

      if (rect.shortestSide >= percentageBackground.minLength) {
        canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
      }
    }
  }

  @override
  bool shouldRepaint(PercentagePainter oldDelegate) {
    return percentageBackground != oldDelegate.percentageBackground;
  }
}

class PercentageBackground {
  final List<Color> colors;
  late final List<double> _values;
  final double minLength;
  final AxisDirection axis;

  PercentageBackground({
    required this.colors,
    List<double>? values,
    double? ratio,
    this.minLength = 0.2,
    this.axis = AxisDirection.right,
  }) {
    assert(
        values != null || ratio != null, 'Both values or value cannot be null');
    assert(!(values != null && ratio != null),
        'Only values or value can be assigned');

    _values = (ratio != null) ? [ratio, 1.0 - ratio] : values!;

    final sum = _values.fold(
        0.0, (double previousValue, element) => previousValue + element);

    if (sum > 1.0) {
      for (int i = 0; i < _values.length; i++) {
        _values[i] = _values[i] / sum;
      }
    }

    assert(
        _values.fold(0.0,
                (double previousValue, element) => previousValue + element) <=
            1.0,
        'The sum of the values cannot be greater than 1.0');
  }

  List<double> get values => _values;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is PercentageBackground &&
        listEquals(other.colors, colors) &&
        other._values == _values &&
        other.minLength == minLength &&
        other.axis == axis;
  }

  @override
  int get hashCode {
    return colors.hashCode ^
        _values.hashCode ^
        minLength.hashCode ^
        axis.hashCode;
  }
}

class TableTextRotate extends SingleChildRenderObjectWidget {
  /// Creates a widget that transforms its child.
  ///
  /// The [transform] argument must not be null.

  TableTextRotate({
    Key? key,
    required this.angle,
    this.origin,
    this.alignment = Alignment.center,
    this.transformHitTests = true,
    Widget? child,
  })  : transform = Matrix4.rotationZ(angle),
        super(key: key, child: child);

  /// The matrix to transform the child by during painting.
  final double angle;
  final Matrix4 transform;
  final Offset? origin;

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as the [origin], both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [Directionality.of] returns
  /// [TextDirection.ltr], and `1.0` if [Directionality.of] returns
  /// [TextDirection.rtl].	 Similarly [AlignmentDirectional.centerEnd] is the
  /// same as an [Alignment] whose [Alignment.x] value is `1.0` if
  /// [Directionality.of] returns	 [TextDirection.ltr], and `-1.0` if
  /// [Directionality.of] returns [TextDirection.rtl].
  final AlignmentGeometry? alignment;

  /// Whether to apply the transformation when performing hit tests.
  final bool transformHitTests;

  @override
  RenderTableTextRotate createRenderObject(BuildContext context) {
    return RenderTableTextRotate(
      transform: transform,
      origin: origin,
      alignment: alignment,
      angle: angle,
      textDirection: Directionality.maybeOf(context),
      transformHitTests: transformHitTests,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderTableTextRotate renderObject) {
    renderObject
      ..transform = transform
      ..origin = origin
      ..alignment = alignment
      ..angle = angle
      ..textDirection = Directionality.maybeOf(context)
      ..transformHitTests = transformHitTests;
  }
}

class RenderTableTextRotate extends RenderProxyBox {
  /// Creates a render object that transforms its child.
  ///
  /// The [transform] argument must not be null.
  RenderTableTextRotate({
    required Matrix4 transform,
    Offset? origin,
    AlignmentGeometry? alignment,
    TextDirection? textDirection,
    this.transformHitTests = true,
    required this.angle,
    RenderBox? child,
  }) : super(child) {
    this.transform = transform;
    this.alignment = alignment;
    this.textDirection = textDirection;
    this.origin = origin;
  }

  double angle = 0.0;
  static const perpendicularAngle = [
    -math.pi / 2.0,
    math.pi / 2.0,
    math.pi / 4.0 * 3.0
  ];

  /// The origin of the coordinate system (relative to the upper left corner of
  /// this render object) in which to apply the matrix.
  ///
  /// Setting an origin is equivalent to conjugating the transform matrix by a
  /// translation. This property is provided just for convenience.
  Offset? get origin => _origin;
  Offset? _origin;
  set origin(Offset? value) {
    if (_origin == value) return;
    _origin = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  debugAssertDoesMeetConstraints() {}

  /// The alignment of the origin, relative to the size of the box.
  ///
  /// This is equivalent to setting an origin based on the size of the box.
  /// If it is specified at the same time as an offset, both are applied.
  ///
  /// An [AlignmentDirectional.centerStart] value is the same as an [Alignment]
  /// whose [Alignment.x] value is `-1.0` if [textDirection] is
  /// [TextDirection.ltr], and `1.0` if [textDirection] is [TextDirection.rtl].
  /// Similarly [AlignmentDirectional.centerEnd] is the same as an [Alignment]
  /// whose [Alignment.x] value is `1.0` if [textDirection] is
  /// [TextDirection.ltr], and `-1.0` if [textDirection] is [TextDirection.rtl].
  AlignmentGeometry? get alignment => _alignment;
  AlignmentGeometry? _alignment;
  set alignment(AlignmentGeometry? value) {
    if (_alignment == value) return;
    _alignment = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// The text direction with which to resolve [alignment].
  ///
  /// This may be changed to null, but only after [alignment] has been changed
  /// to a value that does not depend on the direction.
  TextDirection? get textDirection => _textDirection;
  TextDirection? _textDirection;
  set textDirection(TextDirection? value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  /// When set to true, hit tests are performed based on the position of the
  /// child as it is painted. When set to false, hit tests are performed
  /// ignoring the transformation.
  ///
  /// [applyPaintTransform], and therefore [localToGlobal] and [globalToLocal],
  /// always honor the transformation, regardless of the value of this property.
  bool transformHitTests;

  // Note the lack of a getter for transform because Matrix4 is not immutable
  Matrix4? _transform;

  /// The matrix to transform the child by during painting.
  set transform(Matrix4 value) {
    if (_transform == value) return;
    _transform = Matrix4.copy(value);
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  void setIdentity() {
    _transform!.setIdentity();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  Matrix4? get _effectiveTransform {
    final Alignment? resolvedAlignment = alignment?.resolve(textDirection);
    if (_origin == null && resolvedAlignment == null) return _transform;
    final Matrix4 result = Matrix4.identity();
    if (_origin != null) result.translate(_origin!.dx, _origin!.dy);
    Offset? translation;
    if (resolvedAlignment != null) {
      translation = resolvedAlignment.alongSize(size);
      result.translate(translation.dx, translation.dy);
    }
    result.multiply(_transform!);
    if (resolvedAlignment != null) {
      result.translate(-translation!.dx, -translation.dy);
    }
    if (_origin != null) result.translate(-_origin!.dx, -_origin!.dy);
    return result;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // RenderTransform objects don't check if they are
    // themselves hit, because it's confusing to think about
    // how the untransformed size and the child's transformed
    // position interact.
    return hitTestChildren(result, position: position);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    assert(!transformHitTests || _effectiveTransform != null);
    return result.addWithPaintTransform(
      transform: transformHitTests ? _effectiveTransform : null,
      position: position,
      hitTest: (BoxHitTestResult result, Offset? position) {
        return super.hitTestChildren(result, position: position!);
      },
    );
  }

  @override
  void performLayout() {
    if (child != null) {
      BoxConstraints adjustedConstraints = constraints;

      for (double r in perpendicularAngle) {
        if (r == angle) {
          adjustedConstraints = constraints.flipped;
          break;
        }
      }
      child!.layout(adjustedConstraints, parentUsesSize: true);
      size = child!.size;
    } else {
      size = computeSizeForNoChild(constraints);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child != null) {
      final Matrix4 transform = _effectiveTransform!;
      final Offset? childOffset = MatrixUtils.getAsTranslation(transform);
      if (childOffset == null) {
        layer = context.pushTransform(
          needsCompositing,
          offset,
          transform,
          super.paint,
          oldLayer: layer as TransformLayer?,
        );
      } else {
        super.paint(context, offset + childOffset);
        layer = null;
      }
    }
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.multiply(_effectiveTransform!);
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(TransformProperty('transform matrix', _transform));
    properties.add(DiagnosticsProperty<Offset>('origin', origin));
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties
        .add(DiagnosticsProperty<bool>('transformHitTests', transformHitTests));
  }
}
