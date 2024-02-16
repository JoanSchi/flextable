// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/material.dart';

class KeyedCell extends StatelessWidget {
  const KeyedCell({super.key, required this.child});

  final Widget child;

  factory KeyedCell.wrap(ValueKey? valueKey, Widget child) {
    final Key? key = child.key != null ? ValueKey<Key>(child.key!) : valueKey;
    return KeyedCell(key: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
