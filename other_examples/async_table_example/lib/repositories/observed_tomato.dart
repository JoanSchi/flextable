import 'dart:math';

class ObservedTomatoRespitory {
  static Future<List<ObservedTomato>> fetch(
      {required DateTime startDate, required DateTime endDate}) async {
    DateTime dateTest = startDate;

    List<ObservedTomato> list = [];
    final random = Random();
    while (dateTest.compareTo(endDate) <= 0) {
      list.add(ObservedTomato(
        tableName: '',
        measurementDate: dateTest,
        middle: random.nextInt(100) + 500,
        large: random.nextInt(100) + 50,
        small: random.nextInt(80),
        deformed: random.nextInt(30),
        infected: random.nextInt(15),
      ));

      dateTest = dateTest.add(const Duration(days: 1));
    }
    await Future.delayed(const Duration(milliseconds: 50));
    return list;
  }
}

class ObservedTomato {
  String tableName;
  DateTime measurementDate;
  int? large;
  int? middle;
  int? small;
  int? deformed;
  int? infected;

  ObservedTomato(
      {required this.tableName,
      required this.measurementDate,
      this.large,
      this.middle,
      this.small,
      this.deformed,
      this.infected});
}
