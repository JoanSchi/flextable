// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class HeaderProperties {
  HeaderProperties({
    required this.index,
    required this.digits,
    required this.startPosition,
    required this.endPosition,
  });

  final int index;
  final int digits;
  final double startPosition;
  final double endPosition;

  const HeaderProperties.empty({
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

const noHeader = HeaderProperties.empty();
