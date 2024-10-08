// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/templates/cell_widgets/cell_calculation.dart';
import 'package:flutter/material.dart';
import '../cell_widgets/cell_date.dart';
import '../cell_widgets/cell_action.dart';
import '../cell_widgets/cell_number.dart';
import '../cell_widgets/cell_selection.dart';
import '../cell_widgets/cell_text.dart';

typedef CellWidgetBuilder<C extends AbstractCell, M extends AbstractFtModel<C>>
    = Widget? Function(
        {required FtViewModel<C, M> viewModel,
        required AbstractCell cell,
        required double tableScale,
        required LayoutPanelIndex layoutPanelIndex,
        required FtIndex tableCellIndex,
        required CellStatus cellStatus,
        required bool useAccent,
        ValueKey? valueKey});

typedef UseCellAccent<C extends AbstractCell, M extends AbstractFtModel<C>>
    = bool Function(
  FtViewModel<C, M> viewModel,
  AbstractCell cell,
  FtIndex tableCellIndex,
);

typedef FtTranslation = String Function(String value);

String _cellDateFormat(String format, DateTime dateTime) => '??dateFormat??';

bool _noAction<C, M extends AbstractFtModel<AbstractCell>, A>(
    viewModel, cell, index, action) {
  debugPrint(
      'Set the actionCallback in TableBuilder!, index: $index action: $action');
  return true;
}

String _formNumber({identifier, format, value, dif}) =>
    value == null ? '' : '$value';

class BasicTableBuilder<C extends AbstractCell, M extends AbstractFtModel<C>, A>
    extends AbstractTableBuilder<C, M> {
  BasicTableBuilder(
      {this.singleDigitWidth = 10.0,
      this.digitPadding = 3.0,
      this.columnHeaderHeight = 20.0,
      this.headerBackgroundColor,
      this.headerLineColor,
      this.headerTextStyle,
      FormatCellDate? formatCellDate,
      this.dateFormat = 'dd-MM-yy',
      ActionCallBack<C, M, A>? actionCallBack,
      FormatCellNumber? formatCellNumber,
      this.useCellAccent,
      this.cellWidgetBuilder,
      this.translation,
      this.showSplitLines = true})
      : formatCellDate = formatCellDate ?? _cellDateFormat,
        formatCellNumber = formatCellNumber ?? _formNumber,
        actionCallBack = actionCallBack ?? _noAction<C, M, A>;

  final double singleDigitWidth;
  final double digitPadding;
  @override
  final double columnHeaderHeight;
  final Color? headerBackgroundColor;
  final Color? headerLineColor;
  final TextStyle? headerTextStyle;
  final String dateFormat;
  final FormatCellDate formatCellDate;
  final ActionCallBack<C, M, A> actionCallBack;
  final FormatCellNumber formatCellNumber;
  CellWidgetBuilder<C, M>? cellWidgetBuilder;
  UseCellAccent<C, M>? useCellAccent;
  final FtTranslation? translation;
  final bool showSplitLines;

  @override
  Widget? cellBuilder(
    BuildContext context,
    FtViewModel<C, M> viewModel,
    double tableScale,
    C cell,
    LayoutPanelIndex layoutPanelIndex,
    FtIndex tableCellIndex,
    CellStatus cellStatus,
    ValueKey? valueKey,
  ) {
    final bool useAccent =
        useCellAccent?.call(viewModel, cell, tableCellIndex) ?? false;

    if (cellWidgetBuilder?.call(
      cell: cell,
      viewModel: viewModel,
      layoutPanelIndex: layoutPanelIndex,
      tableCellIndex: tableCellIndex,
      tableScale: tableScale,
      cellStatus: cellStatus,
      useAccent: useAccent,
      valueKey: valueKey,
    )
        case Widget w) {
      return w;
    }

    return switch (cell) {
      (DateTimeCell c) => CellDateWidget<C, M>(
          viewModel: viewModel,
          formatCellDate: formatCellDate,
          format: dateFormat,
          cell: c,
          cellStatus: cellStatus,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          tableScale: tableScale,
          useAccent: useAccent,
          valueKey: valueKey),
      (DecimalCell c) => CellNumberWidget<C, M>(
          viewModel: viewModel,
          cell: c,
          cellStatus: cellStatus,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          tableScale: tableScale,
          formatCellNumber: formatCellNumber,
          useAccent: useAccent,
          valueKey: valueKey,
        ),
      (DigitCell c) => CellNumberWidget<C, M>(
          viewModel: viewModel,
          cell: c,
          cellStatus: cellStatus,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          tableScale: tableScale,
          formatCellNumber: formatCellNumber,
          useAccent: useAccent,
          valueKey: valueKey,
        ),
      (TextCell c) => CellTextWidget<C, M>(
          viewModel: viewModel,
          cell: c,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          tableScale: tableScale,
          cellStatus: cellStatus,
          useAccent: useAccent,
          valueKey: valueKey,
          translation: translation,
        ),
      (SelectionCell c) => CellSelectionWidget<C, M>(
          viewModel: viewModel,
          cell: c,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          tableScale: tableScale,
          cellStatus: cellStatus,
          useAccent: useAccent,
          translate: translation,
        ),
      (ActionCell c) => CellActionWidget<C, M, A>(
          cell: c,
          viewModel: viewModel,
          actionCallBack: actionCallBack,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          tableScale: tableScale,
          cellStatus: cellStatus,
          useAccent: useAccent,
          translate: translation,
        ),
      (CalculationCell c) => CellCalculation(
          tableScale: tableScale,
          cell: c,
          layoutPanelIndex: layoutPanelIndex,
          tableCellIndex: tableCellIndex,
          formatCellNumber: formatCellNumber,
          useAccent: useAccent,
          viewModel: viewModel),
      (AbstractCell c) => switch (c) {
          (Cell c) => TextDrawer(
              cell: c,
              tableScale: tableScale,
              useAccent: useAccent,
            ),
          (_) => const Text(':(')
        }
    };
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
  Widget buildHeaderIndex(BuildContext context, AbstractFtModel viewModel,
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
  void finalPaintMainPanel(FtViewModel<C, M> viewModel, PaintingContext context,
      Offset offset, Size size) {
    if (!showSplitLines) {
      return;
    }
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
      FtViewModel<C, M> viewModel,
      LayoutPanelIndex tableIndex,
      List<GridInfo> rowInfoList,
      List<GridInfo> columnInfoList) {}

  @override
  void finalPaintPanel(
      PaintingContext context,
      Offset offset,
      Size size,
      FtViewModel<C, M> viewModel,
      LayoutPanelIndex tableIndex,
      List<GridInfo> rowInfoList,
      List<GridInfo> columnInfoList) {
    if ((viewModel.model.horizontalLines, viewModel.model.verticalLines)
        case (
          TableLinesOneDirection horizontalLines,
          TableLinesOneDirection verticalLines
        ) when !horizontalLines.isEmpty || !verticalLines.isEmpty) {
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
        lineList: horizontalLines,
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
        lineList: verticalLines,
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
}
