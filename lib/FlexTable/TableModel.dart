import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'TabelPanelViewPort.dart';
import 'TableDragDetails.dart';
import 'TableNotifier.dart';
import 'DataFlexTable.dart';
import 'TableMultiPanelPortView.dart';
import 'TableScroll.dart';
import 'TableScrollbar.dart';

const int KEEPSEARCHING = -5;

enum FreezeLine { horizontal, vertical, both, none }

enum FreezeAction { NOACTION, FREEZE, UNFREEZE }

enum SplitState {
  NO_SPLITE,
  FREEZE_SPLIT,
  AUTO_FREEZE_SPLIT,
  SPLIT,
  CANCELED_FREEZE_SPLIT,
  CANCELED_SPLIT
}

bool noSplit(SplitState split) =>
    split == SplitState.NO_SPLITE ||
    split == SplitState.CANCELED_FREEZE_SPLIT ||
    split == SplitState.CANCELED_SPLIT;

class TableModel with TableScrollMetrics, TableChangeNotifier {
  double _widthMainPanel = 0.0;
  double _heightMainPanel = 0.0;
  List<GridLayout> widthLayoutList =
      List.generate(4, (i) => GridLayout(), growable: false);
  List<GridLayout> heightLayoutList =
      List.generate(4, (i) => GridLayout(), growable: false);
  bool _rowHeader;
  bool columnHeader;
  int maximumColumns;
  int maximumRows;
  double defaultWidthCell;
  double defaultHeightCell;
  List<PropertiesRange> _specificHeight;
  List<PropertiesRange> _specificWidth;
  bool changeSplit = false;
  bool scheduleCorrectOffScroll = false;

  double get widthMainPanel => _widthMainPanel;
  double get heightMainPanel => _heightMainPanel;

  int topLeftCellPaneColumn = 0, topLeftCellPaneRow = 0;

  bool scrollLockX = false, scrollLockY = false;

  SplitState stateSplitX, stateSplitY;

  double _xSplit = 0.0, _ySplit = 0.0;
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

  double headerVisibility = 1.0;

  double spaceSplit = 2.0;
  double spaceSplitFreeze = 2.0;
  double splitChangeInsets = 20.0;

  DataFlexTableBase dataTable;
  double freezeMinimumSize;

  double leftPanelMargin;
  double topPanelMargin;
  double rightPanelMargin;
  double bottomPanelMargin;

  bool scrollBarTrack = false;
  double sizeScrollBarTrack = 0.0;
  double ratioVerticalScrollBarTrack = 1.0;
  double ratioHorizontalScrollBarTrack = 1.0;
  double ratioSizeAnimatedSplitChangeX = 1.0;
  double ratioSizeAnimatedSplitChangeY = 1.0;
  List<HeaderProperty> headerRowProperties = List.empty();
  HeaderProperty rightRowHeaderProperty = noHeader;
  HeaderProperty leftRowHeaderProperty = noHeader;
  double _scale;
  double minTableScale;
  double maxTableScale;
  double maxRowHeaderScale;
  double maxColumnHeaderScale;
  double headerHeight;
  double freezePadding;
  double unfreezePadding;

  final autoFreezeNoRange = AutoFreezeArea.noArea();
  List<AutoFreezeArea> autoFreezeAreasX;
  bool autoFreezeX;
  AutoFreezeArea autoFreezeAreaX = AutoFreezeArea.noArea();
  List<AutoFreezeArea> autoFreezeAreasY;
  bool autoFreezeY;
  AutoFreezeArea autoFreezeAreaY = AutoFreezeArea.noArea();

  late List<TablePanelLayoutIndex> _layoutIndex;
  late List<int> _panelIndex;

  double horizontalSplitFreeze(SplitState split) {
    switch (split) {
      case SplitState.FREEZE_SPLIT:
        return spaceSplitFreeze;
      case SplitState.AUTO_FREEZE_SPLIT:
        return autoFreezeAreaY.spaceSplit(spaceSplitFreeze);
      case SplitState.SPLIT:
        return spaceSplit;
      default:
        return 0.0;
    }
  }

  double verticalSplitFreeze(SplitState split) {
    switch (split) {
      case SplitState.FREEZE_SPLIT:
        return spaceSplitFreeze;
      case SplitState.AUTO_FREEZE_SPLIT:
        return autoFreezeAreaY.spaceSplit(spaceSplitFreeze);
      case SplitState.SPLIT:
        return spaceSplit;
      default:
        return 0.0;
    }
  }

  Alignment alignment;

  bool get noSplitX =>
      stateSplitX == SplitState.NO_SPLITE ||
      stateSplitX == SplitState.CANCELED_FREEZE_SPLIT ||
      stateSplitX == SplitState.CANCELED_SPLIT;

  bool get noSplitY =>
      stateSplitY == SplitState.NO_SPLITE ||
      stateSplitY == SplitState.CANCELED_FREEZE_SPLIT ||
      stateSplitY == SplitState.CANCELED_SPLIT;

  bool get anySplitX =>
      stateSplitX == SplitState.FREEZE_SPLIT ||
      stateSplitX == SplitState.SPLIT ||
      stateSplitX == SplitState.AUTO_FREEZE_SPLIT;

  bool get anySplitY =>
      stateSplitY == SplitState.FREEZE_SPLIT ||
      stateSplitY == SplitState.SPLIT ||
      stateSplitY == SplitState.AUTO_FREEZE_SPLIT;

  bool get anyFreezeSplitX =>
      stateSplitX == SplitState.FREEZE_SPLIT ||
      stateSplitX == SplitState.AUTO_FREEZE_SPLIT;

  bool get anyFreezeSplitY =>
      stateSplitY == SplitState.FREEZE_SPLIT ||
      stateSplitY == SplitState.AUTO_FREEZE_SPLIT;

  bool get splitX => stateSplitX == SplitState.SPLIT;

  bool get splitY => stateSplitY == SplitState.SPLIT;

  TableModel(
      {required this.maximumColumns,
      required this.maximumRows,
      required this.defaultWidthCell,
      required this.defaultHeightCell,
      this.stateSplitX: SplitState.NO_SPLITE,
      this.stateSplitY: SplitState.NO_SPLITE,
      double xSplit = 0.0,
      double ySplit = 0.0,
      rowHeader: false,
      this.columnHeader: false,
      this.scrollLockX: true,
      this.scrollLockY: true,
      int freezeColumns = -1,
      int freezeRows = -1,
      List<PropertiesRange>? specificHeight,
      List<PropertiesRange>? specificWidth,
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
      this.unfreezePadding = 0.0})
      : _scale = scale,
        _xSplit = xSplit,
        _ySplit = ySplit,
        assert(!(!scrollLockX && autoFreezeAreasX.isNotEmpty),
            'If autofreezeX is used, scrollLockX should be locked with true'),
        assert(!(!scrollLockY && autoFreezeAreasY.isNotEmpty),
            'If autofreezeY is used, scrolllockY should be locked with true'),
        assert(
            !(stateSplitX == SplitState.FREEZE_SPLIT &&
                stateSplitY == SplitState.SPLIT),
            'Freezesplit and split can not used together, select one split type or none!'),
        assert(
            !(stateSplitY == SplitState.FREEZE_SPLIT &&
                stateSplitX == SplitState.SPLIT),
            'Freezesplit and split can not used together, select one split type or none!'),
        assert(
            stateSplitX == SplitState.FREEZE_SPLIT ? freezeColumns != -1 : true,
            'Select the number of columns to freeze'),
        assert(stateSplitY == SplitState.FREEZE_SPLIT ? freezeRows != -1 : true,
            'Select the number of rows to freeze'),
        _specificWidth = specificWidth ?? [],
        _specificHeight = specificHeight ?? [],
        leftPanelMargin = leftPanelMargin ?? panelMargin,
        topPanelMargin = topPanelMargin ?? panelMargin,
        rightPanelMargin = rightPanelMargin ?? panelMargin,
        bottomPanelMargin = bottomPanelMargin ?? panelMargin,
        ratioSizeAnimatedSplitChangeX =
            stateSplitX != SplitState.SPLIT ? 0.0 : 1.0,
        ratioSizeAnimatedSplitChangeY =
            stateSplitY != SplitState.SPLIT ? 0.0 : 1.0,
        _rowHeader = rowHeader {
    if (stateSplitX == SplitState.FREEZE_SPLIT && freezeColumns > 0) {
      scrollX0pY0 = getX(freezeColumns);

      topLeftCellPaneColumn = freezeColumns + 1;
      scrollX1pY0 = getX(topLeftCellPaneColumn);
    }

    if (stateSplitY == SplitState.FREEZE_SPLIT && freezeRows > 0) {
      scrollY0pX0 = getY(freezeRows);

      topLeftCellPaneRow = freezeRows + 1;
      scrollY1pX0 = getY(topLeftCellPaneRow);
    }

    calculateHeaderWidth();

    autoFreezeAreasX.forEach((element) => element.setPosition(getX));
    autoFreezeAreasY.forEach((element) => element.setPosition(getY));

    _layoutIndex = List.generate(16, (int index) {
      int r = index % 4;
      int c = index ~/ 4;
      return TablePanelLayoutIndex(xIndex: c, yIndex: r);
    });

    _panelIndex = List.generate(16, (index) => index);
  }

  double get tableScale => _scale;

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

  double get scaleRowHeader =>
      (maxRowHeaderScale < tableScale) ? maxRowHeaderScale : tableScale;

  double get scaleColumnHeader =>
      (maxColumnHeaderScale < tableScale) ? maxColumnHeaderScale : tableScale;

  bool get autoFreezePossibleX =>
      autoFreezeX &&
      stateSplitX != SplitState.SPLIT &&
      autoFreezeAreasX.isNotEmpty;
  //  &&
  // !(stateSplitY == SplitState.SPLIT && !scrollLockY);

  bool get autoFreezePossibleY =>
      autoFreezeY &&
      stateSplitY != SplitState.SPLIT &&
      autoFreezeAreasY.isNotEmpty;
  //  &&
  // !(stateSplitX == SplitState.SPLIT && !scrollLockX);

  set rowHeader(value) {
    _rowHeader = value;
    calculateHeaderWidth();
  }

  get rowHeader => _rowHeader;

  void setScrollScaledX(int horizontal, int vertical, double scrollScaledX) {
    if (autoFreezePossibleX) {
      mainScrollX = scrollScaledX / tableScale;
      calculateAutoScrollX();
    } else if (vertical == 0 || scrollLockX || anyFreezeSplitY) {
      if (horizontal == 0) {
        mainScrollX = scrollX0pY0 = scrollScaledX / tableScale;
      } else {
        scrollX1pY0 = scrollScaledX / tableScale;
      }
    } else {
      if (horizontal == 0) {
        scrollX0pY1 = scrollScaledX / tableScale;
      } else {
        scrollX1pY1 = scrollScaledX / tableScale;
      }
    }
  }

  calculateAutoScrollX() {
    if (!autoFreezePossibleX) return;

    scrollX0pY0 = mainScrollX;
    assert(scrollLockX,
        'autofreezeX and unlock scrollLockX can not used together!');

    final previousHeader = autoFreezeAreaX.header;

    if (!autoFreezeAreaX.constains(mainScrollX)) {
      autoFreezeAreaX = autoFreezeAreasX.firstWhere(
          (element) => element.constains(mainScrollX),
          orElse: () => autoFreezeNoRange);
    }

    if (autoFreezeAreaX.freeze &&
        _isFreezeSplitInWindowX(
            _widthMainPanel, autoFreezeAreaX.header * tableScale)) {
      if (mainScrollX < autoFreezeAreaX.d) {
        scrollX0pY0 = autoFreezeAreaX.startPosition;
        scrollX1pY0 = mainScrollX +
            (autoFreezeAreaX.freezePosition - autoFreezeAreaX.startPosition);
      } else {
        scrollX0pY0 =
            autoFreezeAreaX.startPosition + (mainScrollX - autoFreezeAreaX.d);
        scrollX1pY0 = mainScrollX +
            (autoFreezeAreaX.freezePosition - autoFreezeAreaX.startPosition) -
            (mainScrollX - autoFreezeAreaX.d);
      }

      if (stateSplitX != SplitState.AUTO_FREEZE_SPLIT) {
        if (autoFreezeAreaX.header * tableScale < viewportDimensionX(0) / 2.0) {
          switchX();
        }
        stateSplitX = SplitState.AUTO_FREEZE_SPLIT;
      }

      topLeftCellPaneColumn = autoFreezeAreaX.freezeIndex;
    } else {
      if (stateSplitX == SplitState.AUTO_FREEZE_SPLIT) {
        if (previousHeader * tableScale < viewportDimensionX(0) / 2.0) {
          switchX();
        }
        stateSplitX = SplitState.NO_SPLITE;
      }
    }
  }

