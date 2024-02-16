import '../properties/flextable_range_properties.dart';

class ChangeRange extends FtRange {
  ChangeRange({
    required super.start,
    super.last,
    required this.insert,
  });

  bool insert;
}
