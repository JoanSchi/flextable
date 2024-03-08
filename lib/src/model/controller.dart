// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/widgets.dart';

class FtController<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends ChangeNotifier {
  FtController();

  Iterable<FtViewModel<C, M>> get viewModels => _viewModels;
  final List<FtViewModel<C, M>> _viewModels = <FtViewModel<C, M>>[];

  bool get hasClients => _viewModels.isNotEmpty;

  FtViewModel<C, M> get viewModel {
    assert(_viewModels.isNotEmpty,
        'ScrollController not attached to any scroll views.');
    assert(_viewModels.length == 1,
        'ScrollController attached to multiple scroll views.');
    return _viewModels.single;
  }

  FtViewModel<C, M> lastViewModel({stretch = 3}) {
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

  FtViewModel<C, M>? lastViewModelOrNull({stretch = 3}) {
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

  void attach(FtViewModel<C, M> viewModel) {
    assert(!_viewModels.contains(viewModel));
    _viewModels.add(viewModel);
    viewModel.addListener(notifyListeners);
  }

  void detach(FtViewModel<C, M> viewModel) {
    assert(_viewModels.contains(viewModel));
    viewModel.removeListener(notifyListeners);
    _viewModels.remove(viewModel);
  }

  bool contains(FtViewModel<C, M> viewModel) => _viewModels.contains(viewModel);

  @override
  void dispose() {
    for (FtViewModel viewModel in _viewModels) {
      viewModel.removeListener(notifyListeners);
    }
    super.dispose();
  }
}
