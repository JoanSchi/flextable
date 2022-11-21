import 'package:flextable/FlexTable/DataFlexTable.dart';
import 'package:flextable/FlexTable/TabelPanelViewPort.dart';
import 'package:flextable/FlexTable/TableBuilder.dart';
import 'package:flextable/FlexTable/TableItems/Cells.dart';
import 'package:flextable/FlexTable/TableLine.dart';
import 'package:flextable/FlexTable/TableModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:flextable/FlexTable/FlexTableConstants.dart' as constants;

class HypotheekTableModel {
  final data = DataFlexTableCR();
  var df = DateFormat('dd-MM-yyyy');
  var nf = NumberFormat('###', 'nl_NL');
  final years = 30;
  int rowEndTable = 0;
  int columnEndTable = 0;
  int lastRow = 0;
  int tableRows;
  int tableColumns;

  int initialYear = 2020;

  HypotheekTableModel({required this.tableRows, required this.tableColumns});

  makeTable(
      {required double morgage,
      required double interest,
      int column = 0,
      int row = 0,
      Color bc1 = Colors.white,
      Color bc2 = Colors.white,
      Color lineColor = Colors.white,
      double lineWidth = 0.5,
      bool resetRowCount = false}) {
    const startTableRow = 2;
    int columnStart = column;
    row += resetRowCount ? 0 : lastRow;
    int rowStart = row;
    double monthlyInterest;

    final h = data.horizontalLineList;

    final secondLevelHorizontalNoGap = h.createLineNodeList(
        startLevelTwoIndex: columnStart,
        lineNode: LineNode(
            left: const Line.noLine(),
            right: Line(width: lineWidth, color: lineColor)))
      ..addLineNode(
          startLevelTwoIndex: columnStart + 9,
          lineNode: LineNode(
              left: Line(width: lineWidth, color: lineColor),
              right: const Line.noLine()));

    final secondLevelHorizontalGaps = h.createLineNodeList(
        startLevelTwoIndex: columnStart,
        lineNode: LineNode(right: Line(width: lineWidth, color: lineColor)))
      ..addLineNode(
          startLevelTwoIndex: columnStart + 4,
          lineNode: LineNode(
              left: Line(width: lineWidth, color: lineColor),
              right: const Line.noLine()));

    final topHorizontal = h.createLineNodeList(
        startLevelTwoIndex: columnStart + 2,
        lineNode: LineNode(
            left: const Line.noLine(),
            right: Line(width: lineWidth, color: lineColor)))
      ..addLineNode(
          startLevelTwoIndex: columnStart + 4,
          lineNode: LineNode(
              left: Line(width: lineWidth, color: lineColor),
              right: const Line.noLine()));

    h.addList(
        startLevelOneIndex: rowStart + 1,
        endLevelOneIndex: rowStart + 2,
        lineList: secondLevelHorizontalNoGap);

    h.addList(
        startLevelOneIndex: rowStart + 0,
        endLevelOneIndex: rowStart + 0,
        lineList: topHorizontal);

    data.addCell(
        row: row,
        column: columnStart + 2,
        columns: 2,
        cell: Cell(
            value: 'Per maand', attr: {constants.cell_backgroundColor: bc2}));

    var rowColor = row % 2 == 0 ? bc2 : bc1;

    row++;

    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Datum', attr: {constants.cell_backgroundColor: rowColor}));

    data.addCell(
      row: row,
      column: column++,
      cell: Cell(
          value: 'Lening', attr: {constants.cell_backgroundColor: rowColor}),
    );

    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Rente', attr: {constants.cell_backgroundColor: rowColor}));

    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Aflossen',
            attr: {constants.cell_backgroundColor: rowColor}));
    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Totaal', attr: {constants.cell_backgroundColor: rowColor}));
    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Rente', attr: {constants.cell_backgroundColor: rowColor}));
    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Teruggave',
            attr: {constants.cell_backgroundColor: rowColor}));
    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'Netto', attr: {constants.cell_backgroundColor: rowColor}));
    data.addCell(
        row: row,
        column: column++,
        cell: Cell(
            value: 'N. e/m', attr: {constants.cell_backgroundColor: rowColor}));

    for (int i = 0; i < years; i++) {
      double interestYear = 0;
      double repayYear = 0;
      for (int month = 0; month < 12; month++) {
        int currentYear = initialYear + i;

        row = rowStart + startTableRow + i * 12 + month;
        rowColor = row % 2 == 0 ? bc1 : bc2;

        monthlyInterest = morgage / 100.0 * interest / 12;
        interestYear += monthlyInterest;

        final r1 = 1 -
            math.pow(1 + interest / 100 / 12, -(years * 12 - (i * 12 + month)));
        final repay = monthlyInterest / r1 - monthlyInterest;
        repayYear += repay;

        column = columnStart;
        data.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: df.format(DateTime(currentYear, month + 1)),
                attr: {constants.cell_backgroundColor: rowColor}));
        data.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: nf.format(morgage),
                attr: {constants.cell_backgroundColor: rowColor}));
        data.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: nf.format(monthlyInterest),
                attr: {constants.cell_backgroundColor: rowColor}));
        data.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: nf.format(repay),
                attr: {constants.cell_backgroundColor: rowColor}));

        if (month == 0) {
          h.addList(
              startLevelOneIndex: row,
              lineList: secondLevelHorizontalNoGap.copy());
        } else if (month == 1) {
          h.addList(
              startLevelOneIndex: row,
              endLevelOneIndex: row + 10,
              lineList: secondLevelHorizontalGaps.copy());
        } else if (month == 11) {
          final yearColorBlock = i % 2 == 0 ? bc1 : bc2;
          final yearColorBlockNext = i % 2 == 1 ? bc1 : bc2;

          final total = interestYear + repayYear;
          final back = interestYear * 0.42;
          data.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(interestYear + repay),
                  attr: {constants.cell_backgroundColor: yearColorBlock}));
          data.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(interestYear),
                  attr: {constants.cell_backgroundColor: yearColorBlockNext}));
          data.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(back),
                  attr: {constants.cell_backgroundColor: yearColorBlock}));
          data.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(total - back),
                  attr: {constants.cell_backgroundColor: yearColorBlockNext}));
          data.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value:
                      'T: ${nf.format(total / 12.0)}\nB: ${nf.format(back / 12.0)}\nN: ${nf.format((total - back) / 12.0)}',
                  attr: {constants.cell_backgroundColor: yearColorBlock}));
        }

        morgage -= repay;
      }
    }

    h.addList(
        startLevelOneIndex: row + 1,
        endLevelOneIndex: row + 1,
        lineList: secondLevelHorizontalNoGap);

    final v = data.verticalLineList;

    v.addList(
        startLevelOneIndex: columnStart,
        endLevelOneIndex: columnStart + 9,
        lineList: v.createLineNodeList(
            startLevelTwoIndex: rowStart + 2,
            endLevelTwoIndex: row,
            lineNode: LineNode(
                bottom: Line(width: lineWidth, color: lineColor),
                top: Line(width: lineWidth, color: lineColor)))
          ..addLineNode(
              startLevelTwoIndex: rowStart + 1,
              lineNode:
                  LineNode(bottom: Line(width: lineWidth, color: lineColor)))
          ..addLineNode(
              startLevelTwoIndex: row + 1,
              lineNode: LineNode(top: Line(width: lineWidth, color: lineColor)))
        //  ..addLineNode(startLevelTwoIndex: 50, lineNode: LineNode(bottom: Line(), top: Line()))
        );

    final topVertical = h.createLineNodeList(
        startLevelTwoIndex: rowStart + 0,
        lineNode: LineNode(
            top: const Line.noLine(),
            bottom: Line(width: lineWidth, color: lineColor)))
      ..addLineNode(
          startLevelTwoIndex: rowStart + 1,
          lineNode: LineNode(
              top: Line(width: lineWidth, color: lineColor),
              bottom: Line(width: lineWidth, color: lineColor)));

    v.addList(startLevelOneIndex: columnStart + 2, lineList: topVertical);
    v.addList(startLevelOneIndex: columnStart + 4, lineList: topVertical);

    lastRow = row + 2;

    if (rowEndTable < lastRow) rowEndTable = lastRow;
    if (columnEndTable < column) columnEndTable = column;
  }

  tableModel({
    TargetPlatform? platform,
    scrollLockX = true,
    scrollLockY = true,
    autoFreezeListX = false,
    autoFreezeListY = false,
  }) {
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
        tableScale = 2.0;
        maxTableScale = 4.0;
        break;
    }

    final autoFreezeAreasY = autoFreezeListY
        ? List<AutoFreezeArea>.generate(
            tableRows,
            (index) => AutoFreezeArea(
                startIndex: 364 * index,
                freezeIndex: 3 + 364 * index,
                endIndex: 362 + 364 * index,
                customSplitSize: 0.5))
        : <AutoFreezeArea>[];

    final autoFreezeAreasX = autoFreezeListX
        ? List<AutoFreezeArea>.generate(
            tableColumns,
            (index) => AutoFreezeArea(
                startIndex: 10 * index,
                freezeIndex: 1 + 10 * index,
                endIndex: 9 + 10 * index,
                customSplitSize: 0.5))
        : <AutoFreezeArea>[];

    List<PropertiesRange> specificWidth = [];

    for (int i = 0; i < tableColumns; i++) {
      final begin = i * 10;
      specificWidth
          .add(PropertiesRange(min: 0 + begin, max: 0 + begin, length: 90));
      specificWidth
          .add(PropertiesRange(min: 2 + begin, max: 2 + begin, length: 60));
    }
    return TableModel(
        stateSplitX: SplitState.NO_SPLITE,
        stateSplitY: SplitState.NO_SPLITE,
        // xSplit: 100.0, ySplit: 160.0,
        // freezeColumns: 3, freezeRows: 23,
        columnHeader: false,
        rowHeader: false,
        scrollLockX: scrollLockX,
        scrollLockY: scrollLockY,
        specificWidth: specificWidth,
        defaultWidthCell: 70.0,
        defaultHeightCell: 25.0,
        maximumColumns: columnEndTable,
        maximumRows: rowEndTable,
        dataTable: data,
        panelMargin: 2.0,
        autoFreezeAreasX: autoFreezeAreasX,
        autoFreezeAreasY: autoFreezeAreasY,
        scale: tableScale,
        minTableScale: minTableScale,
        maxTableScale: maxTableScale);
  }
}

