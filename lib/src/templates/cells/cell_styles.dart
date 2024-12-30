import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CellStyle {
  final Color? background;
  final Color? backgroundAccent;
  final Color? foreground;
  final EdgeInsets? padding;
  final AlignmentGeometry? alignment;
  final ValidationCellStyle? validationCellStyle;

  const CellStyle(
      {this.background,
      this.backgroundAccent,
      this.foreground,
      this.padding,
      this.alignment,
      this.validationCellStyle});

  CellStyle copyWith(
      {Color? background,
      Color? backgroundAccent,
      Color? foreground,
      EdgeInsets? padding,
      AlignmentGeometry? alignment,
      ValidationCellStyle? validationCellStyle}) {
    return CellStyle(
        background: background ?? this.background,
        backgroundAccent: backgroundAccent ?? this.backgroundAccent,
        foreground: foreground ?? this.foreground,
        padding: padding ?? this.padding,
        alignment: alignment ?? this.alignment,
        validationCellStyle: validationCellStyle ?? this.validationCellStyle);
  }

  static CellStyle? lerp(CellStyle? a, CellStyle? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return CellStyle(
        background: Color.lerp(a?.background, b?.background, t),
        backgroundAccent:
            Color.lerp(a?.backgroundAccent, b?.backgroundAccent, t),
        foreground: Color.lerp(a?.foreground, b?.foreground, t),
        padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
        alignment: AlignmentGeometry.lerp(a?.alignment, b?.alignment, t),
        validationCellStyle: ValidationCellStyle.lerp(
            a?.validationCellStyle, b?.validationCellStyle, t));
  }
}

class TextCellStyle extends CellStyle {
  final TextStyle? textStyle;
  final TextStyle? textStyleEdit;

  final EdgeInsets? paddingEdit;
  final double? rotation;
  final TextAlign? textAlign;

  const TextCellStyle({
    super.background,
    super.foreground,
    super.backgroundAccent,
    this.textStyle,
    TextStyle? textStyleEdit,
    super.padding,
    EdgeInsets? paddingEdit,
    this.rotation,
    this.textAlign,
    super.alignment,
    super.validationCellStyle,
  })  : paddingEdit = padding,
        textStyleEdit = textStyle;

  @override
  TextCellStyle copyWith({
    Color? background,
    Color? backgroundAccent,
    Color? foreground,
    TextStyle? textStyle,
    TextStyle? textStyleEdit,
    EdgeInsets? padding,
    EdgeInsets? paddingEdit,
    double? rotation,
    TextAlign? textAlign,
    AlignmentGeometry? alignment,
    ValidationCellStyle? validationCellStyle,
  }) {
    return TextCellStyle(
        background: background ?? this.background,
        backgroundAccent: backgroundAccent ?? this.backgroundAccent,
        foreground: foreground ?? this.foreground,
        textStyle: textStyle ?? this.textStyle,
        textStyleEdit: textStyleEdit ?? this.textStyleEdit,
        padding: padding ?? this.padding,
        paddingEdit: paddingEdit ?? this.paddingEdit,
        rotation: rotation ?? this.rotation,
        textAlign: textAlign ?? this.textAlign,
        alignment: alignment ?? this.alignment,
        validationCellStyle: validationCellStyle ?? this.validationCellStyle);
  }

  static TextCellStyle? lerp(TextCellStyle? a, TextCellStyle? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return TextCellStyle(
      background: Color.lerp(a?.background, b?.background, t),
      backgroundAccent: Color.lerp(a?.backgroundAccent, b?.backgroundAccent, t),
      foreground: Color.lerp(a?.foreground, b?.foreground, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      alignment: AlignmentGeometry.lerp(a?.alignment, b?.alignment, t),

      ///
      ///
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      textStyleEdit: TextStyle.lerp(a?.textStyleEdit, b?.textStyleEdit, t),
      paddingEdit: EdgeInsets.lerp(a?.paddingEdit, b?.paddingEdit, t),
      rotation: lerpDouble(a?.rotation, b?.rotation, t),
      textAlign: t < 0.5 ? a?.textAlign : b?.textAlign,
      validationCellStyle: ValidationCellStyle.lerp(
          a?.validationCellStyle, b?.validationCellStyle, t),
    );
  }
}

class NumberCellStyle extends TextCellStyle {
  final TextStyle? textStyleExceed;
  final String? format;

  const NumberCellStyle(
      {super.background,
      super.backgroundAccent,
      super.foreground,
      super.textStyle,
      this.textStyleExceed,
      TextStyle? textStyleEdit,
      super.padding,
      EdgeInsets? paddingEdit,
      this.format,
      super.rotation,
      super.textAlign,
      super.alignment,
      super.validationCellStyle});

