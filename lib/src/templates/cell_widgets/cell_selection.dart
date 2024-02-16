// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/model/view_model.dart';
import 'package:flutter/material.dart';
import '../builders/basic_table_builder.dart';
import 'shared/text_drawer.dart';

class CellSelectionWidget<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  const CellSelectionWidget({
    super.key,
    required this.viewModel,
    required this.tableScale,
    required this.cell,
    required this.layoutPanelIndex,
    required this.tableCellIndex,
    required this.cellStatus,
    required this.useAccent,
    this.translate,
  });
  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final SelectionCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final bool useAccent;
  final FtTranslation? translate;

  @override
  State<CellSelectionWidget> createState() => _CellSelectionWidgetState();
}

class _CellSelectionWidgetState extends State<CellSelectionWidget> {
  Object? selected;
  late SelectionCell cell;

  @override
  void initState() {
    selected = widget.cell.value;
    cell = widget.cell;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CellSelectionWidget oldWidget) {
    if (widget.cell != cell) {
      setState(() {
        cell = widget.cell;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  String translateItem(Object? object) {
    String text;
    if (object case Object v) {
      if ((cell.translate, widget.translate) case (true, FtTranslation t)) {
        text = t('$v');
      } else {
        text = '$v';
      }
    } else {
      text = '';
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Object>(
      tooltip: '',
      initialValue: cell.value,
      // Callback that sets the selected popup menu item.
      onSelected: (value) {
        widget.viewModel
          ..model.updateCell(
              previousCell: widget.cell,
              cell: cell.copyWith(value: value),
              ftIndex: widget.tableCellIndex)
          ..cellsToRemove.add(widget.tableCellIndex)
          ..markNeedsLayout();
      },
      itemBuilder: (BuildContext context) =>
          widget.cell.values.map<PopupMenuEntry<Object>>((value) {
        return PopupMenuItem<Object>(
            value: value, child: Text(translateItem(value)));
      }).toList(),
      child: TextDrawer(
        cell: cell,
        tableScale: widget.tableScale,
        useAccent: widget.useAccent,
        formatedValue: translateItem(cell.value),
      ),
    );
  }
}
