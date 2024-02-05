// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class KeyedCell extends StatelessWidget {
  const KeyedCell({super.key, required this.child});

  final Widget child;

  factory KeyedCell.wrap(FtIndex? childIndex, Widget child) {
    final Key? key = child.key != null
        ? ValueKey<Key>(child.key!)
        : (childIndex != null ? ValueKey<FtIndex>(childIndex) : null);
    return KeyedCell(key: key, child: child);
  }

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