  void setScrollWithSliver(double scaledScroll) {
    if (stateSplitY == SplitState.FREEZE_SPLIT) {
      setScrollScaledY(0, 1, scaledScroll + getMinScrollScaledY(1));
    } else {
      setScrollScaledY(0, 0, scaledScroll);
    }
  }

  void setScrollScaledY(int horizontal, int vertical, double scrollScaledY) {
    if (autoFreezePossibleY) {
      mainScrollY = scrollScaledY / tableScale;
      calculateAutoScrollY();
    } else if (horizontal == 0 || scrollLockY || anyFreezeSplitX) {
      if (vertical == 0) {
        mainScrollY = scrollY0pX0 = mainScrollY = scrollScaledY / tableScale;
      } else {
        scrollY1pX0 = scrollScaledY / tableScale;
      }
    } else {
      if (vertical == 0) {
        scrollY0pX1 = scrollScaledY / tableScale;
      } else {
        scrollY1pX1 = scrollScaledY / tableScale;
      }
    }
  }

  calculateAutoScrollY() {
    if (!autoFreezePossibleY) return;

    scrollY0pX0 = mainScrollY;
    assert(scrollLockY,
        'autofreezeY and unlock scrollLockY can not used together!');

    final previousHeader = autoFreezeAreaY.header;

    if (!autoFreezeAreaY.constains(mainScrollY)) {
      autoFreezeAreaY = autoFreezeAreasY.firstWhere(
          (element) => element.constains(mainScrollY),
          orElse: () => autoFreezeNoRange);
    }

    if (autoFreezeAreaY.freeze &&
        _isFreezeSplitInWindowY(
            _heightMainPanel, autoFreezeAreaY.header * tableScale)) {
      if (mainScrollY < autoFreezeAreaY.d) {
        scrollY0pX0 = autoFreezeAreaY.startPosition;
        scrollY1pX0 = mainScrollY +
            (autoFreezeAreaY.freezePosition - autoFreezeAreaY.startPosition);
      } else {
        scrollY0pX0 =
            autoFreezeAreaY.startPosition + (mainScrollY - autoFreezeAreaY.d);
        scrollY1pX0 = mainScrollY +
            (autoFreezeAreaY.freezePosition - autoFreezeAreaY.startPosition) -
            (mainScrollY - autoFreezeAreaY.d);
      }

      if (stateSplitY != SplitState.AUTO_FREEZE_SPLIT) {
        if (autoFreezeAreaY.header * tableScale < viewportDimensionY(0) / 2.0) {
          switchY();
        }
        stateSplitY = SplitState.AUTO_FREEZE_SPLIT;
      }

      topLeftCellPaneRow = autoFreezeAreaY.freezeIndex;
    } else {
      if (stateSplitY == SplitState.AUTO_FREEZE_SPLIT) {
        if (previousHeader * tableScale < viewportDimensionY(0) / 2.0) {
          switchY();
        }
        stateSplitY = SplitState.NO_SPLITE;
      }
    }
  }

  bool setScrollLock(bool lock) {
    scrollLockX = lock;
    scrollLockY = lock;

    if (!lock) {
      scrollY0pX1 = scrollY0pX0;
      scrollX0pY1 = scrollX0pY0;
      scrollX1pY1 = scrollX1pY0;
      scrollY1pX1 = scrollY1pX0;
    }

    return lock;
  }

  FreezeLine get freezeLine {
    if (stateSplitX == SplitState.FREEZE_SPLIT &&
        stateSplitY == SplitState.FREEZE_SPLIT) {
      return FreezeLine.both;
    } else if (stateSplitX == SplitState.FREEZE_SPLIT) {
      return FreezeLine.horizontal;
    } else if (stateSplitY == SplitState.FREEZE_SPLIT) {
      return FreezeLine.vertical;
    } else {
      return FreezeLine.none;
    }
  }

  double get sheetWidth {
    return getSheetLength(_specificWidth);
  }

  double get sheetHeight {
    return getSheetLength(_specificHeight);
  }

