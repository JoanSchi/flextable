// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class AboutInternationalTrade extends StatelessWidget {
  const AboutInternationalTrade({super.key});

  @override
  Widget build(BuildContext context) {
    const double sizeAbout = 24.0;
    const double sizeParagraph = 16.0;

    final theme = Theme.of(context);

    return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900.0),
                child: ListView(children: [
                  Center(
                    child: Text(
                      'About',
                      style: TextStyle(
                          color: theme.primaryColor, fontSize: sizeAbout),
                    ),
                  ),
                  const SizedBox(
                    height: 8.0,
                  ),
                  RichText(
                    text: const TextSpan(
                      text: 'Trade table with autofreeze.'
                          '\n\n'
                          '''The split function can be applied by dragging from the right top corner. Vertical autofreeze is enabled and the horizontal autofreeze is disabled, therefore the vertical manual freeze can be used. Less intesting option: The horizontal autolock is also disabled, therefore if the horizontal split is applied the top and bottom panel can scroll independently in de horizontal direction.'''
                          ' It is not possible to use autofreeze and the scrollunlock together.'
                          '\n\n',
                      style: TextStyle(
                          color: Colors.black, fontSize: sizeParagraph),
                    ),
                  ),
                  const SizedBox(
                    height: 48.0,
                  ),
                ]))));
  }
}
