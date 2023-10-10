// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class Cell extends AbstractCell {
  Cell(
      {this.value = '',
      Map? attr,
      // super.keepAlive = false,
      this.addRepaintBoundaries = false})
      : attr = attr ?? {};

  Map attr;
  Object value;
  bool addRepaintBoundaries;
}

abstract class AbstractCell {
  // AbstractCell({
  //   required this.keepAlive,
  // }) : assert(!keepAlive, 'KeepAlive not yet implemented.');

  // bool keepAlive;

  Merged? merged;
}

class Merged {
  Merged(
      {required this.startRow,
      required this.lastRow,
      required this.startColumn,
      required this.lastColumn});

  int startRow;
  int lastRow;
  int startColumn;
  int lastColumn;

  bool containCell(int row, int column) {
    return (row >= startRow &&
        row <= lastRow &&
        column >= startColumn &&
        column <= lastColumn);
  }

  columnsMerged() => startColumn < lastColumn;

  rowsMerged() => startRow < lastRow;

  @override
  String toString() {
    return 'Merged(startRow: $startRow, lastRow: $lastRow, startColumn: $startColumn, lastColumn: $lastColumn)';
  }
}