  double getSheetLength(List<PropertiesRange> specificLength) {
    double defaultCellLength = (_specificWidth == specificLength)
        ? defaultWidthCell
        : defaultHeightCell;
    int maxCells =
        (_specificWidth == specificLength) ? maximumColumns : maximumRows;

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

  double getX(int column, {int pc: 0}) {
    return getPosition(column, pc, _specificWidth);
  }

  double getY(int row, {int pc: 0}) {
    return getPosition(row, pc, _specificHeight);
  }

  double getPosition(int index, int pc, List<PropertiesRange> specificLength) {
    /* Start of the cell
			 *
			 */

    double defaultLength = ((specificLength == _specificWidth)
        ? defaultWidthCell
        : defaultHeightCell);

    if (specificLength.isEmpty) {
      return defaultLength * (index + pc);
    }

    double length = 0;
    int first = 0;

    for (PropertiesRange cp in specificLength) {
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
      length += ((specificLength == _specificWidth)
              ? defaultWidthCell
              : defaultHeightCell) *
          (index - first + pc);
    }

    return length;
  }

  double get xSplit {
    switch (stateSplitX) {
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        return leftPanelMargin +
            (getX(topLeftCellPaneColumn) - scrollX0pY0) * tableScale +
            leftHeaderPanelLength;
      case SplitState.SPLIT:
        return _xSplit;
      default:
        return 0.0;
    }
  }

  double get ySplit {
    switch (stateSplitY) {
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        return topPanelMargin +
            (getY(topLeftCellPaneRow) - scrollY0pX0) * tableScale +
            topHeaderPanelLength;
      case SplitState.SPLIT:
        return _ySplit;
      default:
        return 0.0;
    }
  }

  void setXsplit(
      {int indexSplit = 0,
      double? sizeSplit,
      double? deltaSplit,
      required SplitState splitView,
      bool animateSplit = false}) {
    if (splitView == SplitState.SPLIT) {
      assert(indexSplit > 0 || sizeSplit != null || deltaSplit != null,
          'Set a value for indexSplit > 0, sizeSplit or deltaSplit to change the X split');

      if (indexSplit > 0) {
        double splitScroll = getX(indexSplit);
        double split = (splitScroll - scrollX0pY0) * tableScale;

        if (minimalSplitPositionFromLeft <= split &&
            minimalSplitPositionFromRight >= split) {
          scrollX0pY0 = scrollX1pY0 = scrollX1pY1 = mainScrollX;

          stateSplitX = SplitState.SPLIT;
          _xSplit = split;
        }
      } else {
        if (deltaSplit != null) {
          sizeSplit = _xSplit + deltaSplit;
        }

        _xSplit = sizeSplit!;

        if ((animateSplit
                ? initiateSplitLeft + 0.1
                : minimalSplitPositionFromLeft) >=
            sizeSplit) {
          if (stateSplitX == SplitState.SPLIT) {
            mainScrollX = scrollX1pY0;
            scrollX0pY0 = scrollX1pY0;
            scrollX0pY1 = scrollX1pY1;

            if (!scrollLockY) {
              scrollY0pX0 = scrollY0pX1;
              scrollY1pX0 = scrollY1pX1;
            }

            stateSplitX = SplitState.NO_SPLITE;
            switchX();

            calculateAutoScrollX();
          }
        } else if ((animateSplit
                ? initiateSplitRight - 0.1
                : minimalSplitPositionFromRight) <=
            sizeSplit) {
          if (stateSplitX == SplitState.SPLIT) {
            stateSplitX = SplitState.NO_SPLITE;
            mainScrollX = scrollX0pY0;

            calculateAutoScrollX();
          }
        } else if (stateSplitX != SplitState.SPLIT) {
          scrollX0pY0 = scrollX1pY0 = scrollX0pY1 = scrollX1pY1 = mainScrollX;
          stateSplitX = SplitState.SPLIT;

          switchXSplit();
          autoFreezeAreaX = AutoFreezeArea.noArea();

          if (stateSplitY == SplitState.SPLIT) {
            scrollX1pY1 = scrollX0pY1;
            scrollY1pX1 = scrollY1pX0;
          }

          //  else if (autoFreezeAreaY.freeze && !scrollLockY) {
          //   autoFreezeAreaY = AutoFreezeArea.noArea();
          //   scrollY0pX0 = mainScrollY;
          //   stateSplitY = SplitState.NO_SPLITE;
          // }

          scrollY0pX1 = scrollY0pX0;
        }
      }
    } else if (splitView == SplitState.FREEZE_SPLIT) {
      assert(stateSplitX != SplitState.FREEZE_SPLIT,
          'StateSplitX is already in FreezeSplit mode!');

      assert(indexSplit > 0 && indexSplit < maximumColumns - 1,
          'Set indexSplit between 1 and maximumColumns - 2: {maximumColumns - 2}');

      scrollX0pY0 = mainScrollX;
      topLeftCellPaneColumn = indexSplit;
      scrollX1pY0 = getX(indexSplit);

      final freezeHeader = (scrollX1pY0 - scrollX0pY0) * tableScale;

      if (freezeHeader >= freezePadding * tableScale &&
          tableWidthFreeze - freezeHeader >= freezePadding * tableScale) {
        stateSplitX = SplitState.FREEZE_SPLIT;

        switchXFreeze();
      }
    } else {
      if (stateSplitX == SplitState.FREEZE_SPLIT) {
        mainScrollX = scrollX1pY0 - (getX(topLeftCellPaneColumn) - scrollX0pY0);

        switchXFreeze();
      } else if (stateSplitX == SplitState.SPLIT) {
        switchXSplit();
        _xSplit = 0;
      }

      stateSplitX = SplitState.NO_SPLITE;
    }
  }

  switchXFreeze() {
    final freezeHeader = (scrollX1pY0 - scrollX0pY0) * tableScale;

    if (freezeHeader < tableWidthFreeze - freezeHeader) {
      switchX();
    }
  }

  switchXSplit() {
    bool switchPanels = false;

    if (autoFreezeAreaX.freeze) {
      final freezeHeader = autoFreezeAreaX.header;

      if (freezeHeader < tableWidthFreeze - freezeHeader)
        switchPanels = !switchPanels;
    }

    if (_xSplit - initiateSplitLeft < initiateSplitRight - _xSplit)
      switchPanels = !switchPanels;

    if (switchPanels) switchX();
  }

  void setYsplit(
      {int indexSplit = 0,
      double? sizeSplit,
      double? deltaSplit,
      required SplitState splitView,
      bool animateSplit = false}) {
    if (splitView == SplitState.SPLIT) {
      assert(indexSplit > 0 || sizeSplit != null || deltaSplit != null,
          'Set a value for indexSplit > 0, sizeSplit or deltaSplit to change the Y split');

      if (indexSplit > 0) {
        assert(stateSplitY == SplitState.SPLIT,
            'Split from index can not be set when split is already enabled');

        double splitScroll = getY(indexSplit);
        double split = (splitScroll - scrollY0pX0) * tableScale;

        if (minimalSplitPositionFromTop <= split &&
            minimalSplitPositionFromBottom >= split) {
          scrollY0pX0 = scrollY1pX0 = scrollY0pX1 = scrollY1pX1 = mainScrollY;
          stateSplitY = SplitState.SPLIT;
          _ySplit = split;
        }
      } else {
        if (deltaSplit != null) {
          sizeSplit = _ySplit + deltaSplit;
        }

        _ySplit = sizeSplit!;

        if ((animateSplit
                ? initiateSplitTop + 0.1
                : minimalSplitPositionFromTop) >=
            sizeSplit) {
          if (stateSplitY == SplitState.SPLIT) {
            mainScrollY = scrollY1pX0;
            scrollY0pX0 = scrollY1pX0;
            scrollY0pX1 = scrollY1pX1;

            if (!scrollLockX) {
              scrollX0pY0 = scrollX0pY1;
              scrollX1pY0 = scrollX1pY1;
            }

            stateSplitY = SplitState.NO_SPLITE;

            switchY();
          }

          calculateAutoScrollY();
        } else if ((animateSplit
                ? initiateSplitBottom - 0.1
                : minimalSplitPositionFromBottom) <=
            sizeSplit) {
          if (stateSplitY == SplitState.SPLIT) {
            stateSplitY = SplitState.NO_SPLITE;
            mainScrollY = scrollY0pX0;
            calculateAutoScrollY();
          }
        } else if (stateSplitY != SplitState.SPLIT) {
          scrollY0pX0 = scrollY1pX0 = scrollY0pX1 = scrollY1pX1 = mainScrollY;
          stateSplitY = SplitState.SPLIT;

          switchYSplit();
          autoFreezeAreaY = AutoFreezeArea.noArea();

          if (stateSplitX == SplitState.SPLIT) {
            scrollY1pX1 = scrollY0pX1;
            scrollX1pY1 = scrollX1pY0;
          }

          // else if (autoFreezeAreaX.freeze && !scrollLockX) {
          //   autoFreezeAreaX = AutoFreezeArea.noArea();
          //   scrollX0pY0 = mainScrollX;
          //   stateSplitX = SplitState.NO_SPLITE;
          // }

          scrollX0pY1 = scrollX0pY0;
        }
      }
    } else if (splitView == SplitState.FREEZE_SPLIT) {
      assert(stateSplitY != SplitState.FREEZE_SPLIT,
          'StateSplitY is already in FreezeSplit mode!');

      assert(indexSplit > 0 && indexSplit < maximumRows - 1,
          'Set indexSplit between 1 and maximumRows - 2: {maximumRows - 2}');

      scrollY0pX0 = mainScrollY;
      topLeftCellPaneRow = indexSplit;
      scrollY1pX0 = getY(indexSplit);

      final freezeHeader = (scrollY1pX0 - scrollY0pX0) * tableScale;

      if (freezeHeader >= freezePadding * tableScale &&
          tableHeightFreeze - freezeHeader >= freezePadding * tableScale) {
        stateSplitY = SplitState.FREEZE_SPLIT;
        switchYFreeze();
      }
    } else {
      if (stateSplitY == SplitState.FREEZE_SPLIT) {
        mainScrollY = scrollY1pX0 - (getY(topLeftCellPaneRow) - scrollY0pX0);
        switchYFreeze();
      } else if (stateSplitY == SplitState.SPLIT) {
        switchYSplit();
        _ySplit = 0;
      }

      stateSplitY = SplitState.NO_SPLITE;
    }
  }

  switchYFreeze() {
    final freezeHeader = (scrollY1pX0 - scrollY0pX0) * tableScale;

    if (freezeHeader < tableHeightFreeze - freezeHeader) {
      switchY();
    }
  }

  switchYSplit() {
    bool switchPanels = false;

    if (autoFreezeAreaY.freeze) {
      final freezeHeader = autoFreezeAreaY.header;

      if (freezeHeader < tableHeightFreeze - freezeHeader)
        switchPanels = !switchPanels;
    }

    if (_ySplit - initiateSplitTop < initiateSplitBottom - _ySplit)
      switchPanels = !switchPanels;

    if (switchPanels) switchY();
  }

  checkAutoScroll() {
    if (autoFreezePossibleX) calculateAutoScrollX();
    if (autoFreezePossibleY) calculateAutoScrollY();
  }

  double get freezeMiniSizeScaledX => freezeMinimumSize * tableScale;

  double getMinScrollScaledX(int horizontal) {
    if (autoFreezePossibleX) {
      return 0.0;
    } else if (stateSplitX == SplitState.FREEZE_SPLIT) {
      if (horizontal == 0) {
        final width =
            widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;

        final positionFreeze = getX(topLeftCellPaneColumn) * tableScale;
        return width - freezeMiniSizeScaledX > positionFreeze
            ? 0.0
            : positionFreeze - width + freezeMiniSizeScaledX;
      } else {
        return getX(topLeftCellPaneColumn) * tableScale;
      }
    } else {
      return 0;
    }
  }

  double get freezeMiniSizeScaledY => freezeMinimumSize * tableScale;

  double getMinScrollScaledY(int vertical) {
    if (autoFreezePossibleY) {
      return 0.0;
    } else if (stateSplitY == SplitState.FREEZE_SPLIT) {
      if (vertical == 0) {
        final height =
            heightLayoutList[1].panelLength + heightLayoutList[2].panelLength;

        final heightFreeze = getY(topLeftCellPaneRow) * tableScale;
        return height - freezeMiniSizeScaledY > heightFreeze
            ? 0.0
            : heightFreeze - height + freezeMiniSizeScaledY;
      } else {
        return getY(topLeftCellPaneRow) * tableScale;
      }
    } else {
      return 0;
    }
  }

  double getMaxScrollScaledX(int scrollIndex) {
    double maxScroll;

    if (autoFreezePossibleX) {
      double lengthPanels = widthLayoutList[2].panelEndPosition -
          widthLayoutList[1].panelPosition;

      maxScroll = sheetWidth * tableScale - lengthPanels;
    } else {
      maxScroll = (scrollIndex == 0 && stateSplitX == SplitState.FREEZE_SPLIT)
          ? (getX(topLeftCellPaneColumn) - freezeMinimumSize) * tableScale
          : sheetWidth * tableScale -
              widthLayoutList[scrollIndex + 1].panelLength;
    }

    return (maxScroll < 0.0) ? 0.0 : maxScroll;
  }

  double getMaxScrollScaledY(int scrollIndex) {
    double maxScroll;

    if (autoFreezePossibleY) {
      double lengthPanels = heightLayoutList[2].panelEndPosition -
          heightLayoutList[1].panelPosition;

      maxScroll = sheetHeight * tableScale - lengthPanels;
    } else {
      maxScroll = (scrollIndex == 0 && stateSplitY == SplitState.FREEZE_SPLIT)
          ? (getY(topLeftCellPaneRow) - freezeMinimumSize) * tableScale
          : sheetHeight * tableScale -
              heightLayoutList[scrollIndex + 1].panelLength;
    }
    return (maxScroll < 0.0) ? 0.0 : maxScroll;
  }

  void setScroll(int scrollIndexX, int scrollIndexY, Offset offset) {
    setScrollScaledX(scrollIndexX, scrollIndexY, offset.dx);
    setScrollScaledY(scrollIndexX, scrollIndexY, offset.dy);
  }

  Offset getScroll(int scrollIndexX, int scrollIndexY) {
    return Offset(getScrollX(scrollIndexX, scrollIndexY),
        getScrollY(scrollIndexX, scrollIndexY));
  }

  double getScrollScaledX(int scrollIndexX, int scrollIndexY,
          {bool scrollActivity = false}) =>
      getScrollX(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity) *
      tableScale;

  double getScrollX(int scrollIndexX, int scrollIndexY,
      {bool scrollActivity = false}) {
    if (scrollActivity && autoFreezePossibleX) {
      return mainScrollX;
    } else if (scrollIndexY == 0 || scrollLockX || anyFreezeSplitY) {
      return scrollIndexX == 0 ? scrollX0pY0 : scrollX1pY0;
    } else {
      return scrollIndexX == 0 ? scrollX0pY1 : scrollX1pY1;
    }
  }

  DrawScrollBar drawHorizontalScrollBar(int scrollIndexX, int scrollIndexY) {
    if (tableScrollDirection == TableScrollDirection.vertical) {
      return DrawScrollBar.NONE;
    }

    if (widthLayoutList[scrollIndexX + 1].panelLength >=
        sheetWidth * tableScale) return DrawScrollBar.NONE;

    switch (stateSplitY) {
      case SplitState.SPLIT:
        return (scrollIndexY == 0 && stateSplitY == SplitState.SPLIT)
            ? (scrollLockX ? DrawScrollBar.NONE : DrawScrollBar.TOP)
            : DrawScrollBar.BOTTOM;
      default:
        return DrawScrollBar.BOTTOM;
    }
  }

  DrawScrollBar drawHorizontalScrollBarTrack(
      int scrollIndexX, int scrollIndexY) {
    final scrollBar = drawHorizontalScrollBar(scrollIndexX, scrollIndexY);

    if (stateSplitY != SplitState.SPLIT || scrollBar != DrawScrollBar.NONE) {
      return scrollBar;
    }

    return drawHorizontalScrollBar((scrollIndexX + 1) % 2, scrollIndexY);
  }

  double getScrollScaledY(int scrollIndexX, int scrollIndexY,
          {bool scrollActivity = false}) =>
      getScrollY(scrollIndexX, scrollIndexY, scrollActivity: scrollActivity) *
      tableScale;

  double getScrollY(scrollIndexX, scrollIndexY, {bool scrollActivity: false}) {
    if (scrollActivity && autoFreezePossibleY) {
      return mainScrollY;
    } else if (scrollIndexX == 0 || scrollLockY || anyFreezeSplitX) {
      return scrollIndexY == 0 ? scrollY0pX0 : scrollY1pX0;
    } else {
      return scrollIndexY == 0 ? scrollY0pX1 : scrollY1pX1;
    }
  }

  DrawScrollBar drawVerticalScrollBar(int scrollIndexX, int scrollIndexY) {
    if (tableScrollDirection == TableScrollDirection.horizontal) {
      return DrawScrollBar.NONE;
    }

    if (heightLayoutList[scrollIndexY + 1].panelLength >=
        sheetHeight * tableScale) return DrawScrollBar.NONE;

    switch (stateSplitX) {
      case SplitState.SPLIT:
        {
          return (scrollIndexX == 0 && stateSplitX == SplitState.SPLIT)
              ? (scrollLockY ? DrawScrollBar.NONE : DrawScrollBar.LEFT)
              : DrawScrollBar.RIGHT;
        }
      default:
        {
          return DrawScrollBar.RIGHT;
        }
    }
  }

  DrawScrollBar drawVerticalScrollBarTrack(int scrollIndexX, int scrollIndexY) {
    final scrollBar = drawVerticalScrollBar(scrollIndexX, scrollIndexY);

    if (stateSplitX != SplitState.SPLIT || scrollBar != DrawScrollBar.NONE) {
      return scrollBar;
    }

    return drawVerticalScrollBar(scrollIndexX, (scrollIndexY + 1) % 2);
  }

  SelectionIndex findIndex(
      double distance,
      List<PropertiesRange> specificLength,
      int plusOne,
      int maximumCells,
      double defaultLength) {
    int found = KEEPSEARCHING;

    if (specificLength.isEmpty) {
      found = distance ~/ defaultLength;
    } else {
      double length = 0;
      int findIndex = 0;

      for (PropertiesRange cp in specificLength) {
        if (findIndex < cp.min) {
          double lengthDefaultSection = (cp.min - findIndex) * defaultLength;

          if (distance < length + lengthDefaultSection) {
            findIndex += (distance - length) ~/ defaultLength;
            found = findIndex;
            break;
          } else {
            length += lengthDefaultSection;
            findIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double l = cp.length ?? defaultLength;
          double lengthCostumSection = (cp.max - cp.min + 1) * l;

          if (distance < length + lengthCostumSection) {
            findIndex += (distance - length) ~/ l;
            found = findIndex;
            break;
          } else {
            length += lengthCostumSection;
            findIndex += cp.max - cp.min + 1;
          }
        } else {
          findIndex = cp.max + 1;
        }
      }

      if (found == KEEPSEARCHING) {
        findIndex += (distance - length) ~/ defaultLength;
        found = findIndex;
      }
    }

    found += plusOne;

    if (found < 0) {
      found = 0;
    } else if (found > maximumCells) {
      found = maximumCells;
    }

    return findSelectionIndex(specificLength, found);
  }

  SelectionIndex findSelectionIndex(
      List<PropertiesRange> specificLength, int found) {
    bool firstFound = false, secondFound = false;
    int hiddenStartIndex = -1, maximumHiddenStartIndex = 0;

    int hiddenLastIndex = -1;

    for (PropertiesRange cp in specificLength) {
      /* Find start_screen index
             *
             */
      if (!firstFound) {
        if (found > cp.max) {
          if (cp.hidden || cp.collapsed) {
            if (hiddenStartIndex == -1 ||
                maximumHiddenStartIndex + 1 < cp.min) {
              hiddenStartIndex = cp.min;
            }
            maximumHiddenStartIndex = cp.max;
          } else {
            hiddenStartIndex = -1;
          }
        } else {
          firstFound = true;
        }
      }

      /* Find last index
             *
             */
      if (!secondFound) {
        if (cp.min > found &&
            hiddenLastIndex != -1 &&
            hiddenLastIndex < cp.min) {
          secondFound = true;
        } else if (cp.hidden || cp.collapsed) {
          if (cp.min == found || hiddenLastIndex == cp.min) {
            hiddenLastIndex = cp.max + 1;
          }
        }
      }

      if (firstFound && secondFound) {
        break;
      }
    }

    /* Find start_screen index
         *
         */
    if (hiddenStartIndex != -1 && maximumHiddenStartIndex + 1 != found) {
      hiddenStartIndex = -1;
    }

    return SelectionIndex(
        indexStart: hiddenStartIndex != -1 ? hiddenStartIndex : found,
        indexLast: hiddenLastIndex != -1 ? hiddenLastIndex : found);
  }

  SelectionIndex findFirstColumn(int scrollIndexX, int scrollIndexY,
      {double width = 0.0}) {
    double x = getScrollX(scrollIndexX, scrollIndexY) + width;
    return findIndex(x, _specificWidth, 0, maximumColumns, defaultWidthCell);
  }

  SelectionIndex findLastColumn(int scrollIndexX, int scrollIndexY,
      {double width = 0.0}) {
    double x = getScrollX(scrollIndexX, scrollIndexY) + width;
    return findIndex(x, _specificWidth, 1, maximumColumns, defaultWidthCell);
  }

  SelectionIndex findFirstRow(int scrollIndexX, int scrollIndexY,
      {double height = 0.0}) {
    double y = getScrollY(scrollIndexX, scrollIndexY);
    return findIndex(y, _specificHeight, 0, maximumRows, defaultHeightCell);
  }

  SelectionIndex findLastRow(int scrollIndexX, int scrollIndexY,
      {double height = 0.0}) {
    double y = getScrollY(scrollIndexX, scrollIndexY) + height;
    return findIndex(y, _specificHeight, 1, maximumRows, defaultHeightCell);
  }

  gridInfoList(
      {required List<PropertiesRange> specificLength,
      required double begin,
      required double end,
      required double defaultLength,
      required int size,
      required List<GridInfo> infoGridList}) {
    var index = 0;
    var currentLength = 0.0;

    infoGridList.clear();

    bool find(max, double length, bool visible, int listIndex) {
      if (visible) {
        var lengthAtEnd = currentLength + (max - index) * length;

        if (begin > lengthAtEnd) {
          currentLength = lengthAtEnd;
          index = max;
        } else {
          if (currentLength < begin) {
            var delta = (begin - currentLength) ~/ length;
            index += delta;
            currentLength += delta * length;
          }

          if (end <= currentLength + (max - index) * length) {
            var endDeltaIndex = index + (end - currentLength) ~/ length + 1;

            if (endDeltaIndex > max) {
              endDeltaIndex = max;
            }

            for (var i = index; i < endDeltaIndex; i++) {
              infoGridList.add(GridInfo(
                  index: i,
                  length: length,
                  position: currentLength,
                  listIndex: listIndex));
              currentLength += length;
            }

            return true;
          } else {
            for (var i = index; i < max; i++) {
              infoGridList.add(GridInfo(
                  index: i,
                  length: length,
                  position: currentLength,
                  listIndex: listIndex));
              currentLength += length;
            }

            index = max;
          }
        }
      } else {
        index = max;
      }

      return false;
    }

    int listLength = specificLength.length;

    for (int i = 0; i < listLength; i++) {
      final cp = specificLength[i];

      if (index < cp.min) {
        if (find(cp.min, defaultLength, true, i)) {
          return;
        }
      }

      if (index == cp.min) {
        if (find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed), i)) {
          return;
        }
      } else {
        assert(index <= cp.max,
            'Index $index should be equal or smaller then max ${cp.max}');
      }
    }

    find(size, defaultLength, true, listLength);
  }

