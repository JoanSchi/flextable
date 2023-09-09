// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/about/about_energy.dart';

import '../about/about_dialog.dart';
import '../data_model/data_model_energy.dart';
import 'flextable_settings.dart';

class ExampleEnergy extends StatefulWidget {
  const ExampleEnergy({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleEnergy> createState() => _ExampleEnergyState();
}

class _ExampleEnergyState extends State<ExampleEnergy>
    with SettingsBottomSheet {
  final _globalKey = const GlobalObjectKey<ScaffoldState>('energy');
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
        DataModelEngery().makeTable(platform: defaultTargetPlatform);

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
      flexTableController: _flexTableController,
      scaleChangeNotifier: scaleChangeNotifier,
      backgroundColor: Colors.grey[50],
      flexTableModel: flexTableModel,
      tableBuilder: DefaultTableBuilder(
          headerBackgroundColor: const Color.fromARGB(255, 244, 246, 248)),
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
                dialogAboutBuilder(context, (context) => const AboutEnergy()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => toggleSheet(_globalKey, _flexTableController),
          ),
        ],
        centerTitle: true,
        title: const Text('Energy'),
      ),
      body: table,
    );
  }
}
