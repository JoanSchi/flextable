import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/advanced_cells.dart';
import 'dart:math' as math;

class WeekCellBuilder extends StatelessWidget {
  const WeekCellBuilder(
      {super.key,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex});

  final double tableScale;
  final Cell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;

  (String?, String?) decimalInputCellToString(
      DecimalInputCell decimalInputCell) {
    final numberFormat = NumberFormat(decimalInputCell.format);

    if ((decimalInputCell.value, decimalInputCell.exceeded)
        case (double value, double? exceeded)) {
      return (
        numberFormat.format(value),
        switch (exceeded) {
                  (double v) when v.abs() > 0.1 && v.abs() < 1 =>
                    NumberFormat('+0.0;-0.0'),
                  (double _) => NumberFormat('+#0;-#0'),
                  (_) => null
                } !=
                null
            ? numberFormat.format(exceeded)
            : null
      );
    } else {
      return (null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    var (value, exceeded) = switch (cell) {
      (DecimalInputCell v) => decimalInputCellToString(v),
      (DigitInputCell v) => (
          v.value?.toString(),
          v.exceeded == null ? null : NumberFormat('+#0;-#0').format(v.exceeded)
        ),
      (_) => (cell.value, null)
    };
    Widget child = Text(
      value ?? '',
      textAlign: cell.attr[CellAttr.textAlign],
      style: cell.attr[CellAttr.textStyle],
      textScaler: TextScaler.linear(tableScale),
    );

    if (cell.attr.containsKey(CellAttr.rotate)) {
      child = TableTextRotate(
          angle: math.pi * 2.0 / 360 * cell.attr[CellAttr.rotate],
          child: child);
    }

    child = Container(
        padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0) *
            tableScale,
        alignment: cell.attr[CellAttr.alignment] ?? Alignment.center,
        color: cell.attr[CellAttr.background],
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

    if (cell.attr.containsKey(CellAttr.percentagBackground)) {
      final pbg =
          cell.attr[CellAttr.percentagBackground] as PercentageBackground;
      child = CustomPaint(
        painter: PercentagePainter(pbg),
        child: child,
      );
    } else {
      child = child;
    }
    return child;
  }
}