  GridInfo findGridInfoRow(int toIndex) {
    return _findGridInfo(
        specificLength: _specificHeight,
        defaultLength: defaultHeightCell,
        toIndex: toIndex,
        maxGrids: maximumRows);
  }

  GridInfo findGridInfoColumn(int toIndex) {
    return _findGridInfo(
        specificLength: _specificWidth,
        defaultLength: defaultWidthCell,
        toIndex: toIndex,
        maxGrids: maximumColumns);
  }

  GridInfo _findGridInfo(
      {required List<PropertiesRange> specificLength,
      required int toIndex,
      required double defaultLength,
      required int maxGrids}) {
    var listIndex = 0;
    var index = 0;
    var nextPosition = 0.0;

    assert(index <= toIndex, 'lastIndex should be larger then ...');

    GridInfo? find(max, double length, bool visible) {
      final last = toIndex < max ? toIndex + 1 : max;
      length = visible ? length : 0.0;
      var position = nextPosition;

      if (visible) {
        position += (last - index - 1) * length;
        nextPosition = position + length;
      }

      index = last;

      return (toIndex == last - 1)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    final lengthList = specificLength.length;

    while (listIndex < lengthList) {
      final cp = specificLength[listIndex];

      if (index < cp.min) {
        final t = find(cp.min, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.min) {
        final t = find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }

      listIndex++;
    }

    return find(toIndex + 1, defaultLength, true)!;
  }

  GridInfo findGridInfoRowForward(
      {required int toIndex, required GridInfo startingPoint}) {
    return findGridInfoForward(
        specificLength: _specificHeight,
        defaultLength: defaultHeightCell,
        toIndex: toIndex,
        maxGrids: maximumRows,
        startingPoint: startingPoint);
  }

  GridInfo findGridInfoRowReverse(
      {required int toIndex, required GridInfo startingPoint}) {
    return findGridInfoReverse(
        specificLength: _specificHeight,
        defaultLength: defaultHeightCell,
        toIndex: toIndex,
        startingPoint: startingPoint);
  }

  GridInfo findGridInfoForward(
      {required List<PropertiesRange> specificLength,
      required int toIndex,
      required double defaultLength,
      required int maxGrids,
      required GridInfo startingPoint}) {
    int listIndex = startingPoint.listIndex;
    var index = startingPoint.index + 1;
    var nextPosition = startingPoint.position + startingPoint.length;

    assert(index <= toIndex, 'lastIndex should be larger then ...');

    GridInfo? find(max, double length, bool visible) {
      final last = toIndex < max ? toIndex + 1 : max;
      length = visible ? length : 0.0;
      var position = nextPosition;

      if (visible) {
        position += (last - index - 1) * length;
        nextPosition = position + length;
      }

      index = last;

      return (toIndex == last - 1)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    final lengthList = specificLength.length;

    while (listIndex < lengthList) {
      final cp = specificLength[listIndex];

      if (index < cp.min) {
        final t = find(cp.min, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.min) {
        final t = find(cp.max + 1, cp.length ?? defaultLength,
            !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }

      listIndex++;
    }

    return find(toIndex + 1, defaultLength, true)!;
  }

  GridInfo findGridInfoReverse(
      {required List<PropertiesRange> specificLength,
      required int toIndex,
      required double defaultLength,
      required GridInfo startingPoint}) {
    int listIndex = startingPoint.listIndex;
    var index = startingPoint.index;
    var position = startingPoint.position;

    GridInfo? find(min, double length, bool visible) {
      final first = toIndex > min ? toIndex : min;
      length = visible ? length : 0.0;

      if (visible) {
        position -= (index - first) * length;
      }
      index = first;

      return (toIndex >= min)
          ? GridInfo(index: toIndex, length: length, position: position)
          : null;
    }

    if (listIndex == specificLength.length) {
      listIndex--;
    }

    while (0 <= listIndex) {
      final cp = specificLength[listIndex];

      if (index > cp.max + 1) {
        final t = find(cp.max + 1, defaultLength, true);
        if (t != null) {
          return t;
        }
      }

      if (index == cp.max + 1) {
        final t = find(
            cp.min, cp.length ?? defaultLength, !(cp.hidden || cp.collapsed));

        if (t != null) {
          return t;
        }
      }
      listIndex--;
    }

    return find(0, defaultLength, true)!;
  }

  /// layout panels
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  List<GridInfo> rowInfoListX0Y0 = [];
  List<GridInfo> rowInfoListX0Y1 = [];
  List<GridInfo> rowInfoListX1Y0 = [];
  List<GridInfo> rowInfoListX1Y1 = [];
  List<GridInfo> columnInfoListX0Y0 = [];
  List<GridInfo> columnInfoListX0Y1 = [];
  List<GridInfo> columnInfoListX1Y0 = [];
  List<GridInfo> columnInfoListX1Y1 = [];

  TablePanelLayoutIndex layoutIndex(int panelIndex) {
    return _layoutIndex[panelIndex];
  }

  int panelIndex(int row, int column) {
    return _panelIndex[column * 4 + row];
  }

  switchX() {
    for (int r = 0; r < 4; r++) {
      int firstIndex = 1 * 4 + r;
      int secondIndex = 2 * 4 + r;

      exchange(_panelIndex, firstIndex, secondIndex);
      exchange(_layoutIndex, firstIndex, secondIndex);
    }
  }

  switchY() {
    for (int c = 0; c < 4; c++) {
      int firstIndex = c * 4 + 1;
      int secondIndex = c * 4 + 2;

      exchange(_panelIndex, firstIndex, secondIndex);
      exchange(_layoutIndex, firstIndex, secondIndex);
    }
  }

  exchange(List list, firstIndex, secondIndex) {
    final temp = list[firstIndex];
    list[firstIndex] = list[secondIndex];
    list[secondIndex] = temp;
  }

  void calculate({required double width, required double height}) {
    if (tableScrollDirection != TableScrollDirection.horizontal)
      adjustSplitStateAfterWidthResize(width);

    if (tableScrollDirection != TableScrollDirection.vertical)
      adjustSplitStateAfterWidthResize(width);

    if (tableScrollDirection != TableScrollDirection.horizontal)
      adjustSplitStateAfterHeightResize(height);

    if (scrollBarTrack)
      calculateScrollBarTrack(
          width: width,
          height: height,
          widthLayout: widthLayoutList,
          heightLayout: heightLayoutList,
          setRatioHorizontal: (double ratio) =>
              ratioHorizontalScrollBarTrack = ratio,
          setRatioVertical: (double ratio) =>
              ratioVerticalScrollBarTrack = ratio);

    final maxHeightNoSplit = computeMaxIntrinsicHeightNoSplit(width);
    final maxWidthNoSplit = computeMaxIntrinsicWidthNoSplit(height);

    if (maxHeightNoSplit <= height && maxWidthNoSplit <= width) {
      stateSplitX = SplitState.NO_SPLITE;
      stateSplitY = SplitState.NO_SPLITE;
    }

    _layoutY(
        maxHeightNoSplit:
            maxHeightNoSplit + sizeScrollBarBottom + bottomHeaderLayoutLength,
        height: height);
    _layoutX(
        maxWidthNoSplit:
            maxWidthNoSplit + sizeScrollBarRight + rightHeaderLayoutLength,
        width: width);

    if (_widthMainPanel != width ||
        _heightMainPanel != height ||
        scheduleCorrectOffScroll) {
      _widthMainPanel = width;
      _heightMainPanel = height;
      scheduleCorrectOffScroll = false;
      tableScrollPosition.correctOffScroll(0, 0);
    }
  }

  _layoutY({required double maxHeightNoSplit, required double height}) {
    double yOffset = 0.0;

    if (maxHeightNoSplit < height) {
      stateSplitY = SplitState.NO_SPLITE;

      final centerY = (height - maxHeightNoSplit) / 2.0;

      yOffset = centerY + centerY * alignment.y;
      height = maxHeightNoSplit;
    }

    panelLength(
        gridLayoutList: heightLayoutList,
        splitState: stateSplitY,
        panelLength: height,
        headerStartPanelLength: topHeaderPanelLength,
        headerEndPanelLength: bottomHeaderPanelLength,
        headerStartLayoutLength: topHeaderPanelLength,
        headerEndLayoutLength: bottomHeaderLayoutLength,
        splitPosition: ySplit,
        startMargin: topPanelMargin,
        endMargin: bottomPanelMargin,
        sizeScrollBarAtStart: sizeScrollBarTop,
        sizeScrollBarAtEnd: sizeScrollBarBottom,
        spaceSplitFreeze: horizontalSplitFreeze);

    position(heightLayoutList, sizeScrollBarTop + yOffset);

    _calculateRowInfoList(0, 0, rowInfoListX0Y0);

    if (stateSplitX == SplitState.SPLIT && !scrollLockY) {
      _calculateRowInfoList(1, 0, rowInfoListX1Y0);
    } else {
      rowInfoListX1Y0.clear();
    }

    if (stateSplitY != SplitState.NO_SPLITE) {
      _calculateRowInfoList(0, 1, rowInfoListX0Y1);

      if (stateSplitX == SplitState.SPLIT && !scrollLockY) {
        _calculateRowInfoList(1, 1, rowInfoListX1Y1);
      } else {
        rowInfoListX1Y1.clear();
      }
    } else {
      rowInfoListX1Y1.clear();
    }

    findRowHeaderWidth();
  }

  _layoutX({required double maxWidthNoSplit, required double width}) {
    double xOffset = 0.0;

    if (maxWidthNoSplit < width) {
      stateSplitX = SplitState.NO_SPLITE;
      final centerX = (width - maxWidthNoSplit) / 2.0;
      xOffset = centerX + centerX * alignment.x;
      width = maxWidthNoSplit;
    }

    panelLength(
        gridLayoutList: widthLayoutList,
        splitState: stateSplitX,
        panelLength: width,
        headerStartPanelLength: leftHeaderPanelLength,
        headerEndPanelLength: rightHeaderPanelLength,
        headerStartLayoutLength: leftHeaderPanelLength,
        headerEndLayoutLength: rightHeaderLayoutLength,
        splitPosition: xSplit,
        startMargin: leftPanelMargin,
        endMargin: rightPanelMargin,
        sizeScrollBarAtStart: sizeScrollBarLeft,
        sizeScrollBarAtEnd: sizeScrollBarRight,
        spaceSplitFreeze: verticalSplitFreeze);

    position(widthLayoutList, sizeScrollBarLeft + xOffset);

    _calculateColumnInfoList(0, 0, columnInfoListX0Y0);

    if (stateSplitY == SplitState.SPLIT && !scrollLockX) {
      _calculateColumnInfoList(0, 1, columnInfoListX0Y1);
    } else {
      columnInfoListX0Y1.clear();
    }

    if (stateSplitX != SplitState.NO_SPLITE) {
      _calculateColumnInfoList(1, 0, columnInfoListX1Y0);

      if (stateSplitY == SplitState.SPLIT && !scrollLockX) {
        _calculateColumnInfoList(1, 1, columnInfoListX1Y1);
      } else {
        columnInfoListX1Y1.clear();
      }
    } else {
      columnInfoListX1Y1.clear();
    }
  }

  bool _isFreezeSplitInWindowX(double width, double widthFreezedPanel) {
    final xStartPanel = leftHeaderPanelLength + leftPanelMargin;
    final xEndPanel = width - sizeScrollBarTrack - rightPanelMargin;

    final xStartTable = splitChangeInsets * tableScale;
    final xEndTable = xEndPanel - xStartPanel - splitChangeInsets * tableScale;

    return widthFreezedPanel > xStartTable && widthFreezedPanel < xEndTable;
  }

  bool _isFreezeSplitInWindowY(double height, double heightFreezedPanel) {
    final yStartPanel = topHeaderPanelLength + topPanelMargin;
    final yEndPanel = height - sizeScrollBarTrack - bottomPanelMargin;
    final yStartTable = splitChangeInsets * tableScale;
    final yEndTable = yEndPanel - yStartPanel - splitChangeInsets * tableScale;

    return heightFreezedPanel > yStartTable && heightFreezedPanel < yEndTable;
  }

  isSplitInWindowX(double width) {
    final xStart = (scrollLockY ? 0.0 : sizeScrollBarTrack) +
        leftHeaderPanelLength +
        leftPanelMargin +
        splitChangeInsets;
    final xEnd = width -
        sizeScrollBarTrack -
        rightHeaderLayoutLength -
        rightPanelMargin -
        splitChangeInsets * tableScale;

    return _xSplit >= xStart && _xSplit <= xEnd;
  }

  isSplitInWindowY(double height) {
    final yStart = (scrollLockX ? 0.0 : sizeScrollBarTrack) +
        topHeaderPanelLength +
        topPanelMargin +
        splitChangeInsets;
    final yEnd = height -
        sizeScrollBarTrack -
        bottomHeaderLayoutLength -
        splitChangeInsets * tableScale;

    return _ySplit >= yStart && _ySplit <= yEnd;
  }

  adjustSplitStateAfterWidthResize(double width) {
    switch (stateSplitX) {
      case SplitState.CANCELED_FREEZE_SPLIT:
        {
          if (_isFreezeSplitInWindowX(width,
              (getX(topLeftCellPaneColumn) - scrollX0pY0) * tableScale)) {
            stateSplitX = SplitState.FREEZE_SPLIT;

            scrollX1pY0 =
                mainScrollX + (getX(topLeftCellPaneColumn) - scrollX0pY0);
          }
          break;
        }
      case SplitState.FREEZE_SPLIT:
        {
          if (!_isFreezeSplitInWindowX(width,
              (getX(topLeftCellPaneColumn) - scrollX0pY0) * tableScale)) {
            stateSplitX = SplitState.CANCELED_FREEZE_SPLIT;

            mainScrollX =
                scrollX1pY0 - (getX(topLeftCellPaneColumn) - scrollX0pY0);
          }
          break;
        }
      case SplitState.CANCELED_SPLIT:
        {
          if (isSplitInWindowX(width)) {
            stateSplitX = SplitState.SPLIT;
            scrollX0pY0 = mainScrollX;
          }
          break;
        }
      case SplitState.SPLIT:
        {
          if (!isSplitInWindowX(width)) {
            stateSplitX = SplitState.CANCELED_SPLIT;
            mainScrollX = scrollX0pY0;
          }
          break;
        }

      default:
        {
          if (autoFreezePossibleX) {
            calculateAutoScrollX();
          }
        }
    }
  }

  adjustSplitStateAfterHeightResize(double height) {
    switch (stateSplitY) {
      case SplitState.CANCELED_FREEZE_SPLIT:
        {
          if (_isFreezeSplitInWindowY(
              height, (getY(topLeftCellPaneRow) - scrollY0pX0) * tableScale)) {
            stateSplitY = SplitState.FREEZE_SPLIT;

            scrollY1pX0 =
                mainScrollY + (getY(topLeftCellPaneRow) - scrollY0pX0);
          }
          break;
        }
      case SplitState.FREEZE_SPLIT:
        {
          if (!_isFreezeSplitInWindowY(
              height, (getY(topLeftCellPaneRow) - scrollY0pX0) * tableScale)) {
            stateSplitY = SplitState.CANCELED_FREEZE_SPLIT;

            mainScrollY =
                scrollY1pX0 - (getY(topLeftCellPaneRow) - scrollY0pX0);
          }
          break;
        }
      case SplitState.CANCELED_SPLIT:
        {
          if (isSplitInWindowY(height)) {
            stateSplitY = SplitState.SPLIT;
          }
          break;
        }
      case SplitState.SPLIT:
        {
          if (!isSplitInWindowY(height)) {
            stateSplitY = SplitState.CANCELED_SPLIT;
          }
          break;
        }
      default:
        {
          if (autoFreezePossibleY) {
            calculateAutoScrollY();
          }
        }
    }
  }

  _calculateRowInfoList(int scrollIndexX, int scrollIndexY, rowInfoList) {
    final top = getScrollY(scrollIndexX, scrollIndexY);
    final bottom =
        top + heightLayoutList[scrollIndexY + 1].panelLength / tableScale;

    if (rowInfoList.length == 0 ||
        rowInfoList.first.outside(top) ||
        rowInfoList.last.outside(bottom)) {
      gridInfoList(
          specificLength: _specificHeight,
          begin: top,
          end: bottom,
          defaultLength: defaultHeightCell,
          size: maximumRows,
          infoGridList: rowInfoList);
    }
  }

  _calculateColumnInfoList(int scrollIndexX, int scrollIndexY, columnInfoList) {
    final left = getScrollX(scrollIndexX, scrollIndexY);
    final right =
        left + widthLayoutList[scrollIndexX + 1].panelLength / tableScale;

    if (columnInfoList.length == 0 ||
        columnInfoList.first.outside(left) ||
        columnInfoList.last.outside(right)) {
      gridInfoList(
          specificLength: _specificWidth,
          begin: left,
          end: right,
          defaultLength: defaultWidthCell,
          size: maximumColumns,
          infoGridList: columnInfoList);
    }
  }

  List<GridInfo> getRowInfoList(scrollIndexX, scrollIndexY) {
    if (scrollIndexX == 0 || scrollLockY || anyFreezeSplitX) {
      return scrollIndexY == 0 ? rowInfoListX0Y0 : rowInfoListX0Y1;
    } else {
      return scrollIndexY == 0 ? rowInfoListX1Y0 : rowInfoListX1Y1;
    }
  }

  List<GridInfo> getColumnInfoList(int scrollIndexX, int scrollIndexY) {
    if (scrollIndexY == 0 || scrollLockX || anyFreezeSplitY) {
      return scrollIndexX == 0 ? columnInfoListX0Y0 : columnInfoListX1Y0;
    } else {
      return scrollIndexX == 0 ? columnInfoListX0Y1 : columnInfoListX1Y1;
    }
  }

  calculateHeaderWidth() {
    int count = 0;
    int rowNumber = maximumRows + 1;

    if (_rowHeader) {
      while (rowNumber > 0) {
        rowNumber = rowNumber ~/ 10;
        count++;
      }

      double startPosition = 0.0;

      headerRowProperties = List.generate(count, (listIndex) {
        int i = 1;
        int c = 0;

        while (c < listIndex + 1) {
          i *= 10;
          c++;
        }
        final position = getY(i - 1);
        final item = HeaderProperty(
            index: i - 1,
            startPosition: startPosition,
            endPosition: position,
            digits: listIndex + 1);
        startPosition = position;

        return item;
      }, growable: false);
    } else {
      headerRowProperties = List.empty();
      leftRowHeaderProperty = noHeader;
      rightRowHeaderProperty = noHeader;
    }
  }

  findRowHeaderWidth() {
    if (rowHeader) {
      leftRowHeaderProperty = findWidthLeftHeader();
    } else {
      leftRowHeaderProperty = noHeader;
    }

    if (columnHeader && stateSplitX == SplitState.SPLIT && !scrollLockY) {
      rightRowHeaderProperty = findWidthRightHeader();
    } else {
      rightRowHeaderProperty = noHeader;
    }
  }

  HeaderProperty findWidthLeftHeader() {
    if (headerRowProperties.isEmpty) return noHeader;

    double bottomLeftHeader =
        (heightLayoutList[1].panelLength + getScrollY(0, 0) * tableScale) /
            tableScale;

    if (anySplitY) {
      final bottomLeftHeaderSecond =
          (heightLayoutList[2].panelLength + getScrollY(0, 1) * tableScale) /
              tableScale;
      bottomLeftHeader = math.max(bottomLeftHeader, bottomLeftHeaderSecond);
    }

    for (HeaderProperty item in headerRowProperties) {
      if (bottomLeftHeader < item.endPosition) {
        return item;
      }
    }

    return headerRowProperties.last;
  }

  HeaderProperty findWidthRightHeader() {
    if (headerRowProperties.isEmpty || scrollLockY) return noHeader;

    double bottomRightHeader =
        (heightLayoutList[1].panelLength + getScrollY(1, 0) * tableScale) /
            tableScale;

    if (stateSplitY == SplitState.SPLIT) {
      final bottomRightHeaderSecond =
          (heightLayoutList[2].panelLength + getScrollY(1, 1) * tableScale) /
              tableScale;
      bottomRightHeader = math.max(bottomRightHeader, bottomRightHeaderSecond);
    }

    for (HeaderProperty item in headerRowProperties) {
      if (bottomRightHeader < item.endPosition) {
        return item;
      }
    }

    return headerRowProperties.last;
  }

  double digitsToWidth(HeaderProperty headerProperty) =>
      (headerProperty.index != -1)
          ? (headerProperty.digits * 10.0 + 6.0) * scaleRowHeader
          : 0.0;

  double get sizeScrollBarLeft => (scrollLockY
      ? 0.0
      : sizeScrollBarTrack *
          ratioVerticalScrollBarTrack *
          ratioSizeAnimatedSplitChangeX);

  double get sizeScrollBarRight =>
      sizeScrollBarTrack * ratioVerticalScrollBarTrack;

  double get sizeScrollBarTop => (scrollLockX
      ? 0.0
      : sizeScrollBarTrack *
          ratioHorizontalScrollBarTrack *
          ratioSizeAnimatedSplitChangeY);

  double get sizeScrollBarBottom =>
      sizeScrollBarTrack * ratioHorizontalScrollBarTrack;

  double get initiateSplitLeft => leftHeaderPanelLength - spaceSplit;

  double get initiateSplitTop => topHeaderPanelLength - spaceSplit;

  double get initiateSplitRight => widthMainPanel - sizeScrollBarTrack;

  double get initiateSplitBottom => heightMainPanel - sizeScrollBarTrack;

  double get tableWidthFreeze =>
      widthMainPanel - leftHeaderPanelLength - sizeScrollBarTrack;

  double get tableHeightFreeze =>
      heightMainPanel - topHeaderPanelLength - sizeScrollBarTrack;

  double get minimalSplitPositionFromLeft =>
      (scrollLockY ? 0.0 : sizeScrollBarTrack) +
      digitsToWidth(findWidthLeftHeader()) +
      leftPanelMargin +
      splitChangeInsets;

  double get minimalSplitPositionFromTop =>
      (scrollLockY ? 0.0 : sizeScrollBarTrack) +
      topHeaderPanelLength +
      topPanelMargin +
      splitChangeInsets;

  double get minimalSplitPositionFromRight =>
      widthMainPanel -
      sizeScrollBarTrack -
      digitsToWidth(findWidthRightHeader()) -
      rightPanelMargin -
      splitChangeInsets;

  double get minimalSplitPositionFromBottom =>
      heightMainPanel -
      sizeScrollBarTrack -
      (scrollLockX || !columnHeader ? 0.0 : headerHeight * scaleColumnHeader) -
      bottomPanelMargin -
      splitChangeInsets;

  double get leftHeaderPanelLength => digitsToWidth(leftRowHeaderProperty);

  double get topHeaderPanelLength =>
      columnHeader ? headerHeight * scaleColumnHeader : 0.0;

  double get rightHeaderPanelLength =>
      rightHeaderLayoutLength * ratioSizeAnimatedSplitChangeX;

  double get rightHeaderLayoutLength => digitsToWidth(rightRowHeaderProperty);

  double get bottomHeaderPanelLength =>
      bottomHeaderLayoutLength * ratioSizeAnimatedSplitChangeY;

  double get bottomHeaderLayoutLength =>
      columnHeader && stateSplitY == SplitState.SPLIT && !scrollLockX
          ? headerHeight * scaleColumnHeader
          : 0.0;

  rowVisible(int row) => heightLayoutList[row].inUse;

  columnVisible(int column) => widthLayoutList[column].inUse;

  position(List<GridLayout> gridLengthList, double position) {
    gridLengthList.forEach((gridLength) {
      gridLength.gridPosition = position;
      position += gridLength.gridLength;
    });
  }

  void panelLength(
      {required List<GridLayout> gridLayoutList,
      required SplitState splitState,
      required double panelLength,
      required double headerStartPanelLength,
      required double headerEndPanelLength,
      required double headerStartLayoutLength,
      required double headerEndLayoutLength,
      required double splitPosition,
      required double startMargin,
      required double endMargin,
      required double sizeScrollBarAtStart,
      required double sizeScrollBarAtEnd,
      required spaceSplitFreeze}) {
    if (changeSplit) {
      if (noSplit(splitState)) {
        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength: panelLength -
                headerStartPanelLength -
                sizeScrollBarAtStart -
                sizeScrollBarAtEnd,
            marginBegin: startMargin,
            marginEnd: endMargin);
        gridLayoutList[2].empty();
      } else {
        var halfSpace = spaceSplitFreeze(splitState) / 2.0;

        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength:
                splitPosition - headerStartPanelLength - sizeScrollBarAtStart,
            marginBegin: startMargin,
            marginEnd: halfSpace);

        gridLayoutList[2].setGridLayout(
            index: 2,
            gridLength: panelLength -
                splitPosition -
                headerEndPanelLength -
                sizeScrollBarAtEnd,
            marginBegin: halfSpace,
            marginEnd: endMargin);
      }
    } else if (noSplit(splitState)) {
      if (panelLength < headerStartPanelLength) {
        headerStartPanelLength = 0.0;
      } else if (panelLength < 2.0 * headerStartPanelLength) {
        headerStartPanelLength = panelLength - headerStartPanelLength;
      }

      gridLayoutList[1].setGridLayout(
          index: 1,
          gridLength: panelLength -
              headerStartPanelLength -
              sizeScrollBarAtStart -
              sizeScrollBarAtEnd,
          marginBegin: startMargin,
          marginEnd: endMargin);
      gridLayoutList[2].empty();
    } else {
      var halfSpace = spaceSplitFreeze(splitState) / 2.0;

      if (panelLength < splitPosition - halfSpace) {
        halfSpace = 0.0;

        var split;

        if (panelLength < headerStartPanelLength) {
          split = panelLength;
          headerStartPanelLength = 0.0;
        } else if (panelLength < 2.0 * headerStartPanelLength) {
          split = headerStartPanelLength;
          headerStartPanelLength = panelLength - split;
        } else {
          split = panelLength - headerStartPanelLength;
        }

        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength: split,
            marginBegin: startMargin,
            marginEnd: halfSpace);
        gridLayoutList[2].empty();
        headerEndPanelLength = 0.0;
      } else {
        if (splitPosition < headerStartPanelLength) {
          splitPosition = headerStartPanelLength;
        }

        gridLayoutList[1].setGridLayout(
            index: 1,
            gridLength:
                splitPosition - headerStartPanelLength - sizeScrollBarAtStart,
            marginBegin: startMargin,
            marginEnd: halfSpace);

        var second = panelLength - splitPosition - halfSpace;

        if (second < headerEndPanelLength + sizeScrollBarAtEnd) {
          if (second < sizeScrollBarAtEnd) {
            headerEndPanelLength = 0.0;
            sizeScrollBarAtEnd = second;
          } else {
            headerEndPanelLength = second - sizeScrollBarAtEnd;
            sizeScrollBarAtEnd = second;
          }
        }

        if (splitPosition >
            panelLength - headerEndPanelLength - sizeScrollBarAtEnd) {
          splitPosition =
              panelLength - headerEndPanelLength - sizeScrollBarAtEnd;
        }

        gridLayoutList[2].setGridLayout(
            index: 2,
            gridLength: panelLength -
                splitPosition -
                headerEndPanelLength -
                sizeScrollBarAtEnd,
            marginBegin: halfSpace,
            marginEnd: endMargin);
      }
    }

    gridLayoutList[0].setGridLayout(
        index: 0,
        gridLength: headerStartPanelLength,
        preferredGridLength: headerStartLayoutLength);
    gridLayoutList[3].setGridLayout(
        index: 3,
        gridLength: headerEndPanelLength,
        preferredGridLength: headerEndLayoutLength);
  }

  double computeMaxIntrinsicWidth(double height) {
    if (stateSplitX == SplitState.FREEZE_SPLIT && !autoFreezePossibleX) {
      final xTopLeft = getX(topLeftCellPaneColumn);

      return leftHeaderPanelLength +
          (xTopLeft - scrollX0pY0) * tableScale +
          verticalSplitFreeze(stateSplitX) +
          (getSheetLength(_specificWidth) - xTopLeft) * tableScale +
          sizeScrollBarTrack;
    } else {
      return computeMaxIntrinsicWidthNoSplit(height);
    }
  }

  double computeMaxIntrinsicWidthNoSplit(double height) =>
      leftHeaderPanelLength +
      getSheetLength(_specificWidth) * tableScale +
      sizeScrollBarTrack +
      leftPanelMargin +
      rightPanelMargin;

  double computeMaxIntrinsicHeight(double width) {
    if (stateSplitY == SplitState.FREEZE_SPLIT && !autoFreezePossibleY) {
      final yTopLeft = getY(topLeftCellPaneRow);

      return heightLayoutList[0].gridLength +
          (yTopLeft - scrollY0pX0) * tableScale +
          horizontalSplitFreeze(stateSplitY) +
          (getSheetLength(_specificHeight) - yTopLeft) * tableScale +
          sizeScrollBarTrack;
    } else {
      return computeMaxIntrinsicHeightNoSplit(width);
    }
  }

  double computeMaxIntrinsicHeightNoSplit(double width) =>
      topHeaderPanelLength +
      getSheetLength(_specificHeight) * tableScale +
      sizeScrollBarTrack +
      topPanelMargin +
      bottomPanelMargin;

  shouldRebuild(TableModel old) {
    return true;
  }

  markNeedsLayout() {
    notifyListeners();
  }

  TableScrollDirection get tableScrollDirection {
    if (sliverScrollPosition == null) {
      return TableScrollDirection.both;
    } else {
      switch (sliverScrollPosition!.axisDirection) {
        case AxisDirection.down:
        case AxisDirection.up:
          assert(stateSplitY != SplitState.SPLIT,
              'Split Y (vertical split) is not possible if sliver scroll direction is also vertical');

          return TableScrollDirection.horizontal;
        case AxisDirection.left:
        case AxisDirection.right:
          assert((stateSplitX != SplitState.SPLIT),
              'Split X (horizontal split) is not possible if sliver scroll direction is also horizontal');
          return TableScrollDirection.vertical;
      }
    }
  }

  updateHorizonScrollBarTrack(var setRatio) {
    updateScrollBarTrack(sheetWidth, widthLayoutList, stateSplitX, setRatio);
  }

  updateVerticalScrollBarTrack(var setRatio) {
    updateScrollBarTrack(sheetHeight, heightLayoutList, stateSplitY, setRatio);
  }

  void updateScrollBarTrack(
      double sheetlength, List<GridLayout> gl, SplitState split, setRatio) {
    final sheetLengthScale = sheetlength * tableScale;

    switch (split) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        {
          setRatio(gl[1].panelLength < sheetLengthScale ? 1.0 : 0.0);
          break;
        }
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        {
          setRatio(gl[2].panelLength < sheetLengthScale ? 1.0 : 0.0);
          break;
        }
      case SplitState.SPLIT:
        {
          setRatio((gl[1].panelLength < sheetLengthScale ||
                  gl[2].panelLength < sheetLengthScale)
              ? 1.0
              : 0.0);
          break;
        }
    }
  }

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  // tCalculateScrollBarTrack({var setRatioVertical, var setRatioHorizontal}) {
  //   final t = List.generate(4, (i) => GridLayout(), growable: false);
  //   final t2 = List.generate(4, (i) => GridLayout(), growable: false);

  //   calculateScrollBarTrack(
  //       width: _widthMainPanel,
  //       height: _heightMainPanel,
  //       widthLayout: t,
  //       heightLayout: t2,
  //       setRatioHorizontal: setRatioHorizontal,
  //       setRatioVertical: setRatioVertical);
  // }

  calculateScrollBarTrack(
      {required double width,
      required double height,
      required List<GridLayout> widthLayout,
      required List<GridLayout> heightLayout,
      var setRatioVertical,
      var setRatioHorizontal}) {
    double ratioV = 0.0;
    double ratioH = 0.0;

    switch (tableScrollDirection) {
      case TableScrollDirection.both:
        {
          ratioV = _isVerticalBarVisible(
              height: height,
              heightLayout: heightLayout,
              horizonScrollBarVisible: false);

          if (ratioV == 1.0) {
            ratioH = _isHorizontalBarVisible(
                width: width,
                widthLayout: widthLayout,
                verticalScrollBarVisible: true);
          } else {
            ratioH = _isHorizontalBarVisible(
                width: width,
                widthLayout: widthLayout,
                verticalScrollBarVisible: false);
            if (ratioH == 1.0) {
              ratioV = _isVerticalBarVisible(
                  height: height,
                  heightLayout: heightLayout,
                  horizonScrollBarVisible: true);
            }
          }
          break;
        }
      case TableScrollDirection.vertical:
        {
          ratioV = _isVerticalBarVisible(
              height: height,
              heightLayout: heightLayout,
              horizonScrollBarVisible: false);
          break;
        }
      case TableScrollDirection.horizontal:
        {
          ratioH = _isHorizontalBarVisible(
              width: width,
              widthLayout: widthLayout,
              verticalScrollBarVisible: false);
          break;
        }
      default:
        {}
    }

    setRatioVertical(ratioV);
    setRatioHorizontal(ratioH);
  }

  double _isVerticalBarVisible(
      {required List<GridLayout> heightLayout,
      required double height,
      required bool horizonScrollBarVisible}) {
    panelLength(
        gridLayoutList: heightLayout,
        splitState: stateSplitY,
        panelLength: height,
        headerStartPanelLength: topHeaderPanelLength,
        headerEndPanelLength: bottomHeaderLayoutLength,
        headerStartLayoutLength: topHeaderPanelLength,
        headerEndLayoutLength: bottomHeaderLayoutLength,
        splitPosition: ySplit,
        startMargin: topPanelMargin,
        endMargin: bottomPanelMargin,
        sizeScrollBarAtStart: (!scrollLockX && horizonScrollBarVisible)
            ? sizeScrollBarTrack
            : 0.0,
        sizeScrollBarAtEnd: horizonScrollBarVisible ? sizeScrollBarTrack : 0.0,
        spaceSplitFreeze: horizontalSplitFreeze);

    final sheetHeightScale = sheetHeight * tableScale;
    double ratio;

    switch (stateSplitY) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        {
          ratio = heightLayout[1].panelLength < sheetHeightScale ? 1.0 : 0.0;
          break;
        }
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        {
          ratio = heightLayout[2].panelLength < sheetHeightScale ? 1.0 : 0.0;
          break;
        }
      case SplitState.SPLIT:
        {
          ratio = (heightLayout[1].panelLength < sheetHeightScale ||
                  heightLayout[2].panelLength < sheetHeightScale)
              ? 1.0
              : 0.0;
          break;
        }
    }

    return ratio;
  }

