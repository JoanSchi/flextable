import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'TableDragDetails.dart';
import 'TableGesture.dart';
import 'TableScroll.dart';
import 'TableScrollable.dart';

class HitAndDrag extends StatefulWidget {
  final HitAndDragDelegate hitAndDragDelegate;
  final Widget? child;

  const HitAndDrag({Key? key, required this.hitAndDragDelegate, this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => HitAndDragState();
}

class HitAndDragState extends State<HitAndDrag> {
  Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};

  var _lastCanDrag = false;
  TableDrag? _drag;
  late HitAndDragDelegate _hitAndDragDelegate;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hitAndDragDelegate = widget.hitAndDragDelegate;
    setCanDrag(true);
  }

  @override
  void didUpdateWidget(HitAndDrag oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hitAndDragDelegate != widget.hitAndDragDelegate) {
      _hitAndDragDelegate = widget.hitAndDragDelegate;
    }
  }

  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
        gestures: _gestureRecognizers,
        child: HitContainer(
          hitDelegate: _hitAndDragDelegate,
          child: widget.child,
        ));
  }

  void setCanDrag(bool canDrag) {
    if (canDrag == _lastCanDrag) return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
    } else {
      _gestureRecognizers = <Type, GestureRecognizerFactory>{
        TableGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<TableGestureRecognizer>(
          () => TableGestureRecognizer(supportedDevices: kTouchLikeDeviceTypes),
          (TableGestureRecognizer instance) {
            instance
              ..onDown = _handleDragDown
              ..selectionDragDirection =
                  ((DragDownDetails details) => TableScrollDirection.both)
              ..onStart = _handleDragStart
              ..onUpdate = _handleDragUpdate
              ..onEnd = _handleDragEnd;
            // ..onCancel = _handleDragCancel;
            // ..minFlingDistance = _physics?.minFlingDistance
            // ..minFlingVelocity = _physics?.minFlingVelocity
            // ..maxFlingVelocity = _physics?.maxFlingVelocity;
          },
        ),
      };
    }
    _lastCanDrag = canDrag;
  }

  void _handleDragStart(DragStartDetails details) {
    _drag = _hitAndDragDelegate.dragSplit(details, disposeDrag);
  }

  void _handleDragDown(DragDownDetails details) {
    _hitAndDragDelegate.down(details);
  }

  void _handleDragUpdate(TableDragUpdateDetails details) {
    _drag?.update(details);
  }

  void _handleDragEnd(TableDragEndDetails details) {
    _drag?.end(details);
  }

  void disposeDrag() {
    _drag = null;
  }
}

class HitContainer extends SingleChildRenderObjectWidget {
  final HitAndDragDelegate hitDelegate;

  const HitContainer({
    super.key,
    required this.hitDelegate,
    super.child,
  });

  @override
  RenderHitContainer createRenderObject(BuildContext context) {
    return RenderHitContainer(hitDelegate: hitDelegate);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderHitContainer renderObject) {
    renderObject..hitDelegate = hitDelegate;
  }
}

class RenderHitContainer extends RenderProxyBox {
  HitAndDragDelegate _hitDelegate;

  RenderHitContainer({
    RenderBox? child,
    required HitAndDragDelegate hitDelegate,
  })  : _hitDelegate = hitDelegate,
        super(child);

  set hitDelegate(HitAndDragDelegate value) {
    if (value == _hitDelegate) return;
    _hitDelegate = value;
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
  bool hitTestSelf(Offset position) => _hitDelegate.hit(position);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
  }
}

abstract class HitAndDragDelegate {
  TableDrag dragSplit(
      DragStartDetails details, VoidCallback dragCancelCallback);

  down(DragDownDetails details);

  bool hit(Offset position);
}
