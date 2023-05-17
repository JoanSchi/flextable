// Copyright (C) 2023 Joan Schipper
// 
// This file is part of flextable.
// 
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import 'package:example_flextable/tables/energy_table.dart';
import 'package:example_flextable/tables/fruit_table.dart';
import 'package:example_flextable/tables/hypotheek_table.dart';
import 'package:example_flextable/tables/stress_table.dart';
import 'package:example_flextable/tables/trade_table.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'about.dart';
import 'tables/sliver_tables.dart';

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
    return ScrollConfiguration(
      behavior: const MyMaterialScrollBehavior(),
      child: Scaffold(
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

class MyMaterialScrollBehavior extends ScrollBehavior {
  final bool useSwipe;

  const MyMaterialScrollBehavior({this.useSwipe = false});

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

  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    // When modifying this function, consider modifying the implementation in
    // the base class ScrollBehavior as well.
    late final AndroidOverscrollIndicator indicator;
    if (Theme.of(context).useMaterial3) {
      indicator = AndroidOverscrollIndicator.stretch;
    } else {
      indicator = AndroidOverscrollIndicator.glow;
    }
    switch (getPlatform(context)) {
      case TargetPlatform.iOS:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return child;
      case TargetPlatform.android:
        switch (indicator) {
          case AndroidOverscrollIndicator.stretch:
            return StretchingOverscrollIndicator(
              axisDirection: details.direction,
              clipBehavior: details.decorationClipBehavior ?? Clip.hardEdge,
              child: child,
            );
          case AndroidOverscrollIndicator.glow:
            continue glow;
        }
      glow:
      case TargetPlatform.fuchsia:
        return GlowingOverscrollIndicator(
          axisDirection: details.direction,
          color: Theme.of(context).colorScheme.secondary,
          child: child,
        );
    }
  }
}
