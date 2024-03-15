// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:flextable/flextable.dart';

class RecordFtModel<C extends AbstractCell> extends AbstractFtModel<C> {
  RecordFtModel({
    super.tableColumns,
    super.tableRows,
    required super.defaultWidthCell,
    required super.defaultHeightCell,
    super.stateSplitX,
    super.stateSplitY,
    super.xSplit = 0.0,
    super.ySplit = 0.0,
    super.rowHeader = false,
    super.columnHeader = false,
    super.scrollUnlockX = false,
    super.scrollUnlockY = false,
    super.freezeColumns = -1,
    super.freezeRows = -1,
    super.specificHeight,
    super.specificWidth,
    super.tableScale = 1.0,
    super.autoFreezeAreasX,
    super.autoFreezeX,
    super.autoFreezeAreasY,
    super.autoFreezeY,

    //Default
    TableLinesOneDirection? horizontalLines,
    TableLinesOneDirection? verticalLines,
    Map<int, MergedColumns>? mergedColumns,
    Map<int, MergedRows>? mergedRows,
    super.calculationPositionsNeededX,
    super.calculationPositionsNeededY,
  })  : mergedColumns = mergedColumns ?? HashMap<int, MergedColumns>(),
        mergedRows = mergedRows ?? HashMap<int, MergedRows>(),
        //TODO with mutableNumber
        linkedRowRibbons = LinkedRowRibbons<C>();

  final Map<int, MergedColumns> mergedColumns;
  final Map<int, MergedRows> mergedRows;
  LinkedRowRibbons<C> linkedRowRibbons;
  LinkedRowRibbons<C>? _unFilteredLinkedRowRibbons;
  int lastImutableIndex = 0;
  List<int> unUsedImutableRowIndexes = [];
  // RearrangeCells rearrange = const NoRearrangeCells();

  Set<RecordRowRibbon> updateIdRow = {};
  Set<RecordRowRibbon> insertIdRow = {};
  Set<RecordRowRibbon> deletedIdRow = {};
  // HashMap<int, int> uniqueRowNumber = HashMap<int, int>();

  void insertCell(
      {required FtIndex ftIndex,
      int rows = 1,
      int columns = 1,
      required C cell,
      checkPreviousCell = false,
      bool updateBackend = true,
      String? rowId,
      bool user = false}) {
    if (tableRows < ftIndex.row + rows) {
      tableRows = ftIndex.row + rows;
    }

    if (tableColumns < ftIndex.column + columns) {
      tableColumns = ftIndex.column + columns;
    }

    assert(_unFilteredLinkedRowRibbons == null,
        'UnfilteredRowRibbon is not null. If a filter is used add rows with insertRangeRow and update cell, and use insertCell only for initiation!');

    if (linkedRowRibbons.length < tableRows) {
      for (int i = linkedRowRibbons.length; i < tableRows; i++) {
        int u = uniqueImmutableRowIndex;

        linkedRowRibbons.insertRow(
            i,
            RecordRowRibbon<C>(
                immutableRowIndex: u, rowId: ftIndex.row == i ? rowId : null));
      }
    }

    updateCell(
        ftIndex: ftIndex,
        cell: cell,
        rows: rows,
        columns: columns,
        updateBackend: updateBackend,
        user: user);
  }

  int get uniqueImmutableRowIndex => unUsedImutableRowIndexes.isNotEmpty
      ? unUsedImutableRowIndexes.removeLast()
      : ++lastImutableIndex;

