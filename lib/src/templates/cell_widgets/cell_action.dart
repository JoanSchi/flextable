// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/templates/cell_widgets/shared/text_drawer.dart';
import 'package:flextable/src/templates/cells/advanced_cells.dart';
import 'package:flutter/material.dart';

import '../builders/basic_table_builder.dart';
import 'shared/background_drawer.dart';

typedef ActionCallBack<C extends AbstractCell, M extends AbstractFtModel<C>, A>
    = bool Function(
        FtViewModel<C, M> viewModel, ActionCell cell, FtIndex index, A action);

class CellActionWidget<C extends AbstractCell, M extends AbstractFtModel<C>, A>
    extends StatelessWidget {
  const CellActionWidget({
    super.key,
    required this.actionCallBack,
    required this.tableScale,
    required this.cell,
    required this.layoutPanelIndex,
    required this.tableCellIndex,
    required this.cellStatus,
    required this.viewModel,
    required this.useAccent,
    this.translate,
  });

  final ActionCallBack<C, M, A> actionCallBack;
  final double tableScale;
  final ActionCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final FtViewModel<C, M> viewModel;
  final bool useAccent;
  final FtTranslation? translate;

  String translateItem(Object? object) {
    String text;
    if (object case Object v) {
      if ((cell.translate, translate) case (true, FtTranslation t)) {
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
    return switch ((
      cell.value,
      cell.text,
    )) {
      (ActionCellItem<A> item, String? _) => BackgroundDrawer(
          style: cell.style,
          tableScale: tableScale,
          useAccent: useAccent,
          child: SizedBox.expand(
              child: IconButton(
            onPressed: () {
              actionCallBack(viewModel, cell, tableCellIndex, item.action);
            },
            icon: item.widget!,
          ))),
      (List<A> list, String? text) => PopupMenuButton<A>(
          tooltip: '',

          // Callback that sets the selected popup menu item.
          onSelected: (a) => actionCallBack(viewModel, cell, tableCellIndex, a),
          itemBuilder: (BuildContext context) => list.map<PopupMenuEntry<A>>(
                (A value) {
                  return PopupMenuItem<A>(
                      value: value, child: Text(translateItem(value)));
                },
              ).toList(),
          child: text != null
              ? TextDrawer(
                  cell: cell,
                  tableScale: tableScale,
                  formatedValue: translateItem(text),
                  useAccent: useAccent,
                )
              : null),
      (A a, String? text) => BackgroundDrawer(
          style: cell.style,
          tableScale: tableScale,
          useAccent: useAccent,
          child: SizedBox.expand(
              child: TextButton(
            onPressed: () {
              actionCallBack(viewModel, cell, tableCellIndex, a);
            },
            child: Text(translateItem(text ?? ':{'),
                style: cell.style?.textStyle,
                textScaler: TextScaler.linear(tableScale)),
          ))),
      (_) => const Center(child: Text(':('))
    };
  }
}
