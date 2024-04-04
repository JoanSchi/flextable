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

  /// Translate Value saves the translation
  ///
  ///
  String translateValue() {
    String text;

    switch ((cell.value, cell.translate, cell.translation, widget.translate)) {
      case (Object v, true, null, FtTranslation t):
        {
          text = cell.translation = t('$v');
          break;
        }
      case (_, true, String translation, _):
        {
          text = translation;
          break;
        }
      case (Object v, false, _, _):
        {
          text = '$v';
          break;
        }
      default:
        {
          text = '';
        }
    }

    return text;
  }

  String translateItem(Object? object) {
    String text;

    switch ((object, cell.translate, widget.translate)) {
      case (Object object, true, FtTranslation t):
        {
          text = cell.translation = t('$object');
          break;
        }

      case (Object object, false, _):
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
              formatedValue: translateValue(),
            ))
        : PopupMenuButton<Object>(
            onOpened: () {
              widget.viewModel.clearEditCell();
            },
            tooltip: '',
            initialValue: cell.value,
            // Callback that sets the selected popup menu item.
            onSelected: (value) {
              widget.viewModel.updateCell(
                  previousCell: widget.cell,
                  cell: cell.copyWith(value: value),
                  ftIndex: widget.tableCellIndex);
            },
            itemBuilder: (BuildContext context) =>
                widget.cell.values.map<PopupMenuEntry<Object>>((value) {
                  return PopupMenuItem<Object>(
                      value: value, child: Text(translateItem(value)));
                }).toList(),
            child: FtScaledCell(
              scale: widget.tableScale,
              child: TextDrawer(
                cell: cell,
                tableScale: 1.0,
                useAccent: widget.useAccent,
                formatedValue: translateValue(),
              ),
            ));
  }
}
