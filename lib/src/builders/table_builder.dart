// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/material.dart';
import '../panels/header_viewport.dart';
import '../panels/panel_viewport.dart';
import '../model/model.dart';

abstract class TableBuilder {
  TableBuilder();

  Widget? buildCell(
      FlexTableModel flexTableModel, TableCellIndex tableCellIndex);

  Widget backgroundPanel(int panelIndex, Widget? child);

  Widget? buildHeaderIndex(
      FlexTableModel flexTableModel, TableHeaderIndex tableHeaderIndex);

  LineHeader lineHeader(FlexTableViewModel flexTableViewModel, int panelIndex);

  void drawPaintSplit(FlexTableViewModel flexTableViewModel,
      PaintingContext context, Offset offset, Size size);
}

class LineHeader {
  double width;
  Color color;

  LineHeader({
    this.width = 0.5,
    this.color = Colors.black87,
  });
}