  @override
  Set<FtIndex>? updateCell(
      {required FtIndex ftIndex,
      int rows = 1,
      int columns = 1,
      required C? cell,
      C? previousCell,
      checkPreviousCell = false,
      bool updateBackend = true,
      String? rowId,
      bool user = false}) {
    assert((previousCell != null && !checkPreviousCell) || !checkPreviousCell,
        'If checkPreviousCell is true, the function will find the previousCell. PreviousCell is expected to be null');

    /// Convert CellIndex and PanelCellIndex to a simple FtIndex
    ///
    ///
    if (ftIndex case FtIndex cellIndex) {
      ftIndex = FtIndex(row: cellIndex.row, column: cellIndex.column);
    }

    if ((user, cell) case (true, Cell c) when c.noBlank) {
      if (c.value case (null || '')) {
        cell = c.copyWith(validate: 'isBlank') as C;
      } else {
        cell = c.copyWith(validate: '') as C;
      }
    }

    // Clean Previous cell
    //

    if (checkPreviousCell) {
      previousCell = _cell(ftIndex);
    }

    if (previousCell case C previous) {
      _removeCell(ftIndex);

      if (previous.merged case Merged m) {
        if (m.rows > 1) {
          removeMergedCellFromGrid(mergedRows, ftIndex.column, m);
        }
        if (m.columns > 1) {
          removeMergedCellFromGrid(mergedColumns, ftIndex.row, m);
        }
      }
    }
    // Add new/updated cell
    //

    if (cell != null && rows > 1 || columns > 1) {
      final merged = Merged(ftIndex: ftIndex, rows: rows, columns: columns);

      cell = cell?.copyWith(merged: merged) as C?;

      if (rows > 1) {
        mergedRows
            .putIfAbsent(ftIndex.column, () => MergedRows())
            .addMerged(merged);
      }
      if (columns > 1) {
        mergedColumns
            .putIfAbsent(ftIndex.row, () => MergedColumns())
            .addMerged(merged);
      }
    }

    assert(ftIndex.row + rows - 1 < linkedRowRibbons.length,
        'The length of rowRibbon ${linkedRowRibbons.length} is to sort to insert the cell at row from ${ftIndex.row}+to ${ftIndex.row + rows - 1}, use insert at initiation or add rows with insertRowRange first');

    // if (rowRibbons.length < tableRows) {
    //   for (int i = rowRibbons.length; i < tableRows; i++) {
    //     int u = uniqueImmutableRowIndex;

    //     rowRibbons.insertRow(
    //         i,
    //         RecordRowRibbon<C>(
    //             immutableRowIndex: u, rowId: ftIndex.row == i ? rowId : null));
    //   }
    // }

    /// Check RowId
    /// Check updateBackend
    ///
    ///
    if (linkedRowRibbons.indexed[ftIndex.row] case RecordRowRibbon rowRibbon) {
      bool unKnownRowId = rowRibbon.rowId == null;
      String? rowIdFromCell;

      if (cell?.identifier case FtCellIdentifier id) {
        rowIdFromCell = id.rowId;
      }

      rowId = rowRibbon.rowId;

      assert(
          (rowId == null || rowIdFromCell == null) || (rowId == rowIdFromCell),
          'RowId $rowId is not equal to rowId from cell $rowIdFromCell');

      if (rowId == null) {
        rowRibbon.rowId = rowIdFromCell;
      }

      if (updateBackend && rowId != null) {
        assert(rowRibbon.rowId != null,
            'Espected that the rowId was updated!!! ftIndex: $ftIndex');

        if (unKnownRowId) {
          insertIdRow.contains(rowRibbon);
        } else {
          if (!insertIdRow.contains(rowRibbon)) {
            if (!updateIdRow.add(rowRibbon)) {
              debugPrint('RowId alreade in updateIdRow :)');
            }
          }
        }
      }
    }

    _placeCell(ftIndex, cell);

    switch (cell) {
      case (Cell c):
        {
          if (c.ref.isNotEmpty) {
            for (FtIndex imIndex in c.ref) {
              reEvaluation(imIndex);
            }
            return {for (FtIndex i in c.ref) immutableIndexToIndex(i)};
          }
        }
    }
    return null;
  }

  _placeCell(FtIndex ftIndex, C? cell) {
    if (cell case C c) {
      linkedRowRibbons.insertCell(ftIndex, c);
    } else {
      linkedRowRibbons.removeCell(ftIndex);
    }

    if (_unFilteredLinkedRowRibbons case LinkedRowRibbons<C> unfiltered) {
      int? index;
      if (linkedRowRibbons.imRowIndex(ftIndex.row) case int imIndex) {
        index = unfiltered.rowIndex(imIndex);
      }
      index ??= unfiltered.length - 1;
      final unFilteredIndex = ftIndex.copyWith(row: index);

      if (cell case C c) {
        unfiltered.insertCell(unFilteredIndex, c);
      } else {
        unfiltered.removeCell(unFilteredIndex);
      }
    }
  }

