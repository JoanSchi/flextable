// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../../flextable.dart';

mixin TableChangeNotifier {
  void change(FtViewModel viewModel);
}

class FtScaleChangeNotifier extends ChangeNotifier {
  FtScaleChangeNotifier({this.scale = 1.0, this.min = 1.0, this.max = 1.0});

  double scale;
  double min;
  double max;
  bool end = false;

  void changeScale({double? scaleValue, bool scaleEnd = false}) {
    bool notify = false;

    if (scaleValue case double s when s != scale) {
      s = clampDouble(s, min, max);
      scale = s;
      notify = true;
    }

    if (end != scaleEnd) {
      end = scaleEnd;
      if (scaleEnd) {
        notify = true;
      }
    }

    if (notify) {
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

class ScrollChangeNotifier extends ChangeNotifier with TableChangeNotifier {
  ScrollChangeNotifier();

  bool scrolling = false;

  @override
  void change(FtViewModel viewModel) {
    if (viewModel.scrolling != scrolling) {
      scrolling = viewModel.scrolling;
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

class RebuildNotifier extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

class LastEditIndexNotifier extends ChangeNotifier with TableChangeNotifier {
  LastEditIndexNotifier({this.index = const FtIndex()});

  FtIndex index;

  @override
  void change(FtViewModel viewModel) {
    if (viewModel.lastEditIndex != index) {
      index = viewModel.lastEditIndex;
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
