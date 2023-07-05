import 'package:example_flextable_in_sliver/data/hypotheek.dart';
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
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
  final FlexTableController _hypotheekFlexTableController =
      FlexTableController();

  @override
  Widget build(BuildContext context) {
    Widget makeTable(
        {required FlexTableController flexTableController,
        required FlexTableModel model,
        TableBuilder? tableBuilder}) {
      FlexTableScaleChangeNotifier scaleChangeNotifier =
          FlexTableScaleChangeNotifier();

      Widget table = FlexTable(
        scaleChangeNotifier: scaleChangeNotifier,
        flexTableController: flexTableController,
        tableBuilder: tableBuilder,
        backgroundColor: Colors.grey[50],
        flexTableModel: model,
      );

      // if (scaleSlider) {
      //   table = GridBorderLayout(children: [
      //     table,
      //     GridBorderLayoutPosition(
      //         row: 2,
      //         squeezeRatio: 1.0,
      //         measureHeight: true,
      //         child: TableBottomBar(
      //             scaleChangeNotifier: scaleChangeNotifier,
      //             flexTableController: flexTableController,
      //             maxWidthSlider: 200.0))
      //   ]);
      // }
      return FlexTableToSliverBox(
          // maxOverlap: 80,
          flexTableController: flexTableController,
          child: table);
    }

    return Scaffold(
        body: CustomScrollView(slivers: [
      const SliverAppBar(
        title: Text('Overlap'),
        expandedHeight: 300.0,
        // flexibleSpace: Container(),
        floating: true,
        pinned: true,
        snap: true,
      ),
      SliverList(
          delegate: SliverChildListDelegate.fixed([
        Container(
          height: 300,
          color: const Color.fromARGB(255, 216, 230, 238),
        ),
        Container(
          height: 10,
          color: Colors.orange,
        ),
      ])),
      makeTable(
          flexTableController: _hypotheekFlexTableController,
          model: hypotheekExample1(tableRows: 1, tableColumns: 2).tableModel(
            autoFreezeListX: true,
            autoFreezeListY: true,
          ),
          tableBuilder: HypoteekTableBuilder()),
      SliverList(
          delegate: SliverChildListDelegate.fixed([
        Container(
          height: 10,
          color: Colors.orange,
        ),
        Container(
          height: 300,
          color: const Color.fromARGB(255, 216, 230, 238),
        ),
        Container(
          height: 300,
          color: const Color.fromARGB(255, 234, 238, 241),
        ),
        Container(
          height: 300,
          color: const Color.fromARGB(255, 216, 230, 238),
        ),
        Container(
          height: 300,
          color: const Color.fromARGB(255, 234, 238, 241),
        ),
        Container(
          height: 300,
          color: const Color.fromARGB(255, 216, 230, 238),
        ),
      ])),
    ]));
  }
}
