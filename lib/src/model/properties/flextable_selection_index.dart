// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class SelectionIndex {
  SelectionIndex({required this.indexStart, required this.indexLast});

  int indexStart;
  int indexLast;

  SelectionIndex setIndex(int indexStart, int indexLast) {
    this.indexStart = indexStart;
    this.indexLast = indexLast;
    return this;
  }

  int sum() {
    return indexStart + indexLast;
  }

  int compareTo(SelectionIndex si) {
    return (indexStart + indexLast) - (si.indexStart + si.indexLast);
  }

  SelectionIndex copy() {
    return SelectionIndex(indexStart: indexStart, indexLast: indexLast);
  }

  bool hiddenBand() {
    return indexStart != indexLast;
  }

  @override
  String toString() {
    return 'start_screen $indexStart $indexLast';
  }
}