  @override
  NumberCellStyle copyWith(
      {Color? background,
      Color? backgroundAccent,
      Color? foreground,
      TextStyle? textStyle,
      TextStyle? textStyleEdit,
      EdgeInsets? padding,
      EdgeInsets? paddingEdit,
      double? rotation,
      TextAlign? textAlign,
      AlignmentGeometry? alignment,
      String? format,
      ValidationCellStyle? validationCellStyle}) {
    return NumberCellStyle(
        background: background ?? this.background,
        backgroundAccent: backgroundAccent ?? this.backgroundAccent,
        foreground: foreground ?? this.foreground,
        textStyle: textStyle ?? this.textStyle,
        textStyleEdit: textStyleEdit ?? this.textStyleEdit,
        padding: padding ?? this.padding,
        paddingEdit: paddingEdit ?? this.paddingEdit,
        rotation: rotation ?? this.rotation,
        textAlign: textAlign ?? this.textAlign,
        alignment: alignment ?? this.alignment,
        format: format ?? this.format,
        validationCellStyle: validationCellStyle ?? this.validationCellStyle);
  }

  static NumberCellStyle? lerp(
      NumberCellStyle? a, NumberCellStyle? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return NumberCellStyle(
      background: Color.lerp(a?.background, b?.background, t),
      backgroundAccent: Color.lerp(a?.backgroundAccent, b?.backgroundAccent, t),
      foreground: Color.lerp(a?.foreground, b?.foreground, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      alignment: AlignmentGeometry.lerp(a?.alignment, b?.alignment, t),

      ///
      ///
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      textStyleEdit: TextStyle.lerp(a?.textStyleEdit, b?.textStyleEdit, t),
      paddingEdit: EdgeInsets.lerp(a?.paddingEdit, b?.paddingEdit, t),
      rotation: lerpDouble(a?.rotation, b?.rotation, t),
      textAlign: t < 0.5 ? a?.textAlign : b?.textAlign,
      format: t < 0.5 ? a?.format : b?.format,
      validationCellStyle: ValidationCellStyle.lerp(
          a?.validationCellStyle, b?.validationCellStyle, t),
    );
  }
}

class HeaderCellStyle extends CellStyle {
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final Color? foreGroundColor;

  const HeaderCellStyle(
      {super.background,
      super.foreground,
      super.backgroundAccent,
      this.textStyle,
      super.padding,
      this.textAlign,
      super.alignment,
      this.foreGroundColor,
      super.validationCellStyle});

  @override
  HeaderCellStyle copyWith(
      {Color? background,
      Color? backgroundAccent,
      Color? foreground,
      TextStyle? textStyle,
      EdgeInsets? padding,
      TextAlign? textAlign,
      AlignmentGeometry? alignment,
      Color? foreGroundColor,
      ValidationCellStyle? validationCellStyle}) {
    return HeaderCellStyle(
        background: background ?? this.background,
        backgroundAccent: backgroundAccent ?? this.backgroundAccent,
        foreground: foreground ?? this.foreground,
        textStyle: textStyle ?? this.textStyle,
        padding: padding ?? this.padding,
        textAlign: textAlign ?? this.textAlign,
        alignment: alignment ?? this.alignment,
        foreGroundColor: foreGroundColor ?? this.foreGroundColor,
        validationCellStyle: validationCellStyle ?? this.validationCellStyle);
  }

  static HeaderCellStyle? lerp(
      HeaderCellStyle? a, HeaderCellStyle? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return HeaderCellStyle(
      background: Color.lerp(a?.background, b?.background, t),
      backgroundAccent: Color.lerp(a?.backgroundAccent, b?.backgroundAccent, t),
      foreground: Color.lerp(a?.foreground, b?.foreground, t),
      padding: EdgeInsets.lerp(a?.padding, b?.padding, t),
      alignment: AlignmentGeometry.lerp(a?.alignment, b?.alignment, t),
      validationCellStyle: ValidationCellStyle.lerp(
          a?.validationCellStyle, b?.validationCellStyle, t),

      ///
      ///
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      textAlign: t < 0.5 ? a?.textAlign : b?.textAlign,
      foreGroundColor: Color.lerp(a?.foreGroundColor, b?.foreground, t),
    );
  }
}

class ValidationCellStyle {
  Color? validationColor;

  ValidationCellStyle({
    this.validationColor,
  });

  ValidationCellStyle copyWith({
    Color? validationColor,
  }) {
    return ValidationCellStyle(
      validationColor: validationColor ?? this.validationColor,
    );
  }

  static ValidationCellStyle? lerp(
      ValidationCellStyle? a, ValidationCellStyle? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return ValidationCellStyle(
      validationColor: Color.lerp(a?.validationColor, b?.validationColor, t),
    );
  }
}
