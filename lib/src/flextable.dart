// Copyright (C) 2023 Joan Schipper
//
// This file is part of flextable.
//
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

// Copyright (C) 2023 Joan Schipper
//
// This file is part of flextable.
//
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flutter/material.dart';
import 'adjust/adjust_table_freeze.dart';
import 'adjust/adjust_table_move_freeze.dart';
import 'adjust/adjust_table_split.dart';
import 'adjust/zoom/adjust_table_zoom.dart';
import 'adjust/zoom/combi_key.dart';
import 'builders/table_builder.dart';
import 'listeners/scale_change_notifier.dart';
import 'panels/table_multi_panel_viewport.dart';
import 'panels/table_view_scrollable.dart';
import 'listeners/scroll_change_notifier.dart';
import 'model/model.dart';
import 'model/flextable_controller.dart';
import 'model/view_model.dart';
import 'panels/hit_test_stack.dart';
import 'panels/table_scrollbar.dart';

class FlexTable extends StatefulWidget {
  final FlexTableModel flexTableModel;
  final FlexTableController? flexTableController;
  final SplitPositionProperties splitPositionProperties;
  final FreezeOptions freezePositionProperties;
  final MoveFreezePositionProperties moveFreezePositionProperties;
  final TableBuilder tableBuilder;
  final Color? backgroundColor;
  final FlexTableScrollChangeNotifier? scrollChangeNotifier;
  final FlexTableScaleChangeNotifier? scaleChangeNotifier;

  FlexTable({
    super.key,
    required this.flexTableModel,
    this.flexTableController,
    this.splitPositionProperties = const SplitPositionProperties(),
    this.freezePositionProperties = const FreezeOptions(),
    this.moveFreezePositionProperties = const MoveFreezePositionProperties(),
    TableBuilder? tableBuilder,
    this.backgroundColor,
    this.scrollChangeNotifier,
    this.scaleChangeNotifier,
  }) : tableBuilder = tableBuilder ?? DefaultTableBuilder();

  @override
  State<StatefulWidget> createState() => FlexTableState();
}

class FlexTableState extends State<FlexTable> {
  FlexTableController? _flexTableController;

  FlexTableController get flexTableController =>
      _flexTableController ??= FlexTableController();

  FlexTableScrollChangeNotifier? _scrollChangeNotifier;
  FlexTableScrollChangeNotifier get scrollChangeNotifier =>
      _scrollChangeNotifier ?? FlexTableScrollChangeNotifier();

  FlexTableScaleChangeNotifier? _scaleChangeNotifier;
  FlexTableScaleChangeNotifier get scaleChangeNotifier =>
      _scaleChangeNotifier ?? FlexTableScaleChangeNotifier();

  CombiKeyNotification? _combiKeyNotification;

  CombiKeyNotification get combiKeyNotification =>
      _combiKeyNotification ??= CombiKeyNotification();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FlexTable oldWidget) {
    if (widget.flexTableController != null) {
      _flexTableController?.dispose();
      _flexTableController = null;
    }

    if (widget.scrollChangeNotifier != null) {
      _scrollChangeNotifier?.dispose();
      _scrollChangeNotifier = null;
    }

    if (widget.scaleChangeNotifier != null) {
      _scaleChangeNotifier?.dispose();
      _scaleChangeNotifier = null;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _flexTableController?.dispose();
    super.dispose();
  }

  ScrollPosition? findSliverScrollPosition() {
    final ScrollableState? result =
        context.findAncestorStateOfType<ScrollableState>();
    return result?.position;
  }

  @override
  Widget build(BuildContext context) {
    Widget table = TableViewScrollable(
        flexTableModel: widget.flexTableModel,
        controller: widget.flexTableController ?? flexTableController,
        scrollChangeNotifier:
            widget.scrollChangeNotifier ?? scrollChangeNotifier,
        scaleChangeNotifier: widget.scaleChangeNotifier ?? scaleChangeNotifier,
        viewportBuilder:
            (BuildContext context, FlexTableViewModel flexTableViewModel) {
          final theme = Theme.of(context);

          Widget tableZoom;
          switch (theme.platform) {
            case TargetPlatform.iOS:
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
              tableZoom = TableZoomTouch(
                flexTableViewModel: flexTableViewModel,
              );
              _combiKeyNotification = null;
              break;
            case TargetPlatform.macOS:
            case TargetPlatform.linux:
            case TargetPlatform.windows:
              tableZoom = TableZoomMouse(
                combiKeyNotification: combiKeyNotification,
                zoomProperties: TableZoomProperties(),
                flexTableViewModel: flexTableViewModel,
              );
          }

          return MultiHitStack(children: [
            TableMultiPanelViewport(
              flexTableViewModel: flexTableViewModel,
              tableBuilder: widget.tableBuilder,
              tableScale: flexTableViewModel.tableScale,
            ),
            // TablePanel(
            //   flexTableViewModel: flexTableViewModel,
            //   tableBuilder: widget.tableBuilder,
            // ),
            if (flexTableViewModel.ftm.manualFreezePossible &&
                widget.moveFreezePositionProperties.useMoveFreezePosition)
              TableMoveFreeze(
                moveFreezePositionProperties:
                    widget.moveFreezePositionProperties,
                flexTableViewModel: flexTableViewModel,
              ),
            if (flexTableViewModel.ftm.manualFreezePossible &&
                widget.freezePositionProperties.useFreezePosition)
              TableFreeze(
                freezeOptions: widget.freezePositionProperties,
                flexTableViewModel: flexTableViewModel,
              ),
            tableZoom,
            TableScrollbar(
              flexTableViewModel: flexTableViewModel,
            ),
            if (widget.splitPositionProperties.useSplitPosition)
              AdjustTableSplit(
                flexTableViewModel: flexTableViewModel,
                properties: widget.splitPositionProperties,
              ),
          ]);
        });

    if (_combiKeyNotification != null) {
      table = CombiKey(
        combiKeyNotification: combiKeyNotification,
        child: table,
      );
    }

    return table;
  }
}
