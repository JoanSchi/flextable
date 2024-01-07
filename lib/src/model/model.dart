// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/model/grid_ribbon.dart';
import 'package:flutter/foundation.dart';
import '../builders/cells.dart';
import 'properties/flextable_grid_info.dart';
import 'properties/flextable_selection_index.dart';

const int keepSearching = -5;

enum FreezeLine { horizontal, vertical, both, none }

enum FreezeAction { noAction, freeze, unFreeze }

enum SplitState {
  noSplit,
  freezeSplit,
  autoFreezeSplit,
  split,
  canceledFreezeSplit,
  canceledSplit
}

bool noSplit(SplitState split) =>
    split == SplitState.noSplit ||
    split == SplitState.canceledFreezeSplit ||
    split == SplitState.canceledSplit;

bool noManualSplit(SplitState split) =>
    split == SplitState.noSplit ||
    split == SplitState.autoFreezeSplit ||
    split == SplitState.canceledFreezeSplit ||
    split == SplitState.canceledSplit;

typedef DefaultFtModel = FtModel<Cell>;

class FtModel<C extends AbstractCell> extends AbstractFtModel<C> {
  FtModel(
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
      super.autoFreezeAreasX = const [],
      super.autoFreezeX,
      super.autoFreezeAreasY = const [],
      super.autoFreezeY,

      //Default
      this.autoTableRange = true,
      TableLinesOneDirection? horizontalLines,
      TableLinesOneDirection? verticalLines,
      List<RowRibbon<C>?>? rowRibbon,
      List<ColumnRibbon?>? columnRibbon})
      : _rowRibbon = rowRibbon ?? <RowRibbon<C>?>[],
        _columnRibbon = columnRibbon ?? <ColumnRibbon?>[],
        horizontalLines = horizontalLines ?? TableLinesOneDirection(),
        verticalLines = verticalLines ?? TableLinesOneDirection();

  bool autoTableRange;
  TableLinesOneDirection horizontalLines;
  TableLinesOneDirection verticalLines;
  final List<RowRibbon<C>?> _rowRibbon;
  final List<ColumnRibbon?> _columnRibbon;

  GridRibbon ribbon<GridRibbon>(int index, List<GridRibbon?> list, newRibbon) {
    GridRibbon? ribbon;

    if (index < list.length) {
      ribbon = list[index];

      if (ribbon == null) {
        ribbon = newRibbon();
        list[index] = ribbon;
      }
    } else {
      list.length = index + 1;
      ribbon = newRibbon();
      list[index] = ribbon;
    }

    assert(ribbon != null, 'No Ribbon found');

    return ribbon!;
  }

  void addCell(
      {required int row,
      required int column,
      int rows = 1,
      int columns = 1,
      required C? cell,
      C? previousCell}) {
    RowRibbon<C> tableRow =
        ribbon<RowRibbon<C>>(row, _rowRibbon, () => RowRibbon<C>());

    _placeCell(tableRow, column, cell);

    if (cell != null && rows > 1 || columns > 1) {
      final merged = Merged(
          startRow: row,
          startColumn: column,
          lastRow: row + rows - 1,
          lastColumn: column + columns - 1);

      cell!.merged = merged;

      if (rows > 1) {
        columnRibbon(column).addMerged(merged);
      }
      if (columns > 1) {
        rowRibbon(row).addMerged(merged);
      }
    }

    if (autoTableRange && tableRows < row + rows) {
      tableRows = row + rows;
    }

    if (autoTableRange && tableColumns < column + columns) {
      tableColumns = column + columns;
    }
  }

  _placeCell(RowRibbon<C> rowRibbon, int column, C? cell) {
    List<C?> columnList = rowRibbon.columnList;

    if (column >= columnList.length) {
      columnList.length = column + 1;
    }

    columnList[column] = cell;

    return rowRibbon;
  }

  @override
  C? cell({required int row, required int column}) {
    if (row < _rowRibbon.length) {
      final tableRow = _rowRibbon[row];

      final columnList = tableRow?.columnList;

      if (columnList != null && column < columnList.length) {
        return columnList[column];
      }
    }
    return null;
  }

  GridRibbon columnRibbon(int index) {
    return ribbon<GridRibbon>(index, _columnRibbon, () => ColumnRibbon());
  }

  GridRibbon rowRibbon(int index) {
    return ribbon<RowRibbon>(index, _rowRibbon, () => RowRibbon());
  }

  @override
  Merged? findMergedRows(int row, int column) {
    return (column < _columnRibbon.length)
        ? _columnRibbon[column]?.findMerged(index: row, startingOutside: false)
        : null;
  }

  @override
  Merged? findMergedColumns(int row, int column) {
    return (row < _rowRibbon.length)
        ? _rowRibbon[row]?.findMerged(index: column, startingOutside: false)
        : null;
  }

  // _addMerged(
  //     {required C cell,
  //     required int row,
  //     required int column,
  //     required int rows,
  //     required int columns}) {
  //   cell.merged = Merged(
  //       startRow: row,
  //       startColumn: column,
  //       lastRow: row + rows - 1,
  //       lastColumn: column + columns - 1);

  //   if (columns == 1) {
  //     _addMergeOneDirection(
  //         gridRibbon: columnRibbon(column), merged: cell.merged!);
  //   } else if (rows == 1) {
  //     _addMergeOneDirection(gridRibbon: rowRibbon(row), merged: cell.merged!);
  //   }
  // }

  // addMergeOneDirection(
  //     {required GridRibbon gridRibbon, required Merged merged}) {
  //   final startIndex = (merged.startRow == merged.lastRow)
  //       ? merged.startColumn
  //       : merged.startRow;
  //   final indexInList = (merged.startRow == merged.lastRow)
  //       ? (i) => gridRibbon.mergedList[i].startColumn
  //       : (i) => gridRibbon.mergedList[i].startRow;
  //   final length = gridRibbon.mergedList.length;

  //   int i = 0;

  //   while (i < length && startIndex > indexInList(i)) {
  //     i++;
  //   }

  //   gridRibbon.mergedList.insert(i, merged);
  // }

  FtModel copyWith(
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
      bool? autoTableRange,
      TableLinesOneDirection? horizontalLineList,
      TableLinesOneDirection? verticalLineList,
      List<RowRibbon?>? rowRibbon,
      List<ColumnRibbon?>? columnRibbon}) {
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
      horizontalLines: horizontalLineList ?? this.horizontalLines,
      verticalLines: verticalLineList ?? this.verticalLines,
      rowRibbon: rowRibbon ?? _rowRibbon,
      columnRibbon: columnRibbon ?? _columnRibbon,
    );
  }

  @override
  void updateCell(C? previousCell, C? cell, CellIndex cellIndex) {
    RowRibbon<C> tableRow =
        ribbon<RowRibbon<C>>(cellIndex.row, _rowRibbon, () => RowRibbon<C>());

    if (tableRow.columnList.elementAtOrNull(cellIndex.column)?.merged
        case Merged merged) {
      if (merged.columns > 1) {}
    }

    if (previousCell?.merged case Merged m) {
      if (m.rows > 1) {
        columnRibbon(cellIndex.column).removeMerged(merged: m);
      }
      if (m.columns > 1) {
        rowRibbon(cellIndex.row).removeMerged(merged: m);
      }
    }
    addCell(
        row: cellIndex.row,
        column: cellIndex.column,
        rows: cellIndex.rows,
        columns: cellIndex.columns,
        cell: cell);
  }
}

