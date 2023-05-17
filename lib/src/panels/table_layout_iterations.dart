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

import 'package:flextable/src/model/view_model.dart';

import '../builders/cells.dart';
import 'panel_viewport.dart';
import '../model/properties/flextable_grid_info.dart';
import '../data_model/flextable_data_model.dart';
import 'table_multi_panel_viewport.dart';

class TableInterator {
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

  TableInterator({
    required FlexTableViewModel flexTableViewModel,
  }) : _flexTableViewModel = flexTableViewModel;

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
              ? findPositionColumn(m.lastColumn.index).endPosition -
                  columnInfo.position
              : columnInfo.length
          ..height = m.rowsMerged()
              ? findPositionRow(m.lastRow.index).endPosition - rowInfo.position
              : rowInfo.length;
      }
    } else if (rowIndex == firstRowIndex || columnIndex == firstColumnIndex) {
      rowMergeLayout() || columnMergeLayout();
    }

    count++;
  }

  bool get isEmpty => length == 0;

  bool rowMergeLayout() {
    Merged? m = dataTable.mergedRows(columnIndex)?.findMerged(
        find: rowIndex,
        firstIndex: (Merged m) => m.startRow.index,
        lastIndex: (Merged m) => m.lastRow.index);

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
        find: columnIndex,
        firstIndex: (Merged m) => m.startColumn.index,
        lastIndex: (Merged m) => m.lastColumn.index);

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
