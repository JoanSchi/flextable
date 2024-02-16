import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class BackgroundDrawer extends StatelessWidget {
  const BackgroundDrawer({
    super.key,
    this.style,
    required this.tableScale,
    required this.useAccent,
    this.child,
  });

  final double tableScale;
  final bool useAccent;
  final CellStyle? style;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: (style?.padding ??
                const EdgeInsets.symmetric(vertical: 2.0, horizontal: 5.0)) *
            tableScale,
        alignment: style?.alignment ?? Alignment.center,
        color: useAccent
            ? (style?.backgroundAccent ?? style?.background)
            : style?.background,
        child: child);
  }
}
