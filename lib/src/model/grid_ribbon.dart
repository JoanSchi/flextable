// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../builders/cells.dart';

class RowRibbon<C extends AbstractCell> extends GridRibbon {
  // Add indentifier if you like;
  List<C?> columnList;

  RowRibbon() : columnList = <C?>[];
}

class ColumnRibbon extends GridRibbon {
  // Add indentifier if you like;
  ColumnRibbon();
}

abstract class GridRibbon {
  int mergedIndex = 0;
  int findIndex = 0;
  List<Merged> mergedList = [];

  findMerged(
      {required int find,
      required int Function(Merged merged) firstIndex,
      required int Function(Merged merged) lastIndex}) {
    if (mergedList.isEmpty) {
      return null;
    }

    Merged? contains(int find, Merged merged) =>
        find >= firstIndex(merged) && find <= lastIndex(merged) ? merged : null;

    final length = mergedList.length;

    if (findIndex == find) {
      Merged m = mergedList[mergedIndex];
      return contains(find, m);
    } else if (findIndex < find) {
      while (mergedIndex < length) {
        Merged m = mergedList[mergedIndex];

        if (lastIndex(m) < find && mergedIndex < length - 1) {
          mergedIndex++;
        } else {
          findIndex = find;
          return contains(find, m);
        }
      }
    } else {
      while (mergedIndex >= 0) {
        Merged m = mergedList[mergedIndex];

        if (find < firstIndex(m) && mergedIndex > 0) {
          mergedIndex--;
        } else {
          findIndex = find;
          return contains(find, m);
        }
      }
    }
  }
}