class HypoteekTableBuilder extends DefaultTableBuilder {
  HypoteekTableBuilder();

  @override
  Widget? buildCell(double tableScale, TableCellIndex tableCellIndex) {
    //RepaintBoundary for canvas layer

    final cell = tableModel.dataTable
        .cell(row: tableCellIndex.row, column: tableCellIndex.column);

    if (cell == null) {
      return null;
    }

    return Container(
        color: cell.attr[constants.cell_backgroundColor] ?? Colors.white,
        child: Center(
            child: Text(
          '${cell.value}',
          textScaleFactor: tableScale,
        )));
  }

  @override
  Widget backgroundPanel(int panelIndex, Widget? child) {
    // Color color;

    // TablePanelLayoutIndex tpli = tableModel.layoutIndex(panelIndex);
    // final iX = tpli.xIndex;
    // final iY = tpli.yIndex;

    // if (iX % 3 == 0) {
    //   color = Colors.lightBlue[(iY + iX % 2) % 2 * 100 + 200]!;
    // } else if (iY % 3 == 0) {
    //   color = Colors.lightBlue[(iX + iY % 2) % 2 * 100 + 200]!;
    // } else {
    //   color = Colors.grey[50] ?? Colors.white;
    // }

    return Container(child: child);
  }
}

List<Map<String, Color>> tableColors = <Map<String, Color>>[
  {'bc1': Colors.lime[100]!, 'bc2': Colors.white, 'line': Colors.lime[300]!},
  {
    'bc1': Colors.white,
    'bc2': Colors.amberAccent[100]!,
    'line': Colors.amberAccent[200]!
  },
  {
    'bc1': Colors.amberAccent[200]!,
    'bc2': Colors.white,
    'line': Colors.amberAccent[400]!
  },
  {
    'bc1': Colors.lightBlue[50]!,
    'bc2': Colors.lightBlue[100]!,
    'line': Colors.blue
  },
  {
    'bc1': Colors.cyan[50]!,
    'bc2': Colors.cyan[100]!,
    'line': Colors.cyan[200]!
  },
  {
    'bc1': Colors.blueGrey[50]!,
    'bc2': Colors.white,
    'line': Colors.blueGrey[100]!
  },
  {
    'bc1': Colors.purple[50]!,
    'bc2': Colors.white,
    'line': Colors.pinkAccent[100]!
  },
  {
    'bc1': Colors.pink[50]!,
    'bc2': Colors.pink[100]!,
    'line': Colors.pink[200]!
  },
  {'bc1': Colors.lime[100]!, 'bc2': Colors.white, 'line': Colors.lime[300]!},
  {
    'bc1': Colors.orange[200]!,
    'bc2': Colors.pink[50]!,
    'line': Colors.orange[300]!
  },
  {
    'bc1': Colors.indigo[100]!,
    'bc2': Colors.indigo[50]!,
    'line': Colors.indigo[300]!
  },
  {
    'bc1': Colors.lightGreen[100]!,
    'bc2': Colors.lime[50]!,
    'line': Colors.lime[300]!
  }
];