abstract class AbstractFtModel<C extends AbstractCell> {
  AbstractFtModel({
    this.tableColumns = 0,
    this.tableRows = 0,
    required this.defaultWidthCell,
    required this.defaultHeightCell,
    this.stateSplitX = SplitState.noSplit,
    this.stateSplitY = SplitState.noSplit,
    double xSplit = 0.0,
    double ySplit = 0.0,
    this.rowHeader = false,
    this.columnHeader = false,
    this.scrollUnlockX = false,
    this.scrollUnlockY = false,
    int freezeColumns = -1,
    int freezeRows = -1,
    List<RangeProperties>? specificHeight,
    List<RangeProperties>? specificWidth,
    this.tableScale = 1.0,
    this.autoFreezeAreasX = const [],
    bool? autoFreezeX,
    this.autoFreezeAreasY = const [],
    bool? autoFreezeY,
  })  : _autoFreezeX = autoFreezeX,
        _autoFreezeY = autoFreezeY,
        assert(
            !(stateSplitX == SplitState.freezeSplit &&
                stateSplitY == SplitState.split),
            'Freezesplit and split can not used together, select one split type or none!'),
        assert(
            !(stateSplitY == SplitState.freezeSplit &&
                stateSplitX == SplitState.split),
            'Freezesplit and split can not used together, select one split type or none!'),
        assert(
            stateSplitX == SplitState.freezeSplit ? freezeColumns != -1 : true,
            'Select the number of columns to freeze'),
        assert(stateSplitY == SplitState.freezeSplit ? freezeRows != -1 : true,
            'Select the number of rows to freeze'),
        specificWidth = specificWidth ?? [],
        specificHeight = specificHeight ?? [],
        assert(() {
          int index = -1;
          int autoFreezeIndex = 0;
          for (AutoFreezeArea f in autoFreezeAreasX) {
            if (f.startIndex <= index) {
              if (index == -1) {
                debugPrint(
                    'AutoFreezeArea $autoFreezeIndex: StartIndex should start at 0 or higher, current index: ${f.startIndex}');
              } else {
                debugPrint(
                    'AutoFreezeArea $autoFreezeIndex: StartIndex should be greater than the endIndex of the previous autoFreezeArea: {$index}');
              }
              return false;
            }
            index = f.startIndex;

            if (f.freezeIndex <= index) {
              debugPrint(
                  'AutoFreezeArea $autoFreezeIndex: FreezeIndex should be greater than the startIndex: $index');
              return false;
            }
            index = f.freezeIndex;

            if (f.endIndex <= index) {
              debugPrint(
                  'AutoFreezeArea $autoFreezeIndex: EndIndex should be greater than the freezeIndex: $index');
              return false;
            }
            index = f.endIndex;

            autoFreezeIndex++;
          }
          return true;
        }()),
        assert(() {
          int index = -1;
          int autoFreezeIndex = 0;
          for (AutoFreezeArea f in autoFreezeAreasY) {
            if (f.startIndex <= index) {
              if (index == -1) {
                debugPrint(
                    'AutoFreezeArea $autoFreezeIndex: StartIndex should start at 0 or higher, current index: ${f.startIndex}');
              } else {
                debugPrint(
                    'AutoFreezeArea $autoFreezeIndex: StartIndex should be greater than the endIndex of the previous autoFreezeArea: {$index}');
              }
              return false;
            }
            index = f.startIndex;

            if (f.freezeIndex <= index) {
              debugPrint(
                  'AutoFreezeArea $autoFreezeIndex: FreezeIndex should be greater than the startIndex: $index');
              return false;
            }
            index = f.freezeIndex;

            if (f.endIndex <= index) {
              debugPrint(
                  'AutoFreezeArea $autoFreezeIndex: EndIndex should be greater than the freezeIndex: $index');
              return false;
            }
            index = f.endIndex;

            autoFreezeIndex++;
          }
          return true;
        }());

