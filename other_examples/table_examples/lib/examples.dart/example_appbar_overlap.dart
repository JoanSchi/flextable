// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:table_examples/data_model/data_model_mortgage.dart';
import '../about/about_appbar_overlap.dart';
import '../about/about_dialog.dart';

class ExampleAppBarOverlap extends StatefulWidget {
  const ExampleAppBarOverlap({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  State<ExampleAppBarOverlap> createState() => _ExampleAppBarOverlapState();
}

class _ExampleAppBarOverlapState extends State<ExampleAppBarOverlap> {
  late FlexTableController flexTableController;
  late ScaleChangeNotifier scaleChangeNotifier;
  late FlexTableModel flexTableModel;

  @override
  void initState() {
    flexTableController = FlexTableController();
    flexTableModel = createMorgageTableModel(horizontalTables: 1).tableModel(
      autoFreezeListX: true,
      autoFreezeListY: true,
    );
    scaleChangeNotifier = ScaleChangeNotifier(flexTableModel: flexTableModel);
    super.initState();
  }

  @override
  void dispose() {
    flexTableController.dispose();
    scaleChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget table = FlexTable(
      scaleChangeNotifier: scaleChangeNotifier,
      flexTableController: flexTableController,
      tableBuilder: MortgageTableBuilder(),
      backgroundColor: Colors.white,
      flexTableModel: flexTableModel,
    );

    final scaleSlider = switch (defaultTargetPlatform) {
      (TargetPlatform.linux ||
            TargetPlatform.windows ||
            TargetPlatform.macOS) =>
        true,
      (_) => false
    };

    if (scaleSlider) {
      table = GridBorderLayout(children: [
        table,
        GridBorderLayoutPosition(
            row: 2,
            measureHeight: true,
            squeezeRatio: 1.0,
            child: TableBottomBar(
                scaleChangeNotifier: scaleChangeNotifier,
                flexTableController: flexTableController,
                maxWidthSlider: 200.0))
      ]);
    }

    return Scaffold(
        body: CustomScrollView(
      slivers: [
        SliverAppBar(
          leading: IconButton(
            icon: const Icon(Icons.menu),
            onPressed: widget.openDrawer,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => dialogAboutBuilder(
                  context, (context) => const AboutAppBarOverlap()),
            )
          ],
          expandedHeight: 250.0,
          flexibleSpace: const FlexibleSpaceBar(
            centerTitle: true,
            title:
                Text('AppBar Overlap', style: TextStyle(color: Colors.black)),
          ),
          floating: true,
          pinned: true,
          snap: true,
        ),
        FlexTableToSliverBox(
          flexTableController: flexTableController,
          child: table,
        )
      ],
    ));
  }
}
