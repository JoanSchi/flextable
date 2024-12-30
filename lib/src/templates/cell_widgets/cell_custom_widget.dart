import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class CustomCellWidget<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatelessWidget {
  const CustomCellWidget({
    super.key,
    required this.messageCallback,
    required this.tableScale,
    required this.cell,
    required this.layoutPanelIndex,
    required this.tableCellIndex,
    required this.cellStatus,
    required this.viewModel,
    required this.useAccent,
  });

  final MessageCallback<C, M> messageCallback;
  final double tableScale;
  final CustomCell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final CellStatus cellStatus;
  final FtViewModel<C, M> viewModel;
  final bool useAccent;

  @override
  Widget build(BuildContext context) {
    CellStyle? cellStyle = cell.themedStyle;

    Widget child = cell.valueToWidgets(cell, useAccent);

    child = Align(
        alignment: cellStyle?.alignment ?? Alignment.center, child: child);

    child = BackgroundDrawer(
        style: cellStyle,
        tableScale: 1.0,
        useAccent: useAccent,
        child: SizedBox.expand(
            child: TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          onPressed: () {
            viewModel.clearEditCell();
            messageCallback(
                viewModel,
                cell as C,
                PanelCellIndex.from(
                    panelIndexX: layoutPanelIndex.xIndex,
                    panelIndexY: layoutPanelIndex.yIndex,
                    ftIndex: tableCellIndex),
                null);
          },
          child: child,
        )));

    return FtScaledCell(
      scale: tableScale,
      child: child,
    );
  }
}
