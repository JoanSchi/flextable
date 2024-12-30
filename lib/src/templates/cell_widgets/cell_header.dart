import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeaderCellWidget extends StatelessWidget {
  const HeaderCellWidget(
      {super.key,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.cellStatus,
      required this.viewModel,
      required this.useAccent,
      this.translate});

  final double tableScale;
  final HeaderCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final FtViewModel viewModel;
  final bool useAccent;
  final FtTranslation? translate;

  @override
  Widget build(BuildContext context) {
    HeaderCellStyle? headerCellStyle = cell.themedStyle;

    Widget text = Container(
        padding: (headerCellStyle?.padding ?? EdgeInsets.zero),
        alignment: headerCellStyle?.alignment ?? Alignment.center,
        color: useAccent
            ? (headerCellStyle?.backgroundAccent ?? headerCellStyle?.background)
            : headerCellStyle?.background,
        child: RichText(
          text: TextSpan(
            text: switch ((cell.translate, translate)) {
              (true, FtTranslation t) => t(cell.text),
              (_, _) => cell.text
            },
            style: headerCellStyle?.textStyle,
          ),
          softWrap: true,
          textAlign: headerCellStyle?.textAlign ?? TextAlign.start,
        ));

    if (cell case SortHeaderCell sortCell) {
      var (isSorted, rotation) = switch (sortCell.sortAz) {
        (true) => (true, 0.0),
        (false) => (true, 1.0),
        (_) => (false, 0.0)
      };

      return PopupMenuButton<bool>(
          onOpened: () {
            viewModel.clearEditCell();
          },
          tooltip: '',
          // Callback that sets the selected popup menu item.
          onSelected: (a) {
            onValueChange(a, sortCell);
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem<bool>(
                  value: true,
                  child: Text(switch ((cell.translate, translate)) {
                    (true, FtTranslation t) => t('sortAZ'),
                    (_, _) => 'Sort A-Z'
                  })),
              PopupMenuItem<bool>(
                  value: false,
                  child: Text(switch ((cell.translate, translate)) {
                    (true, FtTranslation t) => t('sortZA'),
                    (_, _) => 'Sort Z-A'
                  }))
            ];
          },
          child: FtScaledCell(
              scale: tableScale,
              child: CustomPaint(
                foregroundPainter: _CustomTrianglePainter(
                    height: 8.0,
                    width: 12.0,
                    padding: 6.0,
                    isSorted: isSorted,
                    rotation: rotation,
                    color: headerCellStyle?.foreGroundColor ?? Colors.blueGrey),
                child: text,
              )));
    } else {
      return FtScaledCell(scale: tableScale, child: text);
    }
  }

  void onValueChange(bool? value, SortHeaderCell sortCell) {
    if (!viewModel.mounted) {
      return;
    }

    if (sortCell.sortAz != value) {
      final HeaderCell previousCell = sortCell;
      final HeaderCell newCell = sortCell.copyWith(
        sortAz: value,
      );

      viewModel.updateCell(
          previousCell: previousCell, cell: newCell, ftIndex: tableCellIndex);
    }
  }
}

class _CustomTrianglePainter extends CustomPainter {
  _CustomTrianglePainter({
    required this.width,
    required this.height,
    required this.padding,
    required this.rotation,
    required this.isSorted,
    required this.color,
  });

  final double width;
  final double height;
  final double padding;
  final double rotation;
  final bool isSorted;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final double w = size.width;

    if (isSorted) {
      final path = Path()
        ..moveTo(0.0, -height / 2.0)
        ..lineTo(-width / 2.0, height / 2.0)
        ..lineTo(width / 2.0, height / 2.0)
        ..close();

      canvas
        ..translate(w - padding - width / 2.0, padding + height / 2.0)
        ..rotate(math.pi * rotation)
        ..drawPath(path, paint);
    } else {
      for (int i = 0; i < 2; i++) {
        canvas.drawCircle(Offset(w - 8.0 - 4.0 * i, 8.0), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CustomTrianglePainter oldDelegate) {
    return oldDelegate.isSorted != isSorted ||
        oldDelegate.rotation != rotation ||
        oldDelegate.width != width ||
        oldDelegate.height != height ||
        oldDelegate.padding != padding;
  }
}
