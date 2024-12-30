import '../../../../flextable.dart';

typedef MessageCallback<C extends AbstractCell, M extends AbstractFtModel<C>>
    = bool Function(
        FtViewModel<C, M> viewModel, C cell, FtIndex index, Object? message);
