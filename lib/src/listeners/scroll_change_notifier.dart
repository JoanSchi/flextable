// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../listeners/flextable_change_notifier.dart';
import '../model/flextable_scroll_metrics.dart';
import 'package:flutter/widgets.dart';

class FlexTableScrollChangeNotifier
    extends FlexTableChangeNotifier<FlexTableScrollNotification> {
  FlexTableScrollChangeNotifier();

  notify(Function(FlexTableScrollNotification listener) call) {
    notifyListeners(call);
  }
}

abstract class FlexTableScrollNotification {
  didStartScroll(TableScrollMetrics metrics, BuildContext? context);
  didEndScroll(TableScrollMetrics metrics, BuildContext? context);
}
