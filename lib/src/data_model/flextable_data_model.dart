// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../builders/cells.dart';
import '../builders/table_line.dart';

class FlexTableDataModel extends AbstractFlexTableDataModel {
  FlexTableDataModel()
      : _tableRowList = <TableRow?>[],
        _columnIndices = <GridRibbon?>[],
        super();

  final List<TableRow?> _tableRowList;
  final List<GridRibbon?> _columnIndices;

  T ribbon<T>(int index, List<T?> list, newRibbon) {
    T? ribbon;

    if (index < list.length) {
      ribbon = list[index];

      if (ribbon == null) {
        ribbon = newRibbon(index);
        list[index] = ribbon;
      }
    } else {
      list.length = index + 1;
      ribbon = newRibbon(index);
      list[index] = ribbon;
    }

    assert(ribbon != null, 'No Ribbon found');

    return ribbon!;
  }

  @override
  void addCell(
      {required int row,
      required int column,
      int rows = 1,
      int columns = 1,
      required Cell cell}) {
    TableRow tableRow =
        ribbon<TableRow>(row, _tableRowList, (int index) => TableRow(index));

    _placeCell(tableRow, column, cell);

    if (rows > 1 || columns > 1) {
      _addMerged(
          cell: cell, row: row, column: column, rows: rows, columns: columns);
    }
  }

  _placeCell(TableRow tableRow, int column, Cell cell) {
    List<Cell?> columnList = tableRow.columnList;

    if (column >= columnList.length) {
      columnList.length = column + 1;
    }

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

  @override
  GridRibbon columnRibbon(int index) {
    return ribbon<GridRibbon>(
        index, _columnIndices, (int index) => ColumnIndex(index));
  }

  @override
  GridRibbon rowRibbon(int index) {
    return ribbon<TableRow>(
        index,
        _tableRowList,
        (int index) => TableRow(
              index,
            ));
  }

  @override
  Merged? findMergedRows(int row, int column) {
    return (column < _columnIndices.length)
        ? _columnIndices[column]?.findMerged(
            find: row,
            firstIndex: (Merged m) => m.startRow,
            lastIndex: (Merged m) => m.lastRow)
        : null;
  }

  @override
  Merged? findMergedColumns(int row, int column) {
    return (row < _tableRowList.length)
        ? _tableRowList[row]?.findMerged(
            find: column,
            firstIndex: (Merged m) => m.startColumn,
            lastIndex: (Merged m) => m.lastColumn)
        : null;
  }
}

abstract class AbstractFlexTableDataModel {
  TableLinesOneDirection horizontalLineList;
  TableLinesOneDirection verticalLineList;

  AbstractFlexTableDataModel(
      {TableLinesOneDirection? horizontalLineList,
      TableLinesOneDirection? verticalLineList})
      : horizontalLineList = horizontalLineList ?? TableLinesOneDirection(),
        verticalLineList = verticalLineList ?? TableLinesOneDirection();

  addCell(
      {required int row,
      required int column,
      int rows = 1,
      int columns = 1,
      required Cell cell});

  Cell? cell({required int row, required int column});

  _addMerged(
      {required Cell cell,
      required int row,
      required int column,
      required int rows,
      required int columns}) {
    cell.merged = Merged(
        startRow: row,
        startColumn: column,
        lastRow: row + rows - 1,
        lastColumn: column + columns - 1);

    if (columns == 1) {
      _addMergeOneDirection(
          gridRibbon: columnRibbon(column), merged: cell.merged!);
    } else if (rows == 1) {
      _addMergeOneDirection(gridRibbon: rowRibbon(row), merged: cell.merged!);
    }
  }

  GridRibbon columnRibbon(int index);

  GridRibbon rowRibbon(int index);

  _addMergeOneDirection(
      {required GridRibbon gridRibbon, required Merged merged}) {
    final startIndex = (merged.startRow == merged.lastRow)
        ? merged.startColumn
        : merged.startRow;
    final indexInList = (merged.startRow == merged.lastRow)
        ? (i) => gridRibbon.mergedList[i].startColumn
        : (i) => gridRibbon.mergedList[i].startRow;
    final length = gridRibbon.mergedList.length;

    int i = 0;

    while (i < length && startIndex > indexInList(i)) {
      i++;
    }

    gridRibbon.mergedList.insert(i, merged);
  }

  Merged? findMergedRows(int row, int column);

  Merged? findMergedColumns(int row, int column);
}

class TableRow extends GridRibbon {
  @override
  int index;
  List<Cell?> columnList;

  TableRow(
    this.index,
  ) : columnList = <Cell?>[];
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



// class FlexTableDataModelCR extends AbstractFlexTableDataModel {
//   FlexTableDataModelCR() : super();

//   final List<TableColumn?> _tableColumnList = [];
//   final List<GridRibbon?> _rowIndices = [];

//   @override
//   List<GridRibbon?> get columnIndices => _tableColumnList;

//   @override
//   Index initiateColumnIndex(int index) => TableColumn(index);

//   @override
//   Index initiateRowIndex(int index) => RowIndex(index);

//   @override
//   List<GridRibbon?> get rowIndices => _rowIndices;

//   @override
//   void addCell(
//       {required int row,
//       required int column,
//       int rows = 1,
//       int columns = 1,
//       required Cell cell}) {
//     TableColumn tableColumn = retrieveColumnGridRibbon(column) as TableColumn;

//     placeCell(tableColumn, row, cell);

//     if (rows > 1 || columns > 1) {
//       _addMerged(
//           cell: cell, row: row, column: column, rows: rows, columns: columns);
//     }
//   }

//   placeCell(TableColumn tableColumn, int row, Cell cell) {
//     List<Cell?> rowList = tableColumn.rowList;

//     if (row >= rowList.length) {
//       rowList.length = row + 1;
//       rowList[row] = cell;
//     }

//     cell;

//     rowList[row] = cell;

//     return tableColumn;
//   }

//   @override
//   Cell? cell({required int row, required int column}) {
//     if (column < _tableColumnList.length) {
//       final tableColumn = _tableColumnList[column];

//       final rowList = tableColumn?.rowList;

//       if (rowList != null && row < rowList.length) {
//         return rowList[row];
//       }
//     }
//     return null;
//   }
// }


// class RowIndex extends GridRibbon {
//   @override
//   int index;

//   RowIndex(this.index);
// }