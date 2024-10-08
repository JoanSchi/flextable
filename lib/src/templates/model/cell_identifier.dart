// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class CellIdentifier<Rid> extends FtCellIdentifier<Rid> {
  @override
  Rid rowId;
  @override
  String columnId;

  CellIdentifier({
    required this.rowId,
    required this.columnId,
  });
}

abstract class FtCellIdentifier<Rid> {
  Rid get rowId;
  String get columnId;
}
