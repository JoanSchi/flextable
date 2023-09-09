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
  FlexTableController flexTableController = FlexTableController();
  late ScaleChangeNotifier scaleChangeNotifier;

  final flexTableModel =
      createMorgageTableModel(horizontalTables: 2).tableModel(
    autoFreezeListX: true,
    autoFreezeListY: true,
  );
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

    scaleChangeNotifier = ScaleChangeNotifier(flexTableModel);

    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant ExampleMortgage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    flexTableController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget table = FlexTable(
      scaleChangeNotifier: scaleChangeNotifier,
      flexTableController: flexTableController,
      backgroundColor: Colors.white,
      flexTableModel: flexTableModel,
      tableBuilder: MortgageTableBuilder(),
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
            onPressed: () => toggleSheet(_globalKey, flexTableController),
          ),
        ],
        centerTitle: true,
        title: const Text('Mortgage'),
      ),
      body: table,
    );
  }
}