  double scrollX0pY0 = 0.0;
  double scrollX1pY0 = 0.0;
  double scrollY0pX0 = 0.0;
  double scrollY1pX0 = 0.0;
  double scrollX0pY1 = 0.0;
  double scrollX1pY1 = 0.0;
  double scrollY0pX1 = 0.0;
  double scrollY1pX1 = 0.0;
  double mainScrollX = 0.0;
  double mainScrollY = 0.0;
  double xSplit = 0.0;
  double ySplit = 0.0;
  bool rowHeader;
  bool columnHeader;
  int tableColumns;
  int tableRows;
  double defaultWidthCell;
  double defaultHeightCell;
  List<RangeProperties> specificHeight;
  List<RangeProperties> specificWidth;

  int topLeftCellPaneColumn = 0;
  int topLeftCellPaneRow = 0;

  bool scrollUnlockX = false;
  bool scrollUnlockY = false;

  SplitState stateSplitX;
  SplitState stateSplitY;

  double tableScale;

  List<AutoFreezeArea> autoFreezeAreasX;
  bool? _autoFreezeX;

  set autoFreezeX(bool value) {
    _autoFreezeX = value;
  }

  bool get autoFreezeX => _autoFreezeX ?? autoFreezeAreasX.isNotEmpty;

  List<AutoFreezeArea> autoFreezeAreasY;
  bool? _autoFreezeY;

