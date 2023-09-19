// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/about/about_international_trade.dart';
import 'package:table_examples/examples.dart/flextable_settings.dart';
import '../about/about_dialog.dart';
import '../data_model/data_model_international_trade.dart';

class ExampleInternationalTrade extends StatefulWidget {
  const ExampleInternationalTrade({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleInternationalTrade> createState() =>
      _ExampleInternationalTradeState();
}

class _ExampleInternationalTradeState extends State<ExampleInternationalTrade>
    with SettingsBottomSheet {
  final _globalKey = const GlobalObjectKey<ScaffoldState>('trade');
  late FlexTableController _flexTableController;
  ScaleChangeNotifier? scaleChangeNotifier;
  late FlexTableModel flexTableModel;
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

    flexTableModel = DataModelInternationalTrade().makeTable(
      platform: defaultTargetPlatform,
      scrollUnlockX: false,
      scrollUnlockY: true,
      // autofreezeAreaX: [
      //   AutoFreezeArea(startIndex: 0, freezeIndex: 1, endIndex: 1000)
      // ],
      autofreezeAreasY: [
        AutoFreezeArea(startIndex: 0, freezeIndex: 3, endIndex: 1000)
      ],
    );

    if (scaleSlider) {
      scaleChangeNotifier = ScaleChangeNotifier(flexTableModel: flexTableModel);
    }

    _flexTableController = FlexTableController();
    super.initState();
  }

  @override
  void dispose() {
    _flexTableController.dispose();
    scaleChangeNotifier?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget table = FlexTable(
      flexTableController: _flexTableController,
      scaleChangeNotifier: scaleChangeNotifier,
      backgroundColor: Colors.grey[50],
      flexTableModel: flexTableModel,
      tableBuilder: DefaultTableBuilder(),
    );

    if (scaleSlider) {
      table = GridBorderLayout(children: [
        table,
        GridBorderLayoutPosition(
            row: 2,
            measureHeight: true,
            squeezeRatio: 1.0,
            child: TableBottomBar(
                scaleChangeNotifier: scaleChangeNotifier!,
                flexTableController: _flexTableController,
                maxWidthSlider: 200.0))
      ]);
    }

    return Scaffold(
      key: _globalKey,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 227, 238, 245),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: widget.openDrawer,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => dialogAboutBuilder(
                context, (context) => const AboutInternationalTrade()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => toggleSheet(_globalKey, _flexTableController),
          ),
        ],
        centerTitle: true,
        title: const Text('Trade'),
      ),
      body: table,
    );
  }
}
