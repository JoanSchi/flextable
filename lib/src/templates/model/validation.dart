import '../../../flextable.dart';

class ModelValidation {}

class CellValidation extends ModelValidation {
  final FtIndex ftIndex;
  final FtCellIdentifier cellIdentifier;
  final String message;

  CellValidation(
      {required this.ftIndex,
      required this.cellIdentifier,
      required this.message});
}
