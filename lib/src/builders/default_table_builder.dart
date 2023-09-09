// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/builders/default_paint_split_lines.dart';

import '../builders/table_builder.dart';
import '../model/model.dart';
import '../model/properties/flextable_header_properties.dart';
import '../panels/header_viewport.dart';
import '../utilities/number_to_character.dart';
import 'package:flutter/material.dart';
import '../model/view_model.dart';
import 'default_cell_builder.dart';

class DefaultTableBuilder extends TableBuilder with DefaultCellBuilder {
  DefaultTableBuilder(
      {this.panelPadding = EdgeInsets.zero,
      this.singleDigitWidth = 10.0,
      this.digitPadding = 3.0,
      this.headerHeight = 20.0,
      this.headerBackgroundColor,
      this.headerLineColor,
      this.headerTextStyle});

  @override
  final EdgeInsets panelPadding;
  final double singleDigitWidth;
  final double digitPadding;
  @override
  final double headerHeight;
  final Color? headerBackgroundColor;
  final Color? headerLineColor;
  final TextStyle? headerTextStyle;

  @override
  double rowHeaderWidth(HeaderProperties headerProperty) =>
      (headerProperty.digits * singleDigitWidth + digitPadding * 2.0);

  @override
  Widget backgroundPanel(
    int panelIndex,
    BuildContext context,
    Widget? child,
  ) {
    //Background Headers:
    if (headerBackgroundColor != null &&
        (panelIndex <= 3 ||
            panelIndex >= 12 ||
            panelIndex % 4 == 0 ||
            panelIndex % 4 == 3)) {
      return Container(
        color: headerBackgroundColor,
        child: child,
      );
    }
    return child ?? const SizedBox();
  }

  @override
  Widget buildHeaderIndex(FlexTableModel flexTableModel,
      TableHeaderIndex tableHeaderIndex, BuildContext context) {
    if (tableHeaderIndex.panelIndex <= 3 || tableHeaderIndex.panelIndex >= 12) {
      return Center(
          child: Text(
        '${tableHeaderIndex.index + 1}',
        textScaleFactor: flexTableModel.scaleRowHeader,
        style: headerTextStyle,
      ));
    } else {
      return Center(
          child: Text(numberToCharacter(tableHeaderIndex.index),
              textScaleFactor: flexTableModel.scaleColumnHeader,
              style: headerTextStyle));
    }
  }

  @override
  LineHeader lineHeader(FlexTableViewModel flexTableViewModel, int panelIndex) {
    //final tpli = flexTableViewModel.layoutIndex(panelIndex);

    return LineHeader(color: headerLineColor ?? Colors.blueGrey);
  }

  @override
  void drawPaintSplit(FlexTableViewModel flexTableViewModel,
      PaintingContext context, Offset offset, Size size) {
    defaultDrawPaintSplit(
        flexTableViewModel: flexTableViewModel,
        context: context,
        offset: offset,
        size: size,
        freezeColors: const [
          Color(0xFF016baa),
          Color(0xFF015e96),
          Color(0xFF004d7c)
        ],
        splitColors: const [
          Color(0xFFE0E0E0),
          Color(0xFFD6D6D6),
          Color(0xFF9E9E9E)
        ]);
  }
}
