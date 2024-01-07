// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/panels/panel_viewport.dart';
import 'package:flutter/material.dart';

import '../../../flextable.dart';

class SelectCell extends StatefulWidget {
  final FtViewModel viewModel;

  const SelectCell({super.key, required this.viewModel});

  @override
  State<SelectCell> createState() => _SelectCellState();
}

class _SelectCellState extends State<SelectCell> {
  Offset localPosition = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (TapDownDetails details) {
        localPosition = details.localPosition;
      },
      onTap: () {
        PanelCellIndex? index = widget.viewModel.findCell(localPosition);

        if (index != null && index.isPanel) {
          widget.viewModel
            ..editCell = index.copyWith(edit: true)
            ..markNeedsLayout();
        }
      },
    );
  }
}
