// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

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

class InnerStateChangeNotifier extends ChangeNotifier {
  InnerStateChangeNotifier();

  void notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  bool _mounted = true;
  bool get mounted => _mounted;
}
