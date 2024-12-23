// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/adjust/freeze/adjust_freeze_properties.dart';
import 'package:flextable/src/adjust/split/adjust_split_properties.dart';
import 'package:flutter/widgets.dart';

class FtProperties {
  const FtProperties(
      {this.minTableScale = 0.5,
      this.maxTableScale = 4.0,
      this.maxRowHeaderScale = 1.5,
      this.maxColumnHeaderScale = 1.5,
      this.adjustFreeze,
      this.adjustSplit,
      this.minimalSizeDividedWindow = 20.0,
      this.spaceSplit = 2.0,
      this.spaceSplitFreeze = 2.0,
      this.extentScrollBarHit = 2.0,
      this.hitLineRadial = 12.0,
      this.alignment = Alignment.topCenter,
      this.panelPadding = const EdgeInsets.all(1.0),
      this.editPadding = const EdgeInsets.all(10.0),
      this.thumbColor,
      this.trackColor,
      this.highlightedThumbColor,
      this.thumbSize = 6.0,
      this.paddingInside = 1.0,
      this.paddingOutside = 2.0});

  final double minTableScale;
  final double maxTableScale;
  final double maxRowHeaderScale;
  final double maxColumnHeaderScale;
  final AdjustFreezeProperties? adjustFreeze;
  final AdjustSplitProperties? adjustSplit;
  final double minimalSizeDividedWindow;
  final double spaceSplit;
  final double spaceSplitFreeze;
  final double extentScrollBarHit;
  final double hitLineRadial;
  final Alignment alignment;
  final EdgeInsets panelPadding;
  final EdgeInsets editPadding;
  final Color? thumbColor;
  final Color? trackColor;
  final Color? highlightedThumbColor;
  final double thumbSize;
  final double paddingOutside;
  final double paddingInside;

  double get scrollBarHit => paddingOutside + thumbSize + extentScrollBarHit;
}
