import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class ValidationDrawer extends StatelessWidget {
  const ValidationDrawer(
      {super.key,
      required this.cell,
      required this.child,
      required this.tableScale});

  final Cell cell;
  final Widget child;
  final double tableScale;

  @override
  Widget build(BuildContext context) {
    if (cell.validate.isEmpty) {
      return child;
    }
    ValidationCellStyle? style = cell.style?.validationCellStyle;
    if (style == null) {
      final theme = Theme.of(context);
      style = ValidationCellStyle(validationColor: theme.colorScheme.error);
    }
    return CustomPaint(
        foregroundPainter: ValidationPainter(cell.validate, style, tableScale),
        child: child);
  }
}

class ValidationPainter extends CustomPainter {
  ValidationPainter(this.validation, this.validationStyle, this.tableScale);

  final String validation;
  final ValidationCellStyle? validationStyle;
  final double tableScale;

  @override
  void paint(Canvas canvas, Size size) {
    final color = (validationStyle?.validationColor ??
        const Color.fromARGB(255, 206, 45, 9));

    canvas.drawCircle(
      const Offset(8.0, 8.0),
      4.0,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
