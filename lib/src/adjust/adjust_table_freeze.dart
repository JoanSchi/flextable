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

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flextable/src/hit_test/hit_container.dart';
import '../model/model.dart';
import '../model/properties/flextable_freeze_change.dart';
import '../model/view_model.dart';

class TableFreeze extends StatefulWidget {
  final FlexTableViewModel flexTableViewModel;
  final FreezeOptions freezeOptions;

  const TableFreeze({
    Key? key,
    required this.flexTableViewModel,
    required this.freezeOptions,
  }) : super(key: key);

  @override
  State<TableFreeze> createState() => _TableFreezeState();
}

class _TableFreezeState extends State<TableFreeze>
    with SingleTickerProviderStateMixin {
  FreezeChange freezeChange = FreezeChange();
  late AnimationController _controller;
  Offset pressPosition = Offset.zero;
  Color freezeColor = Colors.blue[700]!;
  Color unFreezeColor = Colors.blueGrey[100]!;
  late FreezeLinePainter _freezeLinePainter;

  @override
  void initState() {
    _controller = AnimationController(
        value: isFrozen() ? 1.0 : 0.0,
        vsync: this,
        duration: const Duration(milliseconds: 300));

    _freezeLinePainter = FreezeLinePainter(
      lineWidth: widget.flexTableViewModel.ftm.spaceSplitFreeze,
      freezeColor: freezeColor,
      unFreezeColor: unFreezeColor,
      hitTestTable: (Offset position) => widget.flexTableViewModel.hitFreeze(
        position,
        kSlope: widget.freezeOptions.freezeSlope,
      ),
      animation: _controller.view,
      freezeChange: freezeChange,
    );

    super.initState();
  }

  @override
  void didUpdateWidget(TableFreeze oldWidget) {
    _freezeLinePainter
      ..freezeChange = freezeChange
      ..freezeColor = freezeColor
      ..unFreezeColor = unFreezeColor
      ..lineWidth = widget.flexTableViewModel.ftm.spaceSplitFreeze
      ..freezeColor = freezeColor
      ..unFreezeColor = unFreezeColor;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _freezeLinePainter.dispose();
    _controller.dispose();
    super.dispose();
  }

  void updateFreezeLinePainter() {}

  bool isFrozen() {
    final ftm = widget.flexTableViewModel.ftm;
    return ftm.stateSplitX == SplitState.freezeSplit ||
        ftm.stateSplitY == SplitState.freezeSplit;
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _freezeLinePainter,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPressStart: (LongPressStartDetails details) =>
            pressPosition = details.localPosition,
        onLongPress: () => changeFreeze(),
      ),
    );
  }

  void changeFreeze() {
    if (_controller.isAnimating) return;

    _freezeLinePainter.freezeChange = freezeChange = widget.flexTableViewModel
        .hitFreezeSplit(pressPosition, widget.freezeOptions.freezeSlope);

    if (freezeChange.action == FreezeAction.freeze) {
      _controller.forward().then((value) => endOfAnimation());
    } else {
      _controller.reverse().then((value) => endOfAnimation());
    }
  }

  endOfAnimation() {
    widget.flexTableViewModel.freezeByPosition(freezeChange);

    if (freezeChange.action == FreezeAction.unFreeze) {
      widget.flexTableViewModel.scheduleCorrectOffScroll = true;
    }
    widget.flexTableViewModel.markNeedsLayout();

    freezeChange = FreezeChange();
  }
}

class FreezeLinePainter extends CustomPainter with ChangeNotifier {
  double lineWidth;
  Color freezeColor;
  Color unFreezeColor;
  FreezeChange freezeChange;
  Animation<double> animation;
  HitTestCallback hitTestTable;

  FreezeLinePainter({
    required this.lineWidth,
    required this.freezeColor,
    required this.unFreezeColor,
    required this.freezeChange,
    required this.animation,
    required this.hitTestTable,
  }) {
    animation.addListener(notifyListeners);
  }

  @override
  void dispose() {
    animation.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    final position = freezeChange.position;

    if (animation.isCompleted ||
        animation.isDismissed ||
        position == Offset.zero) return;

    if (freezeChange.row > 0) {
      double left = position.dx - position.dx * animation.value;
      double right = position.dx + (size.width - position.dx) * animation.value;
      double top = position.dy - lineWidth / 2.0;
      double bottom = top + lineWidth;

      switch (freezeChange.action) {
        case FreezeAction.freeze:
          {
            paint.color = freezeColor;
            canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
            break;
          }
        case FreezeAction.unFreeze:
          {
            paint.color = unFreezeColor;
            canvas.drawRect(Rect.fromLTRB(0.0, top, left, bottom), paint);
            canvas.drawRect(
                Rect.fromLTRB(right, top, size.width, bottom), paint);
            break;
          }
        default:
      }
    }

    if (freezeChange.column > 0) {
      double top = position.dy - position.dy * animation.value;
      double bottom =
          position.dy + (size.height - position.dy) * animation.value;
      double left = position.dx - lineWidth / 2.0;
      double right = left + lineWidth;

      switch (freezeChange.action) {
        case FreezeAction.freeze:
          {
            paint.color = freezeColor;
            canvas.drawRect(Rect.fromLTRB(left, top, right, bottom), paint);
            break;
          }
        case FreezeAction.unFreeze:
          {
            paint.color = unFreezeColor;
            canvas.drawRect(Rect.fromLTRB(left, 0.0, right, top), paint);
            canvas.drawRect(
                Rect.fromLTRB(left, bottom, right, size.height), paint);
            break;
          }
        default:
      }
    }
  }

  @override
  bool shouldRepaint(FreezeLinePainter oldDelegate) {
    return freezeChange.position != oldDelegate.freezeChange.position;
  }

  @override
  bool? hitTest(Offset position) => hitTestTable(position);
}

class FreezeOptions {
  final bool useFreezePosition;
  final double freezeSlope;

  const FreezeOptions({
    this.useFreezePosition = true,
    this.freezeSlope = 32.0,
  });
}