  C? _cell(FtIndex ftIndex) {
    return linkedRowRibbons.cell(ftIndex);
  }

  C? _removeCell(FtIndex ftIndex) {
    return linkedRowRibbons.removeCell(ftIndex);
  }

  @override
  C? cell({required int row, required int column}) {
    return linkedRowRibbons.cell(FtIndex(row: row, column: column));
  }

  C? retrieveCell(FtIndex index) {
    if (!index.isIndex) {
      return null;
    }
    return linkedRowRibbons.cell(index);
  }

  Merged? removeMergedCellFromGrid(
      Map<int, MergedRibbon> gridRibbons, int index, Merged merged) {
    if (gridRibbons[index] case MergedRibbon g) {
      var (m, empty) = g.removeMerged(merged: merged);
      if (empty) {
        gridRibbons.remove(index);
      }
      return m;
    }
    return null;
  }

  @override
  Merged? findMergedRows(int row, int column) =>
      mergedRows[column]?.findMerged(index: row, startingOutside: false);

  @override
  Merged? findMergedColumns(int row, int column) =>
      mergedColumns[row]?.findMerged(index: column, startingOutside: false);

  RecordFtModel copyWith({
    double? scrollX0pY0,
    double? scrollX1pY0,
    double? scrollY0pX0,
    double? scrollY1pX0,
    double? scrollX0pY1,
    double? scrollX1pY1,
    double? scrollY0pX1,
    double? scrollY1pX1,
    double? mainScrollX,
    double? mainScrollY,
    double? xSplit,
    double? ySplit,
    bool? rowHeader,
    bool? columnHeader,
    int? tableColumns,
    int? tableRows,
    double? defaultWidthCell,
    double? defaultHeightCell,
    List<RangeProperties>? specificHeight,
    List<RangeProperties>? specificWidth,
    bool? modifySplit,
    bool? scheduleCorrectOffScroll,
    int? topLeftCellPaneColumn,
    int? topLeftCellPaneRow,
    bool? scrollUnlockX,
    bool? scrollUnlockY,
    SplitState? stateSplitX,
    SplitState? stateSplitY,
    double? headerVisibility,
    double? leftPanelMargin,
    double? topPanelMargin,
    double? rightPanelMargin,
    double? bottomPanelMargin,
    double? tableScale,
    List<AutoFreezeArea>? autoFreezeAreasX,
    bool? autoFreezeX,
    List<AutoFreezeArea>? autoFreezeAreasY,
    bool? autoFreezeY,
    double? minSplitSpaceFromSide,
    double? hitScrollBarThickness,
    //Default
    TableLinesOneDirection? horizontalLines,
    TableLinesOneDirection? verticalLines,
    Map<int, MergedColumns>? mergedColumns,
    Map<int, MergedRows>? mergedRows,
    bool? calculationPositionsNeededX,
    bool? calculationPositionsNeededY,
  }) {
    return RecordFtModel(
      xSplit: xSplit ?? this.xSplit,
      ySplit: ySplit ?? this.ySplit,
      rowHeader: rowHeader ?? this.rowHeader,
      columnHeader: columnHeader ?? this.columnHeader,
      tableColumns: tableColumns ?? this.tableColumns,
      tableRows: tableRows ?? this.tableRows,
      defaultWidthCell: defaultWidthCell ?? this.defaultWidthCell,
      defaultHeightCell: defaultHeightCell ?? this.defaultHeightCell,
      specificHeight: specificHeight ?? specificHeight,
      specificWidth: specificWidth ?? specificWidth,
      scrollUnlockX: scrollUnlockX ?? this.scrollUnlockX,
      scrollUnlockY: scrollUnlockY ?? this.scrollUnlockY,
      stateSplitX: stateSplitX ?? this.stateSplitX,
      stateSplitY: stateSplitY ?? this.stateSplitY,
      tableScale: tableScale ?? this.tableScale,
      autoFreezeAreasX: autoFreezeAreasX ?? this.autoFreezeAreasX,
      autoFreezeX: autoFreezeX ?? this.autoFreezeX,
      autoFreezeAreasY: autoFreezeAreasY ?? this.autoFreezeAreasY,
      autoFreezeY: autoFreezeY ?? this.autoFreezeY,
      //Default
      horizontalLines: horizontalLines ?? this.horizontalLines,
      verticalLines: verticalLines ?? this.verticalLines,
      mergedColumns: mergedColumns ?? this.mergedColumns,
      mergedRows: mergedRows ?? this.mergedRows,
      calculationPositionsNeededX: calculationPositionsNeededX ?? true,
      calculationPositionsNeededY: calculationPositionsNeededY ?? true,
    );
  }

