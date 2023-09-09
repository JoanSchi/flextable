// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/about/about_stress_table.dart';
import '../about/about_dialog.dart';
import '../data_model/data_model_basic.dart';
import 'flextable_settings.dart';

class ExampleStressTest extends StatefulWidget {
  const ExampleStressTest({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleStressTest> createState() => _ExampleStressTestState();
}

class _ExampleStressTestState extends State<ExampleStressTest>
    with SettingsBottomSheet {
  final _globalKey = const GlobalObjectKey<ScaffoldState>('stress');
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

    flexTableModel = DataModelBasic.positions().makeTable(
      scrollUnlockX: true,
      scrollUnlockY: true,
    );

    if (scaleSlider) {
      scaleChangeNotifier = ScaleChangeNotifier(flexTableModel);
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
      scaleChangeNotifier: scaleChangeNotifier,
      flexTableController: _flexTableController,
      tableBuilder: BasicTableBuilder(),
      flexTableModel: flexTableModel,
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
                context, (context) => const AboutStressTable()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => toggleSheet(_globalKey, _flexTableController),
          ),
        ],
        centerTitle: true,
        title: const Text('Stress Test'),
      ),
      body: table,
    );
  }
}
