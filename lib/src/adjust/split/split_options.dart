// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'adjust_table_split.dart';

class SplitOptions {
  const SplitOptions(
      {this.useSplitPosition = true,
      this.xSplitSelectArea = const SelectArea(
          width: 50.0, height: 100.0, horizontalAlignment: HitAlignment.end),
      this.ySplitSelectArea = const SelectArea(
          width: 100.0, height: 50.0, horizontalAlignment: HitAlignment.end),
      this.marginSplit = 20.0});

  final bool useSplitPosition;
  final SelectArea xSplitSelectArea;
  final SelectArea ySplitSelectArea;
  final double marginSplit;
}

class SelectArea {
  const SelectArea(
      {required this.width,
      required this.height,
      this.horizontalAlignment = HitAlignment.end,
      this.verticalAlignment = HitAlignment.start});

  final double width;
  final double height;
  final HitAlignment horizontalAlignment;
  final HitAlignment verticalAlignment;
}
