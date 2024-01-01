// ignore_for_file: public_member_api_docs, sort_constructors_first
// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:flextable/flextable.dart';

class MortgageTableModel {
  MortgageTableModel({this.verticalTables = 6, this.horizontalTables = 5})
      : flexTableModel =
            FtModel<Cell>(defaultHeightCell: 25.0, defaultWidthCell: 75.0) {
    int lengthColors = _tableColors.length;
    int swiftColors = 2;

    for (int c = 0; c < horizontalTables; c++) {
      bool resetRowCount = true;
      for (int r = 0; r < verticalTables; r++) {
        int count = c * verticalTables + r;
        final m = morgages[count % morgages.length];
        final tc = _tableColors[(c * swiftColors + r) % lengthColors];

        add(
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
  }

  final FtModel<Cell> flexTableModel;
  var df = DateFormat('dd-MM-yyyy');
  var nf = NumberFormat('###', 'nl_NL');
  final years = 30;
  int rowEndTable = 0;
  int columnEndTable = 0;
  int lastRow = 0;
  int verticalTables;
  int horizontalTables;

  int initialYear = 2020;

  add(
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

    final h = flexTableModel.horizontalLines;
    final line = Line(width: lineWidth, color: lineColor);

    final horizontalNoGap = LineNodeRange(create: (add) {
      add(LineNode(
          startIndex: columnStart, before: const Line.no(), after: line));

      add(LineNode(
          startIndex: columnStart + 9, before: line, after: const Line.no()));
    });

    final horizontalGaps = LineNodeRange(create: (add) {
      add(LineNode(
          startIndex: columnStart, before: const Line.no(), after: line));

      add(LineNode(
          startIndex: columnStart + 4, before: line, after: const Line.no()));
    });

    /// Header
    ///
    ///
    h.addLineRanges(
      (add) {
        add(LineRange(
            startIndex: rowStart,
            lineNodeRange: LineNodeRange(list: [
              LineNode(
                  startIndex: columnStart + 2,
                  before: const Line.no(),
                  after: line),
              LineNode(
                  startIndex: columnStart + 4,
                  before: line,
                  after: const Line.no())
            ])));

        add(LineRange(
            startIndex: rowStart + 1,
            endIndex: rowStart + 2,
            lineNodeRange: horizontalNoGap));
      },
    );

    flexTableModel.addCell(
        row: row,
        column: columnStart + 2,
        columns: 2,
        cell: Cell(value: 'Per maand', attr: {CellAttr.background: bc2}));

    var rowColor = row % 2 == 0 ? bc2 : bc1;

    row++;

    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Datum', attr: {CellAttr.background: rowColor}));

    flexTableModel.addCell(
      row: row,
      column: column++,
      cell: Cell(value: 'Lening', attr: {CellAttr.background: rowColor}),
    );

    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Rente', attr: {CellAttr.background: rowColor}));

    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Aflossen', attr: {CellAttr.background: rowColor}));
    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Totaal', attr: {CellAttr.background: rowColor}));
    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Rente', attr: {CellAttr.background: rowColor}));
    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Teruggave', attr: {CellAttr.background: rowColor}));
    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'Netto', attr: {CellAttr.background: rowColor}));
    flexTableModel.addCell(
        row: row,
        column: column++,
        cell: Cell(value: 'N. e/m', attr: {CellAttr.background: rowColor}));

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
        flexTableModel.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: df.format(DateTime(currentYear, month + 1)),
                attr: {CellAttr.background: rowColor}));
        flexTableModel.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: nf.format(morgage),
                attr: {CellAttr.background: rowColor}));
        flexTableModel.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: nf.format(monthlyInterest),
                attr: {CellAttr.background: rowColor}));
        flexTableModel.addCell(
            row: row,
            column: column++,
            cell: Cell(
                value: nf.format(repay),
                attr: {CellAttr.background: rowColor}));

        if (month == 0) {
          h.addLineRange(
              LineRange(startIndex: row, lineNodeRange: horizontalNoGap));
        } else if (month == 1) {
          h.addLineRange(LineRange(
              startIndex: row,
              endIndex: row + 10,
              lineNodeRange: horizontalGaps));
        } else if (month == 11) {
          final yearColorBlock = i % 2 == 0 ? bc1 : bc2;
          final yearColorBlockNext = i % 2 == 1 ? bc1 : bc2;

          final total = interestYear + repayYear;
          final back = interestYear * 0.42;
          flexTableModel.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(interestYear + repay),
                  attr: {CellAttr.background: yearColorBlock}));
          flexTableModel.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(interestYear),
                  attr: {CellAttr.background: yearColorBlockNext}));
          flexTableModel.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(back),
                  attr: {CellAttr.background: yearColorBlock}));
          flexTableModel.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value: nf.format(total - back),
                  attr: {CellAttr.background: yearColorBlockNext}));
          flexTableModel.addCell(
              row: row - 11,
              column: column++,
              rows: 12,
              cell: Cell(
                  value:
                      'T: ${nf.format(total / 12.0)}\nB: ${nf.format(back / 12.0)}\nN: ${nf.format((total - back) / 12.0)}',
                  attr: {CellAttr.background: yearColorBlock}));
        }

        morgage -= repay;
      }
    }

    //Bottom line
    h.addLineRange(
        LineRange(startIndex: row + 1, lineNodeRange: horizontalNoGap));

    flexTableModel.verticalLines.addLineRanges((add) {
      add(LineRange(
          startIndex: columnStart,
          endIndex: columnStart + 9,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: rowStart + 1,
              after: line,
            ),
            LineNode(startIndex: row + 1, endIndex: row + 1, before: line),
          ])));

      final lineNodes = [
        LineNode(
          startIndex: rowStart,
          after: line,
        ),
        LineNode(startIndex: rowStart + 1, before: noLine, after: noLine),
      ];

      // Per maand Vertical lines
      add(LineRange(
          startIndex: columnStart + 2,
          lineNodeRange: LineNodeRange(list: lineNodes)));

      add(LineRange(
          startIndex: columnStart + 4,
          lineNodeRange: LineNodeRange(list: lineNodes)));
    });

    lastRow = row + 2;

    if (rowEndTable < lastRow) rowEndTable = lastRow;
    if (columnEndTable < column) columnEndTable = column;
  }

  FtModel<Cell> makeTable({
    TargetPlatform? platform,
    scrollUnlockX = false,
    scrollUnlockY = false,
    autoFreezeListX = false,
    autoFreezeListY = false,
  }) {
    var tableScale = switch (platform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        1.5,
      (_) => 1.0
    };

    final autoFreezeAreasY = autoFreezeListY
        ? List<AutoFreezeArea>.generate(
            verticalTables,
            (index) => AutoFreezeArea(
                startIndex: 364 * index,
                freezeIndex: 3 + 364 * index,
                endIndex: 362 + 364 * index,
                customSplitSize: 0.5))
        : <AutoFreezeArea>[];

    final autoFreezeAreasX = autoFreezeListX
        ? List<AutoFreezeArea>.generate(
            horizontalTables,
            (index) => AutoFreezeArea(
                startIndex: 10 * index,
                freezeIndex: 1 + 10 * index,
                endIndex: 9 + 10 * index,
                customSplitSize: 0.5))
        : <AutoFreezeArea>[];

    List<RangeProperties> specificWidth = [];

    for (int i = 0; i < horizontalTables; i++) {
      final begin = i * 10;
      specificWidth
          .add(RangeProperties(min: 0 + begin, max: 0 + begin, length: 90));
      specificWidth
          .add(RangeProperties(min: 2 + begin, max: 2 + begin, length: 60));
    }
    return flexTableModel
      ..specificWidth = specificWidth
      ..tableColumns = columnEndTable
      ..tableRows = rowEndTable
      ..autoFreezeAreasX = autoFreezeAreasX
      ..autoFreezeAreasY = autoFreezeAreasY
      ..tableScale = tableScale;
  }
}

class MortgageTableBuilder extends DefaultTableBuilder {
  MortgageTableBuilder(
      {super.headerBackgroundColor = const Color.fromARGB(255, 244, 246, 248)});

  @override
  Widget? cellBuilder(
    BuildContext context,
    FtViewModel<FtModel<Cell>, Cell> viewModel,
    Cell cell,
    LayoutPanelIndex layoutPanelIndex,
    CellIndex tableCellIndex,
  ) {
    //RepaintBoundary for canvas layer

    return Container(
        color: cell.attr[CellAttr.background] ?? Colors.white,
        child: Center(
            child: Text(
          '${cell.value}',
          textScaler: TextScaler.linear(viewModel.tableScale),
        )));
  }
}

List<Map<String, Color>> _tableColors = <Map<String, Color>>[
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
