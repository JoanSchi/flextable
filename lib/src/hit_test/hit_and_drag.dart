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

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import '../gesture_scroll/table_drag_details.dart';
import '../gesture_scroll/table_gesture.dart';
import '../panels/table_view_scrollable.dart';
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
  DeviceGestureSettings? _mediaQueryGestureSettings;

  @override
  void didChangeDependencies() {
    _mediaQueryGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    _hitAndDragDelegate = widget.hitAndDragDelegate;
    setCanDrag(true);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(HitAndDrag oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hitAndDragDelegate != widget.hitAndDragDelegate) {
      _hitAndDragDelegate = widget.hitAndDragDelegate;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
        gestures: _gestureRecognizers,
        child: FlexTableHit(
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
              ..onEnd = _handleDragEnd
              ..gestureSettings = _mediaQueryGestureSettings;
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
