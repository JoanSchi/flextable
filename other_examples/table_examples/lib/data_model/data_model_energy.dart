// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class DataModelEngery {
  static DefaultFtModel makeTable({double tableScale = 1.0}) {
    int dataRows = _data.length;
    int endTableColumn = _data[0].length + 2; // 2 rowHeader columns
    int endTableRow = dataRows + _columnHeader.length;

    final ftModel = DefaultFtModel(
        defaultHeightCell: 30,
        defaultWidthCell: 120,
        tableScale: tableScale,
        autoFreezeX: false,
        autoFreezeAreasX: [
          AutoFreezeArea(
              startIndex: 0, freezeIndex: 2, endIndex: endTableColumn)
        ],
        autoFreezeY: false,
        autoFreezeAreasY: [
          AutoFreezeArea(startIndex: 0, freezeIndex: 3, endIndex: endTableRow)
        ],
        specificWidth: [
          RangeProperties(start: 0, size: 40.0),
          RangeProperties(start: 1, size: 210.0),
          RangeProperties(start: 2, size: 150.0),
          RangeProperties(start: 8, size: 150.0),
          RangeProperties(start: endTableColumn, size: 2.0)
        ],
        specificHeight: [
          RangeProperties(start: 2, size: 55.0),
        ],
        tableColumns: endTableColumn,
        tableRows: endTableRow);

    int row = 0;
    int column = 0;

    for (List<_Item> rowItems in _columnHeader) {
      int columnTemp = column + 2;
      for (_Item item in rowItems) {
        ftModel.updateCell(
            ftIndex: FtIndex(row: row, column: columnTemp),
            cell: Cell(
                value: item.value,
                attr: {CellAttr.background: Colors.grey[50]!}),
            columns: item.length);
        columnTemp += item.length;
      }
      row++;
    }

    int rowTemp = row;

    for (var item in _rowHeader1) {
      ftModel.updateCell(
          ftIndex: FtIndex(row: rowTemp, column: column),
          cell: Cell(value: item.value, attr: {
            CellAttr.background: Colors.blueGrey[50]!,
            CellAttr.rotate: -90
          }),
          rows: item.length);
      rowTemp += item.length;
    }

    column++;
    rowTemp = row;

    for (String value in _rowHeader2) {
      ftModel.updateCell(
        ftIndex: FtIndex(row: rowTemp, column: column),
        cell: Cell(
          value: value,
          attr: {
            CellAttr.background: Colors.blueGrey[50]!,
            CellAttr.alignment: Alignment.centerLeft
          },
        ),
      );
      rowTemp++;
    }

    column++;

    for (int r = 0; r < dataRows; r++) {
      int dataColumns = _data[r].length;

      for (int c = 0; c < dataColumns; c++) {
        var value = _data[r][c];
        Map attr = {};
        if (c == 3 && value is num) {
          attr[CellAttr.percentagBackground] = PercentageBackground(
              colors: [Colors.lime[500]!, Colors.lime[50]!],
              ratio: value / 100.0);
        } else if (c == 9 && value is num) {
          attr[CellAttr.percentagBackground] = PercentageBackground(
              colors: [Colors.amber[500]!, Colors.amber[50]!],
              ratio: value / 100.0);
        }

        ftModel.updateCell(
            ftIndex: FtIndex(row: r + row, column: c + column),
            cell: Cell(value: value, attr: attr));
      }
    }

    double lineWidth = 1.0;
    Color lineColor = Colors.blueGrey[200]!;

    ftModel.horizontalLines.addLineRanges((create) {
      final linesHeader = [
        LineNode(
            startIndex: 2,
            before: const Line.no(),
            after: Line(width: lineWidth, color: lineColor)),
        LineNode(
            startIndex: endTableColumn,
            before: Line(width: lineWidth, color: lineColor),
            after: const Line.no())
      ];

      create(LineRange(
          startIndex: 0,
          endIndex: 2,
          lineNodeRange: LineNodeRange(list: linesHeader)));

      for (int i in [3, 16, 29]) {
        create(LineRange(
            startIndex: i,
            lineNodeRange: LineNodeRange(list: [
              LineNode(
                  startIndex: 0,
                  before: const Line.no(),
                  after: Line(width: lineWidth, color: lineColor)),
              LineNode(
                  startIndex: endTableColumn,
                  before: Line(width: lineWidth, color: lineColor),
                  after: const Line.no())
            ])));
      }
    });

    return ftModel;
  }
}

