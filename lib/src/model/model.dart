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

import 'package:flutter/widgets.dart';

import '../data_model/flextable_data_model.dart';
import 'properties/flextable_autofreeze_area.dart';
import 'properties/flextable_range_properties.dart';

const _kScrollBarHitThickness = 32.0;

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

class FlexTableModel {
  double scrollX0pY0 = 0.0,
      scrollX1pY0 = 0.0,
      scrollY0pX0 = 0.0,
      scrollY1pX0 = 0.0,
      scrollX0pY1 = 0.0,
      scrollX1pY1 = 0.0,
      scrollY0pX1 = 0.0,
      scrollY1pX1 = 0.0,
      mainScrollX = 0.0,
      mainScrollY = 0.0;
  double xSplit = 0.0, ySplit = 0.0;
  bool rowHeader;
  bool columnHeader;
  int maximumColumns;
  int maximumRows;
  double defaultWidthCell;
  double defaultHeightCell;
  List<RangeProperties> specificHeight;
  List<RangeProperties> specificWidth;
  bool modifySplit = false;
  bool scheduleCorrectOffScroll = false;

  int topLeftCellPaneColumn = 0, topLeftCellPaneRow = 0;

  bool scrollLockX = false, scrollLockY = false;

  SplitState stateSplitX, stateSplitY;

  double headerVisibility = 1.0;

  double spaceSplit = 2.0;
  double spaceSplitFreeze = 2.0;
  double splitChangeInsets = 20.0;

  AbstractFlexTableDataModel dataTable;
  double freezeMinimumSize;

  double leftPanelMargin;
  double topPanelMargin;
  double rightPanelMargin;
  double bottomPanelMargin;

  double _scale;
  double minTableScale;
  double maxTableScale;
  double maxRowHeaderScale;
  double maxColumnHeaderScale;
  double headerHeight;
  double freezePadding;
  double unfreezePadding;

  List<AutoFreezeArea> autoFreezeAreasX;
  bool autoFreezeX;

  List<AutoFreezeArea> autoFreezeAreasY;
  bool autoFreezeY;

  double minSplitSpaceFromSide;
  double hitScrollBarThickness;

  Alignment alignment;

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

  FlexTableModel(
      {required this.maximumColumns,
      required this.maximumRows,
      required this.defaultWidthCell,
      required this.defaultHeightCell,
      this.stateSplitX = SplitState.noSplit,
      this.stateSplitY = SplitState.noSplit,
      double xSplit = 0.0,
      double ySplit = 0.0,
      this.rowHeader = false,
      this.columnHeader = false,
      this.scrollLockX = true,
      this.scrollLockY = true,
      int freezeColumns = -1,
      int freezeRows = -1,
      List<RangeProperties>? specificHeight,
      List<RangeProperties>? specificWidth,
      required this.dataTable,
      this.freezeMinimumSize = 20.0,
      double panelMargin = 0.0,
      double? leftPanelMargin,
      double? topPanelMargin,
      double? rightPanelMargin,
      double? bottomPanelMargin,
      double scale = 1.0,
      this.minTableScale = 0.5,
      this.maxTableScale = 4.0,
      this.maxRowHeaderScale = 1.5,
      this.maxColumnHeaderScale = 1.5,
      this.autoFreezeAreasX = const [],
      this.autoFreezeX = true,
      this.autoFreezeAreasY = const [],
      this.autoFreezeY = true,
      this.alignment = Alignment.topCenter,
      this.splitChangeInsets = 20.0,
      this.headerHeight = 20.0,
      this.freezePadding = 20.0,
      this.unfreezePadding = 0.0,
      this.minSplitSpaceFromSide = 32.0,
      this.hitScrollBarThickness = _kScrollBarHitThickness})
      : _scale = scale,
        assert(!(!scrollLockX && autoFreezeAreasX.isNotEmpty),
            'If autofreezeX is used, scrollLockX should be locked with true'),
        assert(!(!scrollLockY && autoFreezeAreasY.isNotEmpty),
            'If autofreezeY is used, scrolllockY should be locked with true'),
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
        leftPanelMargin = leftPanelMargin ?? panelMargin,
        topPanelMargin = topPanelMargin ?? panelMargin,
        rightPanelMargin = rightPanelMargin ?? panelMargin,
        bottomPanelMargin = bottomPanelMargin ?? panelMargin;

  set tableScale(value) {
    if (value < minTableScale) {
      value = minTableScale;
    } else if (value > maxTableScale) {
      value = maxTableScale;
    }

    if (value != _scale) {
      _scale = value;
    }
  }

  double get tableScale => _scale;

  double get scaleRowHeader =>
      (maxRowHeaderScale < tableScale) ? maxRowHeaderScale : tableScale;

  double get scaleColumnHeader =>
      (maxColumnHeaderScale < tableScale) ? maxColumnHeaderScale : tableScale;

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

  double getSheetLength(List<RangeProperties> specificLength) {
    double defaultCellLength = (specificWidth == specificLength)
        ? defaultWidthCell
        : defaultHeightCell;
    int maxCells =
        (specificWidth == specificLength) ? maximumColumns : maximumRows;

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
      getPosition(column, pc, specificWidth);

  double getY(
    row,
    pc,
  ) =>
      getPosition(row, pc, specificHeight);

  double getPosition(int index, int pc, List<RangeProperties> specificLength) {
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
}
