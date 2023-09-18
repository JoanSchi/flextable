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
