// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import '../model/scroll_metrics.dart';
import 'package:flutter/widgets.dart';
import 'flextable_change_by_function_notifier.dart';

class FlexTableScrollChangeNotifier
    extends ChangeByFunctionNotifier<FlexTableScrollNotification> {
  FlexTableScrollChangeNotifier();

  notify(Function(FlexTableScrollNotification listener) call) {
    notifyListeners(call);
  }
}

abstract class FlexTableScrollNotification {
  didStartScroll(TableScrollMetrics metrics, BuildContext? context);
  didEndScroll(TableScrollMetrics metrics, BuildContext? context);
}
