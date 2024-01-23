import 'dart:math';

class ObservedClimateRespitory {
  static Future<List<ObservedClimate>> fetch(
      {required DateTime startDate, required DateTime endDate}) async {
    DateTime dateTest = startDate;

    List<ObservedClimate> list = [];
    final random = Random();

    while (dateTest.compareTo(endDate) <= 0) {
      list.add(ObservedClimate(
          tableName: '',
          measurementDate: dateTest,
          moistere: random.nextDouble() * 18.0 + 70,
          temperature: random.nextDouble() * 5.0 + 18,
          sunlight: random.nextDouble() * 3.0 + 5));

      dateTest = dateTest.add(const Duration(days: 1));
    }
    await Future.delayed(const Duration(milliseconds: 50));
    return list;
  }
}

class ObservedClimate {
  String tableName;
  DateTime measurementDate;
  double? moistere;
  double? temperature;
  double? sunlight;

  ObservedClimate({
    required this.tableName,
    required this.measurementDate,
    this.moistere,
    this.temperature,
    this.sunlight,
  });
}
