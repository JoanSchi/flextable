// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';
import 'adjust/select_cell/select_cell.dart';
import 'adjust/split/adjust_table_split.dart';
import 'adjust/freeze/adjust_table_freeze.dart';
import 'adjust/freeze/adjust_table_move_freeze.dart';
import 'adjust/freeze/adjust_freeze_properties.dart';
import 'adjust/split/adjust_split_properties.dart';
import 'adjust/scale/adjust_table_scale.dart';
import 'adjust/scale/combi_key.dart';
import 'listeners/inner_change_notifiers.dart';
import 'properties.dart';
import 'panels/table_multi_panel_viewport.dart';
import 'panels/table_view_scrollable.dart';
import 'panels/hit_test_stack.dart';
import 'panels/table_scrollbar.dart';

typedef DefaultFlexTable = FlexTable<FtModel<Cell>, Cell>;

class FlexTable<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends StatefulWidget {
  FlexTable({
    super.key,
    required this.model,
    this.controller,
    this.properties = const FtProperties(
        minimalSizeDividedWindow: 20.0,
        adjustSplit: AdjustSplitProperties(),
        adjustFreeze: AdjustFreezeProperties()),
    required this.tableBuilder,
    this.backgroundColor,
    this.rebuildNotifier,
    List<TableChangeNotifier>? tableChangeNotifiers,
  }) : tableChangeNotifiers = tableChangeNotifiers ?? [];

  final T model;
  final FtController<T, C>? controller;
  final FtProperties properties;
  final AbstractTableBuilder<T, C> tableBuilder;
  final Color? backgroundColor;
  final ChangeNotifier? rebuildNotifier;
  final List<TableChangeNotifier> tableChangeNotifiers;

  @override
  State<StatefulWidget> createState() => FlexTableState<T, C>();

  static FtViewModel<T, C>?
      viewModelOf<T extends AbstractFtModel<C>, C extends AbstractCell>(
          BuildContext context) {
    final TableViewScrollableState<T, C>? result =
        context.findAncestorStateOfType<TableViewScrollableState<T, C>>();

    return result?.viewModel;
  }
}

class FlexTableState<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends State<FlexTable<T, C>> {
  FtController<T, C>? _ftController;

  FtController<T, C> get ftController => _ftController ??= FtController();

  final InnerScrollChangeNotifier _innerScrollChangeNotifier =
      InnerScrollChangeNotifier();

  final InnerScaleChangeNotifier _innerScaleChangeNotifier =
      InnerScaleChangeNotifier();

  CombiKeyNotification? _combiKeyNotification;

  CombiKeyNotification get combiKeyNotification =>
      _combiKeyNotification ??= CombiKeyNotification();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _innerScaleChangeNotifier.setValues(
        scale: widget.model.tableScale,
        minScale: widget.properties.minTableScale,
        maxScale: widget.properties.maxTableScale);
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FlexTable<T, C> oldWidget) {
    if (widget.controller != null) {
      _ftController?.dispose();
      _ftController = null;
    }

    _innerScaleChangeNotifier.setValues(
        scale: widget.model.tableScale,
        minScale: widget.properties.minTableScale,
        maxScale: widget.properties.maxTableScale);

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _ftController?.dispose();
    _innerScaleChangeNotifier.dispose();
    _innerScrollChangeNotifier.dispose();
    super.dispose();
  }

  ScrollPosition? findSliverScrollPosition() {
    final ScrollableState? result =
        context.findAncestorStateOfType<ScrollableState>();
    return result?.position;
  }

  @override
  Widget build(BuildContext context) {
    Widget table = TableViewScrollable<T, C>(
        model: widget.model,
        properties: widget.properties,
        tableBuilder: widget.tableBuilder,
        controller: widget.controller ?? ftController,
        innerScrollChangeNotifier: _innerScrollChangeNotifier,
        innerScaleChangeNotifier: _innerScaleChangeNotifier,
        tableChangeNotifiers: widget.tableChangeNotifiers,
        rebuildNotifier: widget.rebuildNotifier,
        viewportBuilder: (BuildContext context, FtViewModel<T, C> viewModel) {
          final theme = Theme.of(context);

          Widget tableZoom;
          switch (theme.platform) {
            case TargetPlatform.iOS:
            case TargetPlatform.android:
            case TargetPlatform.fuchsia:
              tableZoom = TableScaleTouch(
                viewModel: viewModel,
              );
              _combiKeyNotification = null;
              break;
            case TargetPlatform.macOS:
            case TargetPlatform.linux:
            case TargetPlatform.windows:
              tableZoom = TableScaleMouse(
                combiKeyNotification: combiKeyNotification,
                properties: TableMouseScaleProperties(),
                viewModel: viewModel,
              );
          }

          final fo = widget.properties.adjustFreeze;
          final so = widget.properties.adjustSplit;

          return MultiHitStack(children: [
            SelectCell(viewModel: viewModel),
            TableMultiPanel<T, C>(
              viewModel: viewModel,
              tableBuilder: widget.tableBuilder,
              tableScale: viewModel.tableScale,
            ),
            if (fo != null)
              TableMoveFreeze(
                viewModel: viewModel,
              ),
            if (fo != null)
              TableFreeze(
                viewModel: viewModel,
              ),
            tableZoom,
            TableScrollbar(
              scrollChangeNotifier: _innerScrollChangeNotifier,
              viewModel: viewModel,
            ),
            if (so != null)
              AdjustTableSplit(
                viewModel: viewModel,
                properties: so,
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
