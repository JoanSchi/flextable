// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';
import '../../../flextable.dart';

typedef DefaultFtModel = FtModel<Cell>;
typedef DefaultFtViewModel = FtViewModel<FtModel<Cell>, Cell>;
typedef DefaultFtController = FtController<FtModel<Cell>, Cell>;

class FtModel<C extends AbstractCell> extends AbstractFtModel<C> {
  FtModel({
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
        verticalLines = verticalLines ?? TableLinesOneDirection();

  bool autoTableRange;
  TableLinesOneDirection horizontalLines;
  TableLinesOneDirection verticalLines;
  final Map<int, MergedColumns> mergedColumns;
  final Map<int, MergedRows> mergedRows;

  final _cells = HashMap<FtIndex, C>();

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
      previousCell = _cells[ftIndex];
    }

    if (previousCell case C previous) {
      _cells.remove(ftIndex);

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
  }

  _placeCell(FtIndex ftIndex, C? cell) {
    if (cell case C c) {
      _cells[ftIndex] = c;
    } else {
      _cells.remove(ftIndex);
    }
  }

  @override
  C? cell({required int row, required int column}) {
    return _cells[FtIndex(row: row, column: column)];
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

  FtModel copyWith({
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
    return FtModel(
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
  FtIndex isCellEditable(FtIndex cellIndex) => cellIndex;
}
