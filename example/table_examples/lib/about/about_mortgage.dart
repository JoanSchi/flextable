// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class AboutMortgage extends StatelessWidget {
  const AboutMortgage({super.key});

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
                'Flextable started with the desire to have a clear table of the mortgage calculation with the following properties: fast, zoomable, customable cells, lines, marged cells and maybe freeze and split.'
                '\n\n'
                'The flextable shows several mortgage tables with merged colums, rows, different lines and predefined autofreezes.'
                'The autofreezes locks the row header (date) and the colum header until the scroll passes the defined end of the autofreeze. As long the start, freeze and the end of the autofreeze does not overlap another autofreeze, multiple autofreezes can be added.'
                'The split function can be applied by dragging from the right top corner. Autofreeze is deactivated.',
            style: TextStyle(color: Colors.black, fontSize: sizeParagraph),
          ),
        ),
      ],
    );
  }
}