  @override
  void didPerformRebuild() {
    // rearrange = const NoRearrangeCells();
  }

  @override
  FtIndex? findIndexByKey(FtIndex oldIndex, key) {
    if (key case ValueKey<FtIndex> v) {
      if (linkedRowRibbons.rowIndex(v.value.row) case int row) {
        return FtIndex(row: row, column: v.value.column);
      }
    }
    return null;
    // return rearrange.findIndexByKey(this, oldIndex, key);
  }

  @override
  FtIndex isCellEditable(FtIndex cellIndex) {
    if (!cellIndex.isIndex) {
      return const FtIndex();
    }
    return switch (cell(row: cellIndex.row, column: cellIndex.column)) {
      (Cell c) when c.editable => cellIndex,
      (_) => const FtIndex()
    };
  }

  @override
  insertRowRange({
    required int startRow,
    int? endRow,
  }) {
    // assert(rearrange is NoRearrangeCells,
    //     'Process the previous RearrangeCells object before adding another range');

    // if (rearrange is! NoRearrangeCells) {
    //   return;
    // }

    // rearrange = InsertDeleteRow(
    //     changeRows: [ChangeRange(start: startRow, last: endRow, insert: true)]);

    for (int i = startRow; i <= (endRow ?? startRow); i++) {
      final rb = RecordRowRibbon<C>(immutableRowIndex: uniqueImmutableRowIndex);

      if (_unFilteredLinkedRowRibbons case LinkedRowRibbons<C> unFiltered) {
        int? index;
        if (linkedRowRibbons.imRowIndex(i) case int imIndex) {
          index = unFiltered.rowIndex(imIndex);
        }
        unFiltered.insertRow(index ?? unFiltered.length, rb);
      }
      linkedRowRibbons.insertRow(i, rb);
      tableRows++;
      insertIdRow.add(rb);
    }
  }

  @override
  removeRowRange({
    required int startRow,
    int? lastRow,
  }) {
    // assert(rearrange is NoRearrangeCells,
    //     'Process the previous RearrangeCells object before adding another range');

    // if (rearrange is! NoRearrangeCells) {
    //   return;
    // }

    // rearrange = InsertDeleteRow(changeRows: [
    //   ChangeRange(start: startRow, last: lastRow, insert: false)
    // ]);

    Set<int> removedImIdex = {};
    for (int i = startRow; i <= (lastRow ?? startRow); i++) {
      final rb = linkedRowRibbons.removeRow(i);

      unUsedImutableRowIndexes.add(rb.immutableRowIndex);
      removedImIdex.add(rb.immutableRowIndex);

      /// If the row is in the insertIdRow, then the row is not inserted in the backend, therefore the row is not added to deltedIdRow
      /// if the row is not in the insertIdRow, then the row is in the backend and should be deleted also remove the row in the updateIdRow
      ///
      if (!insertIdRow.remove(rb)) {
        deletedIdRow.add(rb);
        updateIdRow.remove(rb);
      }
      tableRows--;
    }
    if (_unFilteredLinkedRowRibbons case LinkedRowRibbons<C> unfiltered) {
      unfiltered.removeImIdexes(removedImIdex);
    }
  }

  @override
  FtIndex? indexToImmutableIndex(FtIndex index) {
    return index.isIndex && index.row < linkedRowRibbons.length
        ? index.copyWith(row: linkedRowRibbons.imRowIndex(index.row))
        : null;
  }

  @override
  FtIndex immutableIndexToIndex(FtIndex imIndex) {
    return imIndex.copyWith(row: linkedRowRibbons.rowIndex(imIndex.row) ?? -1);
  }

