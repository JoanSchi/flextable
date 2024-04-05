// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../../flextable.dart';

typedef SelectedCellCallback<C extends AbstractCell,
        M extends AbstractFtModel<C>>
    = bool Function(
        FtViewModel<C, M> viewModel, PanelCellIndex panelCellIndex, C? cell);

class SelectCell<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  final FtViewModel<C, M> viewModel;
  final SelectedCellCallback<C, M>? selectedCell;

  const SelectCell({super.key, required this.viewModel, this.selectedCell});

  @override
  State<SelectCell> createState() => _SelectCellState<C, M>();
}

class _SelectCellState<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends State<SelectCell<C, M>> {
  Offset localPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapDown: (TapDownDetails details) {
        localPosition = details.localPosition;
      },
      onTap: () {
        final viewModel = widget.viewModel;
        final indexAndCell = viewModel.findCell(localPosition);

        if (!(widget.selectedCell?.call(
                viewModel, indexAndCell.panelCellIndex, indexAndCell.cell) ??
            false)) {
          if (!viewModel.editCell.sameIndex(indexAndCell.panelCellIndex)) {
            final editable = viewModel.model
                .isCellEditable(indexAndCell.panelCellIndex)
                .ftIndex
                .isIndex;

            widget.viewModel
              ..editCell = editable
                  ? indexAndCell.panelCellIndex
                  : const PanelCellIndex()
              ..markNeedsLayout();
          }
        }
      },
    );
  }
}
