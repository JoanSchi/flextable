import 'package:flextable/src/templates/cells/advanced_cells.dart';
import 'package:flutter/material.dart';

import '../../../flextable.dart';
import 'cell_number.dart';
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
        case (double value, String format)) {
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
      textScaler: TextScaler.linear(tableScale),
    );

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
