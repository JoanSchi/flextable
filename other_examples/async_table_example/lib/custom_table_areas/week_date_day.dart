import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/create_week_table_area.dart';

class DefinedTableAreaWeekDateDay
    extends DefinedTableArea<AsyncAreaModel, Cell> {
  const DefinedTableAreaWeekDateDay({
    super.minimalHeaderRows = 2,
    super.columns = 3,
    super.tableName = 'weekDataDay',
  });

  @override
  CreateWeekTableArea? create({
    required int minimalHeaderRows,
    required AsyncAreaModel model,
    required FtController<AsyncAreaModel, Cell> tableController,
    required FtCellGroupState cellGroupState,
    required DateTime firstDay,
    required DateTime startWeekDate,
    required DateTime endWeekDate,
    required int startRow,
    required int startColumn,
  }) {
    return CreateWeekDateDay(
        headerRows: minimalHeaderRows,
        model: model,
        tableController: tableController,
        cellGroupState: cellGroupState,
        startColumn: startColumn,
        startRow: startRow,
        firstDate: firstDay,
        startWeekDate: startWeekDate,
        endWeekDate: endWeekDate,
        columns: columns,
        tableName: tableName);
  }
}

class CreateWeekDateDay extends CreateWeekTableArea {
  static const Color dark = Color.fromARGB(255, 201, 215, 144);
  static const Color lightEven = Color.fromARGB(255, 240, 245, 220);
  static const Color lightUnEven = Colors.white10;
  static const Color lightLine = Color.fromARGB(255, 224, 233, 190);
  static const Color headerColor = Color.fromARGB(255, 47, 56, 14);

  CreateWeekDateDay(
      {required super.model,
      required super.tableController,
      required super.cellGroupState,
      required super.startWeekDate,
      required super.endWeekDate,
      required super.firstDate,
      required super.startRow,
      required super.startColumn,
      required super.headerRows,
      required super.columns,
      required super.tableName});

  @override
  bool get synchronize => false;

  @override
  layout() {
    model.updateCell(
        ftIndex: FtIndex(row: startRow + 1, column: startColumn),
        cell: const TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle: TextStyle(color: headerColor),
            CellAttr.background: dark
          },
          value: 'Wk',
        ));

    int firstTotalDays = startWeekDate.difference(firstDate).inDays;
    model.updateCell(
        ftIndex: FtIndex(
          row: startRow + headerRows,
          column: startColumn,
        ),
        rows: weekDays,
        cell: TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle:
                const TextStyle(color: headerColor, fontSize: 24.0),
            CellAttr.background: lightEven
          },
          value: '${firstTotalDays ~/ 7 + 1}',
        ));

    /// Date
    ///
    ///
    ///
    ///
    ///

    model.updateCell(
        ftIndex: FtIndex(row: startRow + 1, column: startColumn + 1),
        cell: const TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle: TextStyle(color: headerColor),
            CellAttr.background: dark
          },
          value: 'Date',
        ));

    DateTime date = startWeekDate;

    while (date.compareTo(endWeekDate) <= 0) {
      final dataRow = date.difference(startWeekDate).inDays;
      int row = startRow + headerRows + dataRow;

      model.updateCell(
          ftIndex: FtIndex(column: startColumn + 1, row: row),
          cell: TextCell(
            attr: {
              CellAttr.background: dataRow.isEven ? lightEven : lightUnEven,
              CellAttr.textStyle: const TextStyle(color: headerColor),
            },
            value: DateFormat('dd/MM/yy').format(date),
          ));

      date = date.add(const Duration(days: 1));
    }

    /// Days
    ///
    ///
    ///
    ///
    model.updateCell(
        ftIndex: FtIndex(row: startRow + 1, column: startColumn + 2),
        cell: const TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle: TextStyle(color: headerColor),
            CellAttr.background: dark
          },
          value: 'Day',
        ));

    int dayNumber = firstTotalDays + 1;
    int dataRow = 0;

    for (int r = startRow + headerRows;
        r < startRow + headerRows + weekDays;
        r++) {
      model.updateCell(
          ftIndex: FtIndex(row: r, column: startColumn + 2),
          cell: TextCell(
            attr: {
              CellAttr.textAlign: TextAlign.center,
              CellAttr.textStyle: const TextStyle(color: headerColor),
              CellAttr.background: dataRow.isEven ? lightEven : lightUnEven
            },
            value: '$dayNumber',
          ));
      dataRow++;
      dayNumber++;
    }

    /// Vertical lines
    ///
    ///
    ///
    ///
    model.verticalLines.addLineRanges((create) {
      create(LineRange(
          startIndex: startColumn + 1,
          endIndex: startColumn + 3,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startRow + headerRows - 1,
              after: const Line(color: lightLine, width: 1.0),
            ),
            LineNode(
                startIndex: startRow + headerRows,
                before: const Line(color: lightLine, width: 1.0))
          ])));

      create(LineRange(
          startIndex: startColumn,
          endIndex: startColumn + 3,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startRow + headerRows,
              after: const Line(color: dark, width: 1.0),
            ),
            LineNode(
                startIndex: startRow + headerRows + weekDays,
                before: const Line(color: lightLine, width: 1.0))
          ])));
    });

    /// Horizontal lines
    ///
    ///
    ///
    ///
    model.horizontalLines.addLineRanges((create) {
      create(LineRange(
          startIndex: startRow,
          endIndex: startRow + headerRows,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startColumn,
              after: const Line(color: Colors.white, width: 1.0),
            ),
            LineNode(
                startIndex: startColumn + 3,
                before: const Line(color: Colors.white, width: 1.0))
          ])));

      create(LineRange(
          startIndex: startRow + headerRows + weekDays,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startColumn,
              after: const Line(color: dark, width: 1.0),
            ),
            LineNode(
                startIndex: startColumn + 3,
                before: const Line(color: dark, width: 1.0))
          ])));

      if (rowCurrentDay case int r when r != -1) {
        create(LineRange(
            startIndex: r,
            endIndex: r + 1,
            lineNodeRange: LineNodeRange(list: [
              LineNode(
                startIndex: startColumn + 1,
                after: const Line(color: dark, width: 2.0),
              ),
              LineNode(
                  startIndex: startColumn + 3,
                  before: const Line(color: dark, width: 2.0))
            ])));
      }
    });
  }

  @override
  fetch() async {}

  /// Loading
  ///
  ///
  ///
  ///
  ///
  ///

  @override
  load() {}
}
