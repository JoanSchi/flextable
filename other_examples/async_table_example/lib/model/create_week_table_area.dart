import 'package:flextable/flextable.dart';

abstract class CreateWeekTableArea
    extends CreateTableArea<AsyncAreaModel, Cell> {
  DateTime firstDate;
  DateTime startWeekDate;
  DateTime endWeekDate;
  int headerRows;
  int startRow;
  int startColumn;
  int weekDays;
  int columns;
  String tableName;

  CreateWeekTableArea({
    required super.model,
    required this.headerRows,
    required super.tableController,
    required super.cellGroupState,
    required this.firstDate,
    required this.startWeekDate,
    required this.endWeekDate,
    required this.startRow,
    required this.startColumn,
    required this.columns,
    required this.tableName,
  }) : weekDays = endWeekDate.difference(startWeekDate).inDays + 1;

  @override
  layout();

  @override
  fetch();

  @override
  load();

  int get rowCurrentDay {
    DateTime now = DateTime.now();

    int deltaDays = DateTime.utc(now.year, now.month, now.day)
        .difference(startWeekDate)
        .inDays;
    return (deltaDays >= 0 && deltaDays < weekDays)
        ? startRow + headerRows + deltaDays
        : -1;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CreateWeekTableArea &&
        other.tableName == tableName &&
        other.startWeekDate == startWeekDate;
  }

  @override
  int get hashCode => tableName.hashCode ^ startWeekDate.hashCode;

  @override
  String toString() =>
      'CreateTableArea(tableName: $tableName, startWeekDate: $startWeekDate)';
}
