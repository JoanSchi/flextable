import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 229, 235, 206))),
      home: const TextEditExample(),
    ),
  );
}

class TextEditExample extends StatefulWidget {
  const TextEditExample({super.key});

  @override
  State<TextEditExample> createState() => _TextEditExampleState();
}

class _TextEditExampleState extends State<TextEditExample>
    with TableSettingsBottomSheet {
  final GlobalKey _globalKey = GlobalKey();
  final DefaultFtController _ftController = DefaultFtController();

  @override
  Widget build(BuildContext context) {
    const columns = 50;
    const rows = 500;

    final model = DefaultFtModel(
      columnHeader: true,
      rowHeader: true,
      defaultWidthCell: 120.0,
      defaultHeightCell: 50.0,
      tableColumns: columns,
      tableRows: rows,
    );

    const line = Line(width: 0.5, color: Color.fromARGB(255, 70, 78, 38));

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < columns; c++) {
        int rows = 1;

        TextCellStyle style = TextCellStyle(
          background: (r % 99 < 1
              ? const Color.fromARGB(255, 249, 250, 245)
              : ((r % 2) % 2 == 0
                  ? Colors.white10
                  : const Color.fromARGB(255, 229, 235, 206))),
          textStyle: const TextStyle(
              fontSize: 20, color: Color.fromARGB(255, 70, 78, 38)),
        );

        model.updateCell(
            ftIndex: FtIndex(row: r, column: c),
            cell: TextCell(
                value: '${numberToCharacter(c)}$r',
                style: style,
                editable: true),
            rows: rows);
      }
    }

    model.horizontalLines.addLineRanges((create) {
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
        // create(LineRange(
        //     startIndex: r + 1,
        //     endIndex: r + 2,
        //     lineNodeRange: LineNodeRange()
        //       ..addLineNodes((create) {
        //         for (int c = 0; c < columns; c += 2) {
        //           create(LineNode(
        //             startIndex: c,
        //             after: line,
        //           ));
        //           create(LineNode(
        //             startIndex: c + 1,
        //             before: line,
        //           ));
        //         }
        //       })));
      }
    });

    model.verticalLines.addLineRange(LineRange(
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

    model
      ..addAutoFreezeAreasX(
          [AutoFreezeArea(startIndex: 1, freezeIndex: 2, endIndex: 8)])
      ..addAutoFreezeAreasY([
        for (int r = 0; r < rows - 100; r += 99)
          AutoFreezeArea(startIndex: r, freezeIndex: r + 3, endIndex: r + 90)
      ])
      ..tableColumns = columns
      ..tableRows = rows;

    return Scaffold(
        key: _globalKey,
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Short FlexTable example'),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => toggleSheet(_globalKey, _ftController),
            ),
          ],
        ),
        body: DefaultFlexTable(
          backgroundColor: Colors.white,
          controller: _ftController,
          model: model,
          tableBuilder: DefaultTableBuilder(),
        ));
  }
}
