import 'package:flextable/flextable.dart';

abstract class DefinedTableArea<T extends AbstractFtModel<C>,
    C extends AbstractCell> {
  const DefinedTableArea({
    required this.minimalHeaderRows,
    required this.columns,
    required this.tableName,
  });

  final int minimalHeaderRows;
  final int columns;
  final String tableName;

  CreateTableArea<T, C>? create({
    required int minimalHeaderRows,
    required AsyncAreaModel model,
    required FtController<T, C> tableController,
    required FtCellGroupState cellGroupState,
    required DateTime firstDay,
    required DateTime startWeekDate,
    required DateTime endWeekDate,
    required int startRow,
    required int startColumn,
  });
}

abstract class CreateTableArea<T extends AbstractFtModel<C>,
    C extends AbstractCell> {
  T model;
  FtController<T, C> tableController;
  FtCellGroupState cellGroupState;

  CreateTableArea({
    required this.model,
    required this.tableController,
    required this.cellGroupState,
  });

  layout();

  fetch();

  load();

  groupState(FtCellState state) {
    cellGroupState.state = state;
  }

  FtCellState get cellState => cellGroupState.state;

  bool get synchronize;
}
