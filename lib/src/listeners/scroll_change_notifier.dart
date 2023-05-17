// Copyright (C) 2023 Joan Schipper
// 
// This file is part of flextable.
// 
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

// Copyright (C) 2023 Joan Schipper
//
// This file is part of flextable.
//
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flextable/src/listeners/flextable_change_notifier.dart';
import 'package:flextable/src/model/flextable_scroll_metrics.dart';
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
