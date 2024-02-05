import 'dart:math';

class ObservedEnergyRespitory {
  static Future<List<ObservedEnergy>> fetch(
      {required DateTime startDate, required DateTime endDate}) async {
    DateTime dateTest = startDate;

    List<ObservedEnergy> list = [];
    final random = Random();

    while (dateTest.compareTo(endDate) <= 0) {
      list.add(ObservedEnergy(
        tableName: '',
        measurementDate: dateTest,
        kwh: random.nextDouble() * 8.0 + 10.0,
        gasM3: random.nextDouble() * 4.0 + 8.0,
      ));

      dateTest = dateTest.add(const Duration(days: 1));
    }
    await Future.delayed(const Duration(milliseconds: 50));
    return list;
  }
}

class ObservedEnergy {
  String tableName;
  DateTime measurementDate;
  double? kwh;
  double? gasM3;

  ObservedEnergy({
    required this.tableName,
    required this.measurementDate,
    this.kwh,
    this.gasM3,
  });
}
