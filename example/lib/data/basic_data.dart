import 'package:flextable/FlexTable/TableItems/Cells.dart';
import 'package:flextable/FlexTable/data_flexfable.dart';
import 'package:flextable/FlexTable/tabel_header_viewport.dart';
import 'package:flextable/FlexTable/tabel_panel_viewport.dart';
import 'package:flextable/FlexTable/table_builder.dart';
import 'package:flextable/FlexTable/table_line.dart';
import 'package:flextable/FlexTable/table_model.dart';
import 'package:flextable/FlexTable/table_tools.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class BasicTable {
  late DataFlexTableBase data;
  final int rows;
  final int columns;

  BasicTable.positions({this.rows = 500, this.columns = 200}) {
    data = DataFlexTable();
    final lineColor = Colors.blueGrey[200]!;

    final h = data.horizontalLineList;
    final lineNodeHorizontalList = h.createLineNodeList();

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        Map attr = {
          'background': (r % 2 + c % 2) % 2 == 0
              ? Colors.white10
              : const Color.fromARGB(255, 140, 191, 237)
        };
        data.addCell(
            row: r, column: c, cell: Cell(value: 'R${r}C$c', attr: attr));
      }
    }

    h.addList(
        startLevelOneIndex: 0,
        endLevelOneIndex: 500,
        lineList: h.createLineNodeList(
            startLevelTwoIndex: 1,
            endLevelTwoIndex: columns,
            lineNode: LineNode(
                left: Line(color: lineColor), right: Line(color: lineColor))));
    h.addList(startLevelOneIndex: 10, lineList: lineNodeHorizontalList);

    final v = data.verticalLineList;

    v.addList(
        startLevelOneIndex: 1,
        endLevelOneIndex: columns,
        lineList: v.createLineNodeList(
            startLevelTwoIndex: 0,
            endLevelTwoIndex: rows,
            lineNode: LineNode(
                bottom: Line(color: lineColor), top: Line(color: lineColor))));

    v.addList(
        startLevelOneIndex: 4,
        endLevelOneIndex: 5,
        lineList: v.createLineNodeList(
            startLevelTwoIndex: 32,
            lineNode: LineNode(
                top: Line(color: lineColor), bottom: const Line.noLine()))
          ..addLineNode(
              startLevelTwoIndex: 33,
              lineNode: LineNode(
                  top: const Line.noLine(), bottom: Line(color: lineColor)))
          ..addLineNode(
              startLevelTwoIndex: 40,
              lineNode: LineNode(
                  top: Line(color: lineColor), bottom: const Line.noLine()))
          ..addLineNode(
              startLevelTwoIndex: 50,
              lineNode: LineNode(
                  top: const Line.noLine(), bottom: Line(color: lineColor))));
  }

  TableModel makeTable(
      {double? xSplit,
      double? ySplit,
      scrollLockX = true,
      scrollLockY = true,
      List<AutoFreezeArea> autoFreezeAreasX = const [],
      List<AutoFreezeArea> autoFreezeAreasY = const []}) {
    double minTableScale = 0.5;
    double maxTableScale = 3.0;
    double tableScale = 1.0;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        minTableScale = 1.0;
        tableScale = 1.5;
        maxTableScale = 4.0;
        break;
    }

    return TableModel(
        stateSplitX: xSplit != null ? SplitState.SPLIT : SplitState.NO_SPLITE,
        stateSplitY: ySplit != null ? SplitState.SPLIT : SplitState.NO_SPLITE,
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
          PropertiesRange(min: 9, max: 9, length: 100.0),
          PropertiesRange(min: 10, max: 15, length: 50.0)
        ],
        dataTable: data);
  }
}

class BasicTableBuilder extends TableBuilder {
  PaintSplitLines paintSplitLines;

  BasicTableBuilder({PaintSplitLines? paintSplitLines})
      : paintSplitLines = paintSplitLines ?? PaintSplitLines();

  @override
  setTableModel(TableModel value) {
    paintSplitLines.tableModel = value;
  }

  @override
  Widget? buildCell(double scale, TableCellIndex tableCellIndex) {
    //RepaintBoundary for canvas layer

    final cell = tableModel.dataTable
        .cell(row: tableCellIndex.row, column: tableCellIndex.column);

    if (cell == null) {
      return null;
    }

    Widget text = Text(
      '${cell.value}',
      style: cell.attr['textStyle'],
      textScaleFactor: scale,
      textAlign: cell.attr['textAlign'],
    );

    if (cell.attr.containsKey('rotate')) {
      text = TableTextRotate(
          angle: math.pi * 2.0 / 360 * cell.attr['rotate'], child: text);
    }

    Widget container = Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0) *
            tableModel.tableScale,
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
  Widget? buildHeaderIndex(double tableScale, double headerScale,
      TableHeaderIndex tableHeaderIndex) {
    if (tableHeaderIndex.panelIndex <= 3 || tableHeaderIndex.panelIndex >= 12) {
      return Center(
        child: Text(
          '${tableHeaderIndex.index + 1}',
          style: const TextStyle(color: Color.fromARGB(255, 38, 77, 95)),
          textScaleFactor:
              (tableScale < headerScale) ? tableScale : headerScale,
        ),
      );
    } else {
      return Center(
        child: Text(
          numberToCharacter(tableHeaderIndex.index),
          style: const TextStyle(color: Color.fromARGB(255, 38, 77, 95)),
          textScaleFactor: headerScale,
        ),
      );
    }
  }

  @override
  LineHeader lineHeader(int panelIndex) {
    return LineHeader(color: const Color.fromARGB(255, 38, 77, 95));
  }

  @override
  drawPaintSplit(PaintingContext context, Offset offset, Size size) {
    paintSplitLines.draw(context, offset, size);
  }
}