  double _isHorizontalBarVisible(
      {required List<GridLayout> widthLayout,
      required double width,
      required bool verticalScrollBarVisible}) {
    findRowHeaderWidth();

    panelLength(
        gridLayoutList: widthLayout,
        splitState: stateSplitX,
        panelLength: width,
        headerStartPanelLength: leftHeaderPanelLength,
        headerEndPanelLength: rightHeaderLayoutLength,
        headerStartLayoutLength: leftHeaderPanelLength,
        headerEndLayoutLength: rightHeaderLayoutLength,
        splitPosition: xSplit,
        startMargin: leftPanelMargin,
        endMargin: rightPanelMargin,
        sizeScrollBarAtStart: (!scrollLockY && verticalScrollBarVisible)
            ? sizeScrollBarTrack
            : 0.0,
        sizeScrollBarAtEnd: verticalScrollBarVisible ? sizeScrollBarTrack : 0.0,
        spaceSplitFreeze: verticalSplitFreeze);

    final sheetWidthScale = sheetWidth * tableScale;
    double ratio;

    switch (stateSplitX) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        {
          ratio = widthLayout[1].panelLength < sheetWidthScale ? 1.0 : 0.0;
          break;
        }
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        {
          ratio = widthLayout[2].panelLength < sheetWidthScale ? 1.0 : 0.0;
          break;
        }
      case SplitState.SPLIT:
        {
          ratio = (widthLayout[1].panelLength < sheetWidthScale ||
                  widthLayout[2].panelLength < sheetWidthScale)
              ? 1.0
              : 0.0;
          break;
        }
    }

