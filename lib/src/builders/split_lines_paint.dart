// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import '../../flextable.dart';

void defaultDrawPaintSplit(
    {required PaintingContext context,
    required Offset offset,
    required Size size,
    required FtViewModel viewModel,
    required List<Color> freezeColors,
    required List<Color> splitColors,
    bool drawLineInside = false}) {
  final w = viewModel.widthLayoutList;
  final h = viewModel.heightLayoutList;

  if (!w[2].inUse && !h[2].inUse) return;

  Canvas canvas = context.canvas;

  canvas.save();
  int debugPreviousCanvasSaveCount = 0;

  assert(() {
    debugPreviousCanvasSaveCount = canvas.getSaveCount();
    return true;
  }());

  if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);

  Paint paint = Paint();
  bool equalSplit = false;

  List<double> x = [
    drawLineInside ? w[1].panelPosition : 0.0,
    w[1].panelEndPosition,
    w[2].panelPosition,
    drawLineInside ? w[2].panelEndPosition : size.width
  ];
  List<double> y = [
    drawLineInside ? h[1].panelPosition : 0.0,
    h[1].panelEndPosition,
    h[2].panelPosition,
    drawLineInside ? h[2].panelEndPosition : size.height
  ];
  final xSplitState = w[2].inUse ? viewModel.stateSplitX : SplitState.noSplit;
  final ySplitState = h[2].inUse ? viewModel.stateSplitY : SplitState.noSplit;

  equalSplit = xSplitState == ySplitState;

  /// Draw Horizontal Split
  ///
  ///
  ///
  ///

  drawHorizontalFill(Canvas canvas, Color color) {
    paint.color = color;
    canvas.drawRect(Rect.fromLTRB(x[0], y[1], x[3], y[2]), paint);
  }

  drawHorizontalLine(Canvas canvas, double y, Color color) {
    paint.color = color;

    if (equalSplit) {
      canvas.drawLine(Offset(x[0], y), Offset(x[1], y), paint);
      canvas.drawLine(Offset(x[2], y), Offset(x[3], y), paint);
    } else {
      canvas.drawLine(Offset(x[0], y), Offset(x[3], y), paint);
    }
  }

  drawHorizontalSplit(
      FtViewModel viewModel, Canvas canvas, SplitState splitState) {
    switch (splitState) {
      case SplitState.autoFreezeSplit:
        {
          drawHorizontalLine(canvas, y[1], freezeColors[1]);
          break;
        }
      case SplitState.freezeSplit:
        {
          drawHorizontalFill(canvas, freezeColors[0]);
          drawHorizontalLine(canvas, y[1], freezeColors[1]);
          drawHorizontalLine(canvas, y[2], freezeColors[2]);

          break;
        }
      case SplitState.split:
        {
          drawHorizontalFill(canvas, splitColors[0]);
          drawHorizontalLine(canvas, y[1], splitColors[1]);
          drawHorizontalLine(canvas, y[2], splitColors[2]);
          break;
        }
      default:
        {}
    }
  }

  /// Draw vertical Split
  ///
  ///
  ///

  drawVerticalFill(Canvas canvas, Color color) {
    paint.color = color;
    canvas.drawRect(Rect.fromLTRB(x[1], y[0], x[2], y[3]), paint);
  }

  drawVerticalLine(canvas, double x, Color color) {
    paint.color = color;

    canvas.drawLine(Offset(x, y[0]), Offset(x, y[1]), paint);

    if (equalSplit) {
      canvas.drawLine(Offset(x, y[0]), Offset(x, y[1]), paint);
      canvas.drawLine(Offset(x, y[2]), Offset(x, y[3]), paint);
    } else {
      canvas.drawLine(Offset(x, y[0]), Offset(x, y[3]), paint);
    }
  }

  drawVerticalSplit(
      FtViewModel viewModel, Canvas canvas, SplitState splitState) {
    switch (splitState) {
      case SplitState.autoFreezeSplit:
        {
          drawVerticalLine(canvas, x[1], freezeColors[1]);
          break;
        }
      case SplitState.freezeSplit:
        {
          drawVerticalFill(canvas, freezeColors[0]);
          drawVerticalLine(canvas, x[1], freezeColors[1]);
          drawVerticalLine(canvas, x[2], freezeColors[2]);

          break;
        }
      case SplitState.split:
        {
          drawVerticalFill(canvas, splitColors[0]);
          drawVerticalLine(canvas, x[1], splitColors[1]);
          drawVerticalLine(canvas, x[2], splitColors[2]);
          break;
        }
      default:
        {}
    }
  }

  ///
  ///
  ///
  ///
  ///

  if (xSplitState == SplitState.split) {
    drawHorizontalSplit(viewModel, canvas, ySplitState);
    drawVerticalSplit(viewModel, canvas, xSplitState);
  } else {
    drawVerticalSplit(viewModel, canvas, xSplitState);
    drawHorizontalSplit(viewModel, canvas, ySplitState);
  }

  assert(() {
    final int debugNewCanvasSaveCount = canvas.getSaveCount();
    return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
  }(), 'Previous canvas count is different from the current canvas count!');

  canvas.restore();
}
