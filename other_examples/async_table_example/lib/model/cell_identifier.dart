// Copyright 2024 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

class CellIdentifier {
  final String tableName;
  final String itemName;
  final DateTime date;

  CellIdentifier(
      {required this.tableName, required this.itemName, required this.date});

  @override
  String toString() =>
      'CellIdentifier(tableName: $tableName, itemName: $itemName, date: $date)';
}