    return ratio;
  }

  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///
  ///

  bool hitFreeze(
    Offset position,
    double kSlope,
  ) {
    if ((stateSplitX == SplitState.SPLIT && stateSplitY == SplitState.SPLIT) ||
        (widthFits && heightFits)) {
      return false;
    }
    // print('table freeze hit');

    bool inArea(double padding) =>
        position.dx >= widthLayoutList[1].panelPosition + padding &&
        position.dx <= widthLayoutList[2].panelEndPosition - padding &&
        position.dy >= heightLayoutList[1].panelPosition + padding &&
        position.dy <= heightLayoutList[2].panelEndPosition - padding;

    bool inFreezeArea = inArea(freezePadding * tableScale);

    bool inUnfreezeArea = (freezePadding == unfreezePadding)
        ? inFreezeArea
        : inArea(unfreezePadding * tableScale);

    if (!autoFreezePossibleX && stateSplitX != SplitState.SPLIT) {
      final column = findIntersectionIndex(
          (position.dx +
                  getScrollX(0, 0) * tableScale -
                  widthLayoutList[0].panelLength) /
              tableScale,
          _specificWidth,
          maximumColumns,
          defaultWidthCell,
          kSlope: kSlope);

      if ((stateSplitX != SplitState.FREEZE_SPLIT &&
              0 < column &&
              inFreezeArea) ||
          (stateSplitX == SplitState.FREEZE_SPLIT &&
              column == topLeftCellPaneColumn &&
              inUnfreezeArea)) {
        return true;
      }
    }
    if (!autoFreezePossibleY && stateSplitY != SplitState.SPLIT) {
      final row = findIntersectionIndex(
          (position.dy +
                  getScrollY(0, 0) * tableScale -
                  heightLayoutList[0].panelLength) /
              tableScale,
          _specificHeight,
          maximumRows,
          defaultHeightCell,
          kSlope: kSlope);

      if ((stateSplitY != SplitState.FREEZE_SPLIT && 0 < row && inFreezeArea) ||
          (stateSplitY == SplitState.FREEZE_SPLIT &&
              row == topLeftCellPaneRow &&
              inUnfreezeArea)) {
        return true;
      }
    }

    return false;
  }

  TableCellIndex freezeIndex(Offset position, double kSlope) {
    return TableCellIndex(
        column: findIntersectionIndex(
            (position.dx +
                    getScrollX(0, 0) * tableScale -
                    widthLayoutList[1].panelPosition) /
                tableScale,
            _specificWidth,
            maximumColumns,
            defaultWidthCell,
            kSlope: kSlope),
        row: findIntersectionIndex(
            (position.dy +
                    getScrollY(0, 0) * tableScale -
                    heightLayoutList[1].panelPosition) /
                tableScale,
            _specificHeight,
            maximumRows,
            defaultHeightCell,
            kSlope: kSlope));
  }

  FreezeChange hitFreezeSplit(Offset position, double kSlope) {
    var cellIndex = freezeIndex(position, kSlope);

    int column = noSplitX &&
            !autoFreezePossibleX &&
            !widthFits &&
            cellIndex.column > 0 &&
            cellIndex.column < maximumColumns - 1
        ? cellIndex.column
        : -1;
    int row = noSplitY &&
            !autoFreezePossibleY &&
            !heightFits &&
            cellIndex.row > 0 &&
            cellIndex.row < maximumRows - 1
        ? cellIndex.row
        : -1;

    if (column > 0 || row > 0) {
      return FreezeChange(
          action: FreezeAction.FREEZE,
          row: row,
          column: column,
          position: Offset(
              column > 0
                  ? (getX(column) - getScrollX(0, 0)) * tableScale +
                      widthLayoutList[1].panelPosition
                  : 0.0,
              row > 0
                  ? (getY(row) - getScrollY(0, 0)) * tableScale +
                      heightLayoutList[1].panelPosition
                  : 0.0));
    }

    column = stateSplitX == SplitState.FREEZE_SPLIT && !autoFreezePossibleX
        ? cellIndex.column
        : -1;
    row = stateSplitY == SplitState.FREEZE_SPLIT && !autoFreezePossibleY
        ? cellIndex.row
        : -1;

    if (column > 0 || row > 0) {
      return FreezeChange(
          action: FreezeAction.UNFREEZE,
          row: topLeftCellPaneRow == cellIndex.row ? topLeftCellPaneRow : -1,
          column: topLeftCellPaneColumn == cellIndex.column
              ? topLeftCellPaneColumn
              : -1,
          position: Offset(
              (getX(cellIndex.column) - getScrollX(0, 0)) * tableScale +
                  widthLayoutList[1].panelPosition,
              (getY(cellIndex.row) - getScrollY(0, 0)) * tableScale +
                  heightLayoutList[1].panelPosition));
    }

    return FreezeChange();
  }

  bool get widthFits =>
      !(widthLayoutList[2].panelEndPosition - widthLayoutList[1].panelPosition <
          sheetWidth * tableScale);

  bool get heightFits => !(heightLayoutList[2].panelEndPosition -
          heightLayoutList[1].panelPosition <
      sheetHeight * tableScale);

  freezeByPosition(FreezeChange freezeChange) {
    if (freezeChange.column > 0 && freezeChange.action == FreezeAction.FREEZE) {
      setXsplit(
          indexSplit: freezeChange.column, splitView: SplitState.FREEZE_SPLIT);
    } else if (freezeChange.column != -1 &&
        freezeChange.action == FreezeAction.UNFREEZE) {
      setXsplit(splitView: SplitState.NO_SPLITE);
    }

    if (freezeChange.row > 0 && freezeChange.action == FreezeAction.FREEZE) {
      if (sliverScrollPosition == null) {
        setYsplit(
            indexSplit: freezeChange.row, splitView: SplitState.FREEZE_SPLIT);
      } else {
        final correct = -getScrollY(0, 0) * tableScale;

        sliverScrollPosition!.correctBy(correct);
        setYsplit(
            indexSplit: freezeChange.row, splitView: SplitState.FREEZE_SPLIT);
      }
    } else if (freezeChange.row != -1 &&
        freezeChange.action == FreezeAction.UNFREEZE) {
      setYsplit(splitView: SplitState.NO_SPLITE);

      if (sliverScrollPosition != null) {
        final correct = scrollY0pX0 * tableScale;

        sliverScrollPosition!.correctBy(correct);
        sliverScrollPosition!.notifyListeners();
      }
    }
  }

  bool setScaleTable(double scale) {
    double oldScale = tableScale;
    tableScale = scale;

    //tableScale sets minScale and maxScale, do not use scale, only oldScale and tableScale

    if (oldScale != tableScale) {
      if (sliverScrollPosition != null) {
        final scrollY = autoFreezePossibleY
            ? getScrollY(0, 0, scrollActivity: true)
            : (stateSplitY == SplitState.FREEZE_SPLIT)
                ? getScrollY(0, 1) - getY(topLeftCellPaneRow)
                : getScrollY(0, 0);
        sliverScrollPosition!.correctPixels(sliverScrollPosition!.pixels +
            scrollY * tableScale -
            scrollY * oldScale);
      }

      return true;
    }
    return false;
  }

  moveFreezeToStartColumnScaled(double decisionInset) =>
      _moveFreezeToStart(getScrollX(0, 0), _specificWidth, maximumColumns,
          defaultWidthCell, decisionInset) *
      tableScale;

  moveFreezeToStartRowScaled(double decisionInset) =>
      _moveFreezeToStart(getScrollY(0, 0), _specificHeight, maximumRows,
          defaultHeightCell, decisionInset) *
      tableScale;

  double _moveFreezeToStart(
      double distance,
      List<PropertiesRange> specificLength,
      int maximumCells,
      double defaultLength,
      double decisionInset) {
    GridInfo gi = findStartEndOfCell(
        distance, specificLength, maximumCells, defaultLength);

    final begin = gi.position;
    final end = gi.endPosition;
    final half = gi.length / 2;

    if (half < decisionInset) {
      decisionInset = half;
    }

    if (gi.index > 0 && distance < begin + decisionInset) {
      distance = begin;
    } else if (distance > end - decisionInset) {
      distance = end;
    }

    return distance;
  }

  GridInfo findStartEndOfCell(
      double distance,
      List<PropertiesRange> specificLength,
      int maximumCells,
      double defaultLength) {
    //Function
    //
    GridInfo find(
        int lastIndex, double distance, double lengthEvaluated, double length) {
      final deltaIndex = (distance - lengthEvaluated) ~/ length;

      final position = lengthEvaluated + deltaIndex * length;

      return GridInfo(
          index: lastIndex + deltaIndex, position: position, length: length);
    }

    if (specificLength.isEmpty) {
      return find(0, distance, 0.0, defaultLength);
    } else {
      double lengthEvaluated = 0;
      int currentIndex = 0;

      for (PropertiesRange cp in specificLength) {
        if (currentIndex < cp.min) {
          double lengthDefaultArea = (cp.min - currentIndex) * defaultLength;

          if (distance <= lengthEvaluated + lengthDefaultArea) {
            return find(currentIndex, distance, lengthEvaluated, defaultLength);
          } else {
            lengthEvaluated += lengthDefaultArea;
            currentIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double customLength = cp.length ?? defaultLength;
          double lengthCostumArea = (cp.max - cp.min + 1) * customLength;

          if (distance <= lengthEvaluated + lengthCostumArea) {
            return find(currentIndex, distance, lengthEvaluated, customLength);
          } else {
            lengthEvaluated += lengthCostumArea;
            currentIndex += cp.max - cp.min + 1;
          }
        } else {
          currentIndex = cp.max + 1;
        }
      }

      return find(currentIndex, distance, lengthEvaluated, defaultLength);
    }
  }

  int findIntersectionIndex(
      double distance,
      List<PropertiesRange> specificLength,
      int maximumCells,
      double defaultLength,
      {double kSlope = 18.0}) {
    int findIndexWitinRadial(int currentIndex, double distance,
        double lengthEvaluated, double length) {
      if ((distance - lengthEvaluated + kSlope / 2.0) % length <= kSlope) {
        return currentIndex +
            (distance - lengthEvaluated + kSlope / 2.0) ~/ length;
      } else {
        return -1;
      }
    }

    if (specificLength.isEmpty) {
      return findIndexWitinRadial(0, distance, 0.0, defaultLength);
    } else {
      double lengthEvaluated = 0;
      int currentIndex = 0;

      for (PropertiesRange cp in specificLength) {
        if (currentIndex < cp.min) {
          double lengthDefaultArea = (cp.min - currentIndex) * defaultLength;

          if (distance <= lengthEvaluated + lengthDefaultArea + kSlope / 2.0) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, defaultLength);
          } else {
            lengthEvaluated += lengthDefaultArea;
            currentIndex = cp.min;
          }
        }

        if (!(cp.hidden || cp.collapsed)) {
          double customLength = cp.length ?? defaultLength;
          double lengthCostumArea = (cp.max - cp.min + 1) * customLength;

          if (distance <= lengthEvaluated + lengthCostumArea + kSlope / 2.0) {
            return findIndexWitinRadial(
                currentIndex, distance, lengthEvaluated, customLength);
          } else {
            lengthEvaluated += lengthCostumArea;
            currentIndex += cp.max - cp.min + 1;
          }
        } else {
          currentIndex = cp.max + 1;
        }
      }

      return findIndexWitinRadial(
          currentIndex, distance, lengthEvaluated, defaultLength);
    }
  }

  @override
  bool containsPositionX(int scrollIndexX, double position) =>
      widthLayoutList[scrollIndexX + 1].panelContains(position);

  @override
  bool containsPositionY(int scrollIndexY, double position) =>
      heightLayoutList[scrollIndexY + 1].panelContains(position);

  @override
  double maxScrollExtentX(int scrollIndexX) =>
      getMaxScrollScaledX(scrollIndexX);

  @override
  double maxScrollExtentY(int scrollIndexY) =>
      getMaxScrollScaledY(scrollIndexY);

  @override
  double minScrollExtentX(int scrollIndexX) =>
      getMinScrollScaledX(scrollIndexX);

  @override
  double minScrollExtentY(int scrollIndexY) =>
      getMinScrollScaledY(scrollIndexY);

  @override
  bool outOfRangeX(int scrollIndexX, int scrollIndexY) {
    final pixelsX = scrollPixelsX(scrollIndexX, scrollIndexY);

    return pixelsX < minScrollExtentX(scrollIndexX) ||
        pixelsX > maxScrollExtentX(scrollIndexX);
  }

  @override
  bool outOfRangeY(int scrollIndexX, int scrollIndexY) {
    final pixelsY = scrollPixelsY(scrollIndexX, scrollIndexY);

    return pixelsY < minScrollExtentY(scrollIndexY) ||
        pixelsY > maxScrollExtentY(scrollIndexY);
  }

  @override
  double scrollPixelsX(int scrollIndexX, int scrollIndexY) =>
      getScrollScaledX(scrollIndexX, scrollIndexY, scrollActivity: true);

  @override
  double scrollPixelsY(int scrollIndexX, int scrollIndexY) =>
      getScrollScaledY(scrollIndexX, scrollIndexY, scrollActivity: true);

  @override
  List<GridLayout> get tableLayoutX => widthLayoutList;

  @override
  List<GridLayout> get tableLayoutY => heightLayoutList;

  @override
  double viewportDimensionX(int scrollIndexX) {
    if (autoFreezePossibleX) {
      return widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;
    }
    switch (stateSplitX) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        return widthLayoutList[1].panelLength;
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        return widthLayoutList[1].panelLength + widthLayoutList[2].panelLength;
      case SplitState.SPLIT:
        return widthLayoutList[scrollIndexX + 1].panelLength;
    }
  }

  @override
  double viewportDimensionY(int scrollIndexY) {
    if (autoFreezePossibleY) {
      return heightLayoutList[1].panelLength + heightLayoutList[2].panelLength;
    }

    switch (stateSplitY) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        return heightLayoutList[1].panelLength;
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        return heightLayoutList[1].panelLength +
            heightLayoutList[2].panelLength;
      case SplitState.SPLIT:
        return heightLayoutList[scrollIndexY + 1].panelLength;
    }
  }

  @override
  double viewportPositionX(int scrollIndexX) =>
      widthLayoutList[stateSplitX != SplitState.SPLIT ? 1 : scrollIndexX + 1]
          .panelPosition;

  @override
  double viewportPositionY(int scrollIndexY) =>
      heightLayoutList[stateSplitY != SplitState.SPLIT ? 1 : scrollIndexY + 1]
          .panelPosition;

  @override
  double trackDimensionX(int scrollIndexX) {
    if (autoFreezePossibleX) {
      return widthLayoutList[2].gridEndPosition -
          widthLayoutList[1].gridPosition;
    }
    switch (stateSplitX) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        return widthLayoutList[1].gridLength;
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        return widthLayoutList[2].gridEndPosition -
            widthLayoutList[1].gridPosition;
      case SplitState.SPLIT:
        final l = widthLayoutList[scrollIndexX + 1];
        return (scrollIndexX == 0)
            ? l.panelEndPosition - l.gridPosition
            : l.gridEndPosition - l.panelPosition;
    }
  }

  @override
  double trackDimensionY(int scrollIndexY) {
    if (autoFreezePossibleY) {
      return heightLayoutList[2].gridEndPosition -
          heightLayoutList[1].gridPosition;
    }
    switch (stateSplitY) {
      case SplitState.CANCELED_FREEZE_SPLIT:
      case SplitState.CANCELED_SPLIT:
      case SplitState.NO_SPLITE:
        return heightLayoutList[1].gridLength;
      case SplitState.AUTO_FREEZE_SPLIT:
      case SplitState.FREEZE_SPLIT:
        return heightLayoutList[2].gridEndPosition -
            heightLayoutList[1].gridPosition;
      case SplitState.SPLIT:
        final l = heightLayoutList[scrollIndexY + 1];
        return (scrollIndexY == 0)
            ? l.panelEndPosition - l.gridPosition
            : l.gridEndPosition - l.panelPosition;
    }
  }

  @override
  double trackPositionX(int scrollIndexX) {
    switch (stateSplitX) {
      case SplitState.SPLIT:
        return (scrollIndexX == 0)
            ? widthLayoutList[1].gridPosition
            : widthLayoutList[2].panelPosition;
      default:
        {
          return widthLayoutList[1].gridPosition;
        }
    }
  }

  @override
  double trackPositionY(int scrollIndexY) {
    switch (stateSplitY) {
      case SplitState.SPLIT:
        return (scrollIndexY == 0)
            ? heightLayoutList[1].gridPosition
            : heightLayoutList[2].panelPosition;
      default:
        {
          return heightLayoutList[1].gridPosition;
        }
    }
  }
}

