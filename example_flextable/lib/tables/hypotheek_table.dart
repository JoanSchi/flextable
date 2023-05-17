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

import '../data/hypotheek.dart';

class HypotheekTable extends StatefulWidget {
  final int tabIndex;
  final Map<int, AboutNotification> notificationMap;

  const HypotheekTable({
    super.key,
    required this.tabIndex,
    required this.notificationMap,
  });

  @override
  State<HypotheekTable> createState() => _HypotheekTableState();

  AboutNotification notification() {
    AboutNotification? ab = notificationMap[tabIndex];
    if (ab == null) {
      ab = AboutNotification();
      notificationMap[tabIndex] = ab;
    }
    return ab;
  }
}

class _HypotheekTableState extends State<HypotheekTable> {
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

    scaleSlider = true;

    if (scaleSlider) {
      scaleChangeNotifier = FlexTableScaleChangeNotifier();
    }

    Widget table = FlexTable(
      scaleChangeNotifier: scaleChangeNotifier,
      flexTableController: _flexTableController,
      backgroundColor: Colors.white,
      flexTableModel: hypotheekExample1(tableColumns: 2).tableModel(
        autoFreezeListX: true,
        autoFreezeListY: true,
      ),
      tableBuilder: HypoteekTableBuilder(),
    );

    if (scaleSlider) {
      table = GridBorderLayout(children: [
        table,
        GridBorderLayoutPosition(
            row: 2,
            squeezeRatio: 1.0,
            measureHeight: true,
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
                  text: TextSpan(
                    text:
                        'Flextable started with the desire to have a clear table of the mortgage calculation with the following properties: fast, zoomable, customable cells, lines, marged cells and maybe freeze and split.'
                        '\n\n'
                        'The flextable below shows several mortgage tables with merged colums, rows, different lines and predefined autofreezes.'
                        'The autofreezes locks the row header (date) and the colum header until the scroll passes the defined end of the autofreeze. As long the start, freeze and the end of the autofreeze does not overlap another autofreeze, multiple autofreezes can be added.'
                        '''The split function can be applied by dragging from the right top corner. Autofreeze is deactivated.'''
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
      body: table,
    );
  }
}