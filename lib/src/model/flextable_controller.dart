// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/widgets.dart';
import '../gesture_scroll/table_scroll_physics.dart';
import '../listeners/default_change_notifier.dart';

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
    if (_viewModels.length > 1) {
      debugPrint(
          'LastViewModel viewModel number is: ${_viewModels.length} (delayed microTask?)');
    }
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
    TableBuilder tableBuilder,
    ScrollChangeNotifier scrollChangeNotifier,
    ScaleChangeNotifier scaleChangeNotifier,
    List<FlexTableChangeNotifier> flexTableChangeNotifiers,
  ) {
    return FlexTableViewModel(
        physics: physics,
        context: context,
        oldPosition: oldViewModel,
        ftm: flexTableModel,
        tableBuilder: tableBuilder,
        scrollChangeNotifier: scrollChangeNotifier,
        scaleChangeNotifier: scaleChangeNotifier,
        flexTableChangeNotifiers: flexTableChangeNotifiers);
  }
}
