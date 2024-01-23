import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class NotReadyCell extends StatelessWidget {
  const NotReadyCell({super.key, required this.cell, required this.tableScale});

  final double tableScale;
  final Cell cell;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 5.0) *
            tableScale,
        alignment: cell.attr[CellAttr.alignment] ?? Alignment.center,
        color: cell.attr[CellAttr.background],
        child: const Text('sync'));
  }
}
