import 'package:flextable/FlexTable/DataFlexTable.dart';
import 'package:flutter/material.dart';
import 'package:flextable/FlexTable/TableItems/Cells.dart';
import 'package:flextable/FlexTable/TableLine.dart';
import 'package:flextable/FlexTable/TableModel.dart';

class InternationaleHandel {
  final dataTable = DataFlexTable();
  int endTableRows = 0;
  int endTableColumns = 0;
  final columnHeader1 = [
    'Perioden',
    '2019 1e kwartaal',
    '2019 2e kwartaal',
    '2019 3e kwartaal',
    '2019 4e kwartaal',
    '2019',
    '2020 1e kwartaal',
    '2020 2e kwartaal',
    '2020 3e kwartaal'
  ];

  final handel = [
    [
      'Diensten/Onderwerp',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo',
      'Invoer',
      'Uitvoer',
      'Saldo'
    ],
    [
      'S Totaal Diensten',
      52985,
      56460,
      3475,
      57879,
      60207,
      2327,
      61676,
      62669,
      993,
      64627,
      67029,
      2402,
      237167,
      246364,
      9198,
      55527,
      57329,
      1802,
      47700,
      53147,
      5447,
      51776,
      55623,
      3847
    ],
    [
      'SA Industriële diensten',
      1572,
      1842,
      270,
      1647,
      1804,
      157,
      1594,
      1767,
      173,
      1621,
      1974,
      352,
      6434,
      7387,
      953,
      1527,
      1654,
      126,
      1519,
      1677,
      158,
      1512,
      1553,
      42
    ],
    [
      'SB Onderhoud en reparatie',
      568,
      603,
      35,
      546,
      627,
      81,
      516,
      633,
      117,
      590,
      669,
      79,
      2218,
      2531,
      313,
      572,
      613,
      41,
      497,
      587,
      90,
      430,
      577,
      147
    ],
    [
      'SC Vervoersdiensten',
      8303,
      10385,
      2082,
      8488,
      10506,
      2018,
      8530,
      10483,
      1953,
      8641,
      10747,
      2107,
      33962,
      42122,
      8159,
      8276,
      9957,
      1680,
      7157,
      8615,
      1458,
      7251,
      9181,
      1930
    ],
    [
      'SC1 Zeevaart',
      1241,
      2508,
      1268,
      1268,
      2558,
      1291,
      1184,
      2668,
      1484,
      1229,
      2680,
      1451,
      4922,
      10415,
      5493,
      1287,
      2670,
      1383,
      1255,
      2482,
      1227,
      1153,
      2559,
      1406
    ],
    [
      'SC11 Zeevaart: passagiersvervoer',
      0,
      19,
      19,
      0,
      34,
      34,
      0,
      48,
      48,
      0,
      25,
      25,
      0,
      127,
      127,
      0,
      22,
      22,
      0,
      28,
      28,
      0,
      34,
      34
    ],
    [
      'SC12 Zeevaart: vrachtvervoer',
      818,
      1774,
      956,
      804,
      1823,
      1019,
      756,
      1907,
      1151,
      778,
      1941,
      1162,
      3156,
      7444,
      4288,
      823,
      1941,
      1118,
      809,
      1789,
      981,
      736,
      1816,
      1080
    ],
    [
      'SC13 Zeevaart: vervoersondersteunend',
      423,
      715,
      292,
      464,
      702,
      238,
      428,
      713,
      285,
      451,
      714,
      263,
      1766,
      2844,
      1078,
      464,
      708,
      243,
      446,
      665,
      219,
      417,
      709,
      292
    ],
    [
      'SC2 Luchtvaart',
      1303,
      3842,
      2539,
      1495,
      3858,
      2364,
      1799,
      3752,
      1952,
      1367,
      3912,
      2545,
      5964,
      15364,
      9400,
      1090,
      3360,
      2270,
      546,
      2359,
      1812,
      563,
      2620,
      2057
    ],
    [
      'SC21 Luchtvaart: passagiersvervoer',
      581,
      1279,
      698,
      727,
      1617,
      890,
      1023,
      1730,
      707,
      621,
      1496,
      875,
      2951,
      6121,
      3170,
      427,
      1109,
      681,
      27,
      224,
      197,
      69,
      417,
      348
    ],
    [
      'SC22 Luchtvaart: vrachtvervoer',
      312,
      1184,
      872,
      297,
      784,
      486,
      291,
      629,
      338,
      313,
      871,
      558,
      1213,
      3468,
      2254,
      274,
      932,
      658,
      321,
      980,
      659,
      270,
      957,
      687
    ],
    [
      'SC23 Luchtvaart: vervoersondersteunend',
      411,
      1379,
      968,
      470,
      1458,
      988,
      486,
      1394,
      908,
      434,
      1545,
      1111,
      1800,
      5775,
      3975,
      389,
      1320,
      931,
      199,
      1155,
      956,
      224,
      1246,
      1023
    ],
    [
      'SC3 Overig vervoer',
      5558,
      3767,
      -1790,
      5470,
      3798,
      -1672,
      5357,
      3722,
      -1636,
      5786,
      3841,
      -1946,
      22171,
      15128,
      -7043,
      5684,
      3645,
      -2039,
      5068,
      3422,
      -1645,
      5284,
      3649,
      -1635
    ],
    [
      'SC31 Overig vervoer: passagiersvervoer',
      25,
      19,
      -6,
      25,
      24,
      -1,
      23,
      26,
      2,
      25,
      23,
      -2,
      98,
      91,
      -7,
      20,
      17,
      -2,
      6,
      12,
      5,
      16,
      22,
      6
    ],
    [
      'SC32 Overig vervoer: vrachtvervoer',
      3043,
      2953,
      -90,
      2925,
      3001,
      76,
      2951,
      2976,
      25,
      3120,
      3058,
      -62,
      12039,
      11989,
      -51,
      3127,
      2852,
      -275,
      2699,
      2684,
      -15,
      2696,
      2919,
      222
    ],
    [
      'SC33 Ov. vervoer: vervoersondersteunend',
      2489,
      795,
      -1694,
      2520,
      773,
      -1747,
      2383,
      720,
      -1663,
      2642,
      761,
      -1881,
      10033,
      3048,
      -6985,
      2538,
      776,
      -1762,
      2362,
      726,
      -1635,
      2571,
      708,
      -1863
    ],
    [
      'SC4 Post- en koeriersdiensten',
      202,
      268,
      66,
      256,
      291,
      35,
      189,
      341,
      152,
      258,
      314,
      57,
      905,
      1215,
      310,
      215,
      281,
      66,
      288,
      352,
      64,
      251,
      353,
      102
    ],
    [
      'SD Reisverkeer',
      3496,
      3667,
      171,
      5052,
      4680,
      -372,
      7644,
      4993,
      -2651,
      3800,
      4274,
      475,
      19992,
      17616,
      -2376,
      2957,
      3048,
      91,
      467,
      1153,
      686,
      2365,
      3204,
      839
    ],
    [
      'SDA Zakelijk reisverkeer',
      656,
      1700,
      1043,
      669,
      1376,
      707,
      690,
      1041,
      350,
      605,
      1995,
      1390,
      2621,
      6111,
      3490,
      450,
      1345,
      895,
      6,
      395,
      388,
      278,
      658,
      379
    ],
    [
      'SDA1 Zakelijk reisverkeer: grens/seizoen',
      24,
      360,
      336,
      24,
      396,
      371,
      24,
      440,
      415,
      24,
      383,
      359,
      98,
      1579,
      1481,
      23,
      307,
      284,
      5,
      284,
      280,
      12,
      377,
      365
    ],
    [
      'SDA2 Zakelijk reisverkeer: overig',
      632,
      1339,
      708,
      644,
      980,
      336,
      666,
      601,
      -65,
      581,
      1612,
      1031,
      2523,
      4532,
      2009,
      427,
      1038,
      611,
      1,
      110,
      109,
      266,
      280,
      14
    ],
    [
      'SDB Privé reisverkeer',
      2840,
      1968,
      -872,
      4383,
      3304,
      -1079,
      6954,
      3953,
      -3001,
      3194,
      2279,
      -915,
      17371,
      11504,
      -5867,
      2508,
      1703,
      -805,
      461,
      758,
      297,
      2086,
      2546,
      460
    ],
    [
      'SDB1 Privé reisverkeer: gezondh.gerel.',
      155,
      19,
      -136,
      155,
      19,
      -136,
      155,
      19,
      -136,
      155,
      19,
      -136,
      622,
      78,
      -544,
      130,
      16,
      -113,
      12,
      1,
      -10,
      38,
      15,
      -23
    ],
    [
      'SDB2 Privé reisverkeer: onderwijsgerel.',
      126,
      211,
      85,
      126,
      211,
      85,
      126,
      211,
      85,
      126,
      211,
      84,
      505,
      844,
      339,
      115,
      196,
      81,
      96,
      147,
      50,
      82,
      129,
      47
    ],
    [
      'SDB3 Privé reisverkeer: overig',
      2558,
      1737,
      -821,
      4102,
      3074,
      -1028,
      6672,
      3722,
      -2950,
      2912,
      2049,
      -863,
      16244,
      10583,
      -5661,
      2263,
      1491,
      -772,
      353,
      610,
      257,
      1966,
      2402,
      436
    ],
    [
      'SE Bouwdiensten',
      609,
      724,
      115,
      710,
      823,
      112,
      761,
      717,
      -44,
      686,
      902,
      216,
      2766,
      3165,
      399,
      647,
      594,
      -53,
      647,
      607,
      -40,
      697,
      618,
      -78
    ],
    [
      'SF Verzekeringsdiensten',
      148,
      342,
      194,
      128,
      327,
      199,
      163,
      336,
      173,
      172,
      332,
      160,
      611,
      1337,
      726,
      168,
      358,
      190,
      124,
      325,
      201,
      116,
      330,
      214
    ],
    [
      'SG Financiële diensten',
      2438,
      1760,
      -679,
      2276,
      1852,
      -423,
      2178,
      1847,
      -331,
      2210,
      1664,
      -546,
      9101,
      7123,
      -1978,
      2823,
      1651,
      -1173,
      2461,
      1638,
      -823,
      3023,
      1754,
      -1269
    ],
    [
      'SH Gebruik intellectueel eigendom n.e.g.',
      12502,
      14068,
      1566,
      14342,
      14617,
      275,
      15158,
      15562,
      404,
      18578,
      16773,
      -1805,
      60580,
      61020,
      440,
      13354,
      15609,
      2255,
      13700,
      16521,
      2821,
      14337,
      15522,
      1185
    ],
    [
      'SI Telecommunicatie, computerdiensten..',
      4100,
      6007,
      1907,
      4483,
      5946,
      1462,
      4271,
      6470,
      2199,
      4881,
      7148,
      2267,
      17736,
      25571,
      7835,
      4513,
      6039,
      1526,
      4222,
      5477,
      1255,
      4341,
      6025,
      1685
    ],
    [
      'SI1 Telecommunicatie-diensten',
      632,
      879,
      247,
      684,
      842,
      157,
      667,
      910,
      243,
      735,
      907,
      173,
      2718,
      3538,
      820,
      725,
      920,
      196,
      684,
      986,
      302,
      656,
      873,
      217
    ],
    [
      'SI2 Computerdiensten',
      2909,
      3392,
      483,
      3253,
      3192,
      -61,
      3042,
      3636,
      594,
      3519,
      4199,
      680,
      12722,
      14419,
      1697,
      3153,
      3330,
      177,
      2967,
      3258,
      290,
      3090,
      3660,
      571
    ],
    [
      'SI3 Informatiediensten',
      559,
      1736,
      1177,
      546,
      1912,
      1365,
      562,
      1924,
      1362,
      628,
      2042,
      1413,
      2296,
      7613,
      5318,
      635,
      1789,
      1154,
      571,
      1234,
      663,
      595,
      1492,
      897
    ],
    [
      'SJ Andere zakelijke diensten',
      18394,
      16043,
      -2351,
      19402,
      17977,
      -1425,
      19985,
      18882,
      -1103,
      22485,
      21471,
      -1015,
      80267,
      74373,
      -5894,
      19769,
      16863,
      -2906,
      16330,
      15635,
      -695,
      17309,
      15976,
      -1333
    ],
    [
      'SJ1 Research en development (R&D)',
      1857,
      1866,
      9,
      2244,
      2063,
      -181,
      2182,
      2117,
      -65,
      2794,
      2738,
      -55,
      9077,
      8784,
      -293,
      1832,
      1514,
      -318,
      1933,
      1767,
      -166,
      2030,
      1796,
      -234
    ],
    [
      'SJ2 Professionele en managementadviesd.',
      9950,
      6547,
      -3402,
      9742,
      7519,
      -2223,
      10734,
      6576,
      -4158,
      11715,
      9267,
      -2448,
      42141,
      29910,
      -12231,
      10679,
      7111,
      -3567,
      8500,
      7712,
      -788,
      9124,
      6742,
      -2382
    ],
    [
      'SJ3 Technische, ov. zakelijke diensten..',
      6588,
      7630,
      1042,
      7416,
      8395,
      979,
      7068,
      10189,
      3120,
      7977,
      9465,
      1489,
      29049,
      35679,
      6630,
      7258,
      8237,
      979,
      5897,
      6156,
      259,
      6155,
      7438,
      1283
    ],
    [
      'SK Pers., cult. en recreatieve diensten',
      805,
      579,
      -226,
      754,
      606,
      -148,
      817,
      535,
      -281,
      911,
      627,
      -284,
      3287,
      2348,
      -940,
      880,
      500,
      -380,
      531,
      479,
      -52,
      365,
      482,
      117
    ],
    [
      'SK1 Audiovisuele en verwante diensten',
      719,
      466,
      -253,
      656,
      506,
      -150,
      722,
      436,
      -286,
      808,
      537,
      -270,
      2905,
      1946,
      -959,
      780,
      392,
      -388,
      457,
      396,
      -61,
      292,
      395,
      103
    ],
    [
      'SK2 Ov. culturele/recreatieve diensten',
      86,
      113,
      27,
      99,
      101,
      2,
      94,
      99,
      5,
      103,
      89,
      -14,
      383,
      402,
      19,
      100,
      108,
      8,
      74,
      84,
      10,
      73,
      87,
      14
    ],
    [
      'SL Overheidsdiensten n.e.g',
      50,
      439,
      389,
      50,
      441,
      391,
      61,
      445,
      384,
      52,
      448,
      396,
      212,
      1772,
      1560,
      39,
      444,
      405,
      45,
      433,
      388,
      32,
      401,
      369
    ]
  ];

