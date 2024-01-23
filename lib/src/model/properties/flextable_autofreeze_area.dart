// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

typedef AutoFreezeGetPosition = double Function(int index);

class AutoFreezeArea {
  AutoFreezeArea({
    required this.startIndex,
    required this.freezeIndex,
    required this.endIndex,
    this.customSplitSize,
  });

  int startIndex;
  int freezeIndex;
  int endIndex;
  double? customSplitSize;

  double startPosition = 0.0;
  double freezePosition = 0.0;
  double endPosition = 0.0;

  double spaceSplit(double spaceSplitFreeze) {
    return customSplitSize ?? spaceSplitFreeze;
  }

  double get header => freezePosition - startPosition;

  double get d => endPosition - freezePosition + startPosition;

  AutoFreezeArea.noArea(
      {this.startIndex = -1, this.freezeIndex = -1, this.endIndex = -1});

  bool get freeze => freezeIndex > 0;

  constains(position) => startPosition < position && position < endPosition;

  bool indexInBody(int index) => freezeIndex <= index && index < endIndex;

  setPosition(AutoFreezeGetPosition position) {
    startPosition = position(startIndex);
    freezePosition = position(freezeIndex);
    endPosition = position(endIndex);
  }
}
