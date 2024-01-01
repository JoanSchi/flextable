// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class DefaultTableBuilder extends AbstractTableBuilder<FtModel<Cell>, Cell> {
  DefaultTableBuilder(
      {this.singleDigitWidth = 10.0,
      this.digitPadding = 3.0,
      this.columnHeaderHeight = 20.0,
      this.headerBackgroundColor,
      this.headerLineColor,
      this.headerTextStyle});

  final double singleDigitWidth;
  final double digitPadding;
  @override
  final double columnHeaderHeight;
  final Color? headerBackgroundColor;
  final Color? headerLineColor;
  final TextStyle? headerTextStyle;

  @override
  Widget? cellBuilder(
    BuildContext context,
    FtViewModel<FtModel<Cell>, Cell> viewModel,
    Cell cell,
    LayoutPanelIndex layoutPanelIndex,
    CellIndex tableCellIndex,
  ) {
    Widget text = Text(
      '${cell.value}',
      textAlign: cell.attr[CellAttr.textAlign],
      style: cell.attr[CellAttr.textStyle],
      textScaler: TextScaler.linear(viewModel.tableScale),
    );

    if (cell.attr.containsKey(CellAttr.rotate)) {
      text = TableTextRotate(
          angle: math.pi * 2.0 / 360 * cell.attr[CellAttr.rotate], child: text);
    }

    Widget child = Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0) *
            viewModel.tableScale,
        alignment: cell.attr[CellAttr.alignment] ?? Alignment.center,
        color: cell.attr[CellAttr.background],
        child: text);

    if (cell.attr.containsKey(CellAttr.percentagBackground)) {
      final pbg =
          cell.attr[CellAttr.percentagBackground] as PercentageBackground;
      child = CustomPaint(
        painter: PercentagePainter(pbg),
        child: child,
      );
    } else {
      child = child;
    }

    return cell.addRepaintBoundaries ? RepaintBoundary(child: child) : child;
  }

  @override
  double rowHeaderWidth(HeaderProperties headerProperty) =>
      (headerProperty.digits * singleDigitWidth + digitPadding * 2.0);

  @override
  Widget backgroundPanel(
    BuildContext context,
    int panelIndex,
    Widget? child,
  ) {
    //Background Headers:
    if (headerBackgroundColor != null &&
        (panelIndex <= 3 ||
            panelIndex >= 12 ||
            panelIndex % 4 == 0 ||
            panelIndex % 4 == 3)) {
      return Container(
        color: headerBackgroundColor,
        child: child,
      );
    }
    return child ?? const SizedBox();
  }

  @override
  Widget buildHeaderIndex(BuildContext context, FtModel model,
      TableHeaderIndex tableHeaderIndex, double scale) {
    if (tableHeaderIndex.panelIndex <= 3 || tableHeaderIndex.panelIndex >= 12) {
      return Center(
          child: Text(
        '${tableHeaderIndex.index + 1}',
        textScaler: TextScaler.linear(scale),
        style: headerTextStyle,
      ));
    } else {
      return Center(
          child: Text(numberToCharacter(tableHeaderIndex.index),
              textScaler: TextScaler.linear(scale), style: headerTextStyle));
    }
  }

  @override
  LineHeader lineHeader(FtViewModel viewModel, int panelIndex) {
    //final tpli = viewModel.layoutIndex(panelIndex);

    return LineHeader(color: headerLineColor ?? Colors.blueGrey);
  }

  @override
  void finalPaintMainPanel(FtViewModel<FtModel<Cell>, Cell> viewModel,
      PaintingContext context, Offset offset, Size size) {
    if (viewModel.model.anySplitX || viewModel.model.anySplitY) {
      defaultDrawPaintSplit(
          viewModel: viewModel,
          context: context,
          offset: offset,
          size: size,
          freezeColors: const [
            Color(0xFF016baa),
            Color(0xFF015e96),
            Color(0xFF004d7c)
          ],
          splitColors: const [
            Color(0xFFE0E0E0),
            Color(0xFFD6D6D6),
            Color(0xFF9E9E9E)
          ]);
    }
  }

  @override
  void firstPaintPanel(
      PaintingContext context,
      Offset offset,
      Size size,
      FtViewModel<FtModel<Cell>, Cell> viewModel,
      LayoutPanelIndex tableIndex,
      List<GridInfo> rowInfoList,
      List<GridInfo> columnInfoList) {}

  @override
  void finalPaintPanel(
      PaintingContext context,
      Offset offset,
      Size size,
      FtViewModel<FtModel<Cell>, Cell> viewModel,
      LayoutPanelIndex tableIndex,
      List<GridInfo> rowInfoList,
      List<GridInfo> columnInfoList) {
    Canvas canvas = context.canvas;

    canvas.save();
    int debugPreviousCanvasSaveCount = 0;

    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());

    /// Painting lines
    ///
    ///
    ///
    if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);

    final scrollIndexX = tableIndex.scrollIndexX;
    final scrollIndexY = tableIndex.scrollIndexY;
    final xScroll = viewModel.getScrollX(scrollIndexX, scrollIndexY);
    final yScroll = viewModel.getScrollY(scrollIndexX, scrollIndexY);
    final tableScale = viewModel.tableScale;

    calculateLinePosition(
      canvas: canvas,
      size: size,
      tableIndex: tableIndex,
      scrollIndexX: scrollIndexX,
      scrollIndexY: scrollIndexY,
      xScroll: xScroll,
      yScroll: yScroll,
      tableScale: tableScale,
      lineList: viewModel.model.horizontalLines,
      horizontal: true,
      infoLevelOne: rowInfoList,
      infoLevelTwo: columnInfoList,
    );

    calculateLinePosition(
      canvas: canvas,
      size: size,
      tableIndex: tableIndex,
      scrollIndexX: scrollIndexX,
      scrollIndexY: scrollIndexY,
      xScroll: xScroll,
      yScroll: yScroll,
      tableScale: tableScale,
      lineList: viewModel.model.verticalLines,
      horizontal: false,
      infoLevelOne: columnInfoList,
      infoLevelTwo: rowInfoList,
    );

    /// Custom Painting?
    /// Keep it simple
    ///
    ///
    ///

    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }(), 'Previous canvas count is different from the current canvas count!');

    canvas.restore();
  }
}
