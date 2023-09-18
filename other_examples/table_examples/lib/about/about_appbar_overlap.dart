// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class AboutAppBarOverlap extends StatelessWidget {
  const AboutAppBarOverlap({super.key});

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
                'A simple CustomScrollView with a floating, pinned, snap SliverAppBar to demonstrate the overlay/overlap implementation of the FlexTableToSliverBox.'
                ' The FlexTableToSliverBox is used to place the FlexTable in a  CustomScrollView.'
                '\n',
            style: TextStyle(color: Colors.black, fontSize: sizeParagraph),
          ),
        ),
      ],
    );
  }
}
