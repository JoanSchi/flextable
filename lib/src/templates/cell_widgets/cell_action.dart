// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

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
    final value = cell.value;

    String? text = switch (cell.cellValue) {
      (int o) => '$o',
      (String o) => o,
      (_) => null
    };

    return switch ((value, text, cell.style)) {
      (ActionCellItem<A> item, Object? _, CellStyle? style) => FtScaledCell(
          scale: tableScale,
          child: BackgroundDrawer(
              style: cell.style,
              tableScale: 1.0,
              useAccent: useAccent,
              child: SizedBox.expand(
                  child: IconButton(
                color: style?.foreground,
                iconSize: 24.0 * 1.0,
                onPressed: () {
                  actionCallBack(viewModel, cell, tableCellIndex, item.action);
                },
                icon: item.widget!,
              )))),
      (List<ActionCellItem> items, Object? _, CellStyle? style) => FtScaledCell(
          scale: tableScale,
          child: BackgroundDrawer(
              style: cell.style,
              tableScale: 1.0,
              useAccent: useAccent,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (var i in items)
                  IconButton(
                    color: style?.foreground,
                    iconSize: 24.0 * 1.0,
                    onPressed: () {
                      actionCallBack(viewModel, cell, tableCellIndex, i.action);
                    },
                    icon: i.widget!,
                  )
              ]))),
      (List<A> list, String? text, CellStyle? _) => PopupMenuButton<A>(
          onOpened: () {
            viewModel.clearEditCell();
          },
          tooltip: '',
          // Callback that sets the selected popup menu item.
          onSelected: (a) {
            actionCallBack(viewModel, cell, tableCellIndex, a);
          },
          itemBuilder: (BuildContext context) => list.map<PopupMenuEntry<A>>(
                (A value) {
                  return PopupMenuItem<A>(
                      value: value, child: Text(translateItem(value)));
                },
              ).toList(),
          child: text != null
              ? FtScaledCell(
                  scale: tableScale,
                  child: TextDrawer(
                    cell: cell,
                    tableScale: 1.0,
                    formatedValue: translateItem(text),
                    useAccent: useAccent,
                  ))
              : null),
      (A a, String? text, TextCellStyle? style) => FtScaledCell(
          scale: tableScale,
          child: BackgroundDrawer(
              style: cell.style,
              tableScale: 1.0,
              useAccent: useAccent,
              child: SizedBox.expand(
                child: TextButton(
                    onPressed: () {
                      viewModel.clearEditCell();
                      actionCallBack(viewModel, cell, tableCellIndex, a);
                    },
                    child: Text(translateItem(text ?? ':{'),
                        style: style?.textStyle,
                        textScaler: const TextScaler.linear(1.0))),
              ))),
      (_) => const Center(child: Text(':('))
    };
  }
}
