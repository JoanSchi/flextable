import 'package:flextable/flextable.dart';

class AsyncCell<T> extends Cell<T> {
  const AsyncCell(
      {super.attr = const {},
      super.value,
      super.merged,
      required this.groupState});

  final FtCellGroupState groupState;

  @override
  get cellState => groupState.state;

  @override
  AsyncCell copyWith(
      {Map? attr, T? value, FtCellGroupState? groupState, Merged? merged}) {
    return AsyncCell(
        attr: attr ?? this.attr,
        value: value ?? this.value,
        merged: merged ?? this.merged,
        groupState: groupState ?? this.groupState);
  }
}
