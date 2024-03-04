import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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
  State<TextEditExample> createState() => _RowChangeExampleState();
}

class _RowChangeExampleState extends State<TextEditExample>
    with TableSettingsBottomSheet {
  final GlobalKey _globalKey = GlobalKey();
  final DefaultRecordFtController _ftController = DefaultRecordFtController();
  final rebuildNotifier = RebuildNotifier();
  late RecordFtModel model;

  @override
  void initState() {
    model = makeModel(tableRows: 4, tableColumns: 10);
    super.initState();
  }

  @override
  void dispose() {
    rebuildNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      body: Shortcuts(
        shortcuts: <LogicalKeySet, Intent>{
          LogicalKeySet(LogicalKeyboardKey.escape): const EscapeIntent(),
        },
        child: DefaultRecordFlexTable(
            rebuildNotifier: rebuildNotifier,
            backgroundColor: Colors.white,
            controller: _ftController,
            model: model,
            tableBuilder: DefaultRecordTableBuilder<dynamic, String>(
                formatCellDate: (format, date) {
              return DateFormat(format).format(date);
            }, actionCallBack: (v, i, c, String a) {
              debugPrint('Specific action: $a');
              return true;
            })),
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {
        setState(() {
          _ftController.lastViewModel().removeRows(
                keepEdit: true,
                startRow: 2,
              );
        });

        // _ftController.lastViewModel().removeRows(
        //       startRow: 8,
        //     );

        // rebuildNotifier.notify();
      }),
    );
  }

  makeModel({required int tableRows, required int tableColumns}) {
    final model = DefaultRecordFtModel(
        columnHeader: true,
        rowHeader: true,
        defaultWidthCell: 120.0,
        defaultHeightCell: 50.0,
        tableColumns: tableColumns,
        tableRows: tableRows,
        autoFreezeAreasX: [
          AutoFreezeArea(startIndex: 0, freezeIndex: 1, endIndex: 10000)
        ],
        autoFreezeAreasY: [
          AutoFreezeArea(startIndex: 0, freezeIndex: 1, endIndex: 10000)
        ]);

    const line = Line(width: 0.5, color: Color.fromARGB(255, 70, 78, 38));
    const color2 = Color.fromARGB(255, 249, 250, 245);
    const color1 = Color.fromARGB(255, 229, 235, 206);

    const style = TextCellStyle(
      background: color1,
      textStyle:
          TextStyle(fontSize: 20, color: Color.fromARGB(255, 70, 78, 38)),
    );

    const styleNumber = NumberCellStyle(
      background: color1,
      textStyle:
          TextStyle(fontSize: 20, color: Color.fromARGB(255, 70, 78, 38)),
      padding: null,
    );

    int column = 0;

    /// DateTime
    ///
    ///
    ///
    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(value: 'Select', style: style, editable: false),
    );

    const values = ['pig', 'chicken', 'cow', 'dog'];

    for (int r = 1; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: SelectionCell(
          value: values[r % 4],
          values: values,
          style: style,
        ),
      );
    }

    column++;

    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(
        value: 'Num. A',
        style: style,
        editable: false,
      ),
    );

    for (int r = 1; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: DecimalCell(
          value: 1.0,
          style: styleNumber,
        ),
      );
    }

    column++;

    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(value: 'Date', style: style, editable: false),
    );

    for (int r = 1; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: DateTimeCell(
            value: DateTime.utc(2024, 1, 1).add(Duration(days: r)),
            style: style,
            isUtc: true),
      );
    }

    column++;

    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(
        value: 'Num. B',
        style: style,
        editable: false,
      ),
    );

    for (int r = 1; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: DecimalCell(
          value: 1.0,
          style: styleNumber,
        ),
      );
    }

    column++;

    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(
        value: 'Calc',
        style: style,
        editable: false,
      ),
    );

    for (int r = 1; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: CalculationCell(
          style: styleNumber,
          calculationSyntax: (List<Object> list) {
            var [a, b] = list.whereType<num>().toList();
            return a * b;
          },
          imRefIndex: [
            FtIndex(row: -2, column: column - 2),
            FtIndex(row: -2, column: column - 1)
          ],
        ),
      );
    }

    column++;

    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(
          value: 'Text',
          style: style,
          editable: true,
          noBlank: true,
          validate: "r"),
    );

    for (int r = 1; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: TextCell(value: 'text', style: style, editable: true),
      );
    }

    column++;

    model.insertCell(
      ftIndex: FtIndex(row: 0, column: column),
      cell: TextCell(
        value: 'Options',
        style: style,
        editable: false,
      ),
    );

    for (int r = 1; r < 3; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: ActionCell(
            value: const ActionCellItem(
              action: 'actie blub',
              widget: Icon(Icons.delete_outline),
            ),
            style: style,
            text: 'Action :)'),
      );
    }

    column++;
    for (int r = 3; r < tableRows; r++) {
      model.insertCell(
        ftIndex: FtIndex(row: r, column: column),
        cell: ActionCell(
          value: [
            'Insert',
            'Delete',
            'Send',
          ],
          style: style,
        ),
      );
    }
    return model;
  }
}

class ClearIntent {
  const ClearIntent();
}