  @override
  void reIndexUniqueRowNumber() {
    _unFilteredLinkedRowRibbons?.reIndexUniqueRowNumer();
    linkedRowRibbons.reIndexUniqueRowNumer();
  }

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  Map<String, dynamic> retrieveRecordData(
      {String? rowId, int? immutableIndex, int? rowIndex}) {
    assert(
        (rowId == null && rowIndex == null && immutableIndex != null) ||
            (rowId != null && rowIndex == null && immutableIndex == null) ||
            (rowId == null && rowIndex != null && immutableIndex == null),
        'Select one identifier rowId, rowIndex or ImmutableIndex');

    if (rowId case String rowId) {
      for (RecordRowRibbon r in linkedRowRibbons.indexed) {
        if (r.rowId == rowId) {
          return recordToMap(r.column, (_, __) => true);
        }
      }
    } else if (immutableIndex case int imIdex) {
      for (RecordRowRibbon r in linkedRowRibbons.indexed) {
        if (r.immutableRowIndex == imIdex) {
          return recordToMap(r.column, (_, __) => true);
        }
      }
    } else if (rowIndex case int rIndex when rIndex < linkedRowRibbons.length) {
      return recordToMap(linkedRowRibbons.column(rIndex), (_, __) => true);
    }
    return {};
  }

  saveInserts({
    required Future<bool> Function(
            String rowId,
            Map<String, dynamic> map,
            Set<FtIndex> Function(Set<String> columnIds, String validation)
                setValidation)
        save,
    bool Function(int, FtCellIdentifier c)? include,
    required Function(List<CellValidation> list) problems,
    bool cellWarning = true,
  }) async {
    include ??= (_, __) => true;

    Set<RecordRowRibbon> temp = Set.from(insertIdRow);

    insertIdRow.clear();

    for (RecordRowRibbon rr in temp) {
      if (rr.rowId case String rowId) {
        List<CellValidation> listProblem =
            checkCellsForProblems(rr, include, cellWarning);
        if (listProblem.isNotEmpty) {
          problems(listProblem);

          /// Found problem insert RowRibbon back, instead to Insert to database
          ///
          insertIdRow.add(rr);
        } else {
          if (!(await save(rowId, recordToMap(rr.column, include),
              (Set<String> columnIds, String validation) {
            return setValidation(
                rowRibbon: rr, columnIds: columnIds, validation: validation);
          }))) {
            insertIdRow.add(rr);
          }
        }
      }
    }
  }

  saveUpdates(
      {required Future<bool> Function(
              String rowId,
              Map<String, dynamic> map,
              Set<FtIndex> Function(Set<String> columnIds, String validation)
                  setValidation)
          save,
      bool Function(int, FtCellIdentifier c)? include,
      required Function(List<CellValidation> list) problems,
      bool cellWarning = true}) async {
    Set temp = Set.from(updateIdRow);

    updateIdRow.clear();

    include ??= (_, __) => true;

    for (RecordRowRibbon rr in temp) {
      if (rr.rowId case String rowId) {
        List<CellValidation> problemList =
            checkCellsForProblems(rr, include, cellWarning);
        if (problemList.isNotEmpty) {
          problems(problemList);

          /// Found problem insert RowRibbon back, instead to update to database
          ///
          updateIdRow.add(rr);
        } else {
          if (!(await save(rowId, recordToMap(rr.column, include),
              (Set<String> columnIds, String validation) {
            return setValidation(
                rowRibbon: rr, columnIds: columnIds, validation: validation);
          }))) {
            updateIdRow.add(rr);
          }
        }
      }
    }
  }

  saveDeletes({
    required Future<bool> Function(String rowId, Map<String, dynamic> map) save,
    bool Function(int, FtCellIdentifier c)? include,
  }) async {
    Set temp = Set.from(deletedIdRow);
    deletedIdRow.clear();

    include ??= (_, __) => true;

    for (RecordRowRibbon rr in temp) {
      if (rr.rowId case String rowId) {
        if (!(await save(rowId, recordToMap(rr.column, include)))) {
          deletedIdRow.add(rr);
        }
      }
    }
  }

