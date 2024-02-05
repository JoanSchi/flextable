import 'package:async_table_example/utils/date_utils.dart';
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'builders/week_table_builder.dart';
import 'custom_table_areas/observed_climate_table_area.dart';
import 'custom_table_areas/observed_energy_table_area.dart';
import 'custom_table_areas/observed_tomate_table_area.dart';
import 'custom_table_areas/week_date_day.dart';
import 'model/week.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final model = AsyncAreaModel(
      specificWidth: [
        RangeProperties(
          start: 0,
          size: 10,
        ),
        RangeProperties(
          start: 1,
          size: 70,
        ),
        RangeProperties(
          start: 3,
          size: 50,
        )
      ],
      defaultWidthCell: 80,
      defaultHeightCell: 30,
      autoFreezeAreasX: [
        AutoFreezeArea(startIndex: 3, freezeIndex: 4, endIndex: 50)
      ],
      autoFreezeAreasY: []);
  final FtController<AsyncAreaModel, Cell> _tableController =
      FtController<AsyncAreaModel, Cell>();

  @override
  void initState() {
    DateTime firstDate = DateTime.utc(2024, 01, 01);
    DateTime date = DateTime.utc(2024, 01, 01);
    final today = TableDateUtils.onlyUtcDateNow();
    FtIndex initialIndex = const FtIndex();
    Set<AutoFreezeArea> autoFreezeAreas = {};

    int firstRow = 1;
    for (int w = 0; w < 5000; w++) {
      DateTime lastDayWeek = date.add(const Duration(days: 6));
      WeekAreaInitializer week = WeekAreaInitializer(
          tableController: _tableController,
          firstRow: firstRow,
          firstColumn: 1,
          firstDate: firstDate,
          firstDayWeek: date,
          lastDayWeek: lastDayWeek,
          definedTableAreas: const [
            DefinedTableAreaWeekDateDay(),
            DefinedTableAreaObservedTomato(),
            DefinedTableAreaObservedClimate(),
            DefinedTableAreaObservedEnergy(),
          ]);

      model.addAreaInitializer(week);

      if ((initialIndex.isIndex, week.rowDate(today) - 1) case (false, int r)
          when r > 0) {
        initialIndex = FtIndex(row: r, column: 0);
      }

      firstRow += week.rows + 2;

      date = date.add(const Duration(days: 7));

      autoFreezeAreas.add(AutoFreezeArea(
          startIndex: week.firstRow,
          freezeIndex: week.freezedRow,
          endIndex: week.lastRow));
    }
    model.tableRows++;

    model.specificWidth.add(
      RangeProperties(
        start: model.tableColumns,
        size: 10,
      ),
    );
    model.tableColumns++;
    model
      ..addAutoFreezeAreasY(autoFreezeAreas)
      ..setInitialIndex(initialIndex);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        // appBar: AppBar(
        //   backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        //   title: Text(widget.title),
        // ),
        body: SafeArea(
      child: FlexTable<AsyncAreaModel, Cell>(
        controller: _tableController,
        model: model,
        tableBuilder: TableWeekBuilder(),
      ),
    ));
  }
}
