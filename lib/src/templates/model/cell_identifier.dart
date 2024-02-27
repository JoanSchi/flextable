// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class CellIdentifier extends FtCellIdentifier {
  @override
  String rowId;
  @override
  String columnId;

  CellIdentifier({
    required this.rowId,
    required this.columnId,
  });
}

abstract class FtCellIdentifier {
  String get rowId;
  String get columnId;
}