class _Item {
  final dynamic value;
  final int length;

  const _Item({
    required this.value,
    this.length = 1,
  });
}

const _rowHeader1 = [
  _Item(value: 'Totaal centrale/decentrale productie', length: 13),
  _Item(value: 'Centrale elektriciteitsproductie', length: 13),
  _Item(value: 'Decentrale elektriciteitsproductie', length: 13),
];

const _rowHeader2 = [
  'Totaal energiedragers',
  'Totaal fossiele brandstoffen',
  'Aardgas',
  'Steenkool',
  'Stookolie',
  'Overige fossiele brandstoffen',
  'Totaal hernieuwbare energie',
  'Zonnestroom',
  'Windenergie',
  'Waterkracht',
  'Biomassa',
  'Kernenergie',
  'Overige energiedragers',
  'Totaal energiedragers',
  'Totaal fossiele brandstoffen',
  'Aardgas',
  'Steenkool',
  'Stookolie',
  'Overige fossiele brandstoffen',
  'Totaal hernieuwbare energie',
  'Zonnestroom',
  'Windenergie',
  'Waterkracht',
  'Biomassa',
  'Kernenergie',
  'Overige energiedragers',
  'Totaal energiedragers',
  'Totaal fossiele brandstoffen',
  'Aardgas',
  'Steenkool',
  'Stookolie',
  'Overige fossiele brandstoffen',
  'Totaal hernieuwbare energie',
  'Zonnestroom',
  'Windenergie',
  'Waterkracht',
  'Biomassa',
  'Kernenergie',
  'Overige energiedragers',
];

const _columnHeader = [
  [_Item(value: ' 2018', length: 6), _Item(value: ' 2019', length: 6)],
  [
    _Item(value: 'Elektriciteit en warmte', length: 1),
    _Item(value: 'Elektriciteit', length: 5),
    _Item(value: 'Elektriciteit en warmte', length: 1),
    _Item(value: 'Elektriciteit', length: 5)
  ],
  [
    _Item(value: 'Totaal elektriciteit en warmte (TJ)', length: 1),
    _Item(value: 'Elektriciteit (MWh)', length: 1),
    _Item(value: 'Elektriciteit (TJ)', length: 1),
    _Item(value: 'Elektriciteit (%)', length: 1),
    _Item(value: 'Warmte (TJ)', length: 2),
    _Item(value: 'Totaal elektriciteit en warmte (TJ)', length: 1),
    _Item(value: 'Elektriciteit (MWh)', length: 1),
    _Item(value: 'Elektriciteit (TJ)', length: 1),
    _Item(value: 'Elektriciteit (%)', length: 1),
    _Item(value: 'Warmte (TJ)', length: 2)
  ]
];

