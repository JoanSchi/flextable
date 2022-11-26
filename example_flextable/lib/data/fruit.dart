import 'package:flextable/FlexTable/TableItems/Cells.dart';
import 'package:flextable/FlexTable/data_flexfable.dart';
import 'package:flextable/FlexTable/table_line.dart';
import 'package:flextable/FlexTable/table_model.dart';

import 'package:flutter/material.dart';

class Fruit {
  final dataTable = DataFlexTable();
  int endTableRows = 0;
  int endTableColumns = 0;
  final fruit = [
    [
      'Soort fruit',
      2015,
      2016,
      2017,
      2018,
      2019,
    ],
    [
      'Fruit open grond (totaal)',
      19770,
      20367,
      20463,
      20443,
      20382,
    ],
    [
      'Kleinfruit open grond (totaal)',
      1613,
      1627,
      1743,
      1868,
      1859,
    ],
    [
      'Blauwe bessen',
      737,
      777,
      832,
      934,
      949,
    ],
    [
      'Bramen open grond',
      36,
      28,
      38,
      43,
      42,
    ],
    [
      'Frambozen open grond',
      151,
      202,
      250,
      259,
      252,
    ],
    [
      'Rode bessen',
      258,
      263,
      283,
      311,
      324,
    ],
    [
      'Zwarte bessen',
      352,
      277,
      234,
      224,
      206,
    ],
    [
      'Overige kleinfruit',
      79,
      80,
      106,
      98,
      85,
    ],
    [
      'Pit- en steen-vruchten (totaal)',
      17947,
      18523,
      18496,
      18334,
      18295,
    ],
    [
      'Appelrassen (totaal)',
      7600,
      7342,
      6953,
      6598,
      6421,
    ],
    [
      'Elstar',
      '',
      '',
      '',
      2892,
      2852,
    ],
    [
      'Golden Delicious',
      '',
      '',
      '',
      212,
      204,
    ],
    [
      'Jonagold (incl. Jonagored)',
      '',
      '',
      '',
      1318,
      1203,
    ],
    [
      'Junami',
      '',
      '',
      '',
      340,
      333,
    ],
    [
      'Kanzi',
      '',
      '',
      '',
      435,
      402,
    ],
    [
      'Rode Boskoop (Goudreinette)',
      '',
      '',
      '',
      333,
      311,
    ],
    [
      'Overige appelrassen',
      '',
      '',
      '',
      1068,
      1117,
    ],
    [
      'Perenrassen (totaal)',
      9234,
      9451,
      9741,
      9970,
      10086,
    ],
    [
      'Beurré Alexandre Lucas',
      '',
      '',
      '',
      673,
      646,
    ],
    [
      'Conference',
      '',
      '',
      '',
      7513,
      7570,
    ],
    [
      'Doyenné du Comice',
      '',
      '',
      '',
      763,
      771,
    ],
    [
      'Overige perenrassen',
      '',
      '',
      '',
      1022,
      1098,
    ],
    [
      'Pruimen',
      259,
      253,
      259,
      261,
      275,
    ],
    [
      'Zoete kersen',
      508,
      534,
      544,
      546,
      529,
    ],
    [
      'Zure kersen',
      327,
      290,
      270,
      245,
      251,
    ],
    [
      'Overige pit- en steenvruchten',
      527,
      1187,
      728,
      715,
      733,
    ],
    [
      'Noten',
      61,
      61,
      67,
      70,
      69,
    ],
    [
      'Wijndruiven',
      148,
      155,
      157,
      171,
      160,
    ],
    [
      'Kleinfruit onder glas (totaal)',
      64,
      87,
      95,
      123,
      101,
    ],
    [
      'Bramen onder glas',
      '',
      '',
      29,
      31,
      32,
    ],
    [
      'Frambozen onder glas',
      '',
      '',
      32,
      26,
      30,
    ],
    [
      'Overige fruit onder glas',
      '',
      '',
      33,
      66,
      39,
    ],
  ];

