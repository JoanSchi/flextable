// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../builders/cells.dart';

class RowRibbon<C extends AbstractCell> extends GridRibbon {
  // Add indentifier if you like;
  List<C?> columnList;

  RowRibbon()
      : columnList = <C?>[],
        super(
            firstIndex: (Merged merged) => merged.startColumn,
            lastIndex: (Merged merged) => merged.lastColumn);
}

class ColumnRibbon extends GridRibbon {
  // Add indentifier if you like;
  ColumnRibbon()
      : super(
            firstIndex: (Merged merged) => merged.startRow,
            lastIndex: (Merged merged) => merged.lastRow);
}

abstract class GridRibbon {
  int listIndex = 0;
  int findIndex = -1;
  var mergedMap = SplayTreeMap<int, Merged>();
  Function(Merged merged) firstIndex;
  Function(Merged merged) lastIndex;

  GridRibbon({
    required this.firstIndex,
    required this.lastIndex,
  });

  Merged? findMerged({required int index, required bool startingOutside}) {
    switch (mergedMap.lastKeyBefore(index + (startingOutside ? 0 : 1))) {
      case int key:
        {
          Merged? m = mergedMap[key];
          return m != null && index <= lastIndex(m) ? m : null;
        }
      default:
        {
          return null;
        }
    }
  }

  addMerged(Merged merged) {
    mergedMap[firstIndex(merged)] = merged;

    /// Check for overlapping merge cells
    ///
    ///
    ///
    assert(() {
      bool first = true;
      late Merged previous;
      for (var MapEntry<int, Merged>(key: index, value: merged)
          in mergedMap.entries) {
        if (first) {
          first = false;
        } else {
          if (lastIndex(previous) >= firstIndex(merged)) {
            debugPrint(
                'Overlapping merge at index: $index. Previous: $previous, current: $merged');
            return false;
          }
        }
        previous = merged;
      }
      return true;
    }());
  }

  Merged? removeMerged({Merged? merged, int? index}) =>
      merged == null && index == null
          ? null
          : mergedMap.remove(index ?? firstIndex(merged!));
}
