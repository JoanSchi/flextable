// ignore_for_file: public_member_api_docs, sort_constructors_first
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
      super.ref,
      super.getThemeStyle,
      super.theme});

  @override
  final bool editable;
  final bool translate;

  @override
  TextCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (TextCellStyle s, TextCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            paddingEdit: s.paddingEdit,
            rotation: s.rotation,
            textAlign: s.textAlign,
            textStyle: s.textStyle,
            textStyleEdit: s.textStyleEdit,
          ),
        (TextCellStyle s, null) => s,
        (null, TextCellStyle? t) => t,
        (_, _) => null,
      };

  @override
  TextCell<I> copyWith(
      {TextCellStyle? style,
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
      String? theme,
      TextCellStyle? Function(Object? theme)? getThemeStyle}) {
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
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
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
  int get hashCode => super.hashCode ^ editable.hashCode ^ translate.hashCode;
}

class DigitCell<I> extends Cell<int, I, NumberCellStyle> {
  DigitCell(
      {super.style,
      super.value,
      super.merged,
      super.identifier,
      super.groupState,
      this.editable = true,
      super.noBlank,
      super.validate = '',
      super.ref,
      super.getThemeStyle,
      super.theme});

  @override
  final bool editable;

  @override
  NumberCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (NumberCellStyle s, NumberCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            format: s.format,
            paddingEdit: s.paddingEdit,
            rotation: s.rotation,
            textAlign: s.textAlign,
            textStyle: s.textStyle,
            textStyleEdit: s.textStyleEdit,
          ),
        (NumberCellStyle s, null) => s,
        (null, NumberCellStyle? t) => t,
        (_, _) => null,
      };

  @override
  DigitCell<I> copyWith(
      {NumberCellStyle? style,
      bool valueCanBeNull = false,
      int? value,
      I? identifier,
      FtCellGroupState? groupState,
      Merged? merged,
      bool? editable,
      bool? noBlank,
      String? validate,
      Set<FtIndex>? ref,
      String? theme,
      NumberCellStyle? Function(Object? theme)? getThemeStyle}) {
    return DigitCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  bool operator ==(covariant DigitCell<I> other) {
    if (identical(this, other)) return true;

    return super == other && other.editable == editable;
  }

  @override
  int get hashCode => super.hashCode ^ editable.hashCode;
}

class DecimalCell<I> extends Cell<double, I, NumberCellStyle> {
  DecimalCell(
      {super.style,
      super.value,
      super.merged,
      super.identifier,
      super.groupState,
      this.format = '#0.0#',
      this.editable = true,
      super.noBlank,
      super.ref,
      super.validate = '',
      super.getThemeStyle,
      super.theme});

  final String format;
  @override
  final bool editable;