List<Map<String, double>> morgages = <Map<String, double>>[
  {'morgage': 188000, 'interest': 3.9},
  {'morgage': 651000, 'interest': 1.4},
  {'morgage': 242000, 'interest': 3.1},
  {'morgage': 317000, 'interest': 4.1},
  {'morgage': 41000, 'interest': 2.3},
  {'morgage': 590000, 'interest': 1.1},
  {'morgage': 267000, 'interest': 2.6},
  {'morgage': 171000, 'interest': 5.5},
  {'morgage': 626000, 'interest': 1.8},
  {'morgage': 222200, 'interest': 3.7},
  {'morgage': 364200, 'interest': 1.4},
  {'morgage': 276000, 'interest': 2.6}
];

HypotheekTableModel hypotheekExample1(
    {int tableRows = 6, int tableColumns = 5}) {
  HypotheekTableModel hypotheekTable =
      HypotheekTableModel(tableRows: tableRows, tableColumns: tableColumns);

  int lengthColors = tableColors.length;
  int swiftColors = 2;

  for (int c = 0; c < tableColumns; c++) {
    bool resetRowCount = true;
    for (int r = 0; r < tableRows; r++) {
      int count = c * tableRows + r;
      final m = morgages[count % morgages.length];
      final tc = tableColors[(c * swiftColors + r) % lengthColors];

      hypotheekTable.makeTable(
          morgage: m['morgage']!,
          interest: m['interest']!,
          column: c * 10,
          row: 1,
          bc1: tc['bc1']!,
          bc2: tc['bc2']!,
          lineColor: tc['line']!,
          lineWidth: 0.5,
          resetRowCount: resetRowCount);

      resetRowCount = false;
    }
  }

  return hypotheekTable;
}
