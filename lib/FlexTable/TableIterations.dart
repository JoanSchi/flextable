import 'TableItems/Cells.dart';
import 'TableModel.dart';
import 'TableMultiPanelPortView.dart';
import 'DataFlexTable.dart';
import 'TabelPanelViewPort.dart';

class TableInterator {
  TableModel _tableModel;
  late List<GridInfo> rowInfoList;
  late List<GridInfo> columnInfoList;
  int rowIndex = 0;
  int columnIndex = 0;
  int count = 0;
  int length = 0;
  int lengthColumnInfoList = 0;
  // GridInfo firstRowGridInfo,
  //     lastRowGridInfo,
  //     firstColumnGridInfo,
  //     lastColumnGridInfo;
  int firstRowIndex = 0, lastRowIndex = 0, firstColumnIndex = 0, lastColumnIndex = 0;
  Cell? cell;
  late GridInfo rowInfo, columnInfo;

  TableInterator({
    required TableModel tableModel,
  }) : _tableModel = tableModel;

  set tableModel(value) {
    _tableModel = value;
  }

  double get scaleAndZoom => _tableModel.tableScale;

  DataFlexTableBase get dataTable => _tableModel.dataTable;

  reset(TablePanelLayoutIndex tpli) {
    rowInfoList = _tableModel.getRowInfoList(tpli.scrollIndexX, tpli.scrollIndexY);
    columnInfoList = _tableModel.getColumnInfoList(tpli.scrollIndexX, tpli.scrollIndexY);

    count = 0;
    lengthColumnInfoList = columnInfoList.length;
    length = rowInfoList.length * lengthColumnInfoList;

    if (length != 0) {
      firstRowIndex = rowInfoList.first.index;
      lastRowIndex = rowInfoList.last.index;
      firstColumnIndex = columnInfoList.first.index;
      lastColumnIndex = columnInfoList.last.index;
    }
  }

  bool get next {
    if (count < length) {
      findLayout();
      return true;
    } else {
      return false;
    }
  }

  findLayout() {
    var indexRowInfo = count ~/ lengthColumnInfoList;
    var indexColumnInfo = count % lengthColumnInfoList;

    rowInfo = rowInfoList[indexRowInfo];
    columnInfo = columnInfoList[indexColumnInfo];

    rowIndex = rowInfo.index;
    columnIndex = columnInfo.index;

    final dataTable = _tableModel.dataTable;

    cell = dataTable.cell(row: rowIndex, column: columnIndex);

    if (cell != null) {
      cell!
        ..left = columnInfo.position
        ..top = rowInfo.position;

      if (cell!.merged == null) {
        cell!
          ..width = columnInfo.length
          ..height = rowInfo.length;
      } else {
        final m = cell!.merged!;
        cell!
          ..width = m.columnsMerged()
              ? findPositionColumn(m.lastColumn.index).endPosition - columnInfo.position
              : columnInfo.length
          ..height = m.rowsMerged() ? findPositionRow(m.lastRow.index).endPosition - rowInfo.position : rowInfo.length;
      }
    } else if (rowIndex == firstRowIndex || columnIndex == firstColumnIndex) {
      rowMergeLayout() || columnMergeLayout();
    }

    count++;
  }

  bool get isEmpty => length == 0;

  bool rowMergeLayout() {
    Merged? m = dataTable.mergedRows(columnIndex)?.findMerged(
        find: rowIndex, firstIndex: (Merged m) => m.startRow.index, lastIndex: (Merged m) => m.lastRow.index);

    if (m != null) {
      rowIndex = m.startRow.index;
      columnIndex = m.startColumn.index;

      cell = dataTable.cell(row: rowIndex, column: columnIndex);

      final top = findPositionRow(rowIndex);
      final bottom = findPositionRow(m.lastRow.index);
      cell!
        ..left = columnInfo.position
        ..top = top.position
        ..width = columnInfo.length
        ..height = bottom.endPosition - top.position;
      return true;
    } else {
      return false;
    }
  }

  bool columnMergeLayout() {
    Merged? m = dataTable.mergedColumns(rowIndex)?.findMerged(
        find: columnIndex, firstIndex: (Merged m) => m.startColumn.index, lastIndex: (Merged m) => m.lastColumn.index);

    if (m != null) {
      rowIndex = m.startRow.index;
      columnIndex = m.startColumn.index;

      cell = dataTable.cell(row: rowIndex, column: columnIndex);

      final left = findPositionColumn(columnIndex);
      final right = findPositionColumn(m.lastColumn.index);
      cell!
        ..left = left.position
        ..top = rowInfo.position
        ..width = right.endPosition - left.position
        ..height = rowInfo.length;
      return true;
    } else {
      return false;
    }
  }

  TableCellIndex get tableCellIndex => TableCellIndex(row: rowIndex, column: columnIndex);

  GridInfo findPositionRow(int toIndex) {
    if (toIndex < firstRowIndex || toIndex > lastRowIndex) {
      return _tableModel.findGridInfoRow(toIndex);
    } else {
      return rowInfoList[toIndex - firstRowIndex];
    }
  }

  GridInfo findPositionColumn(int toIndex) {
    if (toIndex < firstColumnIndex || toIndex > lastColumnIndex) {
      return _tableModel.findGridInfoColumn(toIndex);
    } else {
      return columnInfoList[toIndex - firstColumnIndex];
    }
  }
}
