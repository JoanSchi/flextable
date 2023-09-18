// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

mixin Index {
  int get index;

  // operator <(object) => index < (object is int ? object : object.index);

  // operator <=(object) => index <= (object is int ? object : object.index);

  // operator >(object) => index > (object is int ? object : object.index);

  // operator >=(object) => index >= (object is int ? object : object.index);

  // @override
  // bool operator ==(Object object) => object is Index && index == object.index;

  // @override
  // int get hashCode => index.hashCode;

  @override
  String toString() => '$index';
}

abstract class GridRibbon with Index {
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

class Cell {
  Cell({this.value = '', Map? attr}) : attr = attr ?? {};

  late double left, top, width, height;
  double scaleAndZoom = 1.0;

  Map attr;
  Merged? merged;

  Object value;

  double get leftScaled => left * scaleAndZoom;

  double get topScaled => top * scaleAndZoom;

  double get widthScaled => width * scaleAndZoom;

  double get heightScaled => height * scaleAndZoom;
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
