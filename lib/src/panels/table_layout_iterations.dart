// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/model/view_model.dart';
import '../builders/cells.dart';
import 'panel_viewport.dart';
import '../model/properties/flextable_grid_info.dart';
import '../data_model/flextable_data_model.dart';
import 'table_multi_panel_viewport.dart';

class TableInterator {
  TableInterator({
    required FlexTableViewModel flexTableViewModel,
  }) : _flexTableViewModel = flexTableViewModel;

  FlexTableViewModel _flexTableViewModel;
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
  int firstRowIndex = 0,
      lastRowIndex = 0,
      firstColumnIndex = 0,
      lastColumnIndex = 0;
  Cell? cell;
  late GridInfo rowInfo, columnInfo;

  set flexTableViewModel(value) {
    _flexTableViewModel = value;
  }

  // double get scaleAndZoom => _flexTableViewModel.tableScale;

  AbstractFlexTableDataModel get dataTable => _flexTableViewModel.dataTable;

  reset(TablePanelLayoutIndex tpli) {
    rowInfoList = _flexTableViewModel.getRowInfoList(
        tpli.scrollIndexX, tpli.scrollIndexY);
    columnInfoList = _flexTableViewModel.getColumnInfoList(
        tpli.scrollIndexX, tpli.scrollIndexY);

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

    final dataTable = _flexTableViewModel.dataTable;

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
              ? findPositionColumn(m.lastColumn).endPosition -
                  columnInfo.position
              : columnInfo.length
          ..height = m.rowsMerged()
              ? findPositionRow(m.lastRow).endPosition - rowInfo.position
              : rowInfo.length;
      }
    } else if (rowIndex == firstRowIndex || columnIndex == firstColumnIndex) {
      rowMergeLayout() || columnMergeLayout();
    }

    count++;
  }

  bool get isEmpty => length == 0;

  bool rowMergeLayout() {
    Merged? m = dataTable.findMergedRows(rowIndex, columnIndex);

    if (m != null) {
      rowIndex = m.startRow;
      columnIndex = m.startColumn;

      cell = dataTable.cell(row: rowIndex, column: columnIndex);

      final top = findPositionRow(rowIndex);
      final bottom = findPositionRow(m.lastRow);
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
    Merged? m = dataTable.findMergedColumns(rowIndex, columnIndex);

    if (m != null) {
      rowIndex = m.startRow;
      columnIndex = m.startColumn;

      cell = dataTable.cell(row: rowIndex, column: columnIndex);

      final left = findPositionColumn(columnIndex);
      final right = findPositionColumn(m.lastColumn);
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

  TableCellIndex get tableCellIndex =>
      TableCellIndex(row: rowIndex, column: columnIndex);

  GridInfo findPositionRow(int toIndex) {
    if (toIndex < firstRowIndex || toIndex > lastRowIndex) {
      return _flexTableViewModel.findGridInfoRow(toIndex);
    } else {
      return rowInfoList[toIndex - firstRowIndex];
    }
  }

  GridInfo findPositionColumn(int toIndex) {
    if (toIndex < firstColumnIndex || toIndex > lastColumnIndex) {
      return _flexTableViewModel.findGridInfoColumn(toIndex);
    } else {
      return columnInfoList[toIndex - firstColumnIndex];
    }
  }
}
