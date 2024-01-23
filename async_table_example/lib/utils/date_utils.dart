class TableDateUtils {
  static DateTime onlyUtcDate(DateTime date) {
    date = date.toUtc();
    return DateTime.utc(date.year, date.month, date.day);
  }

  static DateTime onlyUtcDateNow() => onlyUtcDate(DateTime.now());
}
