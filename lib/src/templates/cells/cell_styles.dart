import 'package:flutter/widgets.dart';

class CellStyle {
  final Color? background;
  final Color? backgroundAccent;
  final Color? foreground;
  final EdgeInsets? padding;
  final AlignmentGeometry? alignment;

  const CellStyle({
    this.background,
    this.backgroundAccent,
    this.foreground,
    this.padding,
    this.alignment,
  });
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
  })  : paddingEdit = padding,
        textStyleEdit = textStyle;

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
    );
  }
}

class NumberCellStyle extends TextCellStyle {
  final TextStyle? textStyleExceed;
  final String format;

  const NumberCellStyle(
      {super.background,
      super.backgroundAccent,
      super.foreground,
      super.textStyle,
      this.textStyleExceed,
      TextStyle? textStyleEdit,
      super.padding,
      EdgeInsets? paddingEdit,
      this.format = '#0.###',
      super.rotation,
      super.textAlign,
      super.alignment});
}