  Fruit() {
    int row = 2;
    int column = 0;

    dataTable.addCell(
        row: 0,
        column: 0,
        columns: 5,
        cell: Cell(
            value:
                'Fruitteelt open grond en onder glas; \n teeltoppervlakte, soort fruit',
            attr: {
              'textStyle': TextStyle(
                  color: Colors.green[900],
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold),
              'textAlign': TextAlign.center,
            }));

    dataTable.addCell(
        row: 1,
        column: 1,
        columns: 4,
        cell: Cell(value: 'Perioden (ha/J)', attr: {
          'background': Colors.lime[500],
          'textStyle': const TextStyle(
              color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
          'textAlign': TextAlign.center
        }));

    for (var columns in fruit) {
      int tempColumn = column;

      for (var value in columns) {
        Map attr = {
          'background': Colors.lime[row == 2 ? 500 : (row % 2 == 0 ? 50 : 100)],
          if (tempColumn == 0) 'alignment': Alignment.centerLeft,
          if (row == 2)
            'textStyle': const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold),
        };
        dataTable.addCell(
            row: row, column: tempColumn, cell: Cell(value: value, attr: attr));

        tempColumn++;
      }
      row++;
    }

    endTableColumns = 5;

    if (endTableRows < row) endTableRows = row;

    final v = dataTable.verticalLineList;

    final secondverticalLine = v.createLineNodeList(
      lineNode: LineNode(
        bottom: Line(color: Colors.lime[100]!, width: 1.0),
      ),
      startLevelTwoIndex: 2,
    )
      ..addLineNode(
        lineNode: LineNode(
          bottom: Line(color: Colors.lime[500]!, width: 1.0),
          top: Line(color: Colors.lime[100]!, width: 1.0),
        ),
        startLevelTwoIndex: 3,
      )
      ..addLineNode(
          startLevelTwoIndex: row,
          lineNode: LineNode(top: Line(color: Colors.lime[500]!)));

    v.addList(
        startLevelOneIndex: 1,
        endLevelOneIndex: 4,
        lineList: secondverticalLine);

    final h = dataTable.horizontalLineList;

    h.addList(
        startLevelOneIndex: 2,
        lineList: h.createLineNodeList(
            lineNode:
                LineNode(right: Line(color: Colors.lime[100]!, width: 1.0)),
            startLevelTwoIndex: 0)
          ..addLineNode(
              startLevelTwoIndex: 5,
              lineNode:
                  LineNode(left: Line(color: Colors.lime[100]!, width: 1.0))));
  }

  TableModel makeTable(
      {TargetPlatform? platform, scrollLockX = true, scrollLockY = true}) {
    double minTableScale = 0.5;
    double maxTableScale = 3.0;
    double tableScale = 1.0;

    if (platform != null) {
      switch (platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          break;
        case TargetPlatform.macOS:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          minTableScale = 1.0;
          tableScale = 1.5;
          maxTableScale = 4.0;
          break;
      }
    }

    return TableModel(
        dataTable: dataTable,
        defaultWidthCell: 80.0,
        defaultHeightCell: 50.0,
        leftPanelMargin: 4.0,
        rightPanelMargin: 4.0,
        topPanelMargin: 4.0,
        bottomPanelMargin: 4.0,
        scale: tableScale,
        minTableScale: minTableScale,
        maxTableScale: maxTableScale,
        maximumRows: endTableRows,
        maximumColumns: endTableColumns,
        scrollLockX: scrollLockX,
        scrollLockY: scrollLockY,
        specificWidth: [
          PropertiesRange(min: 0, max: 0, length: 120.0)
        ],
        specificHeight: [
          PropertiesRange(min: 0, length: 60.0),
          PropertiesRange(min: 1, max: 2, length: 40.0)
        ]);
  }
}
