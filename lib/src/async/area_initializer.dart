import 'dart:collection';
import 'package:flextable/flextable.dart';

abstract class AreaInitializer<T extends AbstractFtModel<C>,
    C extends AbstractCell> {
  /// At a tag to initiated if the area is initialized
  /// This will prevent loops when get cell hit a empty cell!!!!
  ///
  ///
  AreaInitializer(
      {required this.tableController, required this.definedTableAreas});

  FtIndex get rightBottomIndex;

  FtIndex get leftTopIndex;

  List<DefinedTableArea<T, C>> definedTableAreas;
  FtController<T, C> tableController;
  Set<String> initiated = HashSet<String>();

  bool cell(
      {required AsyncAreaModel model,
      required FtIndex ftIndex,
      FtCellGroupState? cellGroupState});
}
