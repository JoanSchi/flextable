<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# FlexTable

FlexTable is a customizable table with headers, splitView, freezeView, autoFreeze, zoom and scrollbars. The table consist of a model, a viewmodel and builders. Fig. 1 shows some options. The table can scrolls in two directions at the same time. If the first scroll is however horizontal or vertical, the cross direction is locked until the ballistic scroll ends  to prevent a unwanted drift if the user scrolls enthousiatic for serveral pages.

It is also possible to place the FlexTable in a customScrollView by wrapping the FlexTable in a adaptive sliver, wrapped in a sliver the table can only scroll in one direction at the same time.

[Web App Example](http://js-lab.nl/flextable)

<img src="doc/flextable_options.png" width="800" >

Fig. 1: Option: **A.** scroll direction, **B.** Drag to initiate splitView, **C.** Freeze/unfreeze, **D.** Change freeze position




## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

```dart
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 229, 235, 206))),
      home: const ShortExample(),
    ),
  );
}

class ShortExample extends StatefulWidget {
  const ShortExample({super.key});

  @override
  State<ShortExample> createState() => _ShortExampleState();
}

class _ShortExampleState extends State<ShortExample> {
  late FlexTableDataModel dataTable;
  FlexTableController flexTableController = FlexTableController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    const columns = 50;
    const rows = 5000;
    dataTable = FlexTableDataModel();
    const line = Line(width: 0.5, color: Color.fromARGB(255, 70, 78, 38));

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        int rows = 1;
        if ((c + 1) % 2 == 0) {
          if (r % 3 == 0) {
            rows = 3;
          } else {
            continue;
          }
        }
        Map attr = {
          CellAttr.background: (r % 99 < 1
              ? const Color.fromARGB(255, 249, 250, 245)
              : ((r % 2) % 2 == 0
                  ? Colors.white10
                  : const Color.fromARGB(255, 229, 235, 206))),
          CellAttr.textStyle: const TextStyle(
              fontSize: 20, color: Color.fromARGB(255, 70, 78, 38)),
        };

        dataTable.addCell(
            row: r,
            column: c,
            cell: Cell(value: '${numberToCharacter(c)}$r', attr: attr),
            rows: rows);
      }
    }

    dataTable.horizontalLineList.addLineRanges((create) {
      for (int r = 0; r < rows; r += 3) {
        /// Horizontal lines
        ///
        ///
        create(LineRange(
            startIndex: r,
            lineNodeRange: LineNodeRange(list: [
              LineNode(
                startIndex: 0,
                after: line,
              ),
              LineNode(
                startIndex: 0,
                before: line,
              )
            ])));

        /// Horizontal lines for merged columns
        ///
        ///
        create(LineRange(
            startIndex: r + 1,
            endIndex: r + 2,
            lineNodeRange: LineNodeRange()
              ..addLineNodes((create) {
                for (int c = 0; c < columns; c += 2) {
                  create(LineNode(
                    startIndex: c,
                    after: line,
                  ));
                  create(LineNode(
                    startIndex: c + 1,
                    before: line,
                  ));
                }
              })));
      }
    });

    dataTable.verticalLineList.addLineRange(LineRange(
        startIndex: 0,
        endIndex: columns,
        lineNodeRange: LineNodeRange(list: [
          LineNode(
            startIndex: 0,
            after: line,
          ),
          LineNode(
            startIndex: rows,
            before: line,
          ),
        ])));

    final flexTableModel = FlexTableModel(
        columnHeader: true,
        rowHeader: true,
        dataTable: dataTable,
        defaultWidthCell: 120.0,
        defaultHeightCell: 50.0,
        autoFreezeAreasY: [
          for (int r = 0; r < rows - 100; r += 99)
            AutoFreezeArea(startIndex: r, freezeIndex: r + 3, endIndex: r + 90)
        ],
        maximumColumns: columns,
        maximumRows: rows);

    FlexTable flexTable = FlexTable(
        backgroundColor: Colors.white,
        flexTableController: flexTableController,
        flexTableModel: flexTableModel);

    return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Short FlexTable example'),
        ),
        body: flexTable);
  }
}
```

### Table Lines
The vertical and horizontal lines are added seperatedly to the table in ranges to minimize objects for large tables. The TableLinesOneDirection object contains a LineLinkedList with LineRanges which contains a LineLinkedList with LineNodeRanges for one direction.
The TableLinesOneDirection object will merge added LineRanges and the containing LineNodes. Equal ranges besides each other will merge into a bigger range. 
Lines or parts of the line can be deleted by adding EmptyLineNodes (LineNode with noLines) over the desired range. 
The TableLinesOneDirection will remove the lines where the EmptyLineNode are merged. If the LineRange is empty, the LineRange will be removed automatical.
A LineNodeRange or LineNode object can be reused for loops, because they are coppied or merged by TableLinesOneDirection object.

It is possible to change the width and color of the existing lines over a large range by using Line.change(width:.., color..). The new properties will merge with the existing lines.


```
TableLinesOneDirection horizontalLines = TableLinesOneDirection();

const blueLine = Line(
    width: 0.5,
    color: Color(0xFF42A5F5),
  );

  /// 0: --  --
  /// 1: --  --
  /// 2: --  --
  ///
  
  horizontalLines.addLineRange(LineRange(
      startIndex: 0,
      endIndex: 2,
      lineNodeRange: LineNodeRange(list: [
        LineNode(startIndex: 0, after: blueLine),
        LineNode(startIndex: 2, before: blueLine),
        LineNode(startIndex: 4, after: blueLine),
        LineNode(startIndex: 6, before: blueLine),
      ])));
 ```
Output:

LineRanges in TableLinesOneDirection: 
- LineNodeRange 0-2: 
  - LineNode 0-0: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 2-2: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
  - LineNode 4-4: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null

```
  Change to:

  /// 0: --  --
  /// 1:   --
  /// 2: --  --
  ///

  horizontalLines.addLineRange(LineRange(
      startIndex: 1,
      lineNodeRange: LineNodeRange(
        list: [
          // remove line
          EmptyLineNode(startIndex: 0, endIndex: 6),
          //add new line
          LineNode(startIndex: 2, after: blueLine),
          LineNode(startIndex: 4, before: blueLine),
        ],
      )));
```
Output:

LineRanges in TableLinesOneDirection: 
- LineNodeRange 0-0: 
  - LineNode 0-0: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 2-2: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
  - LineNode 4-4: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
- LineNodeRange 1-1: 
  - LineNode 2-2: before: Line(o:LineOptions.no, w:null, c:null), after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 4-4: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: Line(o:LineOptions.no, w:null, c:null)
- LineNodeRange 2-2: 
  - LineNode 0-0: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 2-2: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
  - LineNode 4-4: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null

```
  Change to:

  /// 0: ------
  /// 1:   --
  /// 2: ------
  ///
  /// Change all lines to: width = 2.0, color = green 

   horizontalLines.addLineRanges((add) {
    // replace complete line
    add(LineRange(
        startIndex: 0,
        lineNodeRange: LineNodeRange(
          list: [
            LineNode(
              startIndex: 0,
              after: blueLine,
            ),
            LineNode(
              startIndex: 1,
              endIndex: 5,
              before: blueLine,
              after: blueLine,
            ),
            LineNode(startIndex: 6, before: blueLine),
          ],
        )));

    // remove middle part of the line
    add(LineRange(
        startIndex: 2,
        lineNodeRange: LineNodeRange(
          list: [
            EmptyLineNode(
              startIndex: 2,
              endIndex: 4,
            ),
          ],
        )));

    // Merge changes to existing lines:
    add(LineRange(
        startIndex: 0,
        endIndex: 2,
        lineNodeRange: LineNodeRange(
          list: [
            LineNode(
                startIndex: 0,
                endIndex: 6,
                before: const Line.change(
                    width: 2.0, color: Color.fromARGB(255, 142, 212, 63)),
                after: const Line.change(
                    width: 2.0, color: Color.fromARGB(255, 142, 212, 63))),
          ],
        )));
  });
```
Output:

LineRanges in TableLinesOneDirection: 
- LineNodeRange 0-0: 
  - LineNode 0-0: before: Line(o:null, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 1-5: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:null, w:2.0, c:Color(0xff8ed43f))
- LineNodeRange 1-1: 
  - LineNode 2-2: before: Line(o:LineOptions.no, w:null, c:null), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 4-4: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.no, w:null, c:null)
- LineNodeRange 2-2: 
  - LineNode 0-0: before: Line(o:null, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:null, w:2.0, c:Color(0xff8ed43f))

```
  Change to:

  /// 0: remove
  /// 1:   --
  /// 2: remove
  ///
  
  horizontalLines.addLineRanges((add) {
    // Reuse of emptyLineNodeRange to remove row 0 and 2

    final emptyLineNodeRange = LineNodeRange(
      list: [EmptyLineNode(startIndex: 0, endIndex: 6)],
    );

    for (int i in [0, 2]) {
      add(LineRange(startIndex: i, lineNodeRange: emptyLineNodeRange));
    }
  });
```

Output:
LineRanges in TableLinesOneDirection: 
- LineNodeRange 1-1: 
  - LineNode 2-2: before: Line(o:LineOptions.no, w:null, c:null), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 4-4: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.no, w:null, c:null)

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
