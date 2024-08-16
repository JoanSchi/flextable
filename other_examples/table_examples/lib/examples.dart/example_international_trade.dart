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
  final _ftController = DefaultFtController();
  late FtScaleChangeNotifier scaleChangeNotifier;
  late DefaultFtModel ftModel;
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

    final tableScale = switch (defaultTargetPlatform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        1.5,
      (_) => 1.0
    };

    ftModel = DataModelInternationalTrade().makeTable(
      tableScale: tableScale,
      scrollUnlockX: false,
      scrollUnlockY: true,
      // autofreezeAreaX: [
      //   AutoFreezeArea(startIndex: 0, freezeIndex: 1, endIndex: 1000)
      // ],
      autofreezeAreasY: [
        AutoFreezeArea(startIndex: 0, freezeIndex: 3, endIndex: 1000)
      ],
    );

    scaleChangeNotifier = FtScaleChangeNotifier(scale: 1.0, min: 0.5, max: 4.0);

    super.initState();
  }

  @override
  void dispose() {
    _ftController.dispose();
    scaleChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget table = DefaultFlexTable(
      controller: _ftController,
      scaleChangeNotifier: scaleChangeNotifier,
      model: ftModel,
      tableBuilder: BasicTableBuilder(),
    );

    if (scaleSlider) {
      table = GridBorderLayout(children: [
        table,
        GridBorderLayoutPosition(
            row: 2,
            measureHeight: true,
            squeezeRatio: 1.0,
            child: TableScaleSlider(
                scaleChangeNotifier: scaleChangeNotifier,
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
            onPressed: () => toggleSheet(_globalKey, _ftController),
          ),
        ],
        centerTitle: true,
        title: const Text('Trade'),
      ),
      body: table,
    );
  }
}
