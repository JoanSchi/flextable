import 'package:example/about.dart';
import 'package:flextable/FlexTable/BodyLayout.dart';
import 'package:flextable/FlexTable/TableBottomBar.dart';
import 'package:flextable/FlexTable/TableMultiPanelPortView.dart';
import 'package:flutter/material.dart';

import '../data/fruit.dart';
import '../data/hypotheek.dart';

class FruitTable extends StatefulWidget {
  final int tabIndex;
  final Map<int, AboutNotification> notificationMap;

  const FruitTable({
    super.key,
    required this.tabIndex,
    required this.notificationMap,
  });

  @override
  State<FruitTable> createState() => _FruitTableState();

  AboutNotification notification() {
    AboutNotification? ab = notificationMap[tabIndex];
    if (ab == null) {
      ab = AboutNotification();
      notificationMap[tabIndex] = ab;
    }
    return ab;
  }
}

class _FruitTableState extends State<FruitTable> {
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
                      style: TextStyle(color: Colors.black87, fontSize: 24),
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  RichText(
                    text: TextSpan(
                      text: 'Simple and small flextable.'
                          '\n\n',
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: 'Android:',
                          style: TextStyle(
                            fontSize: 18,
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
                            fontSize: 18,
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
                            fontSize: 18,
                            color: theme.primaryColor,
                          ),
                        ),
                        const TextSpan(
                            text:
                                '\nScrolling can be performed with the scrollingbars and with the mouse, althought the last one should be officialy blocked it is quite handy. Zoom can be performed by the slider at the bottom right or with the mouse by pressing: ctrl -> move the mouse for precision -> press left button mouse and move for zoom.'
                                '\n\n')
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
          tableModel: Fruit().makeTable(
              platform: platform, scrollLockX: false, scrollLockY: false),
          sizeScrollBarTrack: 0.0,
          //splitPositionProperties: const SplitPositionProperties(useSplitPosition: false),
          sidePanelWidget: [
            if (scaleSlider)
              (tableModel) => FlexTableLayoutParentDataWidget(
                  tableLayoutPosition: const FlexTableLayoutPosition.bottom(),
                  child: TableBottomBar(
                      tableModel: tableModel, maxWidthSlider: 200.0))
          ],
        ));
  }
}
