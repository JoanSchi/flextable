// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class FtRange {
  int start;
  int last;

  FtRange({
    required this.start,
    int? last,
  })  : assert(start <= (last ?? start),
            'The last in the propertiesRange can not be smaller than start'),
        last = last ?? start;

  setRange(int start, int last) {
    this.start = start;
    this.last = last;
    assert(start <= last,
        'The last in the propertiesRange can not be smaller than start');
  }

  int get length => last - start + 1;

  int compareRange(RangeProperties another) {
    if (start == another.start && last == another.last) {
      return 0;
    } else {
      return last - another.start;
    }
  }

  bool contains(int index) {
    return index >= start && index <= last;
  }
}

class RangeProperties extends FtRange {
  RangeProperties(
      {required super.start,
      super.last,
      this.size,
      this.collapsed = false,
      this.hidden = false});

  bool collapsed = false;
  bool hidden = false;
  double? size;
}

class ChangeRange extends FtRange {
  ChangeRange({
    required super.start,
    super.last,
    required this.insert,
  });

  bool insert;
}