const _data = [
  [
    '581708',
    114102849,
    410770,
    100,
    170938,
    888146,
    610012,
    121061552,
    435822,
    100,
    174191,
    903621,
  ],
  [
    '466143',
    88937599,
    320175,
    77.9,
    145968,
    738226,
    476772,
    91914741,
    330893,
    75.9,
    145878,
    738622,
  ],
  [
    '341078',
    57348843,
    206456,
    50.3,
    134622,
    474657,
    387128,
    70438236,
    253578,
    58.2,
    133550,
    548826,
  ],
  [
    '101212',
    27469763,
    98891,
    24.1,
    2321,
    222053,
    66484,
    17714968,
    63774,
    14.6,
    2710,
    146631,
  ],
  [
    '243',
    41221,
    148,
    0,
    95,
    500,
    343,
    74367,
    268,
    0.1,
    76,
    788,
  ],
  [
    '23610',
    4077772,
    14680,
    3.6,
    8930,
    41015,
    22816,
    3687170,
    13274,
    3,
    9542,
    42376,
  ],
  [
    '85404',
    18901501,
    68045,
    16.6,
    17358,
    72001,
    102571,
    22732352,
    81836,
    18.8,
    20735,
    85255,
  ],
  [
    '13354',
    3709364,
    13354,
    3.3,
    '',
    '',
    19210,
    5336055,
    19210,
    4.4,
    '',
    '',
  ],
  [
    '37975',
    10548511,
    37975,
    9.2,
    '',
    '',
    41429,
    11507927,
    41429,
    9.5,
    '',
    '',
  ],
  [
    '260',
    72348,
    260,
    0.1,
    '',
    '',
    267,
    74182,
    267,
    0.1,
    '',
    '',
  ],
  [
    '33815',
    4571278,
    16457,
    4,
    17358,
    72001,
    41666,
    5814188,
    20931,
    4.8,
    20735,
    85255,
  ],
  [
    '12653',
    3514770,
    12653,
    3.1,
    '',
    34008,
    14075,
    3909748,
    14075,
    3.2,
    '',
    38113,
  ],
  [
    '17509',
    2748979,
    9896,
    2.4,
    7612,
    43912,
    16594,
    2504711,
    9017,
    2.1,
    7577,
    41631,
  ],
  [
    '282755',
    71129176,
    256065,
    62.3,
    26690,
    539691,
    290422,
    74735323,
    269047,
    61.7,
    21375,
    545055,
  ],
  [
    '266265',
    66791370,
    240449,
    58.5,
    25816,
    498343,
    268275,
    68924509,
    248128,
    56.9,
    20146,
    491120,
  ],
  [
    '154332',
    36532500,
    131517,
    32,
    22815,
    252451,
    193100,
    48857497,
    175887,
    40.4,
    17213,
    321426,
  ],
  [
    '101212',
    27469763,
    98891,
    24.1,
    2321,
    222053,
    66484,
    17714968,
    63774,
    14.6,
    2710,
    146631,
  ],
  [
    '149',
    31136,
    112,
    0,
    37,
    283,
    232,
    63129,
    227,
    0.1,
    5,
    536,
  ],
  [
    '10572',
    2757971,
    9929,
    2.4,
    643,
    23556,
    8458,
    2288915,
    8240,
    1.9,
    218,
    22526,
  ],
  [
    '2921',
    663579,
    2389,
    0.6,
    533,
    5674,
    7925,
    1865356,
    6715,
    1.5,
    1210,
    15525,
  ],
  [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ],
  [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ],
  [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ],
  [
    '2921',
    663579,
    2389,
    0.6,
    533,
    5674,
    7925,
    1865356,
    6715,
    1.5,
    1210,
    15525,
  ],
  [
    '12653',
    3514770,
    12653,
    3.1,
    '',
    34008,
    14075,
    3909748,
    14075,
    3.2,
    '',
    38113,
  ],
  [
    '915',
    159458,
    574,
    0.1,
    341,
    1666,
    147,
    35710,
    129,
    0,
    18,
    298,
  ],
  [
    '298954',
    42973673,
    154705,
    37.7,
    144249,
    348455,
    319590,
    46326229,
    166774,
    38.3,
    152816,
    358566,
  ],
  [
    '199879',
    22146230,
    79726,
    19.4,
    120152,
    239882,
    208497,
    22990232,
    82765,
    19,
    125732,
    247502,
  ],
  [
    '186747',
    20816343,
    74939,
    18.2,
    111808,
    222206,
    194028,
    21580739,
    77691,
    17.8,
    116337,
    227400,
  ],
  [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ],
  [
    '95',
    10086,
    36,
    0,
    58,
    217,
    111,
    11238,
    40,
    0,
    71,
    252,
  ],
  [
    '13037',
    1319801,
    4751,
    1.2,
    8286,
    17459,
    14358,
    1398255,
    5034,
    1.2,
    9324,
    19850,
  ],
  [
    '82482',
    18237922,
    65657,
    16,
    16826,
    66326,
    94646,
    20866996,
    75121,
    17.2,
    19525,
    69730,
  ],
  [
    '13354',
    3709364,
    13354,
    3.3,
    '',
    '',
    19210,
    5336055,
    19210,
    4.4,
    '',
    '',
  ],
  [
    '37975',
    10548511,
    37975,
    9.2,
    '',
    '',
    41429,
    11507927,
    41429,
    9.5,
    '',
    '',
  ],
  [
    '260',
    72348,
    260,
    0.1,
    '',
    '',
    267,
    74182,
    267,
    0.1,
    '',
    '',
  ],
  [
    '30893',
    3907699,
    14068,
    3.4,
    16826,
    66326,
    33741,
    3948832,
    14216,
    3.3,
    19525,
    69730,
  ],
  [
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
  ],
  [
    '16593',
    2589522,
    9322,
    2.3,
    7271,
    42246,
    16447,
    2469001,
    8888,
    2,
    7559,
    41334,
  ],
];
