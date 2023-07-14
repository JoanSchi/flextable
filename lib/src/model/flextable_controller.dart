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

import 'package:flextable/src/listeners/scroll_change_notifier.dart';
import 'package:flutter/widgets.dart';
import '../gesture_scroll/table_scroll_physics.dart';
import '../listeners/scale_change_notifier.dart';
import 'model.dart';
import 'view_model.dart';

class FlexTableController extends ChangeNotifier {
  FlexTableController();

  Iterable<FlexTableViewModel> get viewModels => _viewModels;
  final List<FlexTableViewModel> _viewModels = <FlexTableViewModel>[];

  bool get hasClients => _viewModels.isNotEmpty;

  FlexTableViewModel get viewModel {
    assert(_viewModels.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    assert(_viewModels.length == 1,
        'ScrollController attached to multiple scroll views.');
    return _viewModels.single;
  }

  FlexTableViewModel lastViewModel({stretch = 3}) {
    assert(_viewModels.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    assert(_viewModels.length <= stretch,
        'ScrollController attached to multiple scroll views.');
    return _viewModels.last;
  }

  void attach(FlexTableViewModel viewModel) {
    assert(!_viewModels.contains(viewModel));
    _viewModels.add(viewModel);
    viewModel.addListener(notifyListeners);
  }

  void detach(FlexTableViewModel viewModel) {
    assert(_viewModels.contains(viewModel));
    viewModel.removeListener(notifyListeners);
    _viewModels.remove(viewModel);
  }

  @override
  void dispose() {
    for (FlexTableViewModel viewModel in _viewModels) {
      viewModel.removeListener(notifyListeners);
    }
    super.dispose();
  }

  FlexTableViewModel createScrollPosition(
      TableScrollPhysics physics,
      ScrollContext context,
      FlexTableViewModel? oldViewModel,
      FlexTableModel flexTableModel,
      FlexTableScrollChangeNotifier scrollChangeNotifier,
      FlexTableScaleChangeNotifier scaleChangeNotifier) {
    return FlexTableViewModel(
        physics: physics,
        context: context,
        oldPosition: oldViewModel,
        ftm: flexTableModel,
        scrollChangeNotifier: scrollChangeNotifier,
        scaleChangeNotifier: scaleChangeNotifier);
  }
}
