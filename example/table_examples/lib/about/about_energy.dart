// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';
import 'dart:math' as math;

class AboutEnergy extends StatelessWidget {
  const AboutEnergy({super.key});

  @override
  Widget build(BuildContext context) {
    const double sizeAbout = 24.0;
    const double sizeParagraph = 16.0;

    final theme = Theme.of(context);

    return ListView(
      shrinkWrap: true,
      children: [
        Center(
          child: Text(
            'About',
            style: TextStyle(color: theme.primaryColor, fontSize: sizeAbout),
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
            style: TextStyle(color: Colors.black, fontSize: sizeParagraph),
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
                image: const AssetImage('graphics/reposition_freeze.png'),
                width: s,
                height: s,
              ));
        }),
        const SizedBox(
          height: 8.0,
        ),
        RichText(
          text: const TextSpan(
            text:
                'If freeze is not enabled, the split function can be applied by dragging from top/right.',
            style: TextStyle(color: Colors.black, fontSize: sizeParagraph),
          ),
        ),
      ],
    );
  }
}
