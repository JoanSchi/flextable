// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:example_flextable/about.dart';
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../data/energie.dart';

class EnergyTable extends StatefulWidget {
  const EnergyTable({
    super.key,
    required this.tabIndex,
    required this.notificationMap,
  });

  final int tabIndex;
  final Map<int, AboutNotification> notificationMap;

  @override
  State<EnergyTable> createState() => _EnergyTableState();

  AboutNotification notification() {
    AboutNotification? ab = notificationMap[tabIndex];
    if (ab == null) {
      ab = AboutNotification();
      notificationMap[tabIndex] = ab;
    }
    return ab;
  }
}

class _EnergyTableState extends State<EnergyTable> {
  late FlexTableController _flexTableController;
  FlexTableScaleChangeNotifier? scaleChangeNotifier;

  @override
  void initState() {
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
    final ThemeData theme = Theme.of(context);
    TargetPlatform platform = theme.platform;

    bool scaleSlider;

    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
        scaleSlider = false;
        break;
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        scaleSlider = true;
        break;
    }

    const double sizeAbout = 24.0;
    const double sizeHeader = 18.0;
    const double sizeParagraph = 16.0;

    if (scaleSlider) {
      scaleChangeNotifier = FlexTableScaleChangeNotifier();
    }

    Widget table = FlexTable(
      flexTableController: _flexTableController,
      scaleChangeNotifier: scaleChangeNotifier,
      backgroundColor: Colors.grey[50],
      flexTableModel: EnergieWarmte().makeTable(platform: platform),

      //splitPositionProperties: const SplitPositionProperties(useSplitPosition: false),
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

    return About(
      notification: widget.notification(),
      about: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900.0),
            child: ListView(
              children: [
                const Center(
                  child: Text(
                    'About',
                    style:
                        TextStyle(color: Colors.black87, fontSize: sizeAbout),
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                RichText(
                  text: const TextSpan(
                    text:
                        'The energy table is about design and is using a customized tablebuilder to draw a bar in percentage columns.'
                        '\n\n'
                        'Autofreeze is not enabled in this example, therefore manual freeze can be used by pressing long on a intersection or cross intersection of the line. Freezing the top left intersection of the first green cell should make sense.'
                        ' Unlike autofreeze manual freeze can be repositioned. The illustration below shows the dragging areas (a square of 50.0)',
                    style:
                        TextStyle(color: Colors.black, fontSize: sizeParagraph),
                  ),
                ),
                const SizedBox(
                  height: 8.0,
                ),
                LayoutBuilder(builder: (context, BoxConstraints constraints) {
                  final double s =
                      math.min(300, constraints.biggest.shortestSide - 16.0);
                  return SizedBox(
                      height: math.min(300, constraints.biggest.shortestSide),
                      child: Image(
                        image:
                            const AssetImage('graphics/reposition_freeze.png'),
                        width: s,
                        height: s,
                      ));
                }),
                const SizedBox(
                  height: 8.0,
                ),
                RichText(
                  text: TextSpan(
                    text:
                        'If freeze is not enabled, the split function can be applied by dragging from top/right.'
                        '\n\n',
                    style: const TextStyle(
                        color: Colors.black, fontSize: sizeParagraph),
                    children: [
                      TextSpan(
                        text: 'Android:',
                        style: TextStyle(
                          fontSize: sizeHeader,
                          color: theme.primaryColor,
                        ),
                      ),
                      const TextSpan(
                          text:
                              '\nFlexbar supports two-way scrolling,to prevent drifting while scrolling flextable use a stabiliser. The scrollbars can be used if the appear after the drag starts. Zoom is like aspected with two fingers.'
                              '\n\n'),
                      TextSpan(
                        text: 'Linux/Windows:',
                        style: TextStyle(
                          fontSize: sizeHeader,
                          color: theme.primaryColor,
                        ),
                      ),
                      const TextSpan(
                          text:
                              '\nScrolling can be performed with the scrollingbars and with the mouse, althought the last one should be officialy blocked it is quite handy. Zoom can be performed by the slider at the bottom right or with the mouse by pressing: ctrl -> move the mouse for precision -> press left button mouse and move for zoom.'
                              '\n\n'),
                      TextSpan(
                        text: 'Linux/Windows:',
                        style: TextStyle(
                          fontSize: sizeHeader,
                          color: theme.primaryColor,
                        ),
                      ),
                      const TextSpan(
                          text:
                              '\nScrolling can be performed with the scrollingbars and with the mouse, althought the last one should be officialy blocked it is quite handy. Zoom can be performed by the slider at the bottom right or with the mouse by pressing: ctrl -> move the mouse for precision -> press left button mouse and move for zoom.')
                    ],
                  ),
                ),
                const SizedBox(
                  height: 48.0,
                ),
              ],
            ),
          ),
        ),
      ),
      body: table,
    );
  }
}