  set autoFreezeY(bool value) {
    _autoFreezeY = value;
  }

  bool get autoFreezeY => _autoFreezeY ?? autoFreezeAreasY.isNotEmpty;

  bool get noSplitX =>
      stateSplitX == SplitState.noSplit ||
      stateSplitX == SplitState.canceledFreezeSplit ||
      stateSplitX == SplitState.canceledSplit;

  bool get noSplitY =>
      stateSplitY == SplitState.noSplit ||
      stateSplitY == SplitState.canceledFreezeSplit ||
      stateSplitY == SplitState.canceledSplit;

  bool get anySplitX =>
      stateSplitX == SplitState.freezeSplit ||
      stateSplitX == SplitState.split ||
      stateSplitX == SplitState.autoFreezeSplit;

  bool get anySplitY =>
      stateSplitY == SplitState.freezeSplit ||
      stateSplitY == SplitState.split ||
      stateSplitY == SplitState.autoFreezeSplit;

  bool get anyFreezeSplitX =>
      stateSplitX == SplitState.freezeSplit ||
      stateSplitX == SplitState.autoFreezeSplit;

  bool get anyFreezeSplitY =>
      stateSplitY == SplitState.freezeSplit ||
      stateSplitY == SplitState.autoFreezeSplit;

  bool get splitX => stateSplitX == SplitState.split;

  bool get splitY => stateSplitY == SplitState.split;

  bool get protectedScrollUnlockX =>
      ((!autoFreezeX || autoFreezeAreasX.isEmpty) &&
                  stateSplitX == SplitState.noSplit) ||
              stateSplitX == SplitState.split
          ? scrollUnlockX
          : false;

  bool get protectedScrollUnlockY =>
      ((!autoFreezeY || autoFreezeAreasY.isEmpty) &&
                  stateSplitY == SplitState.noSplit) ||
              stateSplitY == SplitState.split
          ? scrollUnlockY
          : false;

  bool get manualFreezePossible =>
      !autoFreezeX ||
      autoFreezeAreasX.isEmpty ||
      !autoFreezeY ||
      autoFreezeAreasY.isEmpty;

  bool get autoFreezePossibleX =>
      autoFreezeX &&
      stateSplitX != SplitState.split &&
      autoFreezeAreasX.isNotEmpty;

  bool get autoFreezePossibleY =>
      autoFreezeY &&
      stateSplitY != SplitState.split &&
      autoFreezeAreasY.isNotEmpty;

  C? cell({required int row, required int column});

  Merged? findMergedRows(int row, int column);

  Merged? findMergedColumns(int row, int column);

  /// Lenght en Position
  ///
  ///
  ///
  ///
  ///
  ///

  double get sheetWidth => _getSheetLength(specificWidth);

  double get sheetHeight => _getSheetLength(specificHeight);

  double _getSheetLength(List<RangeProperties> specificLength) {
    double defaultCellLength = (specificWidth == specificLength)
        ? defaultWidthCell
        : defaultHeightCell;
    int maxCells = (specificWidth == specificLength) ? tableColumns : tableRows;

    if (specificLength.isEmpty) {
      return defaultCellLength * maxCells;
    }

    double length = 0.0;
    int first = 0;

    for (var cp in specificLength) {
      if (first < cp.min) {
        length += (cp.min - first) * defaultCellLength;
      }

      double l = cp.length ?? defaultCellLength;

      if (cp.max < maxCells) {
        length += (cp.max - cp.min + 1) * l;
      } else {
        length += (maxCells - cp.min) * l;
        return length;
      }

      first = cp.max + 1;
    }

    length += defaultCellLength * (maxCells - first);

    return length;
  }