class SelectionIndex {
  int indexStart, indexLast;
  //int index = -1;

  SelectionIndex({required this.indexStart, required this.indexLast});

  SelectionIndex setIndex(int indexStart, int indexLast) {
    this.indexStart = indexStart;
    this.indexLast = indexLast;
    return this;
  }

  int sum() {
    return indexStart + indexLast;
  }

  int compareTo(SelectionIndex si) {
    return (this.indexStart + this.indexLast) - (si.indexStart + si.indexLast);
  }

  SelectionIndex copy() {
    return SelectionIndex(
        indexStart: this.indexStart, indexLast: this.indexLast);
  }

  bool hiddenBand() {
    return indexStart != indexLast;
  }

  String toString() {
    return 'start_screen $indexStart $indexLast';
  }
}

class GridLayout {
  int index;
  double gridLength;
  double gridPosition;
  double marginBegin;
  double marginEnd;
  double layoutGridLength;

  GridLayout(
      {this.index = -1,
      this.gridLength = 0.0,
      this.gridPosition = 0.0,
      this.marginBegin: 0.0,
      this.marginEnd: 0.0,
      double? preferredGridLength})
      : layoutGridLength = preferredGridLength ?? gridLength;

  void setGridLayout(
      {required int index,
      double gridLength = 0.0,
      double gridPosition = 0.0,
      double marginBegin: 0.0,
      double marginEnd: 0.0,
      double? preferredGridLength}) {
    this.index = index;
    this.gridLength = gridLength;
    this.layoutGridLength = preferredGridLength ?? gridLength;
    this.gridPosition = gridPosition;
    this.marginBegin = marginBegin;
    this.marginEnd = marginEnd;
  }

