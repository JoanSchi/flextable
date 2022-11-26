import 'package:example_flextable/tables/energy_table.dart';
import 'package:example_flextable/tables/fruit_table.dart';
import 'package:example_flextable/tables/hypotheek_table.dart';
import 'package:example_flextable/tables/sliver_tables.dart';
import 'package:example_flextable/tables/stress_table.dart';
import 'package:example_flextable/tables/trade_table.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'about.dart';

void main() {
  setOverlayStyle();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      title: 'FlexTable',
      theme: ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: const MyHomePage(title: 'FlexTable'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title = ''}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".
  // a = CustomScrollView(s);
  final String title;

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int tabIndex = 0;
  late TabController tabController = TabController(
      length: 6,
      vsync: this,
      animationDuration: const Duration(milliseconds: 300))
    ..addListener(() {
      tabIndex = tabController.index;
    });

  Map<int, AboutNotification> map = {};

  AboutNotification notification(int index) {
    AboutNotification? an = map[index];
    if (an == null) {
      an = AboutNotification();
      map[index] = an;
    }
    return an;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0.0,
        actions: [
          IconButton(onPressed: about, icon: const Icon(Icons.info_outline))
        ],
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(widget.title),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: const <Widget>[
            Tab(text: 'Mortgage'),
            Tab(text: 'Energy'),
            Tab(text: "Table's in sliver"),
            Tab(text: 'Stress'),
            Tab(text: 'Fruit'),
            Tab(text: 'Handel'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HypotheekTable(tabIndex: 0, notificationMap: map),
          EnergyTable(tabIndex: 1, notificationMap: map),
          SliverTables(tabIndex: 2, notificationMap: map),
          StressTable(tabIndex: 3, notificationMap: map),
          FruitTable(tabIndex: 4, notificationMap: map),
          TradeTable(tabIndex: 5, notificationMap: map),
        ],
      ),
    );
  }

  about() {
    map[tabIndex]?.changeVisible();
    debugPrint('index $tabIndex');
  }
}

setOverlayStyle() {
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white, //Color(0xFFf1f4fb),
      systemNavigationBarIconBrightness: Brightness.dark));
}
