// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/templates/cell_widgets/shared/message_callback.dart';
import 'package:flutter/material.dart';

class CellActionWidget<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatelessWidget {
  const CellActionWidget({
    super.key,
    required this.messageCallback,
    required this.tableScale,
    required this.cell,
    required this.layoutPanelIndex,
    required this.tableCellIndex,
    required this.cellStatus,
    required this.viewModel,
    required this.useAccent,
    this.translate,
  });

  final MessageCallback<C, M> messageCallback;
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
    final items = cell.items;

    String? text =
        switch (cell.value) { (int o) => '$o', (String o) => o, (_) => null };

    return switch ((items, text, cell.themedStyle)) {
      (ActionCellItem item, Object? _, CellStyle? style) => FtScaledCell(
          scale: tableScale,
          child: BackgroundDrawer(
              style: cell.themedStyle,
              tableScale: 1.0,
              useAccent: useAccent,
              child: SizedBox.expand(
                  child: IconButton(
                color: style?.foreground,
                iconSize: 24.0 * 1.0,
                onPressed: () {
                  messageCallback(
                      viewModel, cell as C, tableCellIndex, item.action);
                },
                icon: item.widget!,
              )))),
      (List<ActionCellItem> items, Object? _, CellStyle? style) => FtScaledCell(
          scale: tableScale,
          child: BackgroundDrawer(
              style: cell.themedStyle,
              tableScale: 1.0,
              useAccent: useAccent,
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                for (var i in items)
                  IconButton(
                    color: style?.foreground,
                    iconSize: 24.0 * 1.0,
                    onPressed: () {
                      messageCallback(
                          viewModel, cell as C, tableCellIndex, i.action);
                    },
                    icon: i.widget!,
                  )
              ]))),
      (List list, String? text, CellStyle? _) => PopupMenuButton(
          onOpened: () {
            viewModel.clearEditCell();
          },
          tooltip: '',
          // Callback that sets the selected popup menu item.
          onSelected: (a) {
            messageCallback(viewModel, cell as C, tableCellIndex, a);
          },
          itemBuilder: (BuildContext context) => list.map<PopupMenuEntry>(
                (value) {
                  return PopupMenuItem(
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
      (Object a, String? text, TextCellStyle? style) => FtScaledCell(
          scale: tableScale,
          child: BackgroundDrawer(
              style: cell.themedStyle,
              tableScale: 1.0,
              useAccent: useAccent,
              child: SizedBox.expand(
                child: TextButton(
                    onPressed: () {
                      viewModel.clearEditCell();
                      messageCallback(viewModel, cell as C, tableCellIndex, a);
                    },
                    child: Text(
                      translateItem(text ?? ':{'),
                      style: style?.textStyle,
                    )),
              ))),
      (_) => const Center(child: Text(':('))
    };
  }
}
