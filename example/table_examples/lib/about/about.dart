// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key, required this.openDrawer});

  final VoidCallback openDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    const double sizeHeader = 18.0;
    const double sizeParagraph = 16.0;

    Widget about = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900.0),
        child: ListView(
          padding: const EdgeInsets.all(8.0),
          children: [
            RichText(
              text: TextSpan(
                text:
                    'FlexTable is a customizable table with headers, splitView, freezeView, autoFreeze, zoom and scrollbars. The table consist of a model, a viewmodel and builders. The table can scrolls in two directions at the same time. If the first scroll is however horizontal or vertical, the cross direction is locked until the ballistic scroll ends  to prevent a unwanted drift if the user scrolls enthousiatic for serveral pages.'
                    '\n\n'
                    'Flexbar supports two-way scrolling,to prevent drifting while scrolling flextable use a stabiliser. The scrollbars can be used if they appear after the drag starts.'
                    '\n\n'
                    'It is also possible to place the FlexTable in a customScrollView by wrapping the FlexTable in a adaptive sliver, wrapped in a sliver the table can only scroll in one direction at the same time.'
                    '\n\n'
                    'Except for the tables in ScrollView, the examples also have a settings panel to try different settings.'
                    '\n\n',
                style: const TextStyle(
                    color: Colors.black, fontSize: sizeParagraph),
                children: [
                  TextSpan(
                    text: 'Linux/Windows',
                    style: TextStyle(
                      fontSize: sizeHeader,
                      color: theme.primaryColor,
                    ),
                  ),
                  const TextSpan(
                      text:
                          '\nScrolling can be performed with the scrollingbars and with the mouse, althought the last one should be officialy blocked it is quite handy. Zoom can be performed by the slider at the bottom right or with the mouse by pressing: ctrl -> move the mouse for precision -> press left button mouse and move for zoom.'
                          '\n\n'),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 227, 238, 245),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: openDrawer,
        ),
        centerTitle: true,
        title: const Text('About'),
      ),
      body: about,
    );
  }
}
