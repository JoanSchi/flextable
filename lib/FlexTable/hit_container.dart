import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef HitCallback = bool Function(Offset position);

class HitContainer extends SingleChildRenderObjectWidget {
  final HitCallback hit;

  const HitContainer({
    Key? key,
    required this.hit,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderHitContainer createRenderObject(BuildContext context) {
    return RenderHitContainer(hit: hit);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderHitContainer renderObject) {
    renderObject..hit = hit;
  }
}

class RenderHitContainer extends RenderProxyBox {
  HitCallback _hit;

  RenderHitContainer({
    RenderBox? child,
    required HitCallback hit,
  })  : _hit = hit,
        super(child);

  set hit(HitCallback value) {
    if (value == _hit) return;
    _hit = value;
  }

  @override
  void performLayout() {
    if (child != null) {
      final Constraints tight = BoxConstraints.tight(constraints.biggest);
      child!.layout(tight, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.biggest;
    }
  }

  // @override
  // bool hitTest(BoxHitTestResult result, {required Offset position}) {
  //   if (_hitDelegate.hit(position) && hitTestChildren(result, position: position)) {
  //     result.add(BoxHitTestEntry(this, position));
  //     return true;
  //   }

  //   return false;
  // }

  @override
  bool hitTestSelf(Offset position) => _hit(position);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
