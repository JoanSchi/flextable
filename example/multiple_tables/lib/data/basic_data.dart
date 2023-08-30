// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BasicTable {
  late AbstractFlexTableDataModel data;
  final int rows;
  final int columns;

  BasicTable.positions({this.rows = 500, this.columns = 200}) {
    data = FlexTableDataModel();
    final lineColor = Colors.blue[900]!;

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        Map attr = {
          CellAttr.textStyle: (r % 2 + c % 2) % 2 == 0
              ? Colors.white10
              : const Color.fromARGB(255, 140, 191, 237)
        };
        data.addCell(
            row: r,
            column: c,
            cell: Cell(value: '${numberToCharacter(c)}r', attr: attr));
      }
    }

    data.horizontalLineList
        .createLineRange((requestLineRangeModelIndex, requestModelIndex) {
      return LineRange(
          startIndex: requestLineRangeModelIndex(0),
          endIndex: requestLineRangeModelIndex(rows),
          lineNodeRange:
              LineNodeRange(requestNewIndex: requestModelIndex, lineNodes: [
            LineNode(
                startIndex: requestModelIndex(1),
                endIndex: requestModelIndex(columns),
                before: Line(color: lineColor),
                after: Line(color: lineColor))
          ]));
    });

    data.verticalLineList.createLineRange(
        (requestLineRangeModelIndex, requestModelIndex) => LineRange(
            startIndex: requestLineRangeModelIndex(1),
            endIndex: requestLineRangeModelIndex(rows),
            lineNodeRange:
                LineNodeRange(requestNewIndex: requestModelIndex, lineNodes: [
              LineNode(
                  startIndex: requestModelIndex(0),
                  endIndex: requestModelIndex(rows),
                  after: Line(color: lineColor),
                  before: Line(color: lineColor))
            ])));
  }

  FlexTableModel makeTable(
      {double? xSplit,
      double? ySplit,
      scrollLockX = true,
      scrollLockY = true,
      List<AutoFreezeArea> autoFreezeAreasX = const [],
      List<AutoFreezeArea> autoFreezeAreasY = const []}) {
    var (tableScale, minTableScale, maxTableScale) =
        switch (defaultTargetPlatform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        (1.5, 1.0, 4.0),
      (_) => (1.0, 0.5, 3.0)
    };

    return FlexTableModel(
        stateSplitX: xSplit != null ? SplitState.split : SplitState.noSplit,
        stateSplitY: ySplit != null ? SplitState.split : SplitState.noSplit,
        xSplit: xSplit ?? 0.0,
        ySplit: ySplit ?? 0.0,
        // freezeColumns: 3, freezeRows: 23,
        columnHeader: true,
        rowHeader: true,
        scrollLockX: scrollLockX,
        scrollLockY: scrollLockY,
        defaultWidthCell: 90.0,
        defaultHeightCell: 30.0,
        maximumColumns: columns,
        maximumRows: rows,
        scale: tableScale,
        minTableScale: minTableScale,
        maxTableScale: maxTableScale,
        autoFreezeAreasX: autoFreezeAreasX,
        autoFreezeAreasY: autoFreezeAreasY,
        specificHeight: [
          RangeProperties(min: 9, max: 9, length: 100.0),
          RangeProperties(min: 10, max: 15, length: 50.0)
        ],
        dataTable: data);
  }
}

class BasicTableBuilder extends TableBuilder {
  PaintSplitLines paintSplitLines;

  BasicTableBuilder({PaintSplitLines? paintSplitLines})
      : paintSplitLines = paintSplitLines ?? PaintSplitLines();

  @override
  Widget? buildCell(
      FlexTableModel flexTableModel, TableCellIndex tableCellIndex) {
    //RepaintBoundary for canvas layer

    final cell = flexTableModel.dataTable
        .cell(row: tableCellIndex.row, column: tableCellIndex.column);

    if (cell == null) {
      return null;
    }

    Widget text = Text(
      '${cell.value}',
      style: cell.attr['textStyle'],
      textScaleFactor: flexTableModel.tableScale,
      textAlign: cell.attr['textAlign'],
    );

    if (cell.attr.containsKey('rotate')) {
      text = TableTextRotate(
          angle: math.pi * 2.0 / 360 * cell.attr['rotate'], child: text);
    }

    Widget container = Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0) *
            flexTableModel.tableScale,
        alignment: cell.attr['alignment'] ?? Alignment.center,
        color: cell.attr['background'],
        child: text);

    if (cell.attr.containsKey('percentagBackground')) {
      final pbg = cell.attr['percentagBackground'] as PercentageBackground;
      return CustomPaint(
        painter: PercentagePainter(pbg),
        child: container,
      );
    } else {
      return container;
    }
  }

  @override
  Widget backgroundPanel(int panelIndex, Widget? child) {
    // Color color;

    // TablePanelLayoutIndex tpli = _tableModel.layoutIndex(panelIndex);
    // final iX = tpli.xIndex;
    // final iY = tpli.yIndex;

    // if (iX % 3 == 0) {
    //   color = Colors.lightBlue[(iY + iX % 2) % 2 * 100 + 200]!;
    // } else if (iY % 3 == 0) {
    //   color = Colors.lightBlue[(iX + iY % 2) % 2 * 100 + 200]!;
    // } else {
    //   color = Colors.grey[50] ?? Colors.white;
    // }

    if (panelIndex == 5 ||
        panelIndex == 6 ||
        panelIndex == 9 ||
        panelIndex == 10) {
      return Container(child: child);
    } else {
      return Container(
          color: const Color.fromARGB(255, 193, 225, 240), child: child);
    }
  }

  @override
  Widget? buildHeaderIndex(
      FlexTableModel flexTableModel, TableHeaderIndex tableHeaderIndex) {
    if (tableHeaderIndex.panelIndex <= 3 || tableHeaderIndex.panelIndex >= 12) {
      return Center(
        child: Text(
          '${tableHeaderIndex.index + 1}',
          style: const TextStyle(color: Color.fromARGB(255, 38, 77, 95)),
          textScaleFactor:
              (flexTableModel.tableScale < flexTableModel.scaleColumnHeader)
                  ? flexTableModel.tableScale
                  : flexTableModel.scaleColumnHeader,
        ),
      );
    } else {
      return Center(
        child: Text(
          numberToCharacter(tableHeaderIndex.index),
          style: const TextStyle(color: Color.fromARGB(255, 38, 77, 95)),
          textScaleFactor: flexTableModel.scaleRowHeader,
        ),
      );
    }
  }

  @override
  LineHeader lineHeader(FlexTableViewModel flexTableViewModel, int panelIndex) {
    return LineHeader(color: const Color.fromARGB(255, 38, 77, 95));
  }

  @override
  drawPaintSplit(FlexTableViewModel flexTableViewModel, PaintingContext context,
      Offset offset, Size size) {
    paintSplitLines.draw(flexTableViewModel, context, offset, size);
  }
}
