// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class GridLayout {
  GridLayout(
      {this.index = -1,
      this.gridLength = 0.0,
      this.gridPosition = 0.0,
      this.marginBegin = 0.0,
      this.marginEnd = 0.0,
      double? preferredGridLength})
      : layoutGridLength = preferredGridLength ?? gridLength;

  int index;
  double gridLength;
  double gridPosition;
  double marginBegin;
  double marginEnd;
  double layoutGridLength;

  void setGridLayout(
      {required int index,
      double gridLength = 0.0,
      double gridPosition = 0.0,
      double marginBegin = 0.0,
      double marginEnd = 0.0,
      double? preferredGridLength}) {
    this.index = index;
    this.gridLength = gridLength;
    layoutGridLength = preferredGridLength ?? gridLength;
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
