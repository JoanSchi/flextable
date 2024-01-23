// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/rendering.dart';

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
  int focusRowIndex = -1;
  int focusColumnIndex = -1;

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

    //EditCell

    final ec = _viewModel.editCell;
    editColumnIndex = ec.column;
    editRowIndex = ec.row;

    switch ((_viewModel.stateSplitX, tpli.xIndex, ec.panelIndexX, ec.column)) {
      case (
          SplitState.split,
          int panelIndexX,
          int panelIndexEditX,
          int columnEdit
        ):
        {
          editColumnIndex = columnEdit;
          focusColumnIndex = (panelIndexX == panelIndexEditX) ? columnEdit : -1;
          break;
        }
      case (
          SplitState.autoFreezeSplit,
          int panelIndexEditX,
          int _,
          int columnEdit
        ):
        {
          editColumnIndex = focusColumnIndex = fr(panelIndexEditX,
              _viewModel.autoFreezeAreaX.freezeIndex, columnEdit);
          break;
        }
      case (SplitState.freezeSplit, int panelIndexEditX, int _, int columnEdit):
        {
          editColumnIndex = focusColumnIndex = fr(panelIndexEditX,
              _viewModel.model.topLeftCellPaneColumn, columnEdit);

          break;
        }
      case (_, _, int _, int columnEdit):
        {
          editColumnIndex = focusColumnIndex = columnEdit;
          break;
        }
    }

    switch ((_viewModel.stateSplitY, tpli.yIndex, ec.panelIndexY, ec.row)) {
      case (
          SplitState.split,
          int panelIndexY,
          int panelIndexEditY,
          int rowEdit
        ):
        {
          editRowIndex = rowEdit;
          focusRowIndex = (panelIndexY == panelIndexEditY) ? rowEdit : -1;
          break;
        }

      case (SplitState.autoFreezeSplit, int panelIndexY, _, int rowEdit):
        {
          editRowIndex = focusRowIndex =
              fr(panelIndexY, _viewModel.autoFreezeAreaY.freezeIndex, rowEdit);
          break;
        }

      case (SplitState.freezeSplit, int panelIndexEditY, _, int rowEdit):
        {
          editRowIndex = focusRowIndex =
              fr(panelIndexEditY, _viewModel.model.topLeftCellPaneRow, rowEdit);
          break;
        }
      case (_, _, _, int rowEdit):
        {
          editRowIndex = focusRowIndex = rowEdit;
          break;
        }
    }
  }

  int fr(int panel, int freeze, int index) {
    if (panel == 1 && index < freeze) {
      return index;
    } else if (panel == 2 && freeze <= index) {
      return index;
    } else {
      return -1;
    }
  }

  FtIndex tt(LayoutPanelIndex tpli) {
    int row;
    switch (_viewModel.stateSplitY) {
      case SplitState.autoFreezeSplit:
        {
          row = fr(tpli.yIndex, _viewModel.autoFreezeAreaY.freezeIndex,
              editRowIndex);
          break;
        }
      case SplitState.freezeSplit:
        {
          row = fr(
              tpli.yIndex, _viewModel.model.topLeftCellPaneRow, editRowIndex);
          break;
        }
      default:
        {
          row = editRowIndex;
        }
    }

    int column;

    switch (_viewModel.stateSplitX) {
      case SplitState.autoFreezeSplit:
        {
          column = fr(tpli.xIndex, _viewModel.autoFreezeAreaX.freezeIndex,
              editColumnIndex);
          break;
        }
      case SplitState.freezeSplit:
        {
          column = fr(tpli.xIndex, _viewModel.model.topLeftCellPaneColumn,
              editColumnIndex);
          break;
        }
      default:
        {
          column = editColumnIndex;
        }
    }

    return FtIndex(row: row, column: column);
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

  FtIndex get tableCellIndex {
    return FtIndex(
      row: rowIndex,
      column: columnIndex,
    );
  }

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

  (FtIndex, C?, CellStatus, Rect) get editCellOutsideInteration {
    if (focusRowIndex != -1 && focusColumnIndex != -1) {
      C? cell = model.cell(row: focusRowIndex, column: focusColumnIndex);

      final x0 = model.getX(focusRowIndex, 0);
      final columns = (cell?.merged?.columns ?? 1);
      final x1 = model.getX(focusRowIndex + columns, 0);

      final y0 = model.getX(focusColumnIndex, 0);
      final rows = (cell?.merged?.rows ?? 1);
      final y1 = model.getX(focusColumnIndex + rows, 0);
      return (
        FtIndex(
          row: focusRowIndex,
          column: focusColumnIndex,
        ),
        model.cell(row: focusRowIndex, column: focusColumnIndex),
        const CellStatus(edit: true, hasFocus: true),
        Rect.fromLTRB(x0, y0, x1, y1)
      );
    } else {
      return (const FtIndex(), null, const CellStatus(), Rect.zero);
    }
  }

  FtIndex get editCellIndex =>
      FtIndex(row: editRowIndex, column: editColumnIndex);

  CellStatus get editCellStatus => CellStatus(
      edit: editRowIndex != -1 && editColumnIndex != -1,
      hasFocus: focusRowIndex != -1 && focusColumnIndex != -1);

  bool get hasFocus => focusRowIndex != -1 && focusColumnIndex != -1;

  CellStatus get cellStatus => CellStatus(
      edit: editRowIndex == rowIndex && editColumnIndex == columnIndex,
      hasFocus: focusRowIndex == rowIndex && focusColumnIndex == columnIndex);
}
