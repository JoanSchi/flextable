import 'package:flextable/flextable.dart';

class TextCell extends Cell<String> {
  const TextCell({
    super.attr = const {},
    super.value,
    super.merged,
  });

  @override
  get cellState => FtCellState.ready;
  @override
  TextCell copyWith(
      {Map? attr,
      String? value,
      String? tableName,
      String? itemName,
      DateTime? date,
      FtCellGroupState? groupState,
      Merged? merged}) {
    return TextCell(
      attr: attr ?? this.attr,
      value: value ?? this.value,
      merged: merged ?? this.merged,
    );
  }
}

class TextInputCell extends AsyncCell<String> {
  const TextInputCell(
      {super.attr = const {},
      super.value,
      super.merged,
      required this.tableName,
      required this.itemName,
      required this.date,
      required super.groupState});

  final String tableName;
  final String itemName;
  final DateTime date;

  @override
  get cellState => groupState.state;

  @override
  bool get isEditable => true;

  @override
  TextInputCell copyWith(
      {Map? attr,
      bool valueCanBeNull = false,
      String? value,
      String? tableName,
      String? itemName,
      DateTime? date,
      FtCellGroupState? groupState,
      Merged? merged}) {
    return TextInputCell(
      attr: attr ?? this.attr,
      value: valueCanBeNull ? value : (value ?? this.value),
      tableName: tableName ?? this.tableName,
      itemName: itemName ?? this.itemName,
      date: date ?? this.date,
      groupState: groupState ?? this.groupState,
      merged: merged ?? this.merged,
    );
  }
}

class DigitInputCell extends AsyncCell<int> {
  const DigitInputCell(
      {super.attr = const {},
      super.value,
      this.min,
      this.max,
      super.merged,
      required this.tableName,
      required this.itemName,
      required this.date,
      required super.groupState});

  final String tableName;
  final String itemName;
  final DateTime date;
  final int? min;
  final int? max;

  @override
  get cellState => groupState.state;

  @override
  bool get isEditable => true;

  int? get exceeded {
    return switch ((min, max, value)) {
      (int min, _, int value) when value < min => value - min,
      (_, int max, int value) when max < value => value - max,
      (_, _, _) => null,
    };
  }

  @override
  DigitInputCell copyWith({
    Map? attr,
    bool valueCanBeNull = false,
    int? value,
    String? tableName,
    String? itemName,
    DateTime? date,
    FtCellGroupState? groupState,
    Merged? merged,
    int? min,
    int? max,
  }) {
    return DigitInputCell(
      attr: attr ?? this.attr,
      value: valueCanBeNull ? value : (value ?? this.value),
      tableName: tableName ?? this.tableName,
      itemName: itemName ?? this.itemName,
      date: date ?? this.date,
      groupState: groupState ?? this.groupState,
      merged: merged ?? this.merged,
      min: min ?? this.min,
      max: max ?? this.min,
    );
  }
}

class DecimalInputCell extends AsyncCell<double> {
  const DecimalInputCell(
      {super.attr = const {},
      super.value,
      this.min,
      this.max,
      super.merged,
      required this.tableName,
      required this.itemName,
      required this.date,
      required super.groupState,
      this.format = '#0.0#'});

  final String tableName;
  final String itemName;
  final DateTime date;
  final double? min;
  final double? max;
  final String format;

  double? get exceeded {
    return switch ((min, max, value)) {
      (double min, _, double value) when value < min => value - min,
      (_, double max, double value) when max < value => value - max,
      (_, _, _) => null,
    };
  }

  @override
  get cellState => groupState.state;

  @override
  bool get isEditable => true;

  @override
  DecimalInputCell copyWith(
      {Map? attr,
      bool valueCanBeNull = false,
      double? value,
      String? tableName,
      String? itemName,
      DateTime? date,
      FtCellGroupState? groupState,
      Merged? merged,
      double? min,
      double? max,
      String? format}) {
    return DecimalInputCell(
        attr: attr ?? this.attr,
        value: valueCanBeNull ? value : (value ?? this.value),
        tableName: tableName ?? this.tableName,
        itemName: itemName ?? this.itemName,
        date: date ?? this.date,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        min: min ?? this.min,
        max: max ?? this.min,
        format: format ?? this.format);
  }
}