  double getX(
    column,
    pc,
  ) =>
      _getPosition(column, pc, specificWidth);

  double getY(
    row,
    pc,
  ) =>
      _getPosition(row, pc, specificHeight);

  double _getPosition(int index, int pc, List<RangeProperties> specificLength) {
    /* Start of the cell
			 *
			 */

    double defaultLength = ((specificLength == specificWidth)
        ? defaultWidthCell
        : defaultHeightCell);

    if (specificLength.isEmpty) {
      return defaultLength * (index + pc);
    }

    double length = 0;
    int first = 0;

    for (RangeProperties cp in specificLength) {
      if (index < cp.min) {
        length += (index - first + pc) * defaultLength;
        return length;
      } else if (first < cp.min) {
        length += (cp.min - first) * defaultLength;
      }

      double l = cp.length ?? defaultLength;

      if (index > cp.max) {
        if (!(cp.hidden || cp.collapsed)) {
          length += (cp.max - cp.min + 1) * l;
        }
      } else {
        if (!(cp.hidden || cp.collapsed)) {
          length += (index - cp.min + pc) * l; //without +1
        }
        return length;
      }

      first = cp.max + 1;
    }

    if (first < index) {
      length += ((specificLength == specificWidth)
              ? defaultWidthCell
              : defaultHeightCell) *
          (index - first + pc);
    }

    return length;
  }

  /// GrindInfoList
  ///
  ///
  ///
  ///
  ///

  gridInfoListX(
          {required double begin,
          required double end,
          required List<GridInfo> columnInfoList}) =>
      _gridInfoList(
          specificLength: specificWidth,
          begin: begin,
          end: end,
          defaultLength: defaultWidthCell,
          size: tableColumns,
          infoGridList: columnInfoList);

  gridInfoListY(
          {required double begin,
          required double end,
          required List<GridInfo> rowInfoList}) =>
      _gridInfoList(
          specificLength: specificHeight,
          begin: begin,
          end: end,
          defaultLength: defaultHeightCell,
          size: tableRows,
          infoGridList: rowInfoList);

