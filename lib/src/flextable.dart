// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'adjust/split/adjust_table_split.dart';
import 'adjust/freeze/adjust_table_freeze.dart';
import 'adjust/freeze/adjust_table_move_freeze.dart';
import 'adjust/freeze/freeze_options.dart';
import 'adjust/split/split_options.dart';
import 'adjust/zoom/adjust_table_zoom.dart';
import 'adjust/zoom/combi_key.dart';
import 'listeners/default_change_notifier.dart';
import 'panels/table_multi_panel_viewport.dart';
import 'panels/table_view_scrollable.dart';
import 'panels/hit_test_stack.dart';
import 'panels/table_scrollbar.dart';

class FlexTable extends StatefulWidget {
  FlexTable({
    super.key,
    required this.flexTableModel,
    this.flexTableController,
    this.splitPositionProperties = const SplitOptions(),
    this.freezeOptions = const FreezeOptions(),
    TableBuilder? tableBuilder,
    this.backgroundColor,
    this.scrollChangeNotifier,
    this.scaleChangeNotifier,
    List<FlexTableChangeNotifier>? flexTableChangeNotifiers,
  })  : tableBuilder = tableBuilder ?? DefaultTableBuilder(),
        flexTableChangeNotifiers = flexTableChangeNotifiers ?? [];

  final FlexTableModel flexTableModel;
  final FlexTableController? flexTableController;
  final SplitOptions splitPositionProperties;
  final FreezeOptions freezeOptions;
  final TableBuilder tableBuilder;
  final Color? backgroundColor;
  final ScrollChangeNotifier? scrollChangeNotifier;
  final ScaleChangeNotifier? scaleChangeNotifier;
  final List<FlexTableChangeNotifier> flexTableChangeNotifiers;

  @override
  State<StatefulWidget> createState() => FlexTableState();
}

class FlexTableState extends State<FlexTable> {
  FlexTableController? _flexTableController;

  FlexTableController get flexTableController =>
      _flexTableController ??= FlexTableController();

  ScrollChangeNotifier? _scrollChangeNotifier;
  ScrollChangeNotifier get scrollChangeNotifier =>
      _scrollChangeNotifier ??= ScrollChangeNotifier();

  ScaleChangeNotifier? _scaleChangeNotifier;
  ScaleChangeNotifier get scaleChangeNotifier =>
      _scaleChangeNotifier ??
      ScaleChangeNotifier(flexTableModel: widget.flexTableModel);

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

    bool updateFlexTable = widget.flexTableModel != oldWidget.flexTableModel;

    if (widget.scaleChangeNotifier != null || updateFlexTable) {
      _scaleChangeNotifier?.dispose();
      _scaleChangeNotifier = null;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _flexTableController?.dispose();
    _scaleChangeNotifier?.dispose();
    _scaleChangeNotifier = null;
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
        tableBuilder: widget.tableBuilder,
        controller: widget.flexTableController ?? flexTableController,
        scrollChangeNotifier:
            widget.scrollChangeNotifier ?? scrollChangeNotifier,
        scaleChangeNotifier: widget.scaleChangeNotifier ?? scaleChangeNotifier,
        flexTableChangeNotifiers: widget.flexTableChangeNotifiers,
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
            TableMultiPanel(
              flexTableViewModel: flexTableViewModel,
              tableBuilder: widget.tableBuilder,
              tableScale: flexTableViewModel.tableScale,
            ),
            if (widget.freezeOptions.useMoveFreezePosition)
              TableMoveFreeze(
                freezeOptions: widget.freezeOptions,
                flexTableViewModel: flexTableViewModel,
              ),
            if (widget.freezeOptions.useFreezePosition)
              TableFreeze(
                freezeOptions: widget.freezeOptions,
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

    return widget.backgroundColor == null
        ? table
        : Container(color: widget.backgroundColor, child: table);
  }
}
