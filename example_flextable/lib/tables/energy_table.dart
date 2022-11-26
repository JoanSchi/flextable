// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:example_flextable/about.dart';
import 'package:flextable/FlexTable/body_layout.dart';
import 'package:flextable/FlexTable/table_bottombar.dart';
import 'package:flextable/FlexTable/table_multi_panel_portview.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../data/energie.dart';

class EnergyTable extends StatefulWidget {
  final int tabIndex;
  final Map<int, AboutNotification> notificationMap;

  const EnergyTable({
    Key? key,
    required this.tabIndex,
    required this.notificationMap,
  }) : super(key: key);

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
  @override
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
      body: FlexTable(
        backgroundColor: Colors.grey[50],
        tableModel: EnergieWarmte().makeTable(platform: platform),
        sizeScrollBarTrack: 0.0,
        //splitPositionProperties: const SplitPositionProperties(useSplitPosition: false),
        sidePanelWidget: [
          if (scaleSlider)
            (tableModel) => FlexTableLayoutParentDataWidget(
                tableLayoutPosition: const FlexTableLayoutPosition.bottom(),
                child: TableBottomBar(
                    tableModel: tableModel, maxWidthSlider: 200.0))
        ],
      ),
    );
  }
}
