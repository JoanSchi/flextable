import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../flextable.dart';

class IgnoreScrollBarTrack extends SingleChildRenderObjectWidget {
  /// Creates a widget that is invisible to hit testing.
  const IgnoreScrollBarTrack({
    super.key,
    required this.viewModel,
    super.child,
  });

  final FtViewModel viewModel;

  @override
  RenderIgnoreScrollBarTrack createRenderObject(BuildContext context) {
    return RenderIgnoreScrollBarTrack(
      viewModel: viewModel,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderIgnoreScrollBarTrack renderObject) {
    renderObject.viewModel = viewModel;
  }
}

class RenderIgnoreScrollBarTrack extends RenderProxyBox {
  /// Creates a render object that is invisible to hit testing.
  RenderIgnoreScrollBarTrack({
    RenderBox? child,
    required FtViewModel viewModel,
  })  : _viewModel = viewModel,
        super(child);

  FtViewModel get viewModel => _viewModel;
  FtViewModel _viewModel;
  set viewModel(FtViewModel value) {
    if (value == _viewModel) {
      return;
    }
    _viewModel = value;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (viewModel.scrollBarTrack) {
      if (position.dx >= viewModel.leftScrollBarHit &&
          position.dx <= size.width - viewModel.rightScrollBarHit &&
          position.dy >= viewModel.topScrollBarHit &&
          position.dy <= size.height - viewModel.bottomScrollBarHit) {
        return super.hitTest(result, position: position);
      }
      return false;
    } else {
      return super.hitTest(result, position: position);
    }
  }
}
