// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
  RearrangeCells rearrange = const NoRearrangeCells();

  void insertCell(
      {required FtIndex ftIndex,
      int rows = 1,
      int columns = 1,
      required C cell,
      checkPreviousCell = false}) {
    if (tableRows < ftIndex.row + rows) {
      tableRows = ftIndex.row + rows;
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

    if (tableRows < ftIndex.row + rows) {
      tableRows = ftIndex.row + rows;
    }

    if (rowRibbon.length < tableRows) {
      rowRibbon.addAll([
        for (int i = rowRibbon.length; i <= tableRows; i++)
          RowRibbon<C>(immutableRowIndex: uniqueImmutableRowIndex)
      ]);
    }

    if (tableColumns < ftIndex.column + columns) {
      tableColumns = ftIndex.column + columns;
    }
    _placeCell(ftIndex, cell);

    return null;
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
  void didPerformRebuild() {
    rearrange = const NoRearrangeCells();
  }

  @override
  FtIndex? findIndexByKey(FtIndex oldIndex, key) {
    return rearrange.findIndexByKey(this, oldIndex, key);
  }

  @override
  FtIndex isCellEditable(FtIndex cellIndex) => cellIndex;

  @override
  insertRowRange({
    required int startRow,
    int? endRow,
  }) {
    assert(rearrange is NoRearrangeCells,
        'Process the previous RearrangeCells object before adding another range');

    if (rearrange is! NoRearrangeCells) {
      return;
    }

    rearrange = InsertDeleteRow(
        changeRows: [ChangeRange(start: startRow, last: endRow, insert: true)]);

    for (int i = startRow; i <= (endRow ?? startRow); i++) {
      rowRibbon.insert(
          i, RowRibbon(immutableRowIndex: uniqueImmutableRowIndex));
      tableRows++;
    }

    editCell = editCell.copyWith(index: rearrange.obtainNewIndex(editCell));
  }

  @override
  removeRowRange({
    required int startRow,
    int? lastRow,
  }) {
    assert(rearrange is NoRearrangeCells,
        'Process the previous RearrangeCells object before adding another range');

    if (rearrange is! NoRearrangeCells) {
      return;
    }

    rearrange = InsertDeleteRow(changeRows: [
      ChangeRange(start: startRow, last: lastRow, insert: false)
    ]);

    for (int i = startRow; i <= (lastRow ?? startRow); i++) {
      unUsedImutableRowIndexes.add(rowRibbon.removeAt(i).immutableRowIndex);
    }

    editCell = editCell.copyWith(index: rearrange.obtainNewIndex(editCell));
  }

  @override
  FtIndex? indexToImmutableIndex(FtIndex index) {
    return index.copyWith(row: rowRibbon[index.row].immutableRowIndex);
  }

  void reIndexUniqueRowNumber() {
    // TODO: implement calculateCell
    throw UnimplementedError();
  }

  @override
  void calculateCell({AbstractCell? cell, FtIndex? index, FtIndex? imIndex}) {
    // TODO: implement calculateCell
    throw UnimplementedError();
  }

  @override
  num? numberValue({FtIndex? index, required FtIndex? imIndex}) {
    // TODO: implement numberValue
    throw UnimplementedError();
  }

  @override
  Object? valueFromIndex({FtIndex? index, required FtIndex? imIndex}) {
    // TODO: implement valueFromIndex
    throw UnimplementedError();
  }
}

class RowRibbon<C extends AbstractCell> {
  int immutableRowIndex;

  RowRibbon({
    required this.immutableRowIndex,
  });

  HashMap<int, C> column = HashMap<int, C>();
}

abstract class RearrangeCells {
  const RearrangeCells();
  FtIndex? findIndexByKey(BasicFtModel model, FtIndex oldIndex, key);

  FtIndex obtainNewIndex(FtIndex index);
}

class NoRearrangeCells extends RearrangeCells {
  const NoRearrangeCells();
  @override
  FtIndex? findIndexByKey(BasicFtModel model, FtIndex oldIndex, key) =>
      oldIndex;

  @override
  FtIndex obtainNewIndex(FtIndex index) => index;
}

class InsertDeleteRow extends RearrangeCells {
  List<ChangeRange> changeRows;

  InsertDeleteRow({
    required this.changeRows,
  });

  @override
  FtIndex? findIndexByKey(BasicFtModel model, FtIndex oldIndex, key) {
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
          newIndex < model.rowRibbon.length &&
          model.rowRibbon[newIndex].immutableRowIndex == immutableIndex) {
        return oldIndex.copyWith(row: newIndex);
      }
      return null;
    }
    return oldIndex;
  }

  @override
  FtIndex obtainNewIndex(FtIndex index) {
    return index.isIndex
        ? index.copyWith(row: obtainSwift(changeRows, index.row))
        : index;
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

class SortRows extends RearrangeCells {
  const SortRows();
  @override
  FtIndex? findIndexByKey(BasicFtModel model, FtIndex oldIndex, key) => null;

  @override
  FtIndex obtainNewIndex(FtIndex index) => const FtIndex();
}
