// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../panels/panel_viewport.dart';

enum FtCellState {
  ready,
  inQuee,
  removeFromQueueCandidate,
  removedFromQuee,
  empty,
  error,
  none
}

class FtCellGroupState {
  FtCellState state;

  FtCellGroupState(
    this.state,
  );
}

class Cell<T, I> extends AbstractCell {
  const Cell({
    this.value,
    this.attr = const {},
    super.merged,
    this.groupState,
    this.identifier,
  });

  final Map attr;
  final T? value;
  final FtCellGroupState? groupState;
  final I? identifier;

  FtCellState get cellState => groupState?.state ?? FtCellState.ready;

  bool get isEditable => false;

  @override
  Cell copyWith(
      {Map? attr,
      T? value,
      Merged? merged,
      FtCellGroupState? groupState,
      I? identifier}) {
    return Cell(
        groupState: groupState ?? this.groupState,
        attr: attr ?? this.attr,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        identifier: identifier ?? this.identifier);
  }
}

abstract class AbstractCell {
  const AbstractCell({this.merged});

  final Merged? merged;

  AbstractCell copyWith({Merged? merged});
}

class Merged {
  Merged({required FtIndex ftIndex, required int rows, required int columns})
      : startRow = ftIndex.row,
        lastRow = ftIndex.row + rows - 1,
        startColumn = ftIndex.column,
        lastColumn = ftIndex.column + columns - 1;

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
