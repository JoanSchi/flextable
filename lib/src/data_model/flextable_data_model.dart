// Copyright (C) 2023 Joan Schipper
// 
// This file is part of flextable.
// 
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import '../builders/cells.dart';
import '../builders/table_line.dart';

class FlexTableDataModelCR extends AbstractFlexTableDataModel {
  final List<TableColumn?> _tableColumnList = [];
  final List<GridRibbon?> _rowIndices = [];

  FlexTableDataModelCR() : super();

  @override
  List<GridRibbon?> get columnIndices => _tableColumnList;

  @override
  Index initiateColumnIndex(int index) => TableColumn(index);

  @override
  Index initiateRowIndex(int index) => RowIndex(index);

  @override
  List<GridRibbon?> get rowIndices => _rowIndices;

  @override
  void addCell(
      {required int row,
      required int column,
      int rows = 1,
      int columns = 1,
      required Cell cell}) {
    TableColumn tableColumn = retrieveColumnIndex(column) as TableColumn;

    placeCell(tableColumn, row, cell);

    if (rows > 1 || columns > 1) {
      addMerged(cell: cell, rows: rows, columns: columns);
    }
  }

  placeCell(TableColumn tableColumn, int row, Cell cell) {
    List<Cell?> rowList = tableColumn.rowList;

    if (row >= rowList.length) {
      rowList.length = row + 1;
      rowList[row] = cell;
    }

    cell
      ..rowIndex = retrieveRowIndex(row)
      ..columnIndex = tableColumn;

    rowList[row] = cell;

    return tableColumn;
  }

  @override
  Cell? cell({required int row, required int column}) {
    if (column < _tableColumnList.length) {
      final tableColumn = _tableColumnList[column];

      final rowList = tableColumn?.rowList;

      if (rowList != null && row < rowList.length) {
        return rowList[row];
      }
    }
    return null;
  }
}

class FlexTableDataModel extends AbstractFlexTableDataModel {
  final List<TableRow?> _tableRowList = <TableRow?>[];
  final List<GridRibbon?> _columnIndices = <GridRibbon?>[];

  FlexTableDataModel() : super();

  @override
  List<GridRibbon?> get columnIndices => _columnIndices;

  @override
  List<GridRibbon?> get rowIndices => _tableRowList;

  @override
  Index initiateColumnIndex(int index) => ColumnIndex(index);

  @override
  Index initiateRowIndex(int index) => TableRow(index);

  @override
  void addCell(
      {required int row,
      required int column,
      int rows = 1,
      int columns = 1,
      required Cell cell}) {
    TableRow tableRow = retrieveRowIndex(row) as TableRow;

    placeCell(tableRow, column, cell);

    if (rows > 1 || columns > 1) {
      addMerged(cell: cell, rows: rows, columns: columns);
    }
  }

  placeCell(TableRow tableRow, int column, Cell cell) {
    List<Cell?> columnList = tableRow.columnList;

    if (column >= columnList.length) {
      columnList.length = column + 1;
      columnList[column] = cell;
    }

    cell
      ..rowIndex = tableRow
      ..columnIndex = retrieveColumnIndex(column);

    columnList[column] = cell;

    return tableRow;
  }

  @override
  Cell? cell({required int row, required int column}) {
    if (row < _tableRowList.length) {
      final tableRow = _tableRowList[row];

      final columnList = tableRow?.columnList;

      if (columnList != null && column < columnList.length) {
        return columnList[column];
      }
    }
    return null;
  }
}

abstract class AbstractFlexTableDataModel {
  late TableLineList horizontalLineList;
  late TableLineList verticalLineList;

  AbstractFlexTableDataModel() {
    horizontalLineList = TableLineList(
        requestLevelOneIndex: retrieveRowIndex,
        requestLevelTwoIndex: retrieveColumnIndex);
    verticalLineList = TableLineList(
        requestLevelOneIndex: retrieveColumnIndex,
        requestLevelTwoIndex: retrieveRowIndex);
  }

  addCell(
      {required int row,
      required int column,
      int rows = 1,
      int columns = 1,
      required Cell cell});

  List<GridRibbon?> get columnIndices;

  List<GridRibbon?> get rowIndices;

  Index index(int value, List<Index?> list, newIndex) {
    Index? index;

    if (value < list.length) {
      index = list[value];

      if (index == null) {
        index = newIndex(value);
        list[value] = index;
      }
    } else {
      list.length = value + 1;
      index = newIndex(value);
      list[value] = index;
    }

    assert(index != null, 'neeeeee toch');

    return index!;
  }

  Cell? cell({required int row, required int column});

  addMerged({required Cell cell, required int rows, required int columns}) {
    final rowIndex = cell.rowIndex;
    final columnIndex = cell.columnIndex;

    cell.merged = Merged(
        startRow: rowIndex,
        startColumn: columnIndex,
        lastRow: indexOfExtendRow(rowIndex, rows),
        lastColumn: indexOfExtendColumn(columnIndex, columns));

    if (columns == 1) {
      addMergeOneDirection(
          gridRibbon: retrieveColumnIndex(columnIndex.index) as GridRibbon,
          merged: cell.merged!);
    } else if (rows == 1) {
      addMergeOneDirection(
          gridRibbon: retrieveRowIndex(rowIndex.index) as GridRibbon,
          merged: cell.merged!);
    } else {}
  }

  addMergeOneDirection(
      {required GridRibbon gridRibbon, required Merged merged}) {
    final startIndex = (merged.startRow == merged.lastRow)
        ? merged.startColumn
        : merged.startRow;
    final indexInList = (merged.startRow == merged.lastRow)
        ? (i) => gridRibbon.mergedList[i].startColumn
        : (i) => gridRibbon.mergedList[i].startRow;
    final length = gridRibbon.mergedList.length;

    int i = 0;

    while (i < length && startIndex.index > indexInList(i).index) {
      i++;
    }

    gridRibbon.mergedList.insert(i, merged);
  }

  indexOfExtendRow(Index rowIndex, int rows) {
    if (rows == 1) {
      return rowIndex;
    }
    return retrieveRowIndex(rowIndex.index + rows - 1);
  }

  indexOfExtendColumn(Index columnIndex, int columns) {
    if (columns == 1) {
      return columnIndex;
    }
    return retrieveColumnIndex(columnIndex.index + columns - 1);
  }

  Index initiateColumnIndex(int index);

  Index initiateRowIndex(int index);

  Index retrieveColumnIndex(int column) =>
      index(column, columnIndices, initiateColumnIndex);

  Index retrieveRowIndex(int row) => index(row, rowIndices, initiateRowIndex);

  GridRibbon? mergedRows(int column) =>
      column < columnIndices.length ? columnIndices[column] : null;

  GridRibbon? mergedColumns(int row) =>
      row < rowIndices.length ? rowIndices[row] : null;
}

class TableRow extends GridRibbon {
  @override
  int index;
  List<Cell?> columnList = <Cell?>[];

  TableRow(this.index);
}

class ColumnIndex extends GridRibbon {
  @override
  int index;

  ColumnIndex(this.index);
}

class TableColumn extends GridRibbon {
  @override
  int index;
  var rowList = <Cell?>[];

  TableColumn(this.index);
}

class RowIndex extends GridRibbon {
  @override
  int index;

  RowIndex(this.index);
}
