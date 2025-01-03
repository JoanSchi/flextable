// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'shared/validate_drawer.dart';

typedef FormatCellNumber = String Function(
    {dynamic identifier, String? format, num? value, bool? dif});

class CellNumberWidget<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatelessWidget {
  const CellNumberWidget(
      {super.key,
      required this.viewModel,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.cellStatus,
      required this.formatCellNumber,
      required this.useAccent,
      this.valueKey});

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final Cell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final FormatCellNumber formatCellNumber;
  final bool useAccent;
  final ValueKey? valueKey;

  @override
  Widget build(BuildContext context) {
    return cellStatus.edit && cell.editable
        ? _CellNumberEditor(
            viewModel: viewModel,
            tableScale: tableScale,
            cell: cell,
            requestFocus: cellStatus.hasFocus,
            layoutPanelIndex: layoutPanelIndex,
            tableCellIndex: tableCellIndex,
            formatCellNumber: formatCellNumber,
            useAccent: useAccent,
            valueKey: valueKey)
        : _CellNumber(
            tableScale: tableScale,
            cell: cell,
            layoutPanelIndex: layoutPanelIndex,
            tableCellIndex: tableCellIndex,
            formatCellNumber: formatCellNumber,
            useAccent: useAccent,
          );
  }
}

class _CellNumberEditor<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  const _CellNumberEditor(
      {super.key,
      required this.viewModel,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.formatCellNumber,
      required this.useAccent,
      required this.requestFocus,
      this.valueKey});

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final Cell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final FormatCellNumber formatCellNumber;
  final bool useAccent;
  final ValueKey? valueKey;
  final bool requestFocus;

  @override
  State<_CellNumberEditor> createState() => _CellNumberEditorState();
}

class _CellNumberEditorState extends State<_CellNumberEditor> {
  String value = '';
  FtTextEditInputType textEditInputType = FtTextEditInputType.text;
  late Cell cell;
  @override
  void initState() {
    cell = widget.cell;

    switch (cell) {
      case (DecimalCell v):
        {
          value = v.value == null
              ? ''
              : widget.formatCellNumber(value: v.value, format: v.format);
          textEditInputType = FtTextEditInputType.decimal;
          break;
        }
      case (DigitCell v):
        {
          value = v.value == null ? '' : '${v.value}';
          textEditInputType = FtTextEditInputType.decimal;
          break;
        }
      case (Cell v):
        {
          value = v.value == null ? '' : '$v.value';
          break;
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

    NumberCellStyle? numberCellStyle;
    FtTextEditInputType textEditInputType;

    switch (cell) {
      case (DigitCell c):
        {
          numberCellStyle = c.themedStyle;
          textEditInputType = FtTextEditInputType.digits;
          break;
        }
      case (DecimalCell c):
        {
          numberCellStyle = c.themedStyle;
          textEditInputType = FtTextEditInputType.decimal;
          break;
        }
      default:
        {
          textEditInputType = FtTextEditInputType.text;
        }
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
          ? (value) {
              return viewModel.sharedTextControllersByIndex
                  .obtainFromIndex(valueKey, value);
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
          /// Unfocus is called and unfocus will handel onValueChange
          ///
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
          if (!escape &&
              !viewModel.currentEditCell.sameIndex(widget.tableCellIndex)) {
            onValueChange(value);
          }
          if (disposition == UnfocusDisposition.scope) {
            viewModel.clearEditCell(cellIndex: widget.tableCellIndex);
          }
        }
      },
      // onValueChanged: onValueChange,
    ));
    child = Container(
        color: widget.useAccent
            ? (numberCellStyle?.backgroundAccent ?? numberCellStyle?.background)
            : numberCellStyle?.background,
        child: child);
    child = FtScaledCell(scale: widget.tableScale, child: child);
    return AutomaticKeepAlive(child: SelectionKeepAlive(child: child));
  }

  void onValueChange(String text) {
    final viewModel = widget.viewModel;
    if (!widget.viewModel.mounted) {
      return;
    }

    switch (cell) {
      case (DecimalCell c):
        {
          if (double.tryParse(text) case double? v when c.value != v) {
            final previousCell = cell;
            cell = c.copyWith(value: v, valueCanBeNull: true);

            viewModel.updateCell(
                previousCell: previousCell,
                cell: cell,
                ftIndex: widget.tableCellIndex);
          }
          break;
        }
      case (DigitCell c):
        {
          if (int.tryParse(text) case int? v when c.value != v) {
            final previousCell = cell;
            cell = c.copyWith(value: v, valueCanBeNull: true);
            viewModel.updateCell(
                previousCell: previousCell,
                cell: cell,
                ftIndex: widget.tableCellIndex);
          }
          break;
        }

      default:
        {}
    }
  }
}

class _CellNumber extends StatelessWidget {
  const _CellNumber(
      {required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.formatCellNumber,
      required this.useAccent});

  final double tableScale;
  final Cell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final FormatCellNumber formatCellNumber;
  final bool useAccent;

  @override
  Widget build(BuildContext context) {
    NumberCellStyle? numberCellStyle;

    if (cell.themedStyle case NumberCellStyle style) {
      numberCellStyle = style;
    }
    String value = switch (cell) {
      (DecimalCell(value: null)) => '',
      (DecimalCell(
        identifier: dynamic id,
        format: String format,
        value: double? v
      )) =>
        formatCellNumber(
          identifier: id,
          format: format,
          value: v,
        ),
      (DigitCell(value: null)) => '',
      (DigitCell(value: int v)) => '$v',
      (_) => '${cell.value}'
    };
    Widget child = RichText(
      text: TextSpan(
        text: value,
        style: numberCellStyle?.textStyle,
      ),
      textAlign: numberCellStyle?.textAlign ?? TextAlign.start,
      textScaler: TextScaler.linear(tableScale),
    );

    if (numberCellStyle?.rotation case double rotation) {
      child =
          TableTextRotate(angle: math.pi * 2.0 / 360 * rotation, child: child);
    }

    child = Container(
        padding: switch (numberCellStyle?.padding) {
          (EdgeInsets e) => e * tableScale,
          (_) => null
        },
        alignment: numberCellStyle?.alignment ?? Alignment.center,
        color: useAccent
            ? (numberCellStyle?.backgroundAccent ?? numberCellStyle?.background)
            : numberCellStyle?.background,
        child: child);

    return ValidationDrawer(
      cell: cell,
      tableScale: tableScale,
      child: child,
    );
  }
}
