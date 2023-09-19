// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import '../model/model.dart';

class ScaleChangeNotifier extends ChangeNotifier {
  ScaleChangeNotifier(
      {FlexTableModel? flexTableModel,
      double scale = 1.0,
      double min = 0.5,
      double max = 4.0})
      : scale = flexTableModel?.tableScale ?? scale,
        min = flexTableModel?.minTableScale ?? min,
        max = flexTableModel?.maxTableScale ?? max;

  double min = 0.5;
  double max = 3.0;
  double scale = 1.0;

  void changeScale(double value) {
    if (value != scale) {
      scale = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;
  bool get mounted => _mounted;
}

class ScrollChangeNotifier extends ChangeNotifier {
  ScrollChangeNotifier();

  bool scrolling = false;

  changeScrolling(bool value) {
    if (scrolling != value) {
      scrolling = value;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;
  bool get mounted => _mounted;
}
