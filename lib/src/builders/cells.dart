// Copyright (C) 2023 Joan Schipper
// 
// This file is part of flextable.
// 
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

mixin Index {
  int get index;

  operator <(object) => index < (object is int ? object : object.index);

  operator <=(object) => index <= (object is int ? object : object.index);

  operator >(object) => index > (object is int ? object : object.index);

  operator >=(object) => index >= (object is int ? object : object.index);

  @override
  bool operator ==(Object object) => object is Index && index == object.index;

  @override
  int get hashCode => index.hashCode;

  @override
  String toString() => '$index';
}

abstract class GridRibbon with Index {
  int mergedIndex = 0;
  int findIndex = 0;
  List<Merged> mergedList = [];

  findMerged({required int find, firstIndex, lastIndex}) {
    if (mergedList.isEmpty) {
      return null;
    }

    Merged? contains(find, merged) =>
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
  late double left, top, width, height;
  late Index rowIndex;
  late Index columnIndex;
  double scaleAndZoom = 1.0;

  Map attr;
  Merged? merged;

  Object value;

  Cell({this.value = '', Map? attr}) : attr = attr ?? {};

  double get leftScaled => left * scaleAndZoom;

  double get topScaled => top * scaleAndZoom;

  double get widthScaled => width * scaleAndZoom;

  double get heightScaled => height * scaleAndZoom;
}

class Merged {
  Index startRow;
  Index lastRow;
  Index startColumn;
  Index lastColumn;

  Merged(
      {required this.startRow,
      required this.lastRow,
      required this.startColumn,
      required this.lastColumn});

  bool containCell(int row, int column) {
    return (row >= startRow.index &&
        row <= lastRow.index &&
        column >= startColumn.index &&
        column <= lastColumn.index);
  }

  columnsMerged() => startColumn < lastColumn;

  rowsMerged() => startRow < lastRow;

  @override
  String toString() {
    return 'Merged(startRow: ${startRow.index}, lastRow: ${lastRow.index}, startColumn: ${startColumn.index}, lastColumn: ${lastColumn.index})';
  }
}
