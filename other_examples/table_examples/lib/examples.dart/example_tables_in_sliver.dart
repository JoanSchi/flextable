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
  final FlexTableController _energieFlexTableController = FlexTableController();
  final FlexTableController _handelFlexTableController = FlexTableController();
  final FlexTableController _fruitFlexTableController = FlexTableController();
  final FlexTableController _hypotheekFlexTableController =
      FlexTableController();
  final FlexTableController _basicFlexTableController = FlexTableController();
  bool scaleSlider = false;

  @override
  void initState() {
    scaleSlider = switch (defaultTargetPlatform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        true,
      (_) => false
    };
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    TargetPlatform platform = theme.platform;

    Widget makeTable(
        {required FlexTableController flexTableController,
        required FlexTableModel flexTableModel,
        TableBuilder? tableBuilder}) {
      ScaleChangeNotifier scaleChangeNotifier =
          ScaleChangeNotifier(flexTableModel);

      Widget table = FlexTable(
        scaleChangeNotifier: scaleChangeNotifier,
        flexTableController: flexTableController,
        tableBuilder: tableBuilder,
        flexTableModel: flexTableModel,
      );

      if (scaleSlider) {
        table = GridBorderLayout(children: [
          table,
          GridBorderLayoutPosition(
              row: 2,
              squeezeRatio: 1.0,
              measureHeight: true,
              child: TableBottomBar(
                  scaleChangeNotifier: scaleChangeNotifier,
                  flexTableController: flexTableController,
                  maxWidthSlider: 200.0))
        ]);
      }
      return FlexTableToSliverBox(
          flexTableController: flexTableController, child: table);
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
                  flexTableController: _energieFlexTableController,
                  flexTableModel:
                      DataModelEngery().makeTable(platform: platform)),
              const InfoBox(
                  title: 'Trade', info: 'AutoFreeze\nVertical split\nzoom'),
              makeTable(
                  flexTableController: _handelFlexTableController,
                  flexTableModel: DataModelInternationalTrade().makeTable(
                    platform: platform,
                  )),
              const InfoBox(
                  title: 'Fruit', info: 'Freeze\nVertical split\nzoom'),
              makeTable(
                  flexTableController: _fruitFlexTableController,
                  flexTableModel:
                      DataModelFruit().makeTable(platform: platform)),
              const InfoBox(
                title: 'Mortgage',
                info: 'Autofreeze\nVertical split\nzoom',
              ),
              makeTable(
                  flexTableController: _hypotheekFlexTableController,
                  flexTableModel:
                      createMorgageTableModel(horizontalTables: 2).tableModel(
                    autoFreezeListX: true,
                    autoFreezeListY: true,
                  ),
                  tableBuilder: MortgageTableBuilder()),
              const InfoBox(
                title: 'Stress table',
                info: 'Manual freeze\nVertical split\nzoom',
              ),
              makeTable(
                  flexTableController: _basicFlexTableController,
                  flexTableModel:
                      DataModelBasic.positions(rows: 300).makeTable()),
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
