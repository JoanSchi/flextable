// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class AboutSliverTables extends StatelessWidget {
  const AboutSliverTables({super.key});

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
          style: TextStyle(color: Colors.black87, fontSize: sizeParagraph),
          text:
              "Flextable's can be placed in CustomScrollView, by wrapping the flextable in a SliverToViewPortBox with FlexTableToViewPortBoxDelegate as delegate. This makes flextable ideal for a overview at the end of the customscrollview."
              '\n\n'
              'Almost all functions are availibe like zoom, freeze, autofreeze, except for horizontal split and the two way scroll. Two way scroll is not possible because the vertical scroll is controlled by CustomScrollView and the horizontal scroll is controllered by the controller of the table.'
              ' Like the normal flextable, only the visible cells are created, therefore flextable is slivers should be as fast as normal flextable.',
        )),
      ],
    );
  }
}
