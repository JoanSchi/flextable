// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import '../builders/cells.dart';
import '../model/properties/flextable_grid_info.dart';

class TableInterator<T extends AbstractFtModel<C>, C extends AbstractCell> {
  TableInterator({
    required FtViewModel<T, C> viewModel,
  }) : _viewModel = viewModel;

  FtViewModel<T, C> _viewModel;
  late List<GridInfo> rowInfoList;
  late List<GridInfo> columnInfoList;
  int rowIndex = 0;
  int columnIndex = 0;
  int rows = 0;
  int columns = 0;
  int count = 0;
  int length = 0;
  int lengthColumnInfoList = 0;
  int firstRowIndex = 0,
      lastRowIndex = 0,
      firstColumnIndex = 0,
      lastColumnIndex = 0;
  C? cell;
  late GridInfo rowInfo, columnInfo;
  double left = 0.0;
  double top = 0.0;
  double height = 0.0;
  double width = 0.0;
  int editRowIndex = -1;
  int editColumnIndex = -1;

  set viewModel(FtViewModel<T, C> value) {
    _viewModel = value;
  }

  AbstractFtModel<C> get model => _viewModel.model;

  reset(LayoutPanelIndex tpli) {
    rowInfoList =
        _viewModel.getRowInfoList(tpli.scrollIndexX, tpli.scrollIndexY);
    columnInfoList =
        _viewModel.getColumnInfoList(tpli.scrollIndexX, tpli.scrollIndexY);

    count = 0;
    lengthColumnInfoList = columnInfoList.length;
    length = rowInfoList.length * lengthColumnInfoList;

    if (length != 0) {
      firstRowIndex = rowInfoList.first.index;
      lastRowIndex = rowInfoList.last.index;
      firstColumnIndex = columnInfoList.first.index;
      lastColumnIndex = columnInfoList.last.index;
    }
    final ec = _viewModel.editCell;
    if ((_viewModel.model.anyFreezeSplitX ||
            _viewModel.noSplitX ||
            ec.panelIndexX == tpli.xIndex) &&
        (_viewModel.model.anyFreezeSplitX ||
            _viewModel.model.anyFreezeSplitY ||
            _viewModel.noSplitY ||
            ec.panelIndexY == tpli.yIndex)) {
      editRowIndex = ec.row;
      editColumnIndex = ec.column;
    } else {
      editRowIndex = -1;
      editColumnIndex = -1;
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
    rows = 1;
    columns = 1;

    cell = model.cell(row: rowIndex, column: columnIndex);

    if (cell != null) {
      left = columnInfo.position;
      top = rowInfo.position;

      if (cell!.merged == null) {
        width = columnInfo.length;
        height = rowInfo.length;
      } else {
        final m = cell!.merged!;
        columns = m.columns;
        rows = m.rows;
        width = columns > 1
            ? findPositionColumn(m.lastColumn).endPosition - columnInfo.position
            : columnInfo.length;
        height = rows > 1
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
    Merged? m = model.findMergedRows(rowIndex, columnIndex);

    if (m != null) {
      rowIndex = m.startRow;
      columnIndex = m.startColumn;
      rows = m.rows;
      columns = m.columns;

      cell = model.cell(row: rowIndex, column: columnIndex);

      final topGridInfo = findPositionRow(rowIndex);
      final bottomGridInfo = findPositionRow(m.lastRow);

      left = columnInfo.position;
      top = topGridInfo.position;
      width = columnInfo.length;
      height = bottomGridInfo.endPosition - topGridInfo.position;
      return true;
    } else {
      return false;
    }
  }

  bool columnMergeLayout() {
    Merged? m = model.findMergedColumns(rowIndex, columnIndex);

    if (m != null) {
      rowIndex = m.startRow;
      columnIndex = m.startColumn;

      cell = model.cell(row: rowIndex, column: columnIndex);

      final leftGridInfo = findPositionColumn(columnIndex);
      final rightGridInfo = findPositionColumn(m.lastColumn);

      left = leftGridInfo.position;
      top = rowInfo.position;
      width = rightGridInfo.endPosition - leftGridInfo.position;
      height = rowInfo.length;
      return true;
    } else {
      return false;
    }
  }

  CellIndex get tableCellIndex => CellIndex(
      row: rowIndex,
      column: columnIndex,
      rows: rows,
      columns: columns,
      edit: editRowIndex == rowIndex && editColumnIndex == columnIndex);

  GridInfo findPositionRow(int toIndex) {
    if (toIndex < firstRowIndex || toIndex > lastRowIndex) {
      return model.findGridInfoRow(toIndex);
    } else {
      return rowInfoList[toIndex - firstRowIndex];
    }
  }

  GridInfo findPositionColumn(int toIndex) {
    if (toIndex < firstColumnIndex || toIndex > lastColumnIndex) {
      return model.findGridInfoColumn(toIndex);
    } else {
      return columnInfoList[toIndex - firstColumnIndex];
    }
  }
}
