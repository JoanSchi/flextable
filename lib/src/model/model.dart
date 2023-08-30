// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

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
  int maximumColumns;
  int maximumRows;
  double defaultWidthCell;
  double defaultHeightCell;
  List<RangeProperties> specificHeight;
  List<RangeProperties> specificWidth;
  bool modifySplit = false;
  bool scheduleCorrectOffScroll = false;

  int topLeftCellPaneColumn = 0;
  int topLeftCellPaneRow = 0;

  bool scrollLockX = false;
  bool scrollLockY = false;

  SplitState stateSplitX;
  SplitState stateSplitY;

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

  FlexTableModel copyWith({
    double? scrollX0pY0,
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
    int? maximumColumns,
    int? maximumRows,
    double? defaultWidthCell,
    double? defaultHeightCell,
    List<RangeProperties>? specificHeight,
    List<RangeProperties>? specificWidth,
    bool? modifySplit,
    bool? scheduleCorrectOffScroll,
    int? topLeftCellPaneColumn,
    int? topLeftCellPaneRow,
    bool? scrollLockX,
    bool? scrollLockY,
    SplitState? stateSplitX,
    SplitState? stateSplitY,
    double? headerVisibility,
    double? spaceSplit,
    double? spaceSplitFreeze,
    double? splitChangeInsets,
    AbstractFlexTableDataModel? dataTable,
    double? freezeMinimumSize,
    double? leftPanelMargin,
    double? topPanelMargin,
    double? rightPanelMargin,
    double? bottomPanelMargin,
    double? scale,
    double? minTableScale,
    double? maxTableScale,
    double? maxRowHeaderScale,
    double? maxColumnHeaderScale,
    double? headerHeight,
    double? freezePadding,
    double? unfreezePadding,
    List<AutoFreezeArea>? autoFreezeAreasX,
    bool? autoFreezeX,
    List<AutoFreezeArea>? autoFreezeAreasY,
    bool? autoFreezeY,
    double? minSplitSpaceFromSide,
    double? hitScrollBarThickness,
    Alignment? alignment,
  }) {
    return FlexTableModel(
      xSplit: xSplit ?? this.xSplit,
      ySplit: ySplit ?? this.ySplit,
      rowHeader: rowHeader ?? this.rowHeader,
      columnHeader: columnHeader ?? this.columnHeader,
      maximumColumns: maximumColumns ?? this.maximumColumns,
      maximumRows: maximumRows ?? this.maximumRows,
      defaultWidthCell: defaultWidthCell ?? this.defaultWidthCell,
      defaultHeightCell: defaultHeightCell ?? this.defaultHeightCell,
      specificHeight: specificHeight ?? this.specificHeight,
      specificWidth: specificWidth ?? this.specificWidth,
      scrollLockX: scrollLockX ?? this.scrollLockX,
      scrollLockY: scrollLockY ?? this.scrollLockY,
      stateSplitX: stateSplitX ?? this.stateSplitX,
      stateSplitY: stateSplitY ?? this.stateSplitY,
      splitChangeInsets: splitChangeInsets ?? this.splitChangeInsets,
      dataTable: dataTable ?? this.dataTable,
      freezeMinimumSize: freezeMinimumSize ?? this.freezeMinimumSize,
      leftPanelMargin: leftPanelMargin ?? this.leftPanelMargin,
      topPanelMargin: topPanelMargin ?? this.topPanelMargin,
      rightPanelMargin: rightPanelMargin ?? this.rightPanelMargin,
      bottomPanelMargin: bottomPanelMargin ?? this.bottomPanelMargin,
      scale: scale ?? _scale,
      minTableScale: minTableScale ?? this.minTableScale,
      maxTableScale: maxTableScale ?? this.maxTableScale,
      maxRowHeaderScale: maxRowHeaderScale ?? this.maxRowHeaderScale,
      maxColumnHeaderScale: maxColumnHeaderScale ?? this.maxColumnHeaderScale,
      headerHeight: headerHeight ?? this.headerHeight,
      freezePadding: freezePadding ?? this.freezePadding,
      unfreezePadding: unfreezePadding ?? this.unfreezePadding,
      autoFreezeAreasX: autoFreezeAreasX ?? this.autoFreezeAreasX,
      autoFreezeX: autoFreezeX ?? this.autoFreezeX,
      autoFreezeAreasY: autoFreezeAreasY ?? this.autoFreezeAreasY,
      autoFreezeY: autoFreezeY ?? this.autoFreezeY,
      minSplitSpaceFromSide:
          minSplitSpaceFromSide ?? this.minSplitSpaceFromSide,
      hitScrollBarThickness:
          hitScrollBarThickness ?? this.hitScrollBarThickness,
      alignment: alignment ?? this.alignment,
    );
  }
}
