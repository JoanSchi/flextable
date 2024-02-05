import 'dart:async';

import 'package:async_table_example/model/create_week_table_area.dart';
import 'package:async_table_example/repositories/observed_energy.dart';
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import '../model/cell_identifier.dart';

class DefinedTableAreaObservedEnergy
    extends DefinedTableArea<AsyncAreaModel, Cell> {
  const DefinedTableAreaObservedEnergy({
    super.minimalHeaderRows = 2,
    super.columns = 2,
    super.tableName = 'energy',
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
    return CreateObservedEnergy(
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

class CreateObservedEnergy extends CreateWeekTableArea {
  static const Color dark = Color.fromARGB(255, 201, 215, 144);
  static const Color lightEven = Color.fromARGB(255, 240, 245, 220);
  static const Color lightUnEven = Colors.white10;
  static const Color lightLine = Color.fromARGB(255, 224, 233, 190);
  static const Color headerColor = Color.fromARGB(255, 47, 56, 14);

  CreateObservedEnergy(
      {required super.model,
      required super.tableController,
      required super.cellGroupState,
      required super.firstDate,
      required super.startWeekDate,
      required super.endWeekDate,
      required super.startRow,
      required super.startColumn,
      required super.headerRows,
      required super.columns,
      required super.tableName});

  @override
  bool get synchronize => true;

  @override
  layout() {
    model.updateCell(
        ftIndex: FtIndex(row: startRow, column: startColumn),
        columns: columns,
        cell: const TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle: TextStyle(color: headerColor),
            CellAttr.background: dark
          },
          value: 'Energy',
        ));

    model.updateCell(
        ftIndex: FtIndex(row: startRow + 1, column: startColumn),
        cell: const TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle: TextStyle(color: headerColor),
            CellAttr.background: dark
          },
          value: 'Str. (kwh)',
        ));

    model.updateCell(
        ftIndex: FtIndex(row: startRow + 1, column: startColumn + 1),
        cell: const TextCell(
          attr: {
            CellAttr.textAlign: TextAlign.center,
            CellAttr.textStyle: TextStyle(color: headerColor),
            CellAttr.background: dark
          },
          value: 'Gas (m3)',
        ));

    /// Vertical lines
    ///
    ///
    ///
    ///
    model.verticalLines.addLineRanges((create) {
      create(LineRange(
          startIndex: startColumn + 1,
          endIndex: startColumn + columns - 1,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startRow + 1,
              after: const Line(color: lightLine, width: 1.0),
            ),
            LineNode(
                startIndex: startRow + headerRows,
                before: const Line(color: lightLine, width: 1.0))
          ])));

      create(LineRange(
          startIndex: startColumn,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startRow,
              after: const Line(color: lightLine, width: 1.0),
            ),
            LineNode(
                startIndex: startRow + headerRows,
                before: const Line(color: lightLine, width: 1.0))
          ])));

      create(LineRange(
          startIndex: startColumn + columns,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startRow,
              after: const Line(color: lightLine, width: 1.0),
            ),
            LineNode(
                startIndex: startRow + headerRows,
                before: const Line(color: lightLine, width: 1.0))
          ])));

      /// Horizontal lines
      ///
      ///
      create(LineRange(
          startIndex: startColumn,
          endIndex: startColumn + columns,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startRow + headerRows,
              after: const Line(color: dark, width: 1.0),
            ),
            LineNode(
                startIndex: startRow + headerRows + weekDays,
                before: const Line(color: dark, width: 1.0))
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
              after: const Line(color: lightLine, width: 1.0),
            ),
            LineNode(
                startIndex: startColumn + columns,
                before: const Line(color: lightLine, width: 1.0))
          ])));

      create(LineRange(
          startIndex: startRow + headerRows + weekDays,
          lineNodeRange: LineNodeRange(list: [
            LineNode(
              startIndex: startColumn,
              after: const Line(color: dark, width: 1.0),
            ),
            LineNode(
                startIndex: startColumn + columns,
                before: const Line(color: dark, width: 1.0))
          ])));

      if (rowCurrentDay case int r when r != -1) {
        create(LineRange(
            startIndex: r,
            endIndex: r + 1,
            lineNodeRange: LineNodeRange(list: [
              LineNode(
                startIndex: startColumn,
                after: const Line(color: dark, width: 2.0),
              ),
              LineNode(
                  startIndex: startColumn + columns,
                  before: const Line(color: dark, width: 2.0))
            ])));
      }
    });
  }

  @override
  fetch() async {
    cellGroupState.state != FtCellState.inQuee;

    Map<DateTime, ObservedEnergy> map = {
      for (ObservedEnergy v in await ObservedEnergyRespitory.fetch(
          startDate: startWeekDate, endDate: endWeekDate))
        v.measurementDate: v
    };

    final updateCellIndexes = lazyMe(map);

    FtViewModel? viewModel = tableController.lastViewModelOrNull();

    if (viewModel == null || !viewModel.mounted) {
      return;
    }

    /// Remove cellIndexes for update
    ///
    ///

    scheduleMicrotask(() {
      cellGroupState.state = FtCellState.ready;
      viewModel
        ..cellsToRemove.addAll(updateCellIndexes)
        ..markNeedsLayout();
    });
  }

  /// Loading
  ///
  ///
  ///
  ///
  ///
  ///

  @override
  load() {
    if (cellGroupState.state != FtCellState.none) {
      //Loading cells already
      return;
    }
    lazyMe();
  }

  Set<FtIndex> lazyMe([Map<DateTime, ObservedEnergy> map = const {}]) {
    final Set<FtIndex> updateCellIndexes = {};

    DateTime date = startWeekDate;
    int debugMax = 0;
    while (date.compareTo(endWeekDate) <= 0) {
      final dataRow = date.difference(startWeekDate).inDays;
      int row = startRow + headerRows + dataRow;
      int column = startColumn;

      ObservedEnergy? item = map[date];

      /// Moistere
      ///
      ///
      FtIndex ftIndex = FtIndex(column: column, row: row);
      updateCellIndexes.add(ftIndex);

      model.updateCell(
          ftIndex: ftIndex,
          cell: DecimalInputCell(
              attr: {
                CellAttr.alignment: Alignment.center,
                CellAttr.background: dataRow.isEven ? lightEven : lightUnEven
              },
              value: item?.kwh,
              identifier: CellIdentifier(
                  tableName: tableName, itemName: 'kwh', date: date),
              groupState: cellGroupState));

      /// Temperature
      ///
      ///
      column++;
      ftIndex = FtIndex(column: column, row: row);
      updateCellIndexes.add(ftIndex);

      model.updateCell(
          ftIndex: ftIndex,
          cell: DecimalInputCell(
              attr: {
                CellAttr.alignment: Alignment.center,
                CellAttr.background: dataRow.isEven ? lightEven : lightUnEven
              },
              value: item?.gasM3,
              identifier: CellIdentifier(
                  tableName: tableName, itemName: 'gasm3', date: date),
              groupState: cellGroupState));

      date = date.add(const Duration(days: 1));

      assert(debugMax++ < 8, 'Date loop in obtain');
    }
    return updateCellIndexes;
  }
}
