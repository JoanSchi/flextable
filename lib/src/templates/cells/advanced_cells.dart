// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../../../flextable.dart';

class TextCell<I> extends Cell<String, I> {
  const TextCell({
    super.attr = const {},
    super.value,
    super.merged,
    super.identifier,
  });

  @override
  get cellState => FtCellState.ready;
  @override
  TextCell copyWith(
      {Map? attr,
      String? value,
      I? identifier,
      FtCellGroupState? groupState,
      Merged? merged}) {
    return TextCell(
        attr: attr ?? this.attr,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        identifier: identifier ?? this.identifier);
  }
}

class TextInputCell<I> extends Cell<String, I> {
  const TextInputCell(
      {super.attr = const {},
      super.value,
      super.merged,
      super.identifier,
      super.groupState});

  @override
  bool get isEditable => true;

  @override
  TextInputCell copyWith(
      {Map? attr,
      bool valueCanBeNull = false,
      String? value,
      I? identifier,
      FtCellGroupState? groupState,
      Merged? merged}) {
    return TextInputCell(
      attr: attr ?? this.attr,
      value: valueCanBeNull ? value : (value ?? this.value),
      identifier: identifier ?? this.identifier,
      groupState: groupState ?? this.groupState,
      merged: merged ?? this.merged,
    );
  }
}

class DigitInputCell<I> extends Cell<int, I> {
  const DigitInputCell(
      {super.attr = const {},
      super.value,
      this.min,
      this.max,
      super.merged,
      super.identifier,
      super.groupState});

  final int? min;
  final int? max;

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
    I? identifier,
    FtCellGroupState? groupState,
    Merged? merged,
    int? min,
    int? max,
  }) {
    return DigitInputCell(
      attr: attr ?? this.attr,
      value: valueCanBeNull ? value : (value ?? this.value),
      identifier: identifier ?? this.identifier,
      groupState: groupState ?? this.groupState,
      merged: merged ?? this.merged,
      min: min ?? this.min,
      max: max ?? this.min,
    );
  }
}

class DecimalInputCell<I> extends Cell<double, I> {
  const DecimalInputCell(
      {super.attr = const {},
      super.value,
      this.min,
      this.max,
      super.merged,
      super.identifier,
      super.groupState,
      this.format = '#0.0#'});

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
  bool get isEditable => true;

  @override
  DecimalInputCell copyWith(
      {Map? attr,
      bool valueCanBeNull = false,
      double? value,
      FtCellGroupState? groupState,
      Merged? merged,
      double? min,
      double? max,
      String? format,
      I? identifier}) {
    return DecimalInputCell(
        attr: attr ?? this.attr,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        min: min ?? this.min,
        max: max ?? this.min,
        format: format ?? this.format);
  }
}

class BooleanCell<I> extends Cell<bool, I> {
  const BooleanCell(
      {super.attr = const {},
      super.value,
      super.merged,
      super.groupState,
      super.identifier});

  @override
  BooleanCell copyWith(
      {Map? attr,
      bool? value,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier}) {
    return BooleanCell(
      attr: attr ?? this.attr,
      value: value ?? this.value,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
    );
  }
}

class DateTimeCell<I> extends Cell<DateTime, I> {
  const DateTimeCell(
      {super.attr = const {},
      super.value,
      this.minDate,
      this.maxDate,
      required this.isUtc,
      super.merged,
      this.includeTime = false,
      super.groupState,
      super.identifier});

  final DateTime? minDate;
  final DateTime? maxDate;
  final bool includeTime;
  final bool isUtc;

  @override
  DateTimeCell copyWith(
      {Map? attr,
      DateTime? value,
      DateTime? minDate,
      DateTime? maxDate,
      bool? includeTime,
      bool? isUtc,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier}) {
    return DateTimeCell(
      attr: attr ?? this.attr,
      value: value ?? this.value,
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      isUtc: isUtc ?? this.isUtc,
      includeTime: includeTime ?? this.includeTime,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
    );
  }
}

class SelectionCell<I> extends Cell<String, I> {
  const SelectionCell(
      {super.attr = const {},
      super.value,
      required this.values,
      super.merged,
      this.translate = false,
      super.groupState,
      super.identifier});

  final bool translate;
  final List<String> values;

  @override
  SelectionCell copyWith(
      {Map? attr,
      String? value,
      List<String>? values,
      bool? translate,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier}) {
    return SelectionCell(
      attr: attr ?? this.attr,
      value: value ?? this.value,
      values: values ?? this.values,
      translate: translate ?? this.translate,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
    );
  }
}
