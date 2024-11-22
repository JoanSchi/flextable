import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../adjust/select_cell/select_cell.dart';

class IgnorePointerCallback<C extends AbstractCell,
    M extends AbstractFtModel<C>> extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible to hit testing.
  const IgnorePointerCallback({
    super.key,
    required this.ignoring,
    required this.viewModel,
    super.child,
  });

  final IgnoreCellCallback<C, M>? ignoring;
  final FtViewModel<C, M> viewModel;

  @override
  RenderIgnorePointerCallback createRenderObject(BuildContext context) {
    return RenderIgnorePointerCallback<C, M>(
        ignoring: ignoring, viewModel: viewModel);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderIgnorePointerCallback<C, M> renderObject) {
    renderObject
      ..ignoring = ignoring
      ..viewModel = viewModel;
  }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(DiagnosticsProperty<bool>('ignoring', ignoring()));
  // }
}

class RenderIgnorePointerCallback<C extends AbstractCell,
    M extends AbstractFtModel<C>> extends RenderProxyBox {
  /// Creates a render object that is invisible to hit testing.
  RenderIgnorePointerCallback(
      {RenderBox? child,
      required IgnoreCellCallback<C, M>? ignoring,
      required FtViewModel<C, M> viewModel})
      : _ignoring = ignoring,
        _viewModel = viewModel,
        super(child);

  IgnoreCellCallback<C, M>? get ignoring => _ignoring;
  IgnoreCellCallback<C, M>? _ignoring;

  set ignoring(IgnoreCellCallback<C, M>? value) {
    if (value == _ignoring) {
      return;
    }
    _ignoring = value;
  }

  FtViewModel<C, M> _viewModel;
  FtViewModel<C, M> get viewModel => _viewModel;

  set viewModel(FtViewModel<C, M> value) {
    if (value == _viewModel) {
      return;
    }
    _viewModel = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    bool ignore;
    switch (ignoring) {
      case (IgnoreCellCallback<C, M> ignoreCallBack):
        {
          final indexAndCell = viewModel.findCell(position);
          if (indexAndCell.panelCellIndex.isIndex) {
            ignore = ignoreCallBack(
                viewModel, indexAndCell.panelCellIndex, indexAndCell.cell);
          } else {
            ignore = true;
          }
          break;
        }
      default:
        {
          ignore = false;
        }
    }

    return !ignore && super.hitTest(result, position: position);
  }

  // @override
  // void describeSemanticsConfiguration(SemanticsConfiguration config) {
  //   super.describeSemanticsConfiguration(config);
  //   // Do not block user interactions if _ignoringSemantics is false; otherwise,
  //   // delegate to _ignoring
  //   config.isBlockingUserActions = _ignoring();
  // }

  // @override
  // void debugFillProperties(DiagnosticPropertiesBuilder properties) {
  //   super.debugFillProperties(properties);
  //   properties.add(DiagnosticsProperty<bool>('ignoring', _ignoring()));
  // }
}
