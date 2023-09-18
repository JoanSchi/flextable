// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DataModelBasic {
  late AbstractFlexTableDataModel data;
  final int rows;
  final int columns;

  DataModelBasic.positions({this.rows = 500, this.columns = 200}) {
    data = FlexTableDataModel();
    final line = Line(width: 0.5, color: Colors.blue[900]!);

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        Map attr = {
          CellAttr.background: (r % 2 + c % 2) % 2 == 0
              ? const Color.fromARGB(255, 140, 191, 237)
              : Colors.white10,
        };
        data.addCell(
            row: r,
            column: c,
            cell: Cell(value: '${numberToCharacter(c)}$r', attr: attr));
      }
    }

    data.horizontalLineList.addLineRange(LineRange(
        startIndex: 0,
        endIndex: rows,
        lineNodeRange: LineNodeRange(list: [
          LineNode(startIndex: 1, endIndex: columns, before: line, after: line)
        ])));

    data.verticalLineList.addLineRange(LineRange(
        startIndex: 1,
        endIndex: rows,
        lineNodeRange: LineNodeRange(list: [
          LineNode(startIndex: 0, endIndex: rows, after: line, before: line)
        ])));
  }

  FlexTableModel makeTable(
      {double? xSplit,
      double? ySplit,
      scrollUnlockX = false,
      scrollUnlockY = false,
      List<AutoFreezeArea> autoFreezeAreasX = const [],
      List<AutoFreezeArea> autoFreezeAreasY = const []}) {
    var (tableScale, minTableScale, maxTableScale) =
        switch (defaultTargetPlatform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        (1.5, 1.0, 4.0),
      (_) => (1.0, 0.5, 3.0)
    };

    return FlexTableModel(
        stateSplitX: xSplit != null ? SplitState.split : SplitState.noSplit,
        stateSplitY: ySplit != null ? SplitState.split : SplitState.noSplit,
        xSplit: xSplit ?? 0.0,
        ySplit: ySplit ?? 0.0,
        // freezeColumns: 3, freezeRows: 23,
        columnHeader: true,
        rowHeader: true,
        scrollUnlockX: scrollUnlockX,
        scrollUnlockY: scrollUnlockY,
        defaultWidthCell: 90.0,
        defaultHeightCell: 30.0,
        maximumColumns: columns,
        maximumRows: rows,
        scale: tableScale,
        minTableScale: minTableScale,
        maxTableScale: maxTableScale,
        autoFreezeAreasX: autoFreezeAreasX,
        autoFreezeAreasY: autoFreezeAreasY,
        specificHeight: [
          RangeProperties(min: 9, max: 9, length: 100.0),
          RangeProperties(min: 10, max: 15, length: 50.0)
        ],
        dataTable: data);
  }
}

class BasicTableBuilder extends DefaultTableBuilder {
  @override
  Widget backgroundPanel(int panelIndex, BuildContext context, Widget? child) {
    if (panelIndex == 5 ||
        panelIndex == 6 ||
        panelIndex == 9 ||
        panelIndex == 10) {
      return Container(color: Colors.white, child: child);
    } else {
      return Container(
          color: const Color.fromARGB(255, 193, 225, 240), child: child);
    }
  }

  @override
  LineHeader lineHeader(
    FlexTableViewModel flexTableViewModel,
    int panelIndex,
  ) {
    return LineHeader(color: const Color.fromARGB(255, 38, 77, 95));
  }
}
