// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../../flextable.dart';

typedef SelectedCellCallback<C extends AbstractCell,
        M extends AbstractFtModel<C>>
    = bool Function(
        FtViewModel<C, M> viewModel, PanelCellIndex panelCellIndex, C? cell);

typedef IgnoreCellCallback<C extends AbstractCell, M extends AbstractFtModel<C>>
    = bool Function(
        FtViewModel<C, M> viewModel, PanelCellIndex panelCellIndex, C? cell);

class SelectCell<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  final FtViewModel<C, M> viewModel;
  final SelectedCellCallback<C, M>? selectedCell;
  final IgnoreCellCallback<C, M>? ignoreCell;

  const SelectCell(
      {super.key, required this.viewModel, this.selectedCell, this.ignoreCell});

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

        edit() {
          if (!viewModel.currentEditCell
              .sameIndex(indexAndCell.panelCellIndex)) {
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

        if (widget.ignoreCell case SelectedCellCallback<C, M> ig) {
          if ((ig(viewModel, indexAndCell.panelCellIndex, indexAndCell.cell))) {
            widget.selectedCell?.call(
                viewModel, indexAndCell.panelCellIndex, indexAndCell.cell);
          } else {
            edit();
          }
        } else {
          if (!(widget.selectedCell?.call(
                  viewModel, indexAndCell.panelCellIndex, indexAndCell.cell) ??
              false)) {
            edit();
          }
        }
      },
    );
  }
}
