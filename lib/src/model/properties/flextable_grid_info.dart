// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class GridInfo {
  GridInfo({
    required this.index,
    required this.position,
    required this.length,
    this.visible = true,
    this.listIndex = -1,
  });

  int index;
  double position;
  double length;
  bool visible;
  int listIndex;

  bool outside(double value) {
    return value < position || value > position + length;
  }

  double get endPosition => position + length;

  @override
  String toString() {
    return 'GridInfo(index: $index, position: $position, length: $length, visible: $visible)';
  }
}
