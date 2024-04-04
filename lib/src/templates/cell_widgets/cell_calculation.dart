import 'package:flutter/material.dart';
import '../../../flextable.dart';
import 'shared/validate_drawer.dart';

class CellCalculation extends StatelessWidget {
  const CellCalculation(
      {super.key,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.formatCellNumber,
      required this.useAccent,
      required this.viewModel});

  final double tableScale;
  final CalculationCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final FormatCellNumber formatCellNumber;
  final bool useAccent;
  final FtViewModel<AbstractCell, AbstractFtModel<AbstractCell>> viewModel;

  String formatValue(CalculationCell c) {
    if ((
      c.value,
      c.format,
    )
        case (num value, String format)) {
      return formatCellNumber(
        identifier: cell.identifier,
        format: format,
        value: value,
      );
    } else {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    NumberCellStyle? numberCellStyle;

    if (cell.style case NumberCellStyle style) {
      numberCellStyle = style;
    }

    if (!cell.evaluted) {
      viewModel.model.calculateCell(cell: cell, index: tableCellIndex);
    }

    Widget child = Text(
      formatValue(cell),
      textAlign: numberCellStyle?.textAlign,
      style: numberCellStyle?.textStyle,
      textScaler: const TextScaler.linear(1.0),
    );

    child = Container(
        padding: switch (numberCellStyle?.padding) {
          (EdgeInsets e) => e * 1.0,
          (_) => null
        },
        alignment: numberCellStyle?.alignment ?? Alignment.center,
        color: useAccent
            ? (numberCellStyle?.backgroundAccent ?? numberCellStyle?.background)
            : numberCellStyle?.background,
        child: child);

    child = ValidationDrawer(
      cell: cell,
      tableScale: 1.0,
      child: child,
    );

    return FtScaledCell(scale: tableScale, child: child);
  }
}