  _gridInfoList(
      {required List<RangeProperties> specificLength,
      required double begin,
      required double end,
      required double defaultLength,
      required int size,
      required List<GridInfo> infoGridList}) {
    int index = 0;
    double currentLength = 0.0;

    infoGridList.clear();

    bool find(int max, double length, bool visible, int listIndex) {
      if (visible) {
        double lengthAtEnd = currentLength + (max - index) * length;

        if (begin > lengthAtEnd) {
          currentLength = lengthAtEnd;
          index = max;
        } else {
          if (currentLength < begin) {
            var delta = (begin - currentLength) ~/ length;
            index += delta;
            currentLength += delta * length;
          }

          if (end <= currentLength + (max - index) * length) {
            var endDeltaIndex = index + (end - currentLength) ~/ length + 1;

            if (endDeltaIndex > max) {
              endDeltaIndex = max;
            }

            for (var i = index; i < endDeltaIndex; i++) {
              infoGridList.add(GridInfo(
                  index: i,
                  length: length,
                  position: currentLength,
                  listIndex: listIndex));
              currentLength += length;
            }

            return true;
          } else {
            for (var i = index; i < max; i++) {
              infoGridList.add(GridInfo(
                  index: i,
                  length: length,
                  position: currentLength,
                  listIndex: listIndex));
              currentLength += length;
            }

            index = max;
          }
        }
      } else {
        index = max;
      }

      return false;
    }

    int listLength = specificLength.length;

    for (int i = 0; i < listLength; i++) {
      final cp = specificLength[i];

      if (index < cp.min) {
        if (find(cp.min, defaultLength, true, i)) {
          return;
        }
      }

      if (index == cp.min) {
        if (find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed), i)) {
          return;
        }
      } else {
        assert(index <= cp.max,
            'Index $index should be equal or smaller then max ${cp.max}');
      }
    }

    find(size, defaultLength, true, listLength);
  }

  /// Find Index
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  SelectionIndex findSelectionIndexX(
    x,
    plusOne,
  ) =>
      _findIndex(x, specificWidth, plusOne, tableColumns, defaultWidthCell);

  SelectionIndex findSelectionIndexY(
    y,
    plusOne,
  ) =>
      _findIndex(y, specificHeight, plusOne, tableRows, defaultHeightCell);

  SelectionIndex _findIndex(
      double distance,
      List<RangeProperties> specificLength,
      int plusOne,
      int maximumCells,
      double defaultLength) {
    int found = keepSearching;

    if (specificLength.isEmpty) {
      found = distance ~/ defaultLength;
    } else {
      double length = 0;
      int findIndex = 0;

      for (RangeProperties cp in specificLength) {
        if (findIndex < cp.min) {
          double lengthDefaultSection = (cp.min - findIndex) * defaultLength;

          if (distance < length + lengthDefaultSection) {
            findIndex += (distance - length) ~/ defaultLength;
            found = findIndex;
            break;
          } else {
            length += lengthDefaultSection;
            findIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double l = cp.length ?? defaultLength;
          double lengthCostumSection = (cp.max - cp.min + 1) * l;

          if (distance < length + lengthCostumSection) {
            findIndex += (distance - length) ~/ l;
            found = findIndex;
            break;
          } else {
            length += lengthCostumSection;
            findIndex += cp.max - cp.min + 1;
          }
        } else {
          findIndex = cp.max + 1;
        }
      }

      if (found == keepSearching) {
        findIndex += (distance - length) ~/ defaultLength;
        found = findIndex;
      }
    }

    found += plusOne;

    if (found < 0) {
      found = 0;
    } else if (found > maximumCells) {
      found = maximumCells;
    }

    return _findSelectionIndex(specificLength, found);
  }

  SelectionIndex _findSelectionIndex(
      List<RangeProperties> specificLength, int found) {
    bool firstFound = false, secondFound = false;
    int hiddenStartIndex = -1, maximumHiddenStartIndex = 0;

    int hiddenLastIndex = -1;

    for (RangeProperties cp in specificLength) {
      /* Find start_screen index
             *
             */
      if (!firstFound) {
        if (found > cp.max) {
          if (cp.hidden || cp.collapsed) {
            if (hiddenStartIndex == -1 ||
                maximumHiddenStartIndex + 1 < cp.min) {
              hiddenStartIndex = cp.min;
            }
            maximumHiddenStartIndex = cp.max;
          } else {
            hiddenStartIndex = -1;
          }
        } else {
          firstFound = true;
        }
      }

      /* Find last index
             *
             */
      if (!secondFound) {
        if (cp.min > found &&
            hiddenLastIndex != -1 &&
            hiddenLastIndex < cp.min) {
          secondFound = true;
        } else if (cp.hidden || cp.collapsed) {
          if (cp.min == found || hiddenLastIndex == cp.min) {
            hiddenLastIndex = cp.max + 1;
          }
        }
      }

      if (firstFound && secondFound) {
        break;
      }
    }

    /* Find start_screen index
         *
         */
    if (hiddenStartIndex != -1 && maximumHiddenStartIndex + 1 != found) {
      hiddenStartIndex = -1;
    }

    return SelectionIndex(
        indexStart: hiddenStartIndex != -1 ? hiddenStartIndex : found,
        indexLast: hiddenLastIndex != -1 ? hiddenLastIndex : found);
  }

  /// FindIntersection
  ///
  ///
  ///
  ///
  ///
  ///

  int findIntersectionIndexX(
          {required double distance, required double radial}) =>
      _findIntersectionIndex(
          distance, specificWidth, tableColumns, defaultWidthCell, radial);

  int findIntersectionIndexY(
          {required double distance, required double radial}) =>
      _findIntersectionIndex(
          distance, specificHeight, tableRows, defaultHeightCell, radial);

  int _findIntersectionIndex(
      double distance,
      List<RangeProperties> specificLength,
      int maximumCells,
      double defaultLength,
      double radial) {
    int findIndexWitinRadial(int currentIndex, double distance,
        double lengthEvaluated, double length) {
      final r = length / 3.0 < radial ? length / 3.0 : radial;
      final remaining = (distance - lengthEvaluated) % length;

      if (remaining <= r) {
        return currentIndex + (distance - lengthEvaluated) ~/ length;
      } else if (remaining >= length - r) {
        return currentIndex + (distance - lengthEvaluated) ~/ length + 1;
      } else {
        return -1;
      }
    }

    if (specificLength.isEmpty) {
      return findIndexWitinRadial(0, distance, 0.0, defaultLength);
    } else {
      double lengthEvaluated = 0;
      int currentIndex = 0;

      for (RangeProperties cp in specificLength) {
        if (currentIndex < cp.min) {
          double lengthDefaultArea = (cp.min - currentIndex) * defaultLength;

          if (distance <= lengthEvaluated + lengthDefaultArea) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, defaultLength);
          } else {
            lengthEvaluated += lengthDefaultArea;
            currentIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double customLength = cp.length ?? defaultLength;
          double lengthCostumArea = (cp.max - cp.min + 1) * customLength;

          if (distance <= lengthEvaluated + lengthCostumArea + radial / 2.0) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, customLength);
          } else {
            lengthEvaluated += lengthCostumArea;
            currentIndex += cp.max - cp.min + 1;
          }
        } else {
          currentIndex = cp.max + 1;
        }
      }

      return findIndexWitinRadial(
          currentIndex, distance, lengthEvaluated, defaultLength);
    }
  }

  /// GridInfo
  ///
  ///
  ///
  ///
  ///

  GridInfo findGridInfoRow(int toIndex) {
    return _findGridInfo(
        specificLength: specificHeight,
        defaultLength: defaultHeightCell,
        toIndex: toIndex,
        maxGrids: tableRows);
  }

  GridInfo findGridInfoColumn(int toIndex) {
    return _findGridInfo(
        specificLength: specificWidth,
        defaultLength: defaultWidthCell,
        toIndex: toIndex,
        maxGrids: tableColumns);
  }

  GridInfo _findGridInfo(
      {required List<RangeProperties> specificLength,
      required int toIndex,
      required double defaultLength,
      required int maxGrids}) {
    var listIndex = 0;
    var index = 0;
    var nextPosition = 0.0;

    assert(index <= toIndex, 'lastIndex should be larger then ...');

    GridInfo? find(max, double length, bool visible) {
      final last = toIndex < max ? toIndex + 1 : max;
      length = visible ? length : 0.0;
      var position = nextPosition;

      if (visible) {
        position += (last - index - 1) * length;
        nextPosition = position + length;
      }

      index = last;

      return (toIndex == last - 1)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    final lengthList = specificLength.length;

    while (listIndex < lengthList) {
      final cp = specificLength[listIndex];

      if (index < cp.min) {
        final t = find(cp.min, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.min) {
        final t = find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }

      listIndex++;
    }

    return find(toIndex + 1, defaultLength, true)!;
  }

  GridInfo findGridInfoRowForward(
      {required int toIndex, required GridInfo startingPoint}) {
    return _findGridInfoForward(
        specificLength: specificHeight,
        defaultLength: defaultHeightCell,
        toIndex: toIndex,
        maxGrids: tableRows,
        startingPoint: startingPoint);
  }

  GridInfo findGridInfoRowReverse(
      {required int toIndex, required GridInfo startingPoint}) {
    return _findGridInfoReverse(
        specificLength: specificHeight,
        defaultLength: defaultHeightCell,
        toIndex: toIndex,
        startingPoint: startingPoint);
  }

  GridInfo _findGridInfoForward(
      {required List<RangeProperties> specificLength,
      required int toIndex,
      required double defaultLength,
      required int maxGrids,
      required GridInfo startingPoint}) {
    int listIndex = startingPoint.listIndex;
    var index = startingPoint.index + 1;
    var nextPosition = startingPoint.position + startingPoint.length;

    assert(index <= toIndex, 'lastIndex should be larger then ...');

    GridInfo? find(max, double length, bool visible) {
      final last = toIndex < max ? toIndex + 1 : max;
      length = visible ? length : 0.0;
      var position = nextPosition;

      if (visible) {
        position += (last - index - 1) * length;
        nextPosition = position + length;
      }

      index = last;

      return (toIndex == last - 1)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    final lengthList = specificLength.length;

    while (listIndex < lengthList) {
      final cp = specificLength[listIndex];

      if (index < cp.min) {
        final t = find(cp.min, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.min) {
        final t = find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }

      listIndex++;
    }

    return find(toIndex + 1, defaultLength, true)!;
  }

  GridInfo _findGridInfoReverse(
      {required List<RangeProperties> specificLength,
      required int toIndex,
      required double defaultLength,
      required GridInfo startingPoint}) {
    int listIndex = startingPoint.listIndex;
    var index = startingPoint.index;
    var position = startingPoint.position;

    GridInfo? find(min, double length, bool visible) {
      final first = toIndex > min ? toIndex : min;
      length = visible ? length : 0.0;

      if (visible) {
        position -= (index - first) * length;
      }
      index = first;

      return (toIndex >= min)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    if (listIndex == specificLength.length) {
      listIndex--;
    }

    while (0 <= listIndex) {
      final cp = specificLength[listIndex];

      if (index > cp.max + 1) {
        final t = find(cp.max + 1, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.max + 1) {
        final t = find(
            cp.min, cp.length ?? defaultLength, !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }
      listIndex--;
    }

    return find(0, defaultLength, true)!;
  }

  ///
  ///
  ///
  ///

  CellIndex findCellIndex(double x, double y) {
    int columnIndex =
        _findCellIndex(x, specificWidth, tableColumns, defaultWidthCell);
    int rowIndex =
        _findCellIndex(y, specificHeight, tableRows, defaultHeightCell);

    var (row, rows) =
        switch ((rowIndex, findMergedRows(rowIndex, columnIndex))) {
      (int _, Merged merged) => (merged.startRow, merged.rows),
      (int rowIndex, _) => (rowIndex, 1)
    };

    var (column, columns) =
        switch ((columnIndex, findMergedColumns(rowIndex, columnIndex))) {
      (int _, Merged merged) => (merged.startColumn, merged.columns),
      (int columnIndex, _) => (columnIndex, 1)
    };

    return CellIndex(column: column, row: row, rows: rows, columns: columns);
  }

  int _findCellIndex(
    double distance,
    List<RangeProperties> specificLength,
    int maximumCells,
    double defaultLength,
  ) {
    int findIndexWitinRadial(int currentIndex, double distance,
        double lengthEvaluated, double length) {
      final remaining = (distance - lengthEvaluated) % length;

      if (remaining < length) {
        return currentIndex + (distance - lengthEvaluated) ~/ length;
      } else {
        return -1;
      }
    }

    if (specificLength.isEmpty) {
      return findIndexWitinRadial(0, distance, 0.0, defaultLength);
    } else {
      double lengthEvaluated = 0;
      int currentIndex = 0;

      for (RangeProperties cp in specificLength) {
        if (currentIndex < cp.min) {
          double lengthDefaultArea = (cp.min - currentIndex) * defaultLength;

          if (distance <= lengthEvaluated + lengthDefaultArea) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, defaultLength);
          } else {
            lengthEvaluated += lengthDefaultArea;
            currentIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double customLength = cp.length ?? defaultLength;
          double lengthCostumArea = (cp.max - cp.min + 1) * customLength;

          if (distance <= lengthEvaluated + lengthCostumArea) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, customLength);
          } else {
            lengthEvaluated += lengthCostumArea;
            currentIndex += cp.max - cp.min + 1;
          }
        } else {
          currentIndex = cp.max + 1;
        }
      }

      return findIndexWitinRadial(
          currentIndex, distance, lengthEvaluated, defaultLength);
    }
  }

  void updateCell(C? previousCell, C? cell, CellIndex cellIndex);
}
