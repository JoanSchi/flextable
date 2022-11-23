import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class AlignTable extends SingleChildRenderObjectWidget {
  /// Creates an alignment widget.
  ///
  /// The alignment defaults to [Alignment.center].
  const AlignTable({
    Key? key,
    this.alignment = Alignment.center,
    required Widget child,
  }) : super(key: key, child: child);

  final AlignmentGeometry alignment;

  @override
  RenderTablePositioned createRenderObject(BuildContext context) {
    return RenderTablePositioned(
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderTablePositioned renderObject) {
    renderObject..alignment = alignment;
  }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
  //   properties.add(DoubleProperty('widthFactor', widthFactor, defaultValue: null));
  //   properties.add(DoubleProperty('heightFactor', heightFactor, defaultValue: null));
  // }
}

class RenderTablePositioned extends RenderAligningShiftedBox {
  /// Creates a render object that positions its child.
  RenderTablePositioned({
    RenderBox? child,
    AlignmentGeometry alignment = Alignment.center,
    TextDirection? textDirection,
  }) : super(child: child, alignment: alignment, textDirection: textDirection);

  // @override
  // Size computeDryLayout(BoxConstraints constraints) {
  //   final bool shrinkWrapWidth = _widthFactor != null || constraints.maxWidth == double.infinity;
  //   final bool shrinkWrapHeight = _heightFactor != null || constraints.maxHeight == double.infinity;
  //   if (child != null) {
  //     final Size childSize = child!.getDryLayout(constraints.loosen());
  //     return constraints.constrain(
  //       Size(shrinkWrapWidth ? childSize.width * (_widthFactor ?? 1.0) : double.infinity,
  //           shrinkWrapHeight ? childSize.height * (_heightFactor ?? 1.0) : double.infinity),
  //     );
  //   }
  //   return constraints.constrain(Size(
  //     shrinkWrapWidth ? 0.0 : double.infinity,
  //     shrinkWrapHeight ? 0.0 : double.infinity,
  //   ));
  // }

  @override
  void performLayout() {
    final BoxConstraints constraints = this.constraints;

    final tableheight = child!.getMaxIntrinsicHeight(constraints.maxWidth);
    final tableWidth = child!.getMaxIntrinsicWidth(constraints.maxHeight);

    final tableConstraints = constraints.loosen().tighten(width: tableWidth, height: tableheight);

    print('constraints $constraints tablewidth $tableWidth tableHeight $tableheight tableConstrains $tableConstraints');

    if (child != null) {
      child!.layout(tableConstraints, parentUsesSize: true);
      size = constraints.biggest;
      alignChild();
    } else {
      size = constraints.constrain(Size.zero);
    }
  }

  // @override
  // void debugPaintSize(PaintingContext context, Offset offset) {
  //   super.debugPaintSize(context, offset);
  //   assert(() {
  //     final Paint paint;
  //     if (child != null && !child!.size.isEmpty) {
  //       final Path path;
  //       paint = Paint()
  //         ..style = PaintingStyle.stroke
  //         ..strokeWidth = 1.0
  //         ..color = const Color(0xFFFFFF00);
  //       path = Path();
  //       final BoxParentData childParentData = child!.parentData! as BoxParentData;
  //       if (childParentData.offset.dy > 0.0) {
  //         // vertical alignment arrows
  //         final double headSize = math.min(childParentData.offset.dy * 0.2, 10.0);
  //         path
  //           ..moveTo(offset.dx + size.width / 2.0, offset.dy)
  //           ..relativeLineTo(0.0, childParentData.offset.dy - headSize)
  //           ..relativeLineTo(headSize, 0.0)
  //           ..relativeLineTo(-headSize, headSize)
  //           ..relativeLineTo(-headSize, -headSize)
  //           ..relativeLineTo(headSize, 0.0)
  //           ..moveTo(offset.dx + size.width / 2.0, offset.dy + size.height)
  //           ..relativeLineTo(0.0, -childParentData.offset.dy + headSize)
  //           ..relativeLineTo(headSize, 0.0)
  //           ..relativeLineTo(-headSize, -headSize)
  //           ..relativeLineTo(-headSize, headSize)
  //           ..relativeLineTo(headSize, 0.0);
  //         context.canvas.drawPath(path, paint);
  //       }
  //       if (childParentData.offset.dx > 0.0) {
  //         // horizontal alignment arrows
  //         final double headSize = math.min(childParentData.offset.dx * 0.2, 10.0);
  //         path
  //           ..moveTo(offset.dx, offset.dy + size.height / 2.0)
  //           ..relativeLineTo(childParentData.offset.dx - headSize, 0.0)
  //           ..relativeLineTo(0.0, headSize)
  //           ..relativeLineTo(headSize, -headSize)
  //           ..relativeLineTo(-headSize, -headSize)
  //           ..relativeLineTo(0.0, headSize)
  //           ..moveTo(offset.dx + size.width, offset.dy + size.height / 2.0)
  //           ..relativeLineTo(-childParentData.offset.dx + headSize, 0.0)
  //           ..relativeLineTo(0.0, headSize)
  //           ..relativeLineTo(-headSize, -headSize)
  //           ..relativeLineTo(headSize, -headSize)
  //           ..relativeLineTo(0.0, headSize);
  //         context.canvas.drawPath(path, paint);
  //       }
  //     } else {
  //       paint = Paint()..color = const Color(0x90909090);
  //       context.canvas.drawRect(offset & size, paint);
  //     }
  //     return true;
  //   }());
  // }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    // properties.add(DoubleProperty('widthFactor', _widthFactor, ifNull: 'expand'));
    // properties.add(DoubleProperty('heightFactor', _heightFactor, ifNull: 'expand'));
  }
}
