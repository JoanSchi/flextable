import 'package:flutter/widgets.dart';
import 'table_drag_details.dart';
import 'table_gesture.dart';
import 'table_scroll.dart';
import 'table_scrollable.dart';
import 'hit_container.dart';

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

  bool _lastCanDrag = false;
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
          hit: _hitAndDragDelegate.hit,
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
    _drag = _hitAndDragDelegate.drag(details, disposeDrag);
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

abstract class HitAndDragDelegate {
  TableDrag drag(DragStartDetails details, VoidCallback dragCancelCallback);

  down(DragDownDetails details);

  bool hit(Offset position);
}
