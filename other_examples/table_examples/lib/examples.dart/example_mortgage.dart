// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/about/about_mortgage.dart';
import 'package:table_examples/examples.dart/flextable_settings.dart';
import '../about/about_dialog.dart';
import '../data_model/data_model_mortgage.dart';

class ExampleMortgage extends StatefulWidget {
  const ExampleMortgage({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleMortgage> createState() => _ExampleMortgageState();
}

class _ExampleMortgageState extends State<ExampleMortgage>
    with SettingsBottomSheet {
  final _globalKey = const GlobalObjectKey<ScaffoldState>('mortgage');
  final _ftController = DefaultFtController();
  late ScaleChangeNotifier scaleChangeNotifier;

  final ftModel = MortgageTableModel(horizontalTables: 2).makeTable(
    autoFreezeListX: true,
    autoFreezeListY: true,
  );
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

    scaleChangeNotifier = ScaleChangeNotifier(tableScale: tableScale);

    super.initState();
  }

  @override
  void dispose() {
    _ftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget table = DefaultFlexTable(
      tableChangeNotifiers: [scaleChangeNotifier],
      controller: _ftController,
      backgroundColor: Colors.white,
      model: ftModel,
      tableBuilder: MortgageTableBuilder(),
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
                controller: _ftController,
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
                dialogAboutBuilder(context, (context) => const AboutMortgage()),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => toggleSheet(_globalKey, _ftController),
          ),
        ],
        centerTitle: true,
        title: const Text('Mortgage'),
      ),
      body: table,
    );
  }
}