  void empty() {
    index = -1;
    gridLength = 0.0;
    gridPosition = 0.0;
    marginBegin = 0.0;
    marginEnd = 0.0;
    layoutGridLength = 0.0;
  }

  bool validate() {
    return gridLength >= 1.0 &&
        gridPosition >= 0.0 &&
        gridEndPosition >= 0.0 &&
        panelLength >= 0.0 &&
        (panelPosition >= 0.0) &&
        panelEndPosition >= 0.0;
  }

  double get panelLength => gridLength - marginBegin - marginEnd;
  double get panelPosition => gridPosition + marginBegin;
  double get panelEndPosition => gridPosition + gridLength - marginEnd;
  double get gridEndPosition => gridPosition + gridLength;
  bool get inUse => panelLength >= 1.0;

  double get layoutLength => layoutGridLength - marginBegin - marginEnd;
  double get layoutPosition =>
      index < 2 ? marginBegin + panelLength - layoutGridLength : marginBegin;

  panelContains(double position) =>
      panelPosition <= position && position <= panelEndPosition;

  @override
  String toString() {
    return 'GridLayout(gridLength: $gridLength, gridPosition: $gridPosition, marginBegin: $marginBegin, marginEnd: $marginEnd)';
  }
}

class PropertiesRange {
  bool collapsed = false;
  bool hidden = false;
  double? length;

  int min;
  int max;

  setRange(int min, int max) {
    this.min = min;
    this.max = max;
    assert(min <= max,
        'The max in the propertiesRange can not be smaller than min');
  }

  int compareRange(PropertiesRange another) {
    if (min == another.min && max == another.max) {
      return 0;
    } else {
      return max - another.min;
    }
  }

  bool contains(int index) {
    return index >= min && index <= max;
  }

  PropertiesRange(
      {this.length,
      required this.min,
      int? max,
      this.collapsed = false,
      this.hidden = false})
      : assert(min <= (max ?? min),
            'The max in the propertiesRange can not be smaller than min'),
        this.max = max ?? min;
}

class GridInfo {
  int index;
  double position;
  double length;
  bool visible;
  int listIndex;

  GridInfo({
    required this.index,
    required this.position,
    required this.length,
    this.visible = true,
    this.listIndex = -1,
  });

  bool outside(double value) {
    return value < position || value > position + length;
  }

  double get endPosition => position + length;

  @override
  String toString() {
    return 'GridInfo(index: $index, position: $position, length: $length, visible: $visible)';
  }
}

class FreezeChange {
  final FreezeAction action;
  final Offset position;
  final int row;
  final int column;

  FreezeChange(
      {this.action: FreezeAction.NOACTION,
      this.position: Offset.zero,
      this.row: -1,
      this.column: -1});

  @override
  String toString() {
    return 'FreezeChange(action: $action, position: $position, row: $row, column: $column)';
  }
}

class HeaderProperty {
  final int index;
  final int digits;
  final double startPosition;
  final double endPosition;

  HeaderProperty({
    required this.index,
    required this.digits,
    required this.startPosition,
    required this.endPosition,
  });

  const HeaderProperty.empty({
    this.index = -1,
    this.digits = 0,
    this.startPosition = -1,
    this.endPosition = -1,
  });

  //index != -1 is empty
  contains(double position) =>
      index != -1 && startPosition <= position && position < endPosition;

  @override
  String toString() {
    return 'HeaderWidthItem(index: $index, digits: $digits, startPosition: $startPosition, endPosition: $endPosition)';
  }
}

const noHeader = HeaderProperty.empty();

typedef _GetPosition = double Function(int index);

class AutoFreezeArea {
  int startIndex;
  int freezeIndex;
  int endIndex;
  double? customSplitSize;

  double startPosition = 0.0;
  double freezePosition = 0.0;
  double endPosition = 0.0;

  AutoFreezeArea({
    required this.startIndex,
    required this.freezeIndex,
    required this.endIndex,
    this.customSplitSize,
  });

  double spaceSplit(double spaceSplitFreeze) {
    return customSplitSize ?? spaceSplitFreeze;
  }

  double get header => freezePosition - startPosition;

  double get d => endPosition - freezePosition + startPosition;

  AutoFreezeArea.noArea(
      {this.startIndex: -1, this.freezeIndex: -1, this.endIndex: -1});

  bool get freeze => freezeIndex > 0;

  constains(position) => startPosition < position && position < endPosition;

  setPosition(_GetPosition position) {
    startPosition = position(startIndex);
    freezePosition = position(freezeIndex);
    endPosition = position(endIndex);
  }
}

// class PanelExchanger {
//   late List<TablePanelLayoutIndex> _layoutIndex;
//   late List<int> _panelIndex;

//   //  int r = index % 4;
//   //     int c = index ~/ 4;
//   //     int newIndex = c * 4 + r;

//   PanelExchanger() {
//     _layoutIndex = List.generate(16, (int index) {
//       int r = index % 4;
//       int c = index ~/ 4;
//       return TablePanelLayoutIndex(xIndex: c, yIndex: r);
//     });

//     _panelIndex = List.generate(16, (index) => index);
//   }

//   TablePanelLayoutIndex layoutIndex(int panelIndex) {
//     return _layoutIndex[panelIndex];
//   }

//   int panelIndex({required int indexY, required int column}) {
//     return _panelIndex[column * 4 + indexY];
//   }

//   switchX() {
//     for (int r = 0; r < 4; r++) {
//       int firstIndex = 1 * 4 + r;
//       int secondIndex = 2 * 4 + r;

//       exchange(_panelIndex, firstIndex, secondIndex);
//       exchange(_layoutIndex, firstIndex, secondIndex);
//     }
//   }

//   switchY() {
//     for (int c = 0; c < 4; c++) {
//       int firstIndex = c * 4 + 1;
//       int secondIndex = c * 4 + 2;

//       exchange(_panelIndex, firstIndex, secondIndex);
//       exchange(_layoutIndex, firstIndex, secondIndex);
//     }
//   }

//   exchange(List list, firstIndex, secondIndex) {
//     final temp = list[firstIndex];
//     list[firstIndex] = list[secondIndex];
//     list[secondIndex] = temp;
//   }
// }
