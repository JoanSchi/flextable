// Copyright (C) 2023 Joan Schipper
// 
// This file is part of flextable.
// 
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import 'package:example_flextable/about.dart';
import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import '../data/fruit.dart';

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
    if (scaleSlider) {
      scaleChangeNotifier = FlexTableScaleChangeNotifier();
    }

    Widget table = FlexTable(
      flexTableController: _flexTableController,
      scaleChangeNotifier: scaleChangeNotifier,
      backgroundColor: Colors.grey[50],
      flexTableModel: Fruit().makeTable(
          platform: platform, scrollLockX: false, scrollLockY: false),

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
                    text: TextSpan(
                      text: 'Simple and small flextable.'
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
        body: table);
  }
}
