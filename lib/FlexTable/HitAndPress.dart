import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

abstract class HitAndPressDelegate {
  bool hit(Offset position);

  void onLongPressEnd(LongPressEndDetails end) {}

  void onLongPressStart(LongPressStartDetails onLongPressStart) {}
}

class HitAndPress extends StatefulWidget {
  final HitAndPressDelegate hitAndPressDelegate;
  final Widget child;

  const HitAndPress({Key? key, required this.hitAndPressDelegate, required this.child}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HitAndPressState();
}

class HitAndPressState extends State<HitAndPress> {
  late HitAndPressDelegate _hitAndPressDelegate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hitAndPressDelegate = widget.hitAndPressDelegate;
  }

  @override
  void didUpdateWidget(HitAndPress oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hitAndPressDelegate != widget.hitAndPressDelegate) {
      _hitAndPressDelegate = widget.hitAndPressDelegate;
    }
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HitContainer(
        hitDelegate: _hitAndPressDelegate,
        child: GestureDetector(
          child: widget.child,
          onLongPressStart: _hitAndPressDelegate.onLongPressStart,
        ));
  }
}

class HitContainer extends SingleChildRenderObjectWidget {
  final HitAndPressDelegate hitDelegate;

  const HitContainer({
    Key? key,
    required this.hitDelegate,
    Widget? child,
  }) : super(key: key, child: child);

  @override
  RenderHitContainer createRenderObject(BuildContext context) {
    return RenderHitContainer(hitDelegate: hitDelegate);
  }

  @override
  void updateRenderObject(BuildContext context, RenderHitContainer renderObject) {
    renderObject..hitDelegate = hitDelegate;
  }
}

class RenderHitContainer extends RenderProxyBox {
  HitAndPressDelegate _hitDelegate;

  RenderHitContainer({
    RenderBox? child,
    required HitAndPressDelegate hitDelegate,
  })   : _hitDelegate = hitDelegate,
        super(child);

  set hitDelegate(HitAndPressDelegate value) {
    if (value == _hitDelegate) return;
    _hitDelegate = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (_hitDelegate.hit(position) && hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    return false;
  }

  @override
  void performLayout() {
    if (child != null) {
      final Constraints tight = BoxConstraints.tight(constraints.biggest);
      child!.layout(tight, parentUsesSize: true);
      size = child!.size;
    } else {
      size = computeSizeForNoChild(constraints);
    }
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}