  Map<String, dynamic> recordToMap(HashMap<int, AbstractCell> columns,
      bool Function(int, FtCellIdentifier c) include) {
    Map<String, dynamic> map = {};
    for (var MapEntry(key: column, value: c) in columns.entries) {
      String columnId = '';
      if (c.identifier case FtCellIdentifier c) {
        if (include(column, c)) {
          columnId = c.columnId;
        } else {
          continue;
        }
      } else {
        continue;
      }

      switch (c) {
        case (DigitCell c):
          {
            map[columnId] = c.value;
            break;
          }
        case (DecimalCell c):
          {
            map[columnId] = c.value;
            break;
          }
        case (TextCell c):
          {
            map[columnId] = c.value;
            break;
          }
        case (DateTimeCell c):
          {
            map[columnId] = c.value;
            break;
          }
        case (SelectionCell c):
          {
            map[columnId] = c.value;
            break;
          }
        case (ActionCell c):
          {
            map[columnId] = c.text;

            break;
          }
      }
    }
    return map;
  }

  ///
  ///
  ///

  List<CellValidation> checkCellsForProblems(
      RecordRowRibbon<AbstractCell> rowRibbon,
      bool Function(int, FtCellIdentifier c) include,
      bool cellWarning) {
    int rowIndex = linkedRowRibbons.rowIndex(rowRibbon.immutableRowIndex) ?? -1;
    List<CellValidation> problem = [];

    final columns = rowRibbon.column;
    HashMap<int, AbstractCell> temp = HashMap.from(columns);

    for (var MapEntry(key: column, value: c) in temp.entries) {
      if (c.identifier case FtCellIdentifier ci) {
        if (!include(column, ci)) {
          continue;
        }

        if (c case Cell cell) {
          {
            if ((cell.noBlank, cell.value) case (true, null || '')) {
              if (cellWarning) {
                columns[column] = cell.copyWith(validate: 'isBlank');
              }
              problem.add(CellValidation(
                  cellIdentifier: ci,
                  ftIndex: FtIndex(
                    row: rowIndex,
                    column: column,
                  ),
                  message: 'noBlank'));
            }
          }
        }
      }
    }

    return problem;
  }

  ///
  ///
  ///

  Set<FtIndex> setValidation(
      {required RecordRowRibbon<AbstractCell> rowRibbon,
      required Set<String> columnIds,
      required String validation}) {
    Set<FtIndex> updatedFtIndexes = {};

    final rowIndex =
        linkedRowRibbons.rowIndex(rowRibbon.immutableRowIndex) ?? -1;

    for (var MapEntry(key: column, value: cell) in rowRibbon.column.entries) {
      if ((cell, cell.identifier) case (Cell c, FtCellIdentifier ci)
          when columnIds.contains(ci.columnId)) {
        if (c.validate != validation) {
          c.validate = validation;
          updatedFtIndexes.add(FtIndex(row: rowIndex, column: column));
        }
      }
    }
    return updatedFtIndexes;
  }

  ///
  ///
  ///

  @override
  num? numberValue({FtIndex? index, FtIndex? imIndex}) {
    assert(index != null || imIndex != null,
        'Both index and immutableIndex are null');
    if (index == null && imIndex == null) {
      return null;
    } else if (imIndex != null) {
      index = immutableIndexToIndex(imIndex);
    }
    if (index case FtIndex i) {
      return switch (linkedRowRibbons.cell(i)) {
        (DigitCell c) => c.value,
        (DecimalCell c) => c.value,
        (_) => null
      };
    }

    return null;
  }

  @override
  Object? valueFromIndex({FtIndex? index, required FtIndex? imIndex}) {
    assert(index != null || imIndex != null,
        'Both index and immutableIndex are null');
    if (index == null && imIndex == null) {
      return null;
    } else if (imIndex != null) {
      index = immutableIndexToIndex(imIndex);
    }
    if (index case FtIndex i) {
      return switch (linkedRowRibbons.cell(i)) {
        (Cell c) => c.value,
        (_) => null
      };
    }

    return null;
  }

