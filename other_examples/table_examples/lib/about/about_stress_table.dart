// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class AboutStressTable extends StatelessWidget {
  const AboutStressTable({super.key});

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
                'The stress table can be slow. To increase speed, the zoom can be increased or the window can be narrowed.'
                '\n\n'
                'Like the other tables the split function can be applied by dragging from the right top corner. In this table scroll lock is disabled for both directions, this will enable indepent scroll for each panel',
            style: TextStyle(color: Colors.black, fontSize: sizeParagraph),
          ),
        ),
      ],
    );
  }
}
