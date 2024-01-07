import 'package:flutter/foundation.dart';

// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class Cell extends AbstractCell {
  Cell({this.value = '', this.attr = const {}, this.repaintBoundaries = false});

  final Map attr;
  final Object value;
  final bool repaintBoundaries;

  Cell copyWith({
    Map? attr,
    Object? value,
    bool? repaintBoundaries,
  }) {
    return Cell(
      attr: attr ?? this.attr,
      value: value ?? this.value,
      repaintBoundaries: repaintBoundaries ?? this.repaintBoundaries,
    );
  }
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

  final int startRow;
  final int lastRow;
  final int startColumn;
  final int lastColumn;

  bool containCell(int row, int column) {
    return (row >= startRow &&
        row <= lastRow &&
        column >= startColumn &&
        column <= lastColumn);
  }

  columnsMerged() => startColumn < lastColumn;

  rowsMerged() => startRow < lastRow;

  int get columns => lastColumn - startColumn + 1;

  int get rows => lastRow - startRow + 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Merged &&
        other.startRow == startRow &&
        other.lastRow == lastRow &&
        other.startColumn == startColumn &&
        other.lastColumn == lastColumn;
  }

  @override
  int get hashCode {
    return startRow.hashCode ^
        lastRow.hashCode ^
        startColumn.hashCode ^
        lastColumn.hashCode;
  }

  @override
  String toString() {
    return 'Merged(startRow: $startRow, lastRow: $lastRow, startColumn: $startColumn, lastColumn: $lastColumn)';
  }
}
