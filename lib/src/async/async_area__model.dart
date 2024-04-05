import 'dart:collection';
import 'package:flextable/flextable.dart';

class AsyncAreaModel extends BasicFtModel<Cell> {
  AsyncAreaModel(
      {super.tableColumns,
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
      super.horizontalLines,
      super.verticalLines,
      super.mergedColumns,
      super.mergedRows,
      super.calculationPositionsNeededX,
      super.calculationPositionsNeededY});

  /// Farmresult
  ///
  ///
  ///

  Queue queue = Queue();
  SplayTreeMap<FtIndex, AreaInitializer> areaInitializerMap = SplayTreeMap();
  TableAreaQueue tableAreaQueue = TableAreaQueue();

  addAreaInitializer(AreaInitializer ai) {
    areaInitializerMap[ai.leftTopIndex] = ai;

    if (tableRows < ai.rightBottomIndex.row) {
      tableRows = ai.rightBottomIndex.row;
    }

    if (tableColumns < ai.rightBottomIndex.column) {
      tableColumns = ai.rightBottomIndex.column;
    }
  }

  placeInQuee(CreateTableArea area) {
    tableAreaQueue.addToQueue(area);
  }

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  @override
  Cell? cell({required int row, required int column}) {
    Cell? cell = super.cell(row: row, column: column);

    switch (cell) {
      case (Cell v):
        {
          if (v.cellState == FtCellState.removedFromQuee) {
            cell = obtainCellFromRowAreaFinder(
                row: row, column: column, cellGroupState: v.groupState);
          }
          break;
        }

      case (_):
        {
          cell = obtainCellFromRowAreaFinder(
            row: row,
            column: column,
          );
        }
    }

    return cell;
  }

  Cell? obtainCellFromRowAreaFinder(
      {required int row,
      required int column,
      FtCellGroupState? cellGroupState}) {
    if (areaInitializerMap.lastKeyBefore(FtIndex(row: row, column: column + 1))
        case FtIndex firstIndex) {
      if (areaInitializerMap[firstIndex] case AreaInitializer ai) {
        if (ai.cell(
            model: this,
            ftIndex: FtIndex(row: row, column: column),
            cellGroupState: cellGroupState)) {
          return super.cell(row: row, column: column);
        }
      }
    }
    return null;
  }

  @override
  ({FtIndex ftIndex, Cell? cell}) isCellEditable(FtIndex cellIndex) {
    final c = cell(row: cellIndex.row, column: cellIndex.column);
    return (c?.editable ?? false)
        ? (ftIndex: cellIndex, cell: c)
        : (ftIndex: const FtIndex(), cell: null);
  }

  @override
  AsyncAreaModel copyWith(
      {double? scrollX0pY0,
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
      bool? calculationPositionsNeededY}) {
    return AsyncAreaModel(
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
}
