// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class DataModelFruit {
  DefaultFtModel makeTable(
      {double tableScale = 1.0, scrollUnlockX = false, scrollUnlockY = false}) {
    int row = 2;
    int column = 0;

    final ftModel = DefaultFtModel(
        defaultWidthCell: 80.0,
        defaultHeightCell: 50.0,
        tableScale: tableScale,
        tableRows: 0,
        tableColumns: 0,
        scrollUnlockX: scrollUnlockX,
        scrollUnlockY: scrollUnlockY,
        specificWidth: [
          RangeProperties(min: 0, max: 0, length: 120.0)
        ],
        specificHeight: [
          RangeProperties(min: 0, length: 60.0),
          RangeProperties(min: 1, max: 2, length: 40.0)
        ]);

    ftModel.addCell(
        row: 0,
        column: 0,
        columns: 5,
        cell: Cell(
            value:
                'Fruitteelt open grond en onder glas; \n teeltoppervlakte, soort fruit',
            attr: {
              CellAttr.textStyle: TextStyle(
                  color: Colors.green[900],
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold),
            }));

    ftModel.addCell(
        row: 1,
        column: 1,
        columns: 4,
        cell: Cell(value: 'Perioden (ha/J)', attr: {
          CellAttr.background: Colors.lime[500],
          CellAttr.textStyle: const TextStyle(
              color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
        }));

    for (var columns in _fruit) {
      int tempColumn = column;

      for (var value in columns) {
        Map attr = {
          CellAttr.background:
              Colors.lime[row == 2 ? 500 : (row % 2 == 0 ? 50 : 100)],
          if (tempColumn == 0) CellAttr.alignment: Alignment.centerLeft,
          if (row == 2)
            CellAttr.textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.bold),
          if (tempColumn == 0) CellAttr.textAlign: TextAlign.left
        };
        ftModel.addCell(
            row: row, column: tempColumn, cell: Cell(value: value, attr: attr));

        tempColumn++;
      }
      row++;
    }

    int endTableRows = 0;
    int endTableColumns = 5;

    if (endTableRows < row) endTableRows = row;

    ftModel.verticalLines.addLineRange(LineRange(
        startIndex: 1,
        lineNodeRange: LineNodeRange(list: [
          LineNode(
            startIndex: 2,
            after: Line(color: Colors.lime[100]!, width: 1.0),
          ),
          LineNode(
            startIndex: 3,
            after: Line(color: Colors.lime[500]!, width: 1.0),
            before: Line(color: Colors.lime[100]!, width: 1.0),
          ),
          LineNode(
              startIndex: row,
              before: Line(color: Colors.lime[500]!, width: 0.5))
        ])));

    ftModel.horizontalLines.addLineRange(LineRange(
        startIndex: 2,
        lineNodeRange: LineNodeRange(list: [
          LineNode(
              startIndex: 0, after: Line(color: Colors.lime[100]!, width: 1.0)),
          LineNode(
              startIndex: 5, before: Line(color: Colors.lime[100]!, width: 1.0))
        ])));

    return ftModel
      ..autoFreezeAreasX = [
        AutoFreezeArea(startIndex: 0, freezeIndex: 1, endIndex: endTableColumns)
      ]
      ..autoFreezeAreasY = [
        AutoFreezeArea(startIndex: 2, freezeIndex: 3, endIndex: endTableRows)
      ];
  }
}

const _fruit = [
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