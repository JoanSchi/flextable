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
  FtScaleChangeNotifier(
      {double scale = 1.0, double min = 1.0, double max = 1.0})
      : _scale = scale,
        _min = min,
        _max = max;

  double _scale;

  double get scale => _scale;

  set scale(double value) {
    if (clampDouble(value, _min, _max) case double s when s != _scale) {
      _scale = s;
      notifyListeners();
    }
  }

  double get min => _min;

  set min(double value) {
    if (value != _min) {
      _min = value;
      if (_scale < value) {
        _scale = value;
      }
      notifyListeners();
    }
  }

  double get max => _max;

  set max(double value) {
    if (value != _max) {
      _max = value;
      if (value < _scale) {
        _scale = value;
      }
      notifyListeners();
    }
  }

  double _min;
  double _max;
  bool end = false;

  void changeScale({double? scaleValue, bool scaleEnd = false}) {
    bool notify = false;

    if (scaleValue case double s when s != _scale) {
      s = clampDouble(s, _min, _max);
      _scale = s;
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