  InternationaleHandel() {
    int row = 0;
    int column = 0;

    dataTable.addCell(
        row: 0,
        column: 0,
        columns: 8 * 3,
        cell: Cell(
            value:
                'Internationale handel; invoer en uitvoer van diensten naar land, kwartaal (mln euro)',
            attr: {
              'alignment': Alignment.centerLeft,
              'textStyle':
                  const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            }));

    int tempColumn = column;
    row++;

    for (var element in columnHeader1) {
      dataTable.addCell(
          row: 1,
          column: tempColumn,
          columns: tempColumn == column ? 1 : 3,
          cell: Cell(value: element, attr: {
            'background': Colors.blue[200]!,
            if (tempColumn == 0) 'alignment': Alignment.centerLeft,
            // 'textStyle': TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.bold),
            'textAlign': TextAlign.center
          }));
      tempColumn += tempColumn == column ? 1 : 3;
    }

    row++;

    for (var columns in handel) {
      tempColumn = column;

      for (var value in columns) {
        Map attr;

        if (row == 2) {
          attr = {
            'background': Colors.blue[100]!,
            if (tempColumn == 0) 'alignment': Alignment.centerLeft,
          };
        } else {
          attr = {
            if ((row % 2 == 0)) 'background': Colors.blue[50]!,
            if (tempColumn == 0) 'alignment': Alignment.centerLeft,
          };
        }
        dataTable.addCell(
            row: row, column: tempColumn, cell: Cell(value: value, attr: attr));
        tempColumn++;
      }

      row++;
    }

    if (endTableColumns < tempColumn) endTableColumns = tempColumn;

    if (endTableRows < row) endTableRows = row;

    Color lineColor = Colors.blue[400]!;

    final v = dataTable.verticalLineList;

    final verticalLineKwartaal = v.createLineNodeList(
      startLevelTwoIndex: 1,
      lineNode: LineNode(
        bottom: Line(color: lineColor),
      ),
    )..addLineNode(
        startLevelTwoIndex: row,
        lineNode: LineNode(top: Line(color: lineColor)));

    for (int i = 1; i <= endTableColumns; i += 3) {
      v.addList(startLevelOneIndex: i, lineList: verticalLineKwartaal);
    }
  }

  TableModel makeTable(
      {TargetPlatform? platform,
      scrollLockX = true,
      scrollLockY = true,
      List<AutoFreezeArea> autofreezeAreaX = const [],
      List<AutoFreezeArea> autofreezeAreasY = const []}) {
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
        maximumRows: endTableRows,
        maximumColumns: endTableColumns,
        leftPanelMargin: 4.0,
        rightPanelMargin: 4.0,
        topPanelMargin: 4.0,
        bottomPanelMargin: 4.0,
        scale: tableScale,
        minTableScale: minTableScale,
        maxTableScale: maxTableScale,
        scrollLockX: scrollLockX,
        scrollLockY: scrollLockY,
        autoFreezeAreasX: autofreezeAreaX,
        autoFreezeAreasY: autofreezeAreasY,
        specificWidth: [PropertiesRange(min: 0, max: 0, length: 160.0)],
        specificHeight: [PropertiesRange(min: 1, max: 2, length: 30.0)]);
  }
}
