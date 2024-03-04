// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import '../../../flextable.dart';

class TextCell<I> extends Cell<String, I, TextCellStyle> {
  TextCell(
      {super.style,
      super.value,
      super.merged,
      super.identifier,
      super.groupState,
      this.editable = true,
      this.translate = false,
      super.noBlank,
      super.validate = ''});

  @override
  final bool editable;

  final bool translate;

  @override
  TextCell<I> copyWith({
    TextCellStyle? style,
    bool valueCanBeNull = false,
    String? value,
    I? identifier,
    FtCellGroupState? groupState,
    Merged? merged,
    bool? editable,
    bool? translate,
    bool? noBlank,
    String? validate,
  }) {
    return TextCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        editable: editable ?? this.editable,
        translate: translate ?? this.translate,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate);
  }
}

class DigitCell<I> extends Cell<int, I, NumberCellStyle> {
  DigitCell({
    super.style,
    super.value,
    this.min,
    this.max,
    super.merged,
    super.identifier,
    super.groupState,
    this.editable = true,
    super.noBlank,
    super.validate = '',
    Set<FtIndex>? ref,
  }) : ref = ref ?? {};

  final int? min;
  final int? max;
  @override
  final bool editable;
  final Set<FtIndex> ref;

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
    bool? noBlank,
    String? validate,
    Set<FtIndex>? ref,
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
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref);
  }
}

class DecimalCell<I> extends Cell<double, I, NumberCellStyle> {
  DecimalCell(
      {super.style,
      super.value,
      this.min,
      this.max,
      super.merged,
      super.identifier,
      super.groupState,
      this.format = '#0.0#',
      this.editable = true,
      super.noBlank,
      Set<FtIndex>? ref,
      super.validate = ''})
      : ref = ref ?? {};

  final double? min;
  final double? max;
  final String format;
  @override
  final bool editable;
  final Set<FtIndex> ref;

  double? get exceeded {
    return switch ((min, max, value)) {
      (double min, _, double value) when value < min => value - min,
      (_, double max, double value) when max < value => value - max,
      (_, _, _) => null,
    };
  }

  @override
  DecimalCell<I> copyWith({
    NumberCellStyle? style,
    bool valueCanBeNull = false,
    double? value,
    FtCellGroupState? groupState,
    Merged? merged,
    double? min,
    double? max,
    String? format,
    I? identifier,
    bool? editable,
    bool? noBlank,
    String? validate,
    Set<FtIndex>? ref,
  }) {
    return DecimalCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        min: min ?? this.min,
        max: max ?? this.min,
        format: format ?? this.format,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref);
  }
}

typedef FtCalculationFunction = num? Function(List<Object> list);

class CalculationCell<I> extends Cell<num, I, NumberCellStyle> {
  CalculationCell(
      {super.style,
      super.value,
      super.merged,
      super.identifier,
      super.groupState,
      this.format = '#0.0#',
      super.noBlank = false,
      required this.calculationSyntax,
      required this.imRefIndex,
      super.validate = '',
      this.linked = false,
      this.evaluted = false});

  final String format;
  final List<FtIndex> imRefIndex;
  bool evaluted;
  final FtCalculationFunction calculationSyntax;
  bool linked;

  @override
  CalculationCell<I> copyWith({
    NumberCellStyle? style,
    num? value,
    bool valueCanBeNull = false,
    FtCellGroupState? groupState,
    Merged? merged,
    String? format,
    I? identifier,
    String? validate,
    bool? noBlank,
    FtCalculationFunction? calculationSyntax,
    bool? evaluted,
    List<FtIndex>? imRefIndex,
    bool? linked,
  }) {
    return CalculationCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        format: format ?? this.format,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        evaluted: evaluted ?? this.evaluted,
        linked: linked ?? this.linked,
        imRefIndex: imRefIndex ?? this.imRefIndex,
        calculationSyntax: calculationSyntax ?? this.calculationSyntax);
  }
}

