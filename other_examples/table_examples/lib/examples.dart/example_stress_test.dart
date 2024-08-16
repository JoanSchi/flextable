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
  final _flexTableController = DefaultFtController();
  late FtScaleChangeNotifier scaleChangeNotifier;
  late DefaultFtModel ftModel;
  bool scaleSlider = false;

  @override
  void initState() {
    var (tableScale, scaleSlider) = switch (defaultTargetPlatform) {
      (TargetPlatform.macOS ||
            TargetPlatform.linux ||
            TargetPlatform.windows) =>
        (1.5, true),
      (_) => (1.0, false)
    };
    this.scaleSlider = scaleSlider;

    ftModel = DataModelBasic.makeTable(
      scrollUnlockX: true,
      scrollUnlockY: true,
    );

    scaleChangeNotifier = FtScaleChangeNotifier(scale: 1.0, min: 0.5, max: 4.0);

    super.initState();
  }

  @override
  void dispose() {
    _flexTableController.dispose();
    scaleChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget table = DefaultFlexTable(
      scaleChangeNotifier: scaleChangeNotifier,
      controller: _flexTableController,
      tableBuilder: BasicTableBuilder(),
      model: ftModel,
    );

    if (scaleSlider) {
      table = GridBorderLayout(children: [
        table,
        GridBorderLayoutPosition(
            row: 2,
            measureHeight: true,
            squeezeRatio: 1.0,
            child: TableScaleSlider(
                scaleChangeNotifier: scaleChangeNotifier, maxWidthSlider: null))
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
