// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
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
        requestFocus: cellStatus.hasFocus,
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

      return FtScaledCell(
          scale: tableScale,
          child: TextDrawer(
            tableScale: 1.0,
            cell: cell,
            useAccent: useAccent,
            formatedValue: text,
          ));
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
      required this.requestFocus,
      this.valueKey});

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final Cell cell;

  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final bool useAccent;
  final ValueKey? valueKey;
  final bool requestFocus;

  @override
  State<CellTextEditor> createState() => _CellTextEditorState();
}

class _CellTextEditorState extends State<CellTextEditor> {
  String value = '';
  FtTextEditInputType textEditInputType = FtTextEditInputType.text;
  late Cell cell;

  @override
  void initState() {
    cell = widget.cell;
    switch (cell) {
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

    final nextFocus = viewModel
        .nextCell(
            PanelCellIndex.from(ftIndex: widget.tableCellIndex, cell: cell))
        .ftIndex
        .isIndex;

    TextCellStyle? textCellStyle;

    if (cell.style case TextCellStyle style) {
      textCellStyle = style;
    }

    final valueKey = widget.valueKey;

    /// Without resizer:
    ///        MediaQuery(
    ///     data: MediaQuery.of(context)
    ///         .copyWith(textScaler: TextScaler.linear(widget.tableScale)),child:...
    /// }

    Widget child = Center(
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
      requestFocus: widget.requestFocus,
      textAlign: TextAlign.center,
      requestNextFocus: true,
      requestNextFocusCallback: (String text) {
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
                ftIndex: viewModel
                    .nextCell(PanelCellIndex.from(
                        ftIndex: widget.tableCellIndex, cell: cell))
                    .ftIndex)
            ..markNeedsLayout();

          onValueChange(text);
          return true;
        } else {
          viewModel.clearEditCell(cellIndex: widget.tableCellIndex);
          return false;
        }
      },
      focus: () {
        viewModel.updateCellPanel(widget.layoutPanelIndex);
      },
      unFocus: (UnfocusDisposition disposition, String value, bool escape) {
        if (kIsWeb) {
          if (!escape) {
            onValueChange(value);
          }
          if (disposition == UnfocusDisposition.scope) {
            viewModel.clearEditCell(cellIndex: widget.tableCellIndex);
          }
        } else {
          if (!escape && !viewModel.editCell.sameIndex(widget.tableCellIndex)) {
            onValueChange(value);
          }
          if (disposition == UnfocusDisposition.scope) {
            viewModel.clearEditCell(cellIndex: widget.tableCellIndex);
          }
        }
      },
      onValueChanged: onValueChange,
    ));
    child = Container(
        color: widget.useAccent
            ? (textCellStyle?.backgroundAccent ?? textCellStyle?.background)
            : textCellStyle?.background,
        child: child);
    child = FtScaledCell(scale: widget.tableScale, child: child);
    return AutomaticKeepAlive(child: SelectionKeepAlive(child: child));
  }

  void onValueChange(String text) {
    final viewModel = widget.viewModel;

    if (!viewModel.mounted) {
      return;
    }

    switch (cell) {
      case (TextCell c):
        {
          if (cell.value != text) {
            final previousCell = cell;
            cell = c.copyWith(value: text, valueCanBeNull: true);
            viewModel.updateCell(
                previousCell: previousCell,
                cell: cell,
                ftIndex: widget.tableCellIndex);
            break;
          }
        }
      default:
        {}
    }
  }
}
