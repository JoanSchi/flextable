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
  final ftController = DefaultFtController();
  late FtScaleChangeNotifier scaleChangeNotifier;
  late DefaultFtModel ftModel;

  @override
  void initState() {
    ftModel = MortgageTableModel(horizontalTables: 1).makeTable(
      autoFreezeListX: true,
      autoFreezeListY: true,
    );
    scaleChangeNotifier = FtScaleChangeNotifier();
    super.initState();
  }

  @override
  void dispose() {
    ftController.dispose();
    scaleChangeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget flexTable = DefaultFlexTable(
      tableChangeNotifiers: [scaleChangeNotifier],
      controller: ftController,
      tableBuilder: BasicTableBuilder(),
      backgroundColor: Colors.white,
      model: ftModel,
    );

    final scaleSlider = switch (defaultTargetPlatform) {
      (TargetPlatform.linux ||
            TargetPlatform.windows ||
            TargetPlatform.macOS) =>
        true,
      (_) => false
    };

    if (scaleSlider) {
      flexTable = GridBorderLayout(children: [
        flexTable,
        GridBorderLayoutPosition(
            row: 2,
            measureHeight: true,
            squeezeRatio: 1.0,
            child: TableScaleSlider(
                scaleChangeNotifier: scaleChangeNotifier,
                controller: ftController,
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
          ftController: ftController,
          child: flexTable,
        )
      ],
    ));
  }
}
