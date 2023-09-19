// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/about/about_fruit.dart';
import 'package:table_examples/data_model/data_model_fruit.dart';
import 'package:table_examples/examples.dart/flextable_settings.dart';

import '../about/about_dialog.dart';

class ExampleFruit extends StatefulWidget {
  const ExampleFruit({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleFruit> createState() => _ExampleFruitState();
}

class _ExampleFruitState extends State<ExampleFruit> with SettingsBottomSheet {
  final _globalKey = const GlobalObjectKey<ScaffoldState>('fruit');
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

    flexTableModel =
        DataModelFruit().makeTable(platform: defaultTargetPlatform);

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
      tableBuilder: DefaultTableBuilder(
          headerBackgroundColor: const Color.fromARGB(255, 240, 240, 231),
          headerLineColor: const Color.fromARGB(255, 48, 67, 3),
          headerTextStyle:
              const TextStyle(color: Color.fromARGB(255, 48, 67, 3))),
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
            onPressed: () =>
                dialogAboutBuilder(context, (context) => const AboutFruit()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => toggleSheet(_globalKey, _flexTableController),
          ),
        ],
        centerTitle: true,
        title: const Text('Fruit'),
      ),
      body: table,
    );
  }
}
