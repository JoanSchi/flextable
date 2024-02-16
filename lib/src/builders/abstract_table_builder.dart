// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../flextable.dart';

// extension ViewModelBuildContextEntension on BuildContext {
//   FtViewModel<T, C>?
//       viewModel<T extends AbstractFtModel<C>, C extends AbstractCell>() =>
//           FlexTable.viewModelOf<T, C>(this);
// }

abstract class AbstractTableBuilder<C extends AbstractCell,
    M extends AbstractFtModel<C>> {
  AbstractTableBuilder();

  Widget? cellBuilder(
      BuildContext context,
      FtViewModel<C, M> viewModel,
      double tableScale,
      C cell,
      LayoutPanelIndex layoutPanelIndex,
      FtIndex tableCellIndex,
      CellStatus cellStatus,
      ValueKey? valueKey);

  Widget backgroundPanel(
    BuildContext context,
    int panelIndex,
    Widget? child,
  );

  Widget buildHeaderIndex(BuildContext context, M viewModel,
      TableHeaderIndex tableHeaderIndex, double scale);

  LineHeader lineHeader(FtViewModel<C, M> viewModel, int panelIndex);

  void finalPaintMainPanel(FtViewModel<C, M> viewModel, PaintingContext context,
      Offset offset, Size size);

  void firstPaintPanel(
    PaintingContext context,
    Offset offset,
    Size size,
    FtViewModel<C, M> viewModel,
    LayoutPanelIndex tableIndex,
    List<GridInfo> rowInfoList,
    List<GridInfo> columnInfoList,
  );

  void finalPaintPanel(
    PaintingContext context,
    Offset offset,
    Size size,
    FtViewModel<C, M> viewModel,
    LayoutPanelIndex tableIndex,
    List<GridInfo> rowInfoList,
    List<GridInfo> columnInfoList,
  );

  double get columnHeaderHeight => 20.0;

  double rowHeaderWidth(HeaderProperties headerProperty) =>
      (headerProperty.digits * 10.0 + 6.0);
}

class LineHeader {
  double width;
  Color color;

  LineHeader({
    this.width = 0.5,
    this.color = Colors.black87,
  });
}
