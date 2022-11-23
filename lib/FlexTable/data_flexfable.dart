import 'TableItems/Cells.dart';
import 'table_line.dart';

class DataFlexTableCR extends DataFlexTableBase {
  List<TableColumn?> tableColumnList = [];
  List<GridRibbon?> _rowIndices = [];

  DataFlexTableCR() : super();

  @override
  List<GridRibbon?> get columnIndices => tableColumnList;

  @override
  Index initiateColumnIndex(int index) => TableColumn(index);

  @override
  Index initiateRowIndex(int index) => RowIndex(index);

  @override
  List<GridRibbon?> get rowIndices => _rowIndices;

  addCell(
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

  Cell? cell({required int row, required int column}) {
    if (column < tableColumnList.length) {
      final tableColumn = tableColumnList[column];

      final rowList = tableColumn?.rowList;

      if (rowList != null && row < rowList.length) {
        return rowList[row];
      }
    }
    return null;
  }
}

class DataFlexTable extends DataFlexTableBase {
  List<TableRow?> tableRowList = <TableRow?>[];
  List<GridRibbon?> _columnIndices = <GridRibbon?>[];

  DataFlexTable() : super();

  @override
  List<GridRibbon?> get columnIndices => _columnIndices;

  @override
  List<GridRibbon?> get rowIndices => tableRowList;

  Index initiateColumnIndex(int index) => ColumnIndex(index);

  Index initiateRowIndex(int index) => TableRow(index);

  @override
  addCell(
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

  Cell? cell({required int row, required int column}) {
    if (row < tableRowList.length) {
      final tableRow = tableRowList[row];

      final columnList = tableRow?.columnList;

      if (columnList != null && column < columnList.length) {
        return columnList[column];
      }
    }
    return null;
  }
}

abstract class DataFlexTableBase {
  late TableLineList horizontalLineList;
  late TableLineList verticalLineList;

  DataFlexTableBase() {
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
    final _rowIndex = cell.rowIndex;
    final _columnIndex = cell.columnIndex;

    cell.merged = Merged(
        startRow: _rowIndex,
        startColumn: _columnIndex,
        lastRow: indexOfExtendRow(_rowIndex, rows),
        lastColumn: indexOfExtendColumn(_columnIndex, columns));

    if (columns == 1) {
      addMergeOneDirection(
          gridRibbon: retrieveColumnIndex(_columnIndex.index) as GridRibbon,
          merged: cell.merged!);
    } else if (rows == 1) {
      addMergeOneDirection(
          gridRibbon: retrieveRowIndex(_rowIndex.index) as GridRibbon,
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
  int index;
  List<Cell?> columnList = <Cell?>[];

  TableRow(this.index);
}

class ColumnIndex extends GridRibbon {
  int index;

  ColumnIndex(this.index);
}

class TableColumn extends GridRibbon {
  int index;
  var rowList = <Cell?>[];

  TableColumn(this.index);
}

class RowIndex extends GridRibbon {
  int index;

  RowIndex(this.index);
}
