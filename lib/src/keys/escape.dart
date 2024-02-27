import 'package:flextable/flextable.dart';
import 'package:flutter/widgets.dart';

class EscapeIntent extends Intent {
  const EscapeIntent();
}

class EscapeAction extends Action<EscapeIntent> {
  EscapeAction(this.viewModel);

  final FtViewModel viewModel;

  @override
  Object? invoke(covariant EscapeIntent intent) {
    FocusNode? focusChild =
        FocusScope.of(viewModel.context.storageContext).focusedChild;

    if (focusChild case SkipFocusNode skip) {
      skip
        ..escape = true
        ..unfocus(disposition: UnfocusDisposition.scope);
    } else {
      focusChild?.unfocus(disposition: UnfocusDisposition.scope);
    }

    return null;
  }
}
