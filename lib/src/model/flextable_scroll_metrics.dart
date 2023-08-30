// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../gesture_scroll/table_drag_details.dart';
import 'model.dart';
import 'properties/flextable_grid_layout.dart';
import 'view_model.dart';

abstract class TableScrollMetrics {
  List<GridLayout> get tableLayoutX;

  List<GridLayout> get tableLayoutY;

  DrawScrollBar drawVerticalScrollBar(int scrollIndexX, int scrollIndexY);

  DrawScrollBar drawHorizontalScrollBar(int scrollIndexX, int scrollIndexY);

  DrawScrollBar drawVerticalScrollBarTrack(int scrollIndexX, int scrollIndexY);

  DrawScrollBar drawHorizontalScrollBarTrack(
      int scrollIndexX, int scrollIndexY);

  double scrollPixelsX(int scrollIndexX, int scrollIndexY);

  double scrollPixelsY(int scrollIndexX, int scrollIndexY);

  double maxScrollExtentX(int scrollIndexX);

  double minScrollExtentX(int scrollIndexX);

  double maxScrollExtentY(int scrollIndexY);

  double minScrollExtentY(int scrollIndexY);

  double viewportDimensionX(int scrollIndexX);

  double viewportDimensionY(int scrollIndexY);

  double viewportPositionX(int scrollIndexX);

  double viewportPositionY(int scrollIndexY);

  bool containsPositionX(int scrollIndexX, double position);

  bool containsPositionY(int scrollIndexY, double position);

  bool outOfRangeX(int scrollIndexX, int scrollIndexY);

  bool outOfRangeY(int scrollIndexX, int scrollIndexY);

  double trackDimensionX(int scrollIndexX);

  double trackDimensionY(int scrollIndexY);

  double trackPositionX(int scrollIndexX);

  double trackPositionY(int scrollIndexY);

  bool atEdgeX(int scrollIndexX, int scrollIndexY) {
    final pixelsX = scrollPixelsX(scrollIndexX, scrollIndexY);

    return pixelsX == minScrollExtentX(scrollIndexX) ||
        pixelsX == maxScrollExtentX(scrollIndexX);
  }

  bool atEdgeY(int scrollIndexX, int scrollIndexY) {
    final pixelsY = scrollPixelsY(scrollIndexX, scrollIndexY);

    return pixelsY == minScrollExtentY(scrollIndexY) ||
        pixelsY == maxScrollExtentY(scrollIndexY);
  }

  TableScrollDirection get tableScrollDirection;

  SplitState get stateSplitX;

  SplitState get stateSplitY;

  bool get autoFreezePossibleX;

  bool get autoFreezePossibleY;

  bool get noSplitX;

  bool get noSplitY;

  // /// The quantity of content conceptually "above" the viewport in the scrollable.
  // /// This is the content above the content described by [extentInside].
  // double get extentBeforeY => math.max(pixelsY - minScrollExtentY, 0.0);

  // /// The quantity of content conceptually "inside" the viewport in the scrollable.
  // ///
  // /// The value is typically the height of the viewport when [outOfRangeY] is false.
  // /// It could be less if there is less content visible than the size of the
  // /// viewport, such as when overscrolling.
  // ///
  // /// The value is always non-negative, and less than or equal to [viewportDimensionY].
  // double get extentInsideY {
  //   assert(minScrollExtentY <= maxScrollExtentY);
  //   return viewportDimensionY
  //       // "above" overscroll value
  //       -
  //       (minScrollExtentY - pixelsY).clamp(0, viewportDimensionY)
  //       // "below" overscroll value
  //       -
  //       (pixelsY - maxScrollExtentY).clamp(0, viewportDimensionY);
  // }

  // /// The quantity of content conceptually "below" the viewport in the scrollable.
  // /// This is the content below the content described by [extentInside].
  // double get extentAfter => math.max(maxScrollExtentY - pixelsY, 0.0);
}
