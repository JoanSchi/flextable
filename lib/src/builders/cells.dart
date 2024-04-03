// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../panels/panel_viewport.dart';
import '../templates/cells/cell_styles.dart';

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

class Cell<T, I, S extends CellStyle> extends AbstractCell<I> {
  Cell({
    this.value,
    this.style,
    super.merged,
    this.groupState,
    super.identifier,
    this.noBlank = false,
    this.validate = '',
    Set<FtIndex>? ref,
  }) : ref = ref ?? {};

  final S? style;
  T? value;
  final FtCellGroupState? groupState;
  FtCellState get cellState => groupState?.state ?? FtCellState.ready;
  final bool noBlank;
  String validate;
  final Set<FtIndex> ref;

  bool get editable => false;

  @override
  Cell<T, I, S> copyWith(
      {S? style,
      T? value,
      Merged? merged,
      FtCellGroupState? groupState,
      I? identifier,
      bool? noBlank,
      String? validate,
      Set<FtIndex>? ref}) {
    return Cell(
        groupState: groupState ?? this.groupState,
        style: style ?? this.style,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        identifier: identifier ?? this.identifier,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Cell<T, I, S> &&
        super == other &&
        other.value == value &&
        other.identifier == identifier &&
        other.style == style &&
        other.merged == merged &&
        // other.groupState == groupState &&
        other.noBlank == noBlank;
  }

  @override
  int get hashCode =>
      super.hashCode ^
      value.hashCode ^
      identifier.hashCode ^
      style.hashCode ^
      merged.hashCode ^
      // groupState.hashCode ^
      noBlank.hashCode;
}

abstract class AbstractCell<I> {
  const AbstractCell({this.merged, this.identifier});
  final I? identifier;
  final Merged? merged;

  AbstractCell copyWith({Merged? merged});
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AbstractCell<I> &&
        other.identifier == identifier &&
        other.merged == merged;
  }

  @override
  int get hashCode => identifier.hashCode ^ merged.hashCode;
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