class BooleanCell<I> extends Cell<bool, I, CellStyle> {
  BooleanCell(
      {super.style,
      super.value,
      super.merged,
      super.groupState,
      super.identifier,
      this.editable = true,
      super.noBlank,
      super.validate = ''});

  @override
  final bool editable;

  @override
  BooleanCell<I> copyWith({
    CellStyle? style,
    bool? value,
    FtCellGroupState? groupState,
    Merged? merged,
    I? identifier,
    bool? editable,
    bool? noBlank,
    String? validate,
  }) {
    return BooleanCell(
        style: style ?? this.style,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate);
  }
}

class DateTimeCell<I> extends Cell<DateTime, I, TextCellStyle> {
  DateTimeCell(
      {super.style,
      super.value,
      this.minDate,
      this.maxDate,
      required this.isUtc,
      super.merged,
      this.includeTime = false,
      super.groupState,
      super.identifier,
      this.editable = true,
      super.noBlank,
      super.validate = ''});

  final DateTime? minDate;
  final DateTime? maxDate;
  final bool includeTime;
  final bool isUtc;
  @override
  final bool editable;

  @override
  DateTimeCell<I> copyWith({
    TextCellStyle? style,
    DateTime? value,
    bool valueCanBeNull = false,
    DateTime? minDate,
    DateTime? maxDate,
    bool? includeTime,
    bool? isUtc,
    FtCellGroupState? groupState,
    Merged? merged,
    I? identifier,
    bool? editable,
    bool? noBlank,
    String? validate,
  }) {
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
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate);
  }
}

class SelectionCell<T, I> extends Cell<T, I, TextCellStyle> {
  SelectionCell({
    super.style,
    super.value,
    required this.values,
    super.merged,
    this.translate = false,
    super.groupState,
    super.identifier,
    super.noBlank,
    super.validate = '',
    this.editable = true,
    Set<FtIndex>? ref,
    this.translation,
  }) : ref = ref ?? {};

  final bool translate;
  final List<T> values;
  @override
  final bool editable;
  final Set<FtIndex> ref;
  String? translation;

  @override
  SelectionCell<T, I> copyWith(
      {TextCellStyle? style,
      T? value,
      List<T>? values,
      bool? translate,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier,
      bool? noBlank,
      String? validate,
      bool? editable,
      Set<FtIndex>? ref}) {
    return SelectionCell(
        style: style ?? this.style,
        value: value ?? this.value,
        values: values ?? this.values,
        translate: translate ?? this.translate,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        editable: editable ?? this.editable,
        translation: null,
        ref: ref ?? this.ref);
  }
}

class ActionCellItem<A> {
  final A action;
  final String? text;
  final Widget? widget;
  final bool isImage;
  const ActionCellItem({
    required this.action,
    this.text,
    this.widget,
    this.isImage = false,
  });
}

class ActionCell<T, I> extends Cell<T, I, TextCellStyle> {
  ActionCell(
      {super.style,
      super.value,
      this.text,
      super.merged,
      this.translate = false,
      super.groupState,
      super.identifier,
      super.noBlank,
      super.validate = ''});

  final bool translate;
  final String? text;

  @override
  bool get editable => false;

  @override
  ActionCell<T, I> copyWith({
    TextCellStyle? style,
    T? value,
    bool? translate,
    FtCellGroupState? groupState,
    Merged? merged,
    I? identifier,
    String? text,
    bool? noBlank,
    String? validate,
  }) {
    return ActionCell(
      style: style ?? this.style,
      value: value ?? this.value,
      translate: translate ?? this.translate,
      merged: merged ?? this.merged,
      groupState: groupState ?? this.groupState,
      identifier: identifier ?? this.identifier,
      text: text ?? this.text,
      noBlank: noBlank ?? this.noBlank,
      validate: validate ?? this.validate,
    );
  }
}
