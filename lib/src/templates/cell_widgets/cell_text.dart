// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'shared/text_drawer.dart';

class CellTextWidget<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatelessWidget {
  const CellTextWidget(
      {super.key,
      required this.viewModel,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.cellStatus,
      required this.useAccent,
      required this.valueKey,
      required this.translation});
  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final TextCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final bool useAccent;
  final ValueKey? valueKey;
  final FtTranslation? translation;

  @override
  Widget build(BuildContext context) {
    if (cellStatus.edit && cell.editable) {
      return CellTextEditor(
        viewModel: viewModel,
        tableScale: tableScale,
        cell: cell,
        layoutPanelIndex: layoutPanelIndex,
        tableCellIndex: tableCellIndex,
        useAccent: useAccent,
      );
    } else {
      String text;
      if (cell.value case String v) {
        if ((cell.translate, translation) case (true, FtTranslation t)) {
          text = t(v);
        } else {
          text = '${cell.value}';
        }
      } else {
        text = '';
      }

      return TextDrawer(
        tableScale: tableScale,
        cell: cell,
        useAccent: useAccent,
        formatedValue: text,
      );
    }
  }
}

class CellTextEditor<M extends AbstractFtModel<C>, C extends AbstractCell>
    extends StatefulWidget {
  const CellTextEditor(
      {super.key,
      required this.viewModel,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.useAccent,
      this.valueKey});

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final Cell cell;

  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final bool useAccent;
  final ValueKey? valueKey;

  @override
  State<CellTextEditor> createState() => _CellTextEditorState();
}

class _CellTextEditorState extends State<CellTextEditor> {
  String value = '';
  FtTextEditInputType textEditInputType = FtTextEditInputType.text;

  @override
  void initState() {
    switch (widget.cell) {
      case (TextCell v):
        {
          value = v.value == null ? '' : '${v.value}';
          break;
        }
      default:
        {
          value = 'unknow';
        }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final cell = widget.cell;
    final nextFocus = viewModel
        .nextCell(
            PanelCellIndex.from(ftIndex: widget.tableCellIndex, cell: cell))
        .isIndex;

    TextCellStyle? textCellStyle;

    if (cell.style case NumberCellStyle style) {
      textCellStyle = style;
    }

    final valueKey = widget.valueKey;

    Widget child = Center(
        child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(widget.tableScale)),
      child: FtEditText(
        obtainSharedTextEditController: valueKey != null
            ? (String text) {
                return viewModel.sharedTextControllersByIndex
                    .obtainFromIndex(valueKey, text);
              }
            : null,
        removeSharedTextEditController: valueKey != null
            ? () {
                viewModel.sharedTextControllersByIndex.removeIndex(
                  valueKey,
                );
              }
            : null,
        editInputType: textEditInputType,
        text: value,
        requestFocus: viewModel.editCell.samePanel(widget.layoutPanelIndex),
        textAlign: TextAlign.center,
        requestNextFocus: nextFocus,
        requestNextFocusCallback: () {
          ///
          /// ViewModel can be rebuild and the old viewbuild is disposed!
          /// Get the latest viewModel and do again checks.
          ///
          ///

          if (nextFocus) {
            viewModel
              ..editCell = PanelCellIndex.from(
                  panelIndexX: widget.layoutPanelIndex.xIndex,
                  panelIndexY: widget.layoutPanelIndex.yIndex,
                  ftIndex: viewModel.nextCell(PanelCellIndex.from(
                      ftIndex: widget.tableCellIndex, cell: cell)))
              ..markNeedsLayout();
            return true;
          } else {
            viewModel
              ..clearEditCell(widget.tableCellIndex)
              ..markNeedsLayout();
            return false;
          }
        },
        focus: () {
          viewModel.updateCellPanel(widget.layoutPanelIndex);
        },
        unFocus: (UnfocusDisposition disposition) {
          if (disposition == UnfocusDisposition.scope) {
            viewModel
              ..clearEditCell(widget.tableCellIndex)
              ..markNeedsLayout();
          }
        },
        onValueChanged: onValueChange,
      ),
    ));
    child = Container(
        color: widget.useAccent
            ? (textCellStyle?.backgroundAccent ?? textCellStyle?.background)
            : textCellStyle?.background,
        child: child);

    return AutomaticKeepAlive(child: SelectionKeepAlive(child: child));
  }

  void onValueChange(String text) {
    final viewModel = widget.viewModel;

    if (!viewModel.mounted) {
      return;
    }

    switch (widget.cell) {
      case (TextCell v):
        {
          viewModel.model.updateCell(
              previousCell: widget.cell,
              cell: v.copyWith(value: text, valueCanBeNull: true),
              ftIndex: widget.tableCellIndex);
          break;
        }
      default:
        {}

        viewModel
          ..clearEditCell(widget.tableCellIndex)
          ..markNeedsLayout();
    }
  }
}
