// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class RangeProperties {
  RangeProperties(
      {this.length,
      required this.min,
      int? max,
      this.collapsed = false,
      this.hidden = false})
      : assert(min <= (max ?? min),
            'The max in the propertiesRange can not be smaller than min'),
        max = max ?? min;

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

  int compareRange(RangeProperties another) {
    if (min == another.min && max == another.max) {
      return 0;
    } else {
      return max - another.min;
    }
  }

  bool contains(int index) {
    return index >= min && index <= max;
  }
}
