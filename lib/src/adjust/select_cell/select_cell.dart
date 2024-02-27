// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import '../../../flextable.dart';

class SelectCell extends StatefulWidget {
  final FtViewModel viewModel;
  const SelectCell({
    super.key,
    required this.viewModel,
  });

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
        final foundPanelCellIndex = viewModel.findCell(localPosition);

        if (!viewModel.editCell.sameIndex(foundPanelCellIndex)) {
          final editable =
              viewModel.model.isCellEditable(foundPanelCellIndex).isIndex;

          widget.viewModel
            ..editCell = editable ? foundPanelCellIndex : const PanelCellIndex()
            ..markNeedsLayout();
        }
      },
    );
  }
}
