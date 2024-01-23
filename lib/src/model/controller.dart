// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/properties.dart';
import 'package:flutter/widgets.dart';
import '../gesture_scroll/table_scroll_physics.dart';
import '../listeners/inner_change_notifiers.dart';

typedef DefaultFtController = FtController<FtModel<Cell>, Cell>;

class FtController<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends ChangeNotifier {
  FtController();

  Iterable<FtViewModel<T, C>> get viewModels => _viewModels;
  final List<FtViewModel<T, C>> _viewModels = <FtViewModel<T, C>>[];

  bool get hasClients => _viewModels.isNotEmpty;

  FtViewModel<T, C> get viewModel {
    assert(_viewModels.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    assert(_viewModels.length == 1,
        'ScrollController attached to multiple scroll views.');
    return _viewModels.single;
  }

  FtViewModel<T, C> lastViewModel({stretch = 3}) {
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

  FtViewModel<T, C>? lastViewModelOrNull({stretch = 3}) {
    if (_viewModels.isEmpty) {
      return null;
    }
    assert(_viewModels.length <= stretch,
        'ScrollController attached to multiple scroll views.');
    if (_viewModels.length > 1) {
      debugPrint(
          'LastViewModel viewModel number is: ${_viewModels.length} (delayed microTask?)');
    }
    return _viewModels.last;
  }

  void attach(FtViewModel<T, C> viewModel) {
    assert(!_viewModels.contains(viewModel));
    _viewModels.add(viewModel);
    viewModel.addListener(notifyListeners);
  }

  void detach(FtViewModel<T, C> viewModel) {
    assert(_viewModels.contains(viewModel));
    viewModel.removeListener(notifyListeners);
    _viewModels.remove(viewModel);
  }

  @override
  void dispose() {
    for (FtViewModel viewModel in _viewModels) {
      viewModel.removeListener(notifyListeners);
    }
    super.dispose();
  }

  FtViewModel<T, C> createViewModel(
    TableScrollPhysics physics,
    ScrollContext context,
    FtViewModel<T, C>? oldViewModel,
    T model,
    AbstractTableBuilder<T, C> tableBuilder,
    InnerScrollChangeNotifier scrollChangeNotifier,
    InnerScaleChangeNotifier scaleChangeNotifier,
    List<TableChangeNotifier> tableChangeNotifiers,
    FtProperties properties,
  ) {
    return FtViewModel<T, C>(
        physics: physics,
        context: context,
        oldPosition: oldViewModel,
        model: model,
        tableBuilder: tableBuilder,
        scrollChangeNotifier: scrollChangeNotifier,
        scaleChangeNotifier: scaleChangeNotifier,
        tableChangeNotifiers: tableChangeNotifiers,
        properties: properties);
  }
}