  @override
  void calculateCell({AbstractCell? cell, FtIndex? index, FtIndex? imIndex}) {
    assert(index != null || imIndex != null,
        'CalculateCell: Index and Immutable index are both null');

    if (imIndex == null && index != null) {
      imIndex = indexToImmutableIndex(index);
    } else if (index == null && imIndex != null) {
      index = immutableIndexToIndex(imIndex);
    }

    if (index == null || imIndex == null) {
      if (cell case CalculationCell c) {
        c
          ..evaluted = true
          ..linked = false
          ..validate = 'Index?';
      }
      return;
    }

    cell ??= retrieveCell(index);

    switch (cell) {
      case (CalculationCell c):
        {
          if (!c.linked) {
            for (int i = 0; i < c.imRefIndex.length; i++) {
              final ii = c.imRefIndex[i];
              final immutableRef = ii.copyWith(
                  row: ii.row == -2 ? imIndex.row : ii.row,
                  column: ii.column == -2 ? imIndex.column : ii.column);

              if (ii != immutableRef) {
                c.imRefIndex[i] = immutableRef;
              }

              if (!linkReference(
                  immutableIndex: imIndex, immutableRef: immutableRef)) {
                c
                  ..evaluted = true
                  ..linked = false
                  ..validate = 'SetRef?';
              }
            }
            c.linked = true;
          }

          ///
          ///
          ///
          List<Object?> values = [
            for (FtIndex i in c.imRefIndex) valueFromIndex(imIndex: i)
          ];

          try {
            final num? calculatedValue = c.calculationSyntax(values);
            c
              ..value = calculatedValue
              ..evaluted = true;
          } catch (e) {
            c
              ..value = null
              ..validate = 'Calc?'
              ..evaluted = true;
          }
        }
      default:
        {}
    }
  }

  bool linkReference(
      {required FtIndex immutableIndex, required FtIndex immutableRef}) {
    if (linkedRowRibbons.rowIndex(immutableRef.row) case int row) {
      switch (linkedRowRibbons.cell(immutableRef.copyWith(row: row))) {
        case (Cell c):
          {
            c.ref.add(immutableIndex);
            return true;
          }
      }
    }
    return false;
  }

  reEvaluation(FtIndex imIndex) {
    if (retrieveCell(immutableIndexToIndex(imIndex))
        case CalculationCell cell) {
      cell.evaluted = false;
    }
  }

  setFilteredList(List<RecordRowRibbon<C>> filteredRibbon) {
    _unFilteredLinkedRowRibbons ??= linkedRowRibbons;
    linkedRowRibbons = LinkedRowRibbons(indexed: filteredRibbon);
    tableRows = filteredRibbon.length;
  }

  undoFilter() {
    if (_unFilteredLinkedRowRibbons case LinkedRowRibbons<C> unFiltered) {
      linkedRowRibbons = unFiltered;
      _unFilteredLinkedRowRibbons = null;
      tableRows = linkedRowRibbons.length;
    }
  }

  List<RecordRowRibbon<C>> get unFilteredRowRibbons =>
      (_unFilteredLinkedRowRibbons ?? linkedRowRibbons).indexed;

  bool get filterInUse => _unFilteredLinkedRowRibbons != null;
}

class RecordRowRibbon<C extends AbstractCell> {
  int immutableRowIndex;
  String? rowId;

  RecordRowRibbon({required this.immutableRowIndex, this.rowId});

  HashMap<int, C> column = HashMap<int, C>();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RecordRowRibbon<C> &&
        other.immutableRowIndex == immutableRowIndex;
  }

  @override
  int get hashCode => immutableRowIndex.hashCode;

  @override
  String toString() =>
      'RecordRowRibbon(immutableRowIndex: $immutableRowIndex, rowId: $rowId column: $column)';
}

abstract class RearrangeCells {
  const RearrangeCells();
  FtIndex? findIndexByKey(RecordFtModel model, FtIndex oldIndex, key);

  FtIndex obtainNewIndex(FtIndex index);
}

class NoRearrangeCells extends RearrangeCells {
  const NoRearrangeCells();
  @override
  FtIndex? findIndexByKey(RecordFtModel model, FtIndex oldIndex, key) =>
      oldIndex;

  @override
  FtIndex obtainNewIndex(FtIndex index) => index;
}

// class InsertDeleteRow extends RearrangeCells {
//   List<ChangeRange> changeRows;

//   InsertDeleteRow({
//     required this.changeRows,
//   });

