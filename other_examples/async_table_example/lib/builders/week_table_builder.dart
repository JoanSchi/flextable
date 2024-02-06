import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'not_ready_builder.dart';
import 'week_cell_builder.dart';
import 'week_cell_editor_builder.dart';

class TableWeekBuilder extends AbstractTableBuilder<AsyncAreaModel, Cell> {
  TableWeekBuilder(
      {this.singleDigitWidth = 10.0,
      this.digitPadding = 3.0,
      this.columnHeaderHeight = 20.0,
      this.headerBackgroundColor,
      this.headerLineColor,
      this.headerTextStyle});

  final double singleDigitWidth;
  final double digitPadding;
  @override
  final double columnHeaderHeight;
  final Color? headerBackgroundColor;
  final Color? headerLineColor;
  final TextStyle? headerTextStyle;

  @override
  Widget? cellBuilder(
    BuildContext context,
    FtViewModel<AsyncAreaModel, Cell> viewModel,
    double tableScale,
    Cell cell,
    LayoutPanelIndex layoutPanelIndex,
    FtIndex tableCellIndex,
    CellStatus cellStatus,
  ) {
    if (cell.cellState != FtCellState.ready) {
      return NotReadyCell(
        cell: cell,
        tableScale: tableScale,
      );
    } else if (cellStatus.edit) {
      return WeekCellEditorBuilder(
        tableScale: tableScale,
        cell: cell,
        layoutPanelIndex: layoutPanelIndex,
        tableCellIndex: tableCellIndex,
        requestFocus: cellStatus.hasFocus,
      );
    } else {
      return WeekCellBuilder(
        tableScale: tableScale,
        cell: cell,
        layoutPanelIndex: layoutPanelIndex,
        tableCellIndex: tableCellIndex,
      );
    }
  }

  @override
  double rowHeaderWidth(HeaderProperties headerProperty) =>
      (headerProperty.digits * singleDigitWidth + digitPadding * 2.0);

  @override
  Widget backgroundPanel(
    BuildContext context,
    int panelIndex,
    Widget? child,
  ) {
    //Background Headers:
    if (headerBackgroundColor != null &&
        (panelIndex <= 3 ||
            panelIndex >= 12 ||
            panelIndex % 4 == 0 ||
            panelIndex % 4 == 3)) {
      return Container(
        color: headerBackgroundColor,
        child: child,
      );
    }
    return child ?? const SizedBox();
  }

  @override
  Widget buildHeaderIndex(BuildContext context, AsyncAreaModel model,
      TableHeaderIndex tableHeaderIndex, double scale) {
    if (tableHeaderIndex.panelIndex <= 3 || tableHeaderIndex.panelIndex >= 12) {
      return Center(
          child: Text(
        '${tableHeaderIndex.index + 1}',
        textScaler: TextScaler.linear(scale),
        style: headerTextStyle,
      ));
    } else {
      return Center(
          child: Text(numberToCharacter(tableHeaderIndex.index),
              textScaler: TextScaler.linear(scale), style: headerTextStyle));
    }
  }

  @override
  LineHeader lineHeader(FtViewModel viewModel, int panelIndex) {
    //final tpli = viewModel.layoutIndex(panelIndex);

    return LineHeader(color: headerLineColor ?? Colors.blueGrey);
  }

  @override
  void finalPaintMainPanel(FtViewModel<AsyncAreaModel, Cell> viewModel,
      PaintingContext context, Offset offset, Size size) {
    if (viewModel.model.anySplitX || viewModel.model.anySplitY) {
      defaultDrawPaintSplit(
          viewModel: viewModel,
          context: context,
          offset: offset,
          size: size,
          freezeColors: const [
            Color(0xFF016baa),
            Color(0xFF015e96),
            Color(0xFF004d7c)
          ],
          splitColors: const [
            Color(0xFFE0E0E0),
            Color(0xFFD6D6D6),
            Color(0xFF9E9E9E)
          ]);
    }
  }

  @override
  void firstPaintPanel(
      PaintingContext context,
      Offset offset,
      Size size,
      FtViewModel<AsyncAreaModel, Cell> viewModel,
      LayoutPanelIndex tableIndex,
      List<GridInfo> rowInfoList,
      List<GridInfo> columnInfoList) {}

  @override
  void finalPaintPanel(
      PaintingContext context,
      Offset offset,
      Size size,
      FtViewModel<AsyncAreaModel, Cell> viewModel,
      LayoutPanelIndex tableIndex,
      List<GridInfo> rowInfoList,
      List<GridInfo> columnInfoList) {
    Canvas canvas = context.canvas;

    canvas.save();
    int debugPreviousCanvasSaveCount = 0;

    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());

    /// Painting lines
    ///
    ///
    ///
    if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);

    final scrollIndexX = tableIndex.scrollIndexX;
    final scrollIndexY = tableIndex.scrollIndexY;
    final xScroll = viewModel.getScrollX(scrollIndexX, scrollIndexY);
    final yScroll = viewModel.getScrollY(scrollIndexX, scrollIndexY);
    final tableScale = viewModel.tableScale;

    calculateLinePosition(
      canvas: canvas,
      size: size,
      tableIndex: tableIndex,
      scrollIndexX: scrollIndexX,
      scrollIndexY: scrollIndexY,
      xScroll: xScroll,
      yScroll: yScroll,
      tableScale: tableScale,
      lineList: viewModel.model.horizontalLines,
      horizontal: true,
      infoLevelOne: rowInfoList,
      infoLevelTwo: columnInfoList,
    );

    calculateLinePosition(
      canvas: canvas,
      size: size,
      tableIndex: tableIndex,
      scrollIndexX: scrollIndexX,
      scrollIndexY: scrollIndexY,
      xScroll: xScroll,
      yScroll: yScroll,
      tableScale: tableScale,
      lineList: viewModel.model.verticalLines,
      horizontal: false,
      infoLevelOne: columnInfoList,
      infoLevelTwo: rowInfoList,
    );

    /// Custom Painting?
    /// Keep it simple
    ///
    ///
    ///

    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }(), 'Previous canvas count is different from the current canvas count!');

    canvas.restore();
  }
}
