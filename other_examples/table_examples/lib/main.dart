import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/examples.dart/example_appbar_overlap.dart';
import 'package:table_examples/examples.dart/example_energy.dart';
import 'package:table_examples/examples.dart/example_fruit.dart';
import 'package:table_examples/examples.dart/example_international_trade.dart';
import 'package:table_examples/examples.dart/example_mortgage.dart';
import 'about/about.dart';
import 'examples.dart/example_tables_in_sliver.dart';
import 'examples.dart/example_stress_test.dart';

class ExampleInfo {
  const ExampleInfo(this.label, this.example);

  final String label;
  final Widget example;
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flextable Examples',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 109, 182, 216)),
        useMaterial3: true,
      ),
      home: const TableExamples(title: 'Flutter Demo Home Page'),
    );
  }
}

class TableExamples extends StatefulWidget {
  const TableExamples({super.key, required this.title});

  final String title;

  @override
  State<TableExamples> createState() => _TableExamplesState();
}

class _TableExamplesState extends State<TableExamples> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  int screenIndex = 0;
  late List<ExampleInfo> exampleDestinations;

  @override
  void initState() {
    exampleDestinations = <ExampleInfo>[
      ExampleInfo(
        'Mortgage',
        ExampleMortgage(openDrawer: openDrawer),
      ),
      ExampleInfo(
        'Energy',
        ExampleEnergy(openDrawer: openDrawer),
      ),
      ExampleInfo(
        'Trade',
        ExampleInternationalTrade(openDrawer: openDrawer),
      ),
      ExampleInfo(
        'Fruit',
        ExampleFruit(openDrawer: openDrawer),
      ),
      ExampleInfo(
        'Stress Test',
        ExampleStressTest(openDrawer: openDrawer),
      ),
      ExampleInfo(
        'Tables in ScrollView',
        ExampleSliverInTables(openDrawer: openDrawer),
      ),
      ExampleInfo(
          'AppBar Overlap', ExampleAppBarOverlap(openDrawer: openDrawer)),
      ExampleInfo('About', About(openDrawer: openDrawer))
    ];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleSmall =
        theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary);

    int i = 0;

    final scaffold = Scaffold(
      key: scaffoldKey,

      body: exampleDestinations[screenIndex].example,
      drawer: NavigationDrawer(
        onDestinationSelected: handleScreenChanged,
        selectedIndex: screenIndex,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Tables',
              style: titleSmall,
            ),
          ),
          ...exampleDestinations.sublist(i, i += 5).map(
            (ExampleInfo destination) {
              return NavigationDrawerDestination(
                label: Text(destination.label),
                icon: const Icon(Icons.table_rows),
              );
            },
          ),
          const Divider(
            indent: 8.0,
            endIndent: 8.0,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
            child: Text(
              'Tables in ScrollView',
              style: titleSmall,
            ),
          ),
          ...exampleDestinations.sublist(i, i += 2).map(
            (ExampleInfo destination) {
              return NavigationDrawerDestination(
                label: Text(destination.label),
                icon: const Icon(Icons.table_rows_outlined),
              );
            },
          ),
          const Divider(
            indent: 8.0,
            endIndent: 8.0,
          ),
          NavigationDrawerDestination(
            label: Text(exampleDestinations[i++].label),
            icon: const Icon(Icons.info),
          )
        ],
      ),
      // This trailing comma makes auto-formatting nicer for build methods.
    );

    return ScrollConfiguration(
        behavior: const MyMaterialScrollBehavior(), child: scaffold);
  }

  void openDrawer() {
    scaffoldKey.currentState!.openDrawer();
  }

  void handleScreenChanged(int index) {
    scaffoldKey.currentState!.closeDrawer();
    setState(() {
      screenIndex = index;
    });
  }
}

class MyMaterialScrollBehavior extends MaterialScrollBehavior {
  const MyMaterialScrollBehavior({this.useSwipe = false});
  final bool useSwipe;

  @override
  TargetPlatform getPlatform(BuildContext context) {
    final platform = defaultTargetPlatform;
    switch (platform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return platform;
      default:
        return useSwipe ? TargetPlatform.android : platform;
    }
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
      };

  @override
  Widget buildScrollbar(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    switch (axisDirectionToAxis(details.direction)) {
      case Axis.horizontal:
      //Heel raar geen scrollbar
      // return child;
      case Axis.vertical:
        switch (getPlatform(context)) {
          case TargetPlatform.linux:
          case TargetPlatform.macOS:
          case TargetPlatform.windows:
            return Scrollbar(
              interactive: true,
              controller: details.controller,
              child: child,
            );
          case TargetPlatform.android:
          case TargetPlatform.fuchsia:
          case TargetPlatform.iOS:
            return child;
        }
    }
  }
}
