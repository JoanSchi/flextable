// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:ui';
import '../model.dart';

class FreezeChange {
  FreezeChange({
    this.action = FreezeAction.noAction,
    this.position = Offset.zero,
    this.row = -1,
    this.column = -1,
  });

  final FreezeAction action;
  final Offset position;
  final int row;
  final int column;

  @override
  String toString() {
    return 'FreezeChange(action: $action, position: $position, row: $row, column: $column)';
  }
}
