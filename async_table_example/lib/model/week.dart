import 'package:flextable/flextable.dart';

class WeekAreaInitializer<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends AreaInitializer {
  int firstRow;
  int firstColumn;
  DateTime firstDate;
  DateTime firstDayWeek;
  DateTime lastDayWeek;
  int week;
  int headerRows = 2;
  int headerColumns = 3;
  int dataColumns = -1;
  int day;
  int dataRows;

  WeekAreaInitializer({
    required this.firstRow,
    required this.firstColumn,
    required this.firstDate,
    required this.firstDayWeek,
    required this.lastDayWeek,
    required super.definedTableAreas,
    required super.tableController,
  })  : week = firstDayWeek.difference(firstDate).inDays ~/ 7 + 1,
        dataRows = lastDayWeek.difference(firstDayWeek).inDays,
        day = firstDayWeek.difference(firstDate).inDays,
        dataColumns = definedTableAreas.fold<int>(
            0, (previousValue, element) => previousValue + element.columns);

  Set<String> tableName = {};

  int get rows => headerRows + dataRows;

  int get lastRow => firstRow + headerRows + dataRows;

  int get columns => dataColumns;

  int get lastColumn => firstColumn + dataColumns;

  int get freezedRow => firstRow + headerRows;

  @override
  FtIndex get leftTopIndex => FtIndex(row: firstRow, column: firstColumn);

  @override
  FtIndex get rightBottomIndex => FtIndex(row: lastRow, column: lastColumn);

  int rowDate(DateTime date) {
    if (date.compareTo(firstDate) >= 0 && lastDayWeek.compareTo(date) >= 0) {
      return firstRow + headerRows + date.difference(firstDayWeek).inDays;
    }
    return -1;
  }

  @override
  bool cell(
      {required AsyncAreaModel model,
      required FtIndex ftIndex,
      FtCellGroupState? cellGroupState}) {
    int row = ftIndex.row;
    int column = ftIndex.column;

    int lastRow = firstRow + headerRows + dataRows;
    int lastColumn = firstColumn + headerColumns + dataColumns;

    if (row < firstRow ||
        row > lastRow ||
        column < firstColumn ||
        column > lastColumn) {
      return false;
    }

    switch (obtainAreaAtColumn(ftIndex.column)) {
      case (int firstColumn, DefinedTableArea a):
        {
          if (cellGroupState == null && initiated.contains(a.tableName)) {
            return false;
          }
          initiated.add(a.tableName);

          final tableArea = a.create(
              minimalHeaderRows: 2,
              cellGroupState: FtCellGroupState(FtCellState.none),
              model: model,
              startColumn: firstColumn,
              startRow: firstRow,
              tableController: tableController,
              firstDay: firstDate,
              startWeekDate: firstDayWeek,
              endWeekDate: lastDayWeek);

          if (tableArea != null) {
            tableArea.layout();
            if (tableArea.synchronize) {
              tableArea.load();
              model.placeInQuee(tableArea);
            }
          }

          return true;
        }
      default:
        {
          return false;
        }
    }
  }

  (int?, DefinedTableArea?) obtainAreaAtColumn(int column) {
    if (column < firstColumn) {
      return (-1, null);
    }
    int lastAreaColumn = firstColumn;

    for (DefinedTableArea area in definedTableAreas) {
      int firstAreaColumn = lastAreaColumn;
      lastAreaColumn += area.columns;

      if (firstAreaColumn <= column && column < lastAreaColumn) {
        return (firstAreaColumn, area);
      }
    }
    return (-1, null);
  }
}
