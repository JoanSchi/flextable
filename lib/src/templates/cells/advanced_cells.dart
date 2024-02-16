// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../flextable.dart';

class TextCell<I> extends Cell<String, I, TextCellStyle> {
  const TextCell({
    super.style,
    super.value,
    super.merged,
    super.identifier,
    super.groupState,
    this.editable = true,
    this.translate,
  });

  @override
  final bool editable;

  final bool? translate;

  @override
  TextCell<I> copyWith(
      {TextCellStyle? style,
      bool valueCanBeNull = false,
      String? value,
      I? identifier,
      FtCellGroupState? groupState,
      Merged? merged,
      bool? editable,
      bool? translate}) {
    return TextCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        editable: editable ?? this.editable,
        translate: translate ?? this.translate);
  }
}

class DigitCell<I> extends Cell<int, I, NumberCellStyle> {
  const DigitCell(
      {super.style,
      super.value,
      this.min,
      this.max,
      super.merged,
      super.identifier,
      super.groupState,
      this.editable = true});

  final int? min;
  final int? max;
  @override
  final bool editable;

  int? get exceeded {
    return switch ((min, max, value)) {
      (int min, _, int value) when value < min => value - min,
      (_, int max, int value) when max < value => value - max,
      (_, _, _) => null,
    };
  }

  @override
  DigitCell<I> copyWith({
    NumberCellStyle? style,
    bool valueCanBeNull = false,
    int? value,
    I? identifier,
    FtCellGroupState? groupState,
    Merged? merged,
    int? min,
    int? max,
    bool? editable,
  }) {
    return DigitCell(
      style: style ?? this.style,
      value: valueCanBeNull ? value : (value ?? this.value),
      identifier: identifier ?? this.identifier,
      groupState: groupState ?? this.groupState,
      merged: merged ?? this.merged,
      min: min ?? this.min,
      max: max ?? this.min,
      editable: editable ?? this.editable,
    );
  }
}

class DecimalCell<I> extends Cell<double, I, NumberCellStyle> {
  const DecimalCell(
      {super.style,
      super.value,
      this.min,
      this.max,
      super.merged,
      super.identifier,
      super.groupState,
      this.format = '#0.0#',
      this.editable = true});

  final double? min;
  final double? max;
  final String format;
  @override
  final bool editable;

  double? get exceeded {
    return switch ((min, max, value)) {
      (double min, _, double value) when value < min => value - min,
      (_, double max, double value) when max < value => value - max,
      (_, _, _) => null,
    };
  }

  @override
  DecimalCell<I> copyWith(
      {NumberCellStyle? style,
      bool valueCanBeNull = false,
      double? value,
      FtCellGroupState? groupState,
      Merged? merged,
      double? min,
      double? max,
      String? format,
      I? identifier,
      bool? editable}) {
    return DecimalCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        min: min ?? this.min,
        max: max ?? this.min,
        format: format ?? this.format,
        editable: editable ?? this.editable);
  }
}

class BooleanCell<I> extends Cell<bool, I, CellStyle> {
  const BooleanCell(
      {super.style,
      super.value,
      super.merged,
      super.groupState,
      super.identifier,
      this.editable = true});

  @override
  final bool editable;

  @override
  BooleanCell<I> copyWith(
      {CellStyle? style,
      bool? value,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier,
      bool? editable}) {
    return BooleanCell(
      style: style ?? this.style,
      value: value ?? this.value,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
      editable: editable ?? this.editable,
    );
  }
}

class DateTimeCell<I> extends Cell<DateTime, I, TextCellStyle> {
  const DateTimeCell(
      {super.style,
      super.value,
      this.minDate,
      this.maxDate,
      required this.isUtc,
      super.merged,
      this.includeTime = false,
      super.groupState,
      super.identifier,
      this.editable = true});

  final DateTime? minDate;
  final DateTime? maxDate;
  final bool includeTime;
  final bool isUtc;
  @override
  final bool editable;

  @override
  DateTimeCell<I> copyWith(
      {TextCellStyle? style,
      DateTime? value,
      bool valueCanBeNull = false,
      DateTime? minDate,
      DateTime? maxDate,
      bool? includeTime,
      bool? isUtc,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier,
      bool? editable}) {
    return DateTimeCell(
      style: style ?? this.style,
      value: valueCanBeNull ? value : (value ?? this.value),
      minDate: minDate ?? this.minDate,
      maxDate: maxDate ?? this.maxDate,
      isUtc: isUtc ?? this.isUtc,
      includeTime: includeTime ?? this.includeTime,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
      editable: editable ?? this.editable,
    );
  }
}

class SelectionCell<T, I> extends Cell<T, I, TextCellStyle> {
  const SelectionCell(
      {super.style,
      super.value,
      required this.values,
      super.merged,
      this.translate = false,
      super.groupState,
      super.identifier});

  final bool translate;
  final List<T> values;

  @override
  bool get editable => true;

  @override
  SelectionCell<T, I> copyWith(
      {TextCellStyle? style,
      T? value,
      List<T>? values,
      bool? translate,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier}) {
    return SelectionCell(
      style: style ?? this.style,
      value: value ?? this.value,
      values: values ?? this.values,
      translate: translate ?? this.translate,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
    );
  }
}

class ActionCell<T, I> extends Cell<T, I, TextCellStyle> {
  const ActionCell(
      {super.style,
      super.value,
      this.text,
      super.merged,
      this.translate = false,
      super.groupState,
      super.identifier});

  final bool translate;
  final String? text;

  @override
  bool get editable => false;

  @override
  ActionCell<T, I> copyWith(
      {TextCellStyle? style,
      T? value,
      bool? translate,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier,
      String? text,
      Widget? icon}) {
    return ActionCell(
      style: style ?? this.style,
      value: value ?? this.value,
      translate: translate ?? this.translate,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
      text: text ?? this.text,
    );
  }
}
