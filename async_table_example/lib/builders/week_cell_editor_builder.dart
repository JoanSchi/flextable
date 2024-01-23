import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/advanced_cells.dart';

class WeekCellEditorBuilder extends StatefulWidget {
  const WeekCellEditorBuilder(
      {super.key,
      required this.tableScale,
      required this.cell,
      required this.layoutPanelIndex,
      required this.tableCellIndex,
      required this.requestFocus});

  final double tableScale;
  final Cell cell;
  final LayoutPanelIndex layoutPanelIndex;
  final FtIndex tableCellIndex;
  final bool requestFocus;

  @override
  State<WeekCellEditorBuilder> createState() => _WeekCellEditorBuilderState();
}

class _WeekCellEditorBuilderState extends State<WeekCellEditorBuilder> {
  String value = '';
  FtTextEditInputType textEditInputType = FtTextEditInputType.text;
  @override
  void initState() {
    switch (widget.cell) {
      case (DecimalInputCell v):
        {
          value = v.value == null ? '' : NumberFormat('#0.0').format(v.value);
          textEditInputType = FtTextEditInputType.decimal;
          break;
        }
      case (DigitInputCell v):
        {
          value = v.value == null ? '' : '${v.value}';
          textEditInputType = FtTextEditInputType.decimal;
          break;
        }
      case (Cell v):
        {
          value = v.value == null ? '' : '$v.value';
          break;
        }
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.viewModel<AsyncAreaModel, Cell>();
    final cell = widget.cell;
    final nextFocus = viewModel
            ?.nextCell(
                PanelCellIndex.from(ftIndex: widget.tableCellIndex, cell: cell))
            .isIndex ??
        false;

    Widget child = Center(
        child: MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(widget.tableScale)),
      child: FtEditText(
        editInputType: textEditInputType,
        text: value,
        requestFocus: widget.requestFocus,
        textAlign: TextAlign.center,
        requestNextFocus: nextFocus,
        requestNextFocusCallback: () {
          ///
          /// ViewModel can be rebuild and the old viewbuild is disposed!
          /// Get the latest viewModel and do again checks.
          ///
          ///
          final vm = viewModel;

          if (vm == null) {
            return false;
          }
          if (nextFocus) {
            vm
              ..editCell = PanelCellIndex.from(
                  panelIndexX: widget.layoutPanelIndex.xIndex,
                  panelIndexY: widget.layoutPanelIndex.yIndex,
                  ftIndex: vm.nextCell(PanelCellIndex.from(
                      ftIndex: widget.tableCellIndex, cell: cell)))
              ..markNeedsLayout();
            return true;
          } else {
            vm
              ..clearEditCell(widget.tableCellIndex)
              ..markNeedsLayout();
            return false;
          }
        },
        focus: () {
          viewModel?.updateCellPanel(widget.layoutPanelIndex);
        },
        unFocus: (UnfocusDisposition disposition) {
          if (disposition == UnfocusDisposition.scope) {
            viewModel
              ?..clearEditCell(widget.tableCellIndex)
              ..markNeedsLayout();
          }
        },
        onValueChanged: (String text) => onValueChange(viewModel, text),
      ),
    ));
    child = Container(color: cell.attr[CellAttr.background], child: child);

    return AutomaticKeepAlive(child: SelectionKeepAlive(child: child));
  }

  void onValueChange(FtViewModel? viewModel, String text) {
    if (viewModel == null ||
        !viewModel.mounted ||
        (text.isEmpty && widget.cell.value == null)) {
      return;
    }

    switch (widget.cell) {
      case (DecimalInputCell v):
        {
          viewModel.model.updateCell(
              previousCell: widget.cell,
              cell: v.copyWith(
                  value: double.tryParse(text), valueCanBeNull: true),
              ftIndex: widget.tableCellIndex);
          break;
        }
      case (DigitInputCell v):
        {
          viewModel.model.updateCell(
              previousCell: widget.cell,
              cell: v.copyWith(value: int.tryParse(text), valueCanBeNull: true),
              ftIndex: widget.tableCellIndex);
          break;
        }
      case (TextInputCell v):
        {
          viewModel.model.updateCell(
              previousCell: widget.cell,
              cell: v.copyWith(value: text, valueCanBeNull: true),
              ftIndex: widget.tableCellIndex);
          break;
        }
      default:
        {}

        viewModel
          ..clearEditCell(widget.tableCellIndex)
          ..markNeedsLayout();
    }
  }
}
