// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../about/about_dialog.dart';
import '../about/about_sliver_tables.dart';
import '../data_model/data_model_basic.dart';
import '../data_model/data_model_energy.dart';
import '../data_model/data_model_fruit.dart';
import '../data_model/data_model_international_trade.dart';
import '../data_model/data_model_mortgage.dart';

class ExampleSliverInTables extends StatefulWidget {
  const ExampleSliverInTables({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleSliverInTables> createState() => _ExampleSliverInTablesState();
}

class _ExampleSliverInTablesState extends State<ExampleSliverInTables> {
  Map<String, DefaultFtController> controllers = {};

  bool scaleSlider = false;
  double tableScale = 1.0;
  @override
  void initState() {
    var (tableScale, scaleSlider) = switch (defaultTargetPlatform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        (1.5, true),
      (_) => (1.0, false)
    };
    this.tableScale = tableScale;
    this.scaleSlider = scaleSlider;

    super.initState();
  }

  @override
  void dispose() {
    controllers.forEach((key, value) {
      value.dispose();
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget makeTable(
        {required String id,
        required DefaultFtModel ftModel,
        DefaultTableBuilder? tableBuilder}) {
      ScaleChangeNotifier scaleChangeNotifier =
          ScaleChangeNotifier(tableScale: ftModel.tableScale);

      final ftController =
          controllers.putIfAbsent(id, () => DefaultFtController());

      Widget table = DefaultFlexTable(
        tableChangeNotifiers: [scaleChangeNotifier],
        controller: ftController,
        model: ftModel,
        tableBuilder: DefaultTableBuilder(),
      );

      if (scaleSlider) {
        table = GridBorderLayout(children: [
          table,
          GridBorderLayoutPosition(
              row: 2,
              squeezeRatio: 1.0,
              measureHeight: true,
              child: TableScaleSlider(
                  scaleChangeNotifier: scaleChangeNotifier,
                  controller: ftController,
                  maxWidthSlider: 200.0))
        ]);
      }
      return FlexTableToSliverBox(ftController: ftController, child: table);
    }

    final scrollView = Container(
      color: const Color.fromARGB(255, 245, 248, 250),
      alignment: Alignment.center,
      child: Container(
          color: Colors.white,
          width: 1000.0,
          child: CustomScrollView(
            slivers: <Widget>[
              const InfoBox(
                  title: 'Energy and heat',
                  info: 'Manual Freeze\nVertical split\nzoom'),
              makeTable(
                  id: 'Energy',
                  ftModel: DataModelEngery.makeTable(tableScale: tableScale)),
              const InfoBox(
                  title: 'Trade', info: 'AutoFreeze\nVertical split\nzoom'),
              makeTable(
                  id: 'Trade',
                  ftModel: DataModelInternationalTrade().makeTable(
                    tableScale: tableScale,
                  )),
              const InfoBox(
                  title: 'Fruit', info: 'Freeze\nVertical split\nzoom'),
              makeTable(
                  id: 'Fruit',
                  ftModel: DataModelFruit().makeTable(tableScale: tableScale)),
              const InfoBox(
                title: 'Mortgage',
                info: 'Autofreeze\nVertical split\nzoom',
              ),
              makeTable(
                  id: 'Mortgage',
                  ftModel: MortgageTableModel(horizontalTables: 2).makeTable(
                    autoFreezeListX: true,
                    autoFreezeListY: true,
                  ),
                  tableBuilder: MortgageTableBuilder()),
              const InfoBox(
                title: 'Stress table',
                info: 'Manual freeze\nVertical split\nzoom',
              ),
              makeTable(
                  id: 'Basic', ftModel: DataModelBasic.makeTable(rows: 300)),
            ],
          )),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => dialogAboutBuilder(
                context, (context) => const AboutSliverTables()),
          )
        ],
        centerTitle: true,
        title: const Text('Tables in Slivers'),
      ),
      body: scrollView,
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String info;
  const InfoBox({
    Key? key,
    required this.title,
    required this.info,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        color: const Color.fromARGB(255, 245, 248, 250),
        margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 4.0),
        child: DefaultTextStyle(
          style: const TextStyle(
              color: Color.fromARGB(255, 75, 127, 154), fontSize: 24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 400.0),
            child: Column(children: [
              const SizedBox(
                height: 16.0,
              ),
              Text(
                title,
                style: const TextStyle(fontSize: 24.0),
              ),
              const Divider(
                  color: Color.fromARGB(255, 117, 167, 193),
                  indent: 8.0,
                  endIndent: 8.0),
              const Text(
                '{ spacer }',
              ),
              Expanded(child: Center(child: Text(info))),
              const SizedBox(
                height: 16.0,
              )
            ]),
          ),
        ),
      ),
    );
  }
}
