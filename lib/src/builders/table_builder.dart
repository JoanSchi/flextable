// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/material.dart';
import '../model/properties/flextable_header_properties.dart';
import '../panels/header_viewport.dart';
import '../panels/panel_viewport.dart';
import '../model/model.dart';

abstract class TableBuilder {
  TableBuilder();

  Widget? cellBuilder(FlexTableModel flexTableModel,
      TableCellIndex tableCellIndex, BuildContext context);

  Widget backgroundPanel(
    int panelIndex,
    BuildContext context,
    Widget? child,
  );

  Widget buildHeaderIndex(FlexTableModel flexTableModel,
      TableHeaderIndex tableHeaderIndex, BuildContext context);

  LineHeader lineHeader(FlexTableViewModel flexTableViewModel, int panelIndex);

  void drawPaintSplit(FlexTableViewModel flexTableViewModel,
      PaintingContext context, Offset offset, Size size);

  double get headerHeight => 20.0;

  double rowHeaderWidth(HeaderProperties headerProperty) =>
      (headerProperty.digits * 10.0 + 6.0);

  EdgeInsets get panelPadding => const EdgeInsets.all(2.0);
}

class LineHeader {
  double width;
  Color color;

  LineHeader({
    this.width = 0.5,
    this.color = Colors.black87,
  });
}
