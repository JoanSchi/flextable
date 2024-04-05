// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../../flextable.dart';

typedef SelectedCellCallback = bool Function(
    FtViewModel viewModel, PanelCellIndex panelCellIndex, AbstractCell? cell);

class SelectCell extends StatefulWidget {
  final FtViewModel viewModel;
  final SelectedCellCallback? selectedCell;

  const SelectCell({super.key, required this.viewModel, this.selectedCell});

  @override
  State<SelectCell> createState() => _SelectCellState();
}

class _SelectCellState extends State<SelectCell> {
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
        final cellIndex = viewModel.findCell(localPosition);

        if (!(widget.selectedCell
                ?.call(viewModel, cellIndex.panelCellIndex, cellIndex.cell) ??
            false)) {
          if (!viewModel.editCell.sameIndex(cellIndex.panelCellIndex)) {
            final editable = viewModel.model
                .isCellEditable(cellIndex.panelCellIndex)
                .ftIndex
                .isIndex;

            widget.viewModel
              ..editCell =
                  editable ? cellIndex.panelCellIndex : const PanelCellIndex()
              ..markNeedsLayout();
          }
        }
      },
    );
  }
}
