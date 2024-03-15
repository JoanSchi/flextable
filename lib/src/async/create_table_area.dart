import 'package:flextable/flextable.dart';

abstract class DefinedTableArea<I> {
  const DefinedTableArea({
    required this.minimalHeaderRows,
    required this.columns,
    required this.tableName,
  });

  final int minimalHeaderRows;
  final int columns;
  final String tableName;

  CreateTableArea<I>? create({
    required int minimalHeaderRows,
    required AsyncAreaModel model,
    required FtController tableController,
    required FtCellGroupState cellGroupState,
    required DateTime firstDay,
    required DateTime startWeekDate,
    required DateTime endWeekDate,
    required int startRow,
    required int startColumn,
  });
}

abstract class CreateTableArea<I> {
  AsyncAreaModel model;
  FtController tableController;
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