  @override
  NumberCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (NumberCellStyle s, NumberCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            format: s.format,
            paddingEdit: s.paddingEdit,
            rotation: s.rotation,
            textAlign: s.textAlign,
            textStyle: s.textStyle,
            textStyleEdit: s.textStyleEdit,
          ),
        (NumberCellStyle s, null) => s,
        (null, NumberCellStyle? t) => t,
        (_, _) => null,
      };

  @override
  DecimalCell<I> copyWith(
      {NumberCellStyle? style,
      bool valueCanBeNull = false,
      double? value,
      FtCellGroupState? groupState,
      Merged? merged,
      String? format,
      I? identifier,
      bool? editable,
      bool? noBlank,
      String? validate,
      Set<FtIndex>? ref,
      String? theme,
      NumberCellStyle? Function(Object? theme)? getThemeStyle}) {
    return DecimalCell(
        style: style ?? this.style,
        value: valueCanBeNull ? value : (value ?? this.value),
        identifier: identifier ?? this.identifier,
        groupState: groupState ?? this.groupState,
        merged: merged ?? this.merged,
        format: format ?? this.format,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DecimalCell<I> &&
        super == other &&
        other.format == format &&
        other.editable == editable &&
        setEquals(other.ref, ref);
  }

  @override
  int get hashCode {
    return super.hashCode ^ format.hashCode ^ editable.hashCode ^ ref.hashCode;
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
      super.ref,
      super.getThemeStyle,
      super.theme});

  final String format;
  final List<FtIndex> imRefIndex;
  bool evaluted;
  final FtCalculationFunction calculationSyntax;
  bool linked;

  @override
  NumberCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (NumberCellStyle s, NumberCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            format: s.format,
            paddingEdit: s.paddingEdit,
            rotation: s.rotation,
            textAlign: s.textAlign,
            textStyle: s.textStyle,
            textStyleEdit: s.textStyleEdit,
          ),
        (NumberCellStyle s, null) => s,
        (null, NumberCellStyle? t) => t,
        (_, _) => null,
      };

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
      Set<FtIndex>? ref,
      String? theme,
      NumberCellStyle? Function(Object? theme)? getThemeStyle}) {
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
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
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
      super.ref,
      super.getThemeStyle,
      super.theme});

  @override
  final bool editable;

  @override
  BooleanCell<I> copyWith(
      {CellStyle? style,
      bool? value,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier,
      bool? editable,
      bool? noBlank,
      String? validate,
      Set<FtIndex>? ref,
      String? theme,
      CellStyle? Function(Object? theme)? getThemeStyle}) {
    return BooleanCell(
        style: style ?? this.style,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        editable: editable ?? this.editable,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  CellStyle? get themedStyle => switch ((style, getThemeStyle?.call(theme))) {
        (CellStyle s, CellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle),
        (CellStyle s, null) => s,
        (null, CellStyle? t) => t,
        (_, _) => null,
      };

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
  DateTimeCell(
      {super.style,
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
      super.getThemeStyle,
      super.theme});

  final DateTime? minDate;
  final DateTime? maxDate;
  final bool includeTime;
  @override
  final bool editable;

  @override
  TextCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (TextCellStyle s, TextCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            paddingEdit: s.paddingEdit,
            rotation: s.rotation,
            textAlign: s.textAlign,
            textStyle: s.textStyle,
            textStyleEdit: s.textStyleEdit,
          ),
        (TextCellStyle s, null) => s,
        (null, TextCellStyle? t) => t
      };

  @override
  DateTimeCell<I> copyWith(
      {TextCellStyle? style,
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
      String? theme,
      TextCellStyle? Function(Object? theme)? getThemeStyle}) {
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
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
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
  SelectionCell(
      {super.style,
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
      super.getThemeStyle,
      super.theme});

  final bool translate;
  final dynamic values;
  @override
  final bool editable;

  String? translation;

  @override
  TextCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (TextCellStyle s, TextCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            paddingEdit: s.paddingEdit,
            rotation: s.rotation,
            textAlign: s.textAlign,
            textStyle: s.textStyle,
            textStyleEdit: s.textStyleEdit,
          ),
        (TextCellStyle s, null) => s,
        (null, TextCellStyle? t) => t,
        (_, _) => null,
      };

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
      Set<FtIndex>? ref,
      String? theme,
      TextCellStyle? Function(Object? theme)? getThemeStyle}) {
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
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
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

class ActionCell<T, I> extends Cell<T, I, CellStyle> {
  ActionCell(
      {super.style,
      super.value,
      this.items,
      super.merged,
      this.translate = false,
      super.groupState,
      super.identifier,
      super.noBlank,
      super.validate = '',
      super.ref,
      this.format = '',
      super.theme,
      super.getThemeStyle});

  final bool translate;
  final Object? items;
  final String format;

  @override
  CellStyle? get themedStyle => switch ((style, getThemeStyle?.call(theme))) {
        (CellStyle s, CellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle),
        (CellStyle s, null) => s,
        (null, CellStyle? t) => t
      };

  @override
  bool get editable => false;

  @override
  ActionCell<T, I> copyWith(
      {CellStyle? style,
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
      String? theme,
      CellStyle? Function(Object? theme)? getThemeStyle}) {
    return ActionCell(
        style: style ?? this.style,
        value: value ?? this.value,
        translate: translate ?? this.translate,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        items: cellValue ?? this.items,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref,
        format: format ?? this.format,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActionCell<T, I> &&
        super == other &&
        other.translate == translate &&
        other.items == items &&
        other.format == format;
  }

  @override
  int get hashCode =>
      super.hashCode ^ translate.hashCode ^ items.hashCode ^ format.hashCode;
}

class HeaderCell<I> extends AbstractCell<I> {
  HeaderCell({
    super.merged,
    super.identifier,
    this.style,
    required this.text,
    this.translate = false,
    this.theme,
    this.getThemeStyle,
  });

  final HeaderCellStyle? style;
  final String text;
  final bool translate;
  final Object? theme;
  final HeaderCellStyle? Function(Object? theme)? getThemeStyle;

  HeaderCellStyle? get themedStyle =>
      switch ((style, getThemeStyle?.call(theme))) {
        (HeaderCellStyle s, HeaderCellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle,
            foreGroundColor: s.foreGroundColor,
            textAlign: s.textAlign,
            textStyle: s.textStyle),
        (HeaderCellStyle s, null) => s,
        (null, HeaderCellStyle? t) => t,
        (_, _) => null,
      };

  @override
  HeaderCell<I> copyWith({
    HeaderCellStyle? style,
    bool? translate,
    Merged? merged,
    I? identifier,
    String? text,
    String? theme,
    HeaderCellStyle? Function(Object? theme)? getThemeStyle,
  }) {
    return HeaderCell(
        identifier: identifier ?? this.identifier,
        merged: merged ?? this.merged,
        style: style ?? this.style,
        text: text ?? this.text,
        translate: translate ?? this.translate,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is HeaderCell<I> &&
        super == other &&
        other.style == style &&
        other.text == text &&
        other.translate == translate;
  }

  @override
  int get hashCode {
    return super.hashCode ^ style.hashCode ^ text.hashCode ^ translate.hashCode;
  }
}

class SortHeaderCell<I> extends HeaderCell<I> {
  SortHeaderCell({
    super.merged,
    super.identifier,
    super.style,
    this.sortAz,
    required super.text,
    super.translate = false,
    this.translateSort = false,
    super.theme,
    super.getThemeStyle,
  });

  final bool? sortAz;
  final bool translateSort;

  @override
  SortHeaderCell<I> copyWith({
    HeaderCellStyle? style,
    Object? sortAz = const Object(),
    bool? translate,
    bool? translateActions,
    Merged? merged,
    I? identifier,
    String? text,
    Object? theme,
    HeaderCellStyle? Function(Object? theme)? getThemeStyle,
  }) {
    return SortHeaderCell(
        identifier: identifier ?? this.identifier,
        merged: merged ?? this.merged,
        style: style ?? this.style,
        text: text ?? this.text,
        sortAz: switch (sortAz) { (bool? v) => v, (_) => this.sortAz },
        translate: translate ?? this.translate,
        translateSort: translateActions ?? this.translateSort,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SortHeaderCell<I> &&
        super == other &&
        other.sortAz == sortAz &&
        other.translateSort == translateSort;
  }

  @override
  int get hashCode {
    return super.hashCode ^ sortAz.hashCode ^ translateSort.hashCode;
  }
}

class CustomCell<T, I> extends Cell<T, I, CellStyle> {
  CustomCell(
      {super.style,
      super.value,
      super.merged,
      this.editable = false,
      required this.valueToWidgets,
      super.groupState,
      super.identifier,
      super.noBlank,
      super.validate = '',
      super.ref,
      super.getThemeStyle,
      super.theme});

  final Widget Function(CustomCell<T, I> cell, bool useAccent) valueToWidgets;

  @override
  final bool editable;

  @override
  CellStyle? get themedStyle => switch ((style, getThemeStyle?.call(theme))) {
        (CellStyle s, CellStyle t) => t.copyWith(
            alignment: s.alignment,
            background: s.background,
            backgroundAccent: s.backgroundAccent,
            foreground: s.foreground,
            padding: s.padding,
            validationCellStyle: s.validationCellStyle),
        (CellStyle s, null) => s,
        (null, CellStyle? t) => t,
        (_, _) => null,
      };

  @override
  CustomCell<T, I> copyWith(
      {CellStyle? style,
      T? value,
      bool? editable,
      Widget Function(CustomCell<T, I> cell, bool useAccent)? widgetsFromValue,
      bool? translate,
      FtCellGroupState? groupState,
      Merged? merged,
      I? identifier,
      bool? noBlank,
      String? validate,
      Set<FtIndex>? ref,
      String? theme,
      CellStyle? Function(Object? theme)? getThemeStyle}) {
    return CustomCell(
        style: style ?? this.style,
        value: value ?? this.value,
        editable: editable ?? this.editable,
        valueToWidgets: widgetsFromValue ?? this.valueToWidgets,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState,
        identifier: identifier ?? this.identifier,
        noBlank: noBlank ?? this.noBlank,
        validate: validate ?? this.validate,
        ref: ref ?? this.ref,
        theme: theme ?? this.theme,
        getThemeStyle: getThemeStyle ?? this.getThemeStyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CustomCell<T, I> &&
        super == other &&
        other.valueToWidgets == valueToWidgets &&
        other.editable == editable;
  }

  @override
  int get hashCode =>
      editable.hashCode ^ valueToWidgets.hashCode ^ super.hashCode;
}
