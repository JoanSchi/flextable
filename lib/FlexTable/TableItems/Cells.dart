import '../FlexTableConstants.dart';

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
    if (mergedList.length == 0) {
      return null;
    }

    final contains = (find, merged) => find >= firstIndex(merged) && find <= lastIndex(merged) ? merged : null;

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

  CellStatus status = CellStatus.UpToDate;
  Map attr;
  Merged? merged;

  var value;

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

  Merged({required this.startRow, required this.lastRow, required this.startColumn, required this.lastColumn});

  bool containCell(int row, int column) {
    return (row >= startRow.index && row <= lastRow.index && column >= startColumn.index && column <= lastColumn.index);
  }

  columnsMerged() => startColumn < lastColumn;

  rowsMerged() => startRow < lastRow;

  @override
  String toString() {
    return 'Merged(startRow: ${startRow.index}, lastRow: ${lastRow.index}, startColumn: ${startColumn.index}, lastColumn: ${lastColumn.index})';
  }
}
