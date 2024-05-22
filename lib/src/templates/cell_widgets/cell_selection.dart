// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
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
  late SelectionCell cell;

  @override
  void initState() {
    cell = widget.cell;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CellSelectionWidget oldWidget) {
    cell = widget.cell;

    super.didUpdateWidget(oldWidget);
  }

  String valueToText(Object? value, SelectionCell cell) =>
      switch ((value, cell.translate, widget.translate)) {
        (Object object, true, FtTranslation t) => cell.translation =
            t('$object'),
        (Object object, false, _) => '$object',
        (_, _, _) => ''
      };

  String cellToText(SelectionCell cell) {
    String text;

    switch ((cell.values, cell.value, cell.translate, widget.translate)) {
      case (Map m, Object object, true, FtTranslation t):
        {
          text = cell.translation = t(m[object]);
          break;
        }

      case (Map m, Object object, false, _):
        {
          text = m[object];
          break;
        }
      case (_, Object object, true, FtTranslation t):
        {
          text = cell.translation = t('$object');
          break;
        }

      case (_, Object object, false, _):
        {
          text = '$object';
          break;
        }
      default:
        {
          text = '';
        }
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    return !cell.editable
        ? FtScaledCell(
            scale: widget.tableScale,
            child: TextDrawer(
                cell: cell,
                tableScale: 1.0,
                useAccent: widget.useAccent,
                formatedValue: cellToText(cell)))
        : PopupMenuButton<Object>(
            onOpened: () {
              widget.viewModel.clearEditCell();
            },
            tooltip: '',
            initialValue: cell.value,
            // Callback that sets the selected popup menu item.
            onSelected: (value) {
              final prevousCell = cell;
              cell = cell.copyWith(value: value);

              widget.viewModel.updateCell(
                  previousCell: prevousCell,
                  cell: cell,
                  ftIndex: widget.tableCellIndex);
            },
            itemBuilder: (BuildContext context) => switch (cell.values) {
                  (List l) => [
                      for (var v in l)
                        PopupMenuItem<Object>(
                            value: v, child: Text(valueToText(v, cell)))
                    ],
                  (Map m) => [
                      for (var MapEntry(key: id, value: v) in m.entries)
                        PopupMenuItem<Object>(
                            value: id, child: Text(valueToText(v, cell)))
                    ],
                  (_) => throw Exception('Values should be a list or a map')
                },
            child: FtScaledCell(
              scale: widget.tableScale,
              child: TextDrawer(
                cell: cell,
                tableScale: 1.0,
                useAccent: widget.useAccent,
                formatedValue: cellToText(cell),
              ),
            ));
  }
}
