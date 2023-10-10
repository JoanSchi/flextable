// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

class InnerScaleChangeNotifier extends ChangeNotifier {
  InnerScaleChangeNotifier(
      {this.minScale = 0.5, this.maxScale = 3.0, this.scale = 1.0});

  double minScale;
  double maxScale;
  double scale;

  setValues({
    required double minScale,
    required double maxScale,
    required double scale,
  }) {
    this.scale = scale;
    this.minScale = minScale;
    this.maxScale = maxScale;
  }

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

class InnerScrollChangeNotifier extends ChangeNotifier {
  InnerScrollChangeNotifier();

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
