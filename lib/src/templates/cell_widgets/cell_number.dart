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
      this.valueKey});

  final FtViewModel<C, M> viewModel;
  final double tableScale;
  final Cell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final FormatCellNumber formatCellNumber;
  final bool useAccent;
  final ValueKey? valueKey;

  @override
  State<_CellNumberEditor> createState() => _CellNumberEditorState();
}

class _CellNumberEditorState extends State<_CellNumberEditor> {
  String value = '';
  FtTextEditInputType textEditInputType = FtTextEditInputType.text;
  @override
  void initState() {
    switch (widget.cell) {
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
    final cell = widget.cell;
    final nextFocus = viewModel
        .nextCell(
            PanelCellIndex.from(ftIndex: widget.tableCellIndex, cell: cell))
        .isIndex;

    NumberCellStyle? numberCellStyle;
    FtTextEditInputType textEditInputType;

    switch (cell) {
      case (DigitCell c):
        {
          numberCellStyle = c.style;
          textEditInputType = FtTextEditInputType.digits;
          break;
        }
      case (DecimalCell c):
        {
          numberCellStyle = c.style;
          textEditInputType = FtTextEditInputType.decimal;
          break;
        }
      default:
        {
          textEditInputType = FtTextEditInputType.text;
        }
    }

    final valueKey = widget.valueKey;

    Widget child = Center(
        child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(widget.tableScale)),
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
        requestFocus: viewModel.editCell.samePanel(widget.layoutPanelIndex),
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
                  ftIndex: viewModel.nextCell(PanelCellIndex.from(
                      ftIndex: widget.tableCellIndex, cell: cell)))
              ..markNeedsLayout();

            onValueChange(text);
            return true;
          } else {
            /// Unfocus is called and unfocus will handel onValueChange
            ///
            viewModel
              ..clearEditCell(widget.tableCellIndex)
              ..markNeedsLayout();
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
              viewModel
                ..clearEditCell(widget.tableCellIndex)
                ..markNeedsLayout();
            }
          } else {
            if (!escape &&
                !viewModel.editCell.sameIndex(widget.tableCellIndex)) {
              onValueChange(value);
            }
            if (disposition == UnfocusDisposition.scope) {
              viewModel
                ..clearEditCell(widget.tableCellIndex)
                ..markNeedsLayout();
            }
          }
        },
        onValueChanged: onValueChange,
      ),
    ));
    child = Container(
        color: widget.useAccent
            ? (numberCellStyle?.backgroundAccent ?? numberCellStyle?.background)
            : numberCellStyle?.background,
        child: child);

    return AutomaticKeepAlive(child: SelectionKeepAlive(child: child));
  }

  void onValueChange(String text) {
    final viewModel = widget.viewModel;
    if (!widget.viewModel.mounted) {
      return;
    }

    switch (widget.cell) {
      case (DecimalCell v):
        {
          viewModel.updateCell(
              previousCell: widget.cell,
              cell: v.copyWith(
                  value: double.tryParse(text), valueCanBeNull: true),
              ftIndex: widget.tableCellIndex);
          break;
        }
      case (DigitCell v):
        {
          viewModel.updateCell(
              previousCell: widget.cell,
              cell: v.copyWith(value: int.tryParse(text), valueCanBeNull: true),
              ftIndex: widget.tableCellIndex);
          break;
        }

      default:
        {}
    }
  }
}

class _CellNumber extends StatelessWidget {
  const _CellNumber(
      {super.key,
      required this.tableScale,
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

  (String?, String?) decimalInputCellToString(DecimalCell decimalInputCell) {
    if ((
      decimalInputCell.value,
      decimalInputCell.format,
      decimalInputCell.exceeded
    )
        case (double value, String format, double? exceeded)) {
      return (
        formatCellNumber(
          identifier: cell.identifier,
          format: format,
          value: value,
        ),
        switch (exceeded) {
          (double v) when v.abs() > 0.1 && v.abs() < 1 => formatCellNumber(
              identifier: cell.identifier,
              format: '+0.0;-0.0',
              value: v,
              dif: true),
          (double v) => formatCellNumber(
              identifier: cell.identifier,
              format: '+#0;-#0',
              value: v,
              dif: true),
          (_) => null
        }
      );
    } else {
      return (null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    NumberCellStyle? numberCellStyle;

    if (cell.style case NumberCellStyle style) {
      numberCellStyle = style;
    }
    var (value, exceeded) = switch (cell) {
      (DecimalCell v) => decimalInputCellToString(v),
      (DigitCell v) => (
          v.value?.toString(),
          v.exceeded == null
              ? null
              : formatCellNumber(format: '+#0;-#0', value: v.exceeded!)
        ),
      (_) => (cell.value, null)
    };
    Widget child = Text(
      value ?? '',
      textAlign: numberCellStyle?.textAlign,
      style: numberCellStyle?.textStyle,
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

    if (exceeded != null) {
      child = Stack(
        children: [
          Positioned.fill(
            child: child,
          ),
          Positioned(
              left: 4.0 * tableScale,
              top: 0.0 * tableScale,
              child: Text(
                exceeded,
                textAlign: TextAlign.left,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10.0,
                    color: Color.fromARGB(255, 183, 156, 34)),
                textScaler: TextScaler.linear(tableScale),
              )),
        ],
      );
    }

    return ValidationDrawer(
      cell: cell,
      tableScale: tableScale,
      child: child,
    );
  }
}
