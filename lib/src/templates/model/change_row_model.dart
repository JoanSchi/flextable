// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:flextable/flextable.dart';
import 'package:flutter/widgets.dart';

import '../../model/properties/flextable_range_properties.dart';

class ChangeRowModel<C extends AbstractCell> extends AbstractFtModel<C> {
  ChangeRowModel({
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
    this.autoTableRange = true,
    TableLinesOneDirection? horizontalLines,
    TableLinesOneDirection? verticalLines,
    Map<int, MergedColumns>? mergedColumns,
    Map<int, MergedRows>? mergedRows,
    super.calculationPositionsNeededX,
    super.calculationPositionsNeededY,
  })  : mergedColumns = mergedColumns ?? HashMap<int, MergedColumns>(),
        mergedRows = mergedRows ?? HashMap<int, MergedRows>(),
        horizontalLines = horizontalLines ?? TableLinesOneDirection(),
        verticalLines = verticalLines ?? TableLinesOneDirection(),
        rowRibbon = List.generate(
            tableRows, (index) => RowRibbon(immutableRowIndex: index));

  bool autoTableRange;
  TableLinesOneDirection horizontalLines;
  TableLinesOneDirection verticalLines;
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
    if (autoTableRange && tableRows < ftIndex.row + rows) {
      tableRows = ftIndex.row + rows;

      if (rowRibbon.length < rows) {
        int needed = tableRows - rowRibbon.length;
        rowRibbon.addAll([
          for (int i = 0; i <= needed; i++)
            RowRibbon<C>(immutableRowIndex: uniqueImmutableRowIndex)
        ]);
      }
    }

    if (autoTableRange && tableColumns < ftIndex.column + columns) {
      tableColumns = ftIndex.column + columns;
    }

    updateCell(ftIndex: ftIndex, cell: cell);
  }

  int get uniqueImmutableRowIndex => unUsedImutableRowIndexes.isNotEmpty
      ? unUsedImutableRowIndexes.removeLast()
      : ++lastImutableIndex;

  @override
  void updateCell(
      {required FtIndex ftIndex,
      int rows = 1,
      int columns = 1,
      required C? cell,
      C? previousCell,
      checkPreviousCell = false}) {
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

    _placeCell(ftIndex, cell);

    if (autoTableRange && tableRows < ftIndex.row + rows) {
      tableRows = ftIndex.row + rows;
    }

    if (autoTableRange && tableColumns < ftIndex.column + columns) {
      tableColumns = ftIndex.column + columns;
    }
  }

  _placeCell(FtIndex ftIndex, C? cell) {
    if (cell case C c) {
      rowRibbon[ftIndex.row].column[ftIndex.column] = c;
    } else {
      rowRibbon[ftIndex.row].column.remove(ftIndex.column);
    }
  }

  C? _cell(FtIndex ftIndex) {
    return rowRibbon.elementAtOrNull(ftIndex.row)?.column[ftIndex.column];
  }

  C? _removeCell(FtIndex ftIndex) {
    return rowRibbon[ftIndex.row].column.remove(ftIndex.column);
  }

  @override
  C? cell({required int row, required int column}) {
    return rowRibbon.elementAtOrNull(row)?.column[column];
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

  ChangeRowModel copyWith({
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
    bool? autoTableRange,
    TableLinesOneDirection? horizontalLines,
    TableLinesOneDirection? verticalLines,
    Map<int, MergedColumns>? mergedColumns,
    Map<int, MergedRows>? mergedRows,
    bool? calculationPositionsNeededX,
    bool? calculationPositionsNeededY,
  }) {
    return ChangeRowModel(
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
      autoTableRange: autoTableRange ?? this.autoTableRange,
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
    changeRows.clear();
  }

  List<ChangeRange> changeRows = [];

  @override
  FtIndex? findIndexByKey(FtIndex oldIndex, key) {
    int immutableIndex = -1;
    if (key is ValueKey<FtIndex>) {
      immutableIndex = key.value.row;
    } else {
      throw Exception();
    }
    int swift = 0;
    int previous = oldIndex.row;
    for (ChangeRange c in changeRows) {
      if (previous < c.start) {
        break;
      } else if (c.last < previous) {
        if (c.insert) {
          swift += c.length;
        } else {
          swift -= c.length;
        }
      } else {
        if (c.insert) {
          swift += c.length;
          break;
        } else {
          return null;
        }
      }
    }

    if (swift != 0) {
      int newIndex = oldIndex.row + swift;
      if (newIndex >= 0 &&
          newIndex < rowRibbon.length &&
          rowRibbon[newIndex].immutableRowIndex == immutableIndex) {
        return oldIndex.copyWith(row: newIndex);
      }
      return null;
    }
    return oldIndex;
  }

  @override
  FtIndex isCellEditable(FtIndex cellIndex) => cellIndex;

  @override
  insertRowRange({
    required int startRow,
    int? endRow,
  }) {
    assert(changeRows.isEmpty,
        'Process the changeRows range first before adding another range');
    changeRows.add(ChangeRange(start: startRow, last: endRow, insert: true));

    for (int i = startRow; i <= (endRow ?? startRow); i++) {
      rowRibbon.insert(
          i, RowRibbon(immutableRowIndex: uniqueImmutableRowIndex));
      tableRows++;
    }

    if ((editCell.isIndex, obtainNewRow(editCell.row)) case (true, int r)) {
      editCell = editCell.copyWith(row: r);
    }
  }

  @override
  removeRowRange({
    required int startRow,
    int? lastRow,
  }) {
    assert(changeRows.isEmpty,
        'Process the row range first before adding another range');

    changeRows.add(ChangeRange(start: startRow, last: lastRow, insert: false));

    for (int i = startRow; i < (lastRow ?? startRow); i++) {
      unUsedImutableRowIndexes.add(rowRibbon.removeAt(i).immutableRowIndex);
    }

    if ((editCell.isIndex, obtainNewRow(editCell.row)) case (true, int r)) {
      editCell = editCell.copyWith(row: r);
    }
  }

  // changeRows.insert(
  //     switch (changeRows.indexWhere(
  //       (element) => element.start > startRow,
  //     )) {
  //       (-1) => 0,
  //       (int i) => i
  //     },
  //     ChangeRange(start: startRow, last: lastRow, insert: false));

  @override
  FtIndex? immutableFtIndex(FtIndex index) {
    return index.copyWith(row: rowRibbon[index.row].immutableRowIndex);
  }

  @override
  int obtainNewRow(int index) {
    return obtainSwift(changeRows, index);
  }

  int obtainSwift(List<ChangeRange> changeRanges, int index) {
    int swift = 0;
    for (ChangeRange c in changeRanges) {
      if (index < c.start) {
        break;
      } else if (c.last < index) {
        if (c.insert) {
          swift += c.length;
        } else {
          swift -= c.length;
        }
      } else {
        if (c.insert) {
          swift += c.length;
          break;
        } else {
          return -1;
        }
      }
    }
    int newIndex = index + swift;
    return (0 < newIndex) ? newIndex : -1;
  }
}

class RowRibbon<C extends AbstractCell> {
  int immutableRowIndex;

  RowRibbon({
    required this.immutableRowIndex,
  });

  HashMap<int, C> column = HashMap<int, C>();
}
