// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/templates/cell_widgets/shared/validate_drawer.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TextDrawer extends StatelessWidget {
  const TextDrawer(
      {super.key,
      required this.cell,
      this.formatedValue,
      required this.tableScale,
      required this.useAccent});

  final Cell cell;
  final String? formatedValue;
  final double tableScale;
  final bool useAccent;

  @override
  Widget build(BuildContext context) {
    TextCellStyle? textCellStyle;

    if (cell.style case TextCellStyle style) {
      textCellStyle = style;
    }

    Widget text = RichText(
      text: TextSpan(
        text: formatedValue ?? '${cell.value ?? ''}',
        style: textCellStyle?.textStyle,
      ),
      softWrap: true,
      textAlign: textCellStyle?.textAlign ?? TextAlign.start,
      // textScaler: TextScaler.linear(tableScale),
    );

    if (textCellStyle?.rotation case double rotation) {
      text =
          TableTextRotate(angle: math.pi * 2.0 / 360 * rotation, child: text);
    }

    Widget child = Container(
        padding: (textCellStyle?.padding ?? EdgeInsets.zero) * tableScale,
        alignment: textCellStyle?.alignment ?? Alignment.center,
        color: useAccent
            ? (textCellStyle?.backgroundAccent ?? textCellStyle?.background)
            : textCellStyle?.background,
        child: text);

    if (cell.noBlank) {
      child = ValidationDrawer(
        cell: cell,
        tableScale: tableScale,
        child: child,
      );
    }

    return ValidationDrawer(cell: cell, tableScale: tableScale, child: child);
  }
}
