// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:flextable/flextable.dart';

class BasicFtModel<C extends AbstractCell> extends AbstractFtModel<C> {
  BasicFtModel({
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
        rowRibbon = List.generate(
            tableRows, (index) => RowRibbon(immutableRowIndex: index));

  final Map<int, MergedColumns> mergedColumns;
  final Map<int, MergedRows> mergedRows;
  List<RowRibbon<C>> rowRibbon;
  int lastImutableIndex = 0;
  List<int> unUsedImutableRowIndexes = [];

  void insertCell(
      {required FtIndex ftIndex,
      int rows = 1,
      int columns = 1,
      required C cell,
      checkPreviousCell = false}) {
    if (tableRows < ftIndex.row + rows) {
      tableRows = ftIndex.row + rows;
    }
    if (tableColumns < ftIndex.column + columns) {
      tableColumns = ftIndex.column + columns;
    }

    updateCell(ftIndex: ftIndex, cell: cell, rows: rows, columns: columns);
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
      bool user = false}) {
    assert((previousCell != null && !checkPreviousCell) || !checkPreviousCell,
        'If checkPreviousCell is true, the function will find the previousCell. PreviousCell is expected to be null');

    /// Convert CellIndex and PanelCellIndex to a simple FtIndex
    ///
    ///
    if (ftIndex case FtIndex cellIndex) {
      ftIndex = FtIndex(row: cellIndex.row, column: cellIndex.column);
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

    assert(ftIndex.row + rows <= tableRows,
        'TableRows $tableRows is not larger than lastest index: ${ftIndex.row + rows - 1}');

    assert(ftIndex.column + columns <= tableColumns,
        'TableColumns $tableColumns is not larger than lastest index: ${ftIndex.column + columns - 1}');

    if (rowRibbon.length < tableRows) {
      rowRibbon.addAll([
        for (int i = rowRibbon.length; i <= tableRows; i++)
          RowRibbon<C>(immutableRowIndex: uniqueImmutableRowIndex)
      ]);
    }

    _placeCell(ftIndex, cell);

    return null;
  }

  _placeCell(FtIndex ftIndex, C? cell) {
    rowRibbon[ftIndex.row].addCell(ftIndex.column, cell);
  }

  C? _cell(FtIndex ftIndex) {
    return rowRibbon.elementAtOrNull(ftIndex.row)?.cell(ftIndex.column);
  }

  C? _removeCell(FtIndex ftIndex) {
    return rowRibbon[ftIndex.row].removeCell(ftIndex.column);
  }

  @override
  C? cell({required int row, required int column}) {
    return rowRibbon.elementAtOrNull(row)?.cell(column);
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

  BasicFtModel copyWith({
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
    return BasicFtModel(
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
  FtIndex? findIndexByKey(FtIndex oldIndex, key) {
    return null;
  }

  @override
  ({FtIndex ftIndex, C? cell}) isCellEditable(FtIndex cellIndex) =>
      (ftIndex: cellIndex, cell: null);

  @override
  insertRowRange({
    required int startRow,
    int? endRow,
  }) {}

  @override
  removeRowRange({
    required int startRow,
    int? lastRow,
  }) {}

  @override
  FtIndex? indexToImmutableIndex(FtIndex index) {
    return index.copyWith(row: rowRibbon[index.row].immutableRowIndex);
  }

  @override
  void reIndexUniqueRowNumber() {
    throw UnimplementedError();
  }

  @override
  void calculateCell({AbstractCell? cell, FtIndex? index, FtIndex? imIndex}) {
    throw UnimplementedError();
  }

  @override
  num? numberValue({FtIndex? index, required FtIndex? imIndex}) {
    throw UnimplementedError();
  }

  @override
  Object? valueFromIndex({FtIndex? index, required FtIndex? imIndex}) {
    throw UnimplementedError();
  }
}

class RowRibbon<C extends AbstractCell> {
  int immutableRowIndex;
  final List<C?> _columns = <C?>[];

  RowRibbon({
    required this.immutableRowIndex,
  });

  addCell(int column, C? cell) {
    final l = _columns.length;
    if (column < l) {
      _columns[column] = cell;
    } else {
      for (int i = l; i < column; i++) {
        _columns.insert(i, null);
      }

      assert(column == _columns.length,
          'Cell not added at the end of the list column: $column, length list: ${_columns.length}');

      _columns.insert(column, cell);
    }
  }

  C? removeCell(int column) {
    C? cell;
    if (column < _columns.length) {
      cell = _columns[column];
      _columns[column] = null;
    }
    return cell;
  }

  List<(int, C)> filterCells(bool Function(int index, C cell) filter) {
    return [
      for (int i = 0; i < _columns.length; i++)
        if (_columns[i] case C c)
          if (filter(i, c)) (i, c)
    ];
  }

  C? cell(int column) => _columns.elementAtOrNull(column);
}