//   @override
//   FtIndex? findIndexByKey(RecordFtModel model, FtIndex oldIndex, key) {
//     int immutableIndex = -1;
//     if (key is ValueKey<FtIndex>) {
//       immutableIndex = key.value.row;
//     } else {
//       throw Exception();
//     }
//     int swift = 0;
//     int previous = oldIndex.row;
//     for (ChangeRange c in changeRows) {
//       if (previous < c.start) {
//         break;
//       } else if (c.last < previous) {
//         if (c.insert) {
//           swift += c.length;
//         } else {
//           swift -= c.length;
//         }
//       } else {
//         if (c.insert) {
//           swift += c.length;
//           break;
//         } else {
//           return null;
//         }
//       }
//     }

//     if (swift != 0) {
//       int newIndex = oldIndex.row + swift;
//       if (newIndex >= 0 &&
//           newIndex < model.rowRibbon.length &&
//           model.rowRibbon[newIndex].immutableRowIndex == immutableIndex) {
//         return oldIndex.copyWith(row: newIndex);
//       }
//       return null;
//     }
//     return oldIndex;
//   }

//   @override
//   FtIndex obtainNewIndex(FtIndex index) {
//     return index.isIndex
//         ? index.copyWith(row: obtainSwift(changeRows, index.row))
//         : index;
//   }

//   int obtainSwift(List<ChangeRange> changeRanges, int index) {
//     int swift = 0;
//     for (ChangeRange c in changeRanges) {
//       if (index < c.start) {
//         break;
//       } else if (c.last < index) {
//         if (c.insert) {
//           swift += c.length;
//         } else {
//           swift -= c.length;
//         }
//       } else {
//         if (c.insert) {
//           swift += c.length;
//           break;
//         } else {
//           return -1;
//         }
//       }
//     }
//     int newIndex = index + swift;
//     return (0 < newIndex) ? newIndex : -1;
//   }
// }

// class SortRows extends RearrangeCells {
//   const SortRows();
//   @override
//   FtIndex? findIndexByKey(RecordFtModel model, FtIndex oldIndex, key) => null;

//   @override
//   FtIndex obtainNewIndex(FtIndex index) => const FtIndex();
// }

class LinkedRowRibbons<C extends AbstractCell> {
  List<RecordRowRibbon<C>> indexed;
  HashMap<int, int> uniqueRowNumber = HashMap<int, int>();
  bool reImIndex = false;

  LinkedRowRibbons({List<RecordRowRibbon<C>>? indexed})
      : indexed = indexed ?? [],
        reImIndex = indexed?.isNotEmpty ?? false;

  int get length => indexed.length;

  insertCell(FtIndex ftIndex, C cell) {
    indexed[ftIndex.row].column[ftIndex.column] = cell;
  }

  removeCell(FtIndex ftIndex) {
    indexed[ftIndex.row].column.remove(ftIndex.column);
  }

  insertRow(int rowIndex, RecordRowRibbon<C> ribbon) {
    if (!reImIndex) {
      reImIndex = true;
    }
    indexed.insert(rowIndex, ribbon);
  }

  RecordRowRibbon<C> removeRow(int rowIndex) {
    if (!reImIndex) {
      reImIndex = true;
    }
    return indexed.removeAt(rowIndex);
  }

  C? cell(FtIndex ftIndex) {
    return indexed.elementAtOrNull(ftIndex.row)?.column[ftIndex.column];
  }

  int? rowIndex(int imIndex) {
    if (reImIndex) {
      reIndexUniqueRowNumer();
      reImIndex = false;
    }
    return uniqueRowNumber[imIndex];
  }

  int? imRowIndex(int index) =>
      indexed.elementAtOrNull(index)?.immutableRowIndex;

  reIndexUniqueRowNumer() {
    uniqueRowNumber.clear();

    for (int i = 0; i < indexed.length; i++) {
      uniqueRowNumber[indexed[i].immutableRowIndex] = i;
    }
  }

  removeImIdexes(Set<int> imIndexes) {
    indexed
        .removeWhere((ribbon) => imIndexes.contains(ribbon.immutableRowIndex));
    reImIndex = true;
  }

  HashMap<int, C> column(int rowIndex) => indexed[rowIndex].column;
}
