// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/foundation.dart';
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
      super.validate = '',
      super.ref});

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
    Set<FtIndex>? ref,
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
        validate: validate ?? this.validate,
        ref: ref ?? this.ref);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TextCell<I> &&
        super == other &&
        other.editable == editable &&
        other.translate == translate;
  }

  @override
  int get hashCode => editable.hashCode ^ translate.hashCode ^ super.hashCode;
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
    super.ref,
  });

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DigitCell<I> &&
        super == other &&
        other.min == min &&
        other.max == max &&
        other.editable == editable &&
        setEquals(other.ref, ref);
  }

  @override
  int get hashCode {
    return super.hashCode ^
        min.hashCode ^
        max.hashCode ^
        editable.hashCode ^
        ref.hashCode;
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
      super.ref,
      super.validate = ''});

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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DecimalCell<I> &&
        super == other &&
        other.min == min &&
        other.max == max &&
        other.format == format &&
        other.editable == editable &&
        setEquals(other.ref, ref);
  }

  @override
  int get hashCode {
    return super.hashCode ^
        min.hashCode ^
        max.hashCode ^
        format.hashCode ^
        editable.hashCode ^
        ref.hashCode;
  }
}

typedef FtCalculationFunction = num? Function(List<Object?> list);

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
      this.evaluted = false,
      super.ref});

  final String format;
  final List<FtIndex> imRefIndex;
  bool evaluted;
  final FtCalculationFunction calculationSyntax;
  bool linked;

  @override
  CalculationCell<I> copyWith(
      {NumberCellStyle? style,
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
      Set<FtIndex>? ref}) {
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
        calculationSyntax: calculationSyntax ?? this.calculationSyntax,
        ref: ref ?? this.ref);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CalculationCell<I> &&
        super == other &&
        other.format == format &&
        listEquals(other.imRefIndex, imRefIndex) &&
        other.calculationSyntax == calculationSyntax;
  }

  @override
  int get hashCode =>
      format.hashCode ^ imRefIndex.hashCode ^ calculationSyntax.hashCode;
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
      super.validate = '',
      super.ref});

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
    Set<FtIndex>? ref,
  }) {
    return BooleanCell(
        style: style ?? this.style,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is BooleanCell<I> &&
        super == other &&
        other.editable == editable;
  }

  @override
  int get hashCode => super.hashCode ^ editable.hashCode;
}

class DateTimeCell<I> extends Cell<DateTime, I, TextCellStyle> {
  DateTimeCell({
    super.style,
    super.value,
    this.minDate,
    this.maxDate,
    super.merged,
    this.includeTime = false,
    super.groupState,
    super.identifier,
    this.editable = true,
    super.noBlank,
    super.validate = '',
    super.ref,
  });

  final DateTime? minDate;
  final DateTime? maxDate;
  final bool includeTime;
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
    FtCellGroupState? groupState,
    Merged? merged,
    I? identifier,
    bool? editable,
    bool? noBlank,
    String? validate,
    Set<FtIndex>? ref,
  }) {
    return DateTimeCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        minDate: minDate ?? this.minDate,
        maxDate: maxDate ?? this.maxDate,
        includeTime: includeTime ?? this.includeTime,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DateTimeCell<I> &&
        super == other &&
        other.minDate == minDate &&
        other.maxDate == maxDate &&
        other.includeTime == includeTime &&
        other.editable == editable;
  }

  @override
  int get hashCode {
    return super.hashCode ^
        minDate.hashCode ^
        maxDate.hashCode ^
        includeTime.hashCode ^
        editable.hashCode;
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
    super.ref,
    this.translation,
  });

  final bool translate;
  final dynamic values;
  @override
  final bool editable;

  String? translation;

  @override
  SelectionCell<T, I> copyWith(
      {TextCellStyle? style,
      T? value,
      dynamic values,
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

  // @override
  // bool operator ==(Object other) {
  //   if (identical(this, other)) return true;

  //   return other is SelectionCell<T, I> &&
  //       super == other &&
  //       other.translate == translate &&
  //       switch ((other.values, values)) {
  //         (Map o, Map v) => mapEquals(o, v),
  //         (List o, List v) => listEquals(o, v),
  //         (_, _) => false
  //       } &&
  //       other.editable == editable &&
  //       setEquals(other.ref, ref);
  // }

  // @override
  // int get hashCode {
  //   return super.hashCode ^
  //       translate.hashCode ^
  //       values.hashCode ^
  //       editable.hashCode ^
  //       ref.hashCode;
  // }
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

class ActionCell<T, I> extends Cell<T, I, CellStyle> {
  ActionCell({
    super.style,
    super.value,
    this.cellValue,
    super.merged,
    this.translate = false,
    super.groupState,
    super.identifier,
    super.noBlank,
    super.validate = '',
    super.ref,
    this.format = '',
  });

  final bool translate;
  final Object? cellValue;
  final String format;

  @override
  bool get editable => false;

  @override
  ActionCell<T, I> copyWith({
    CellStyle? style,
    T? value,
    bool? translate,
    FtCellGroupState? groupState,
    Merged? merged,
    I? identifier,
    String? cellValue,
    bool? noBlank,
    String? validate,
    Set<FtIndex>? ref,
    String? format,
  }) {
    return ActionCell(
        style: style ?? this.style,
        value: value ?? this.value,
        translate: translate ?? this.translate,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        cellValue: cellValue ?? this.cellValue,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref,
        format: format ?? this.format);
  }
}
