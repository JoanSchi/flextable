// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flextable/src/keys/escape.dart';
import 'package:flutter/material.dart';
import 'adjust/select_cell/select_cell.dart';
import 'adjust/split/adjust_table_split.dart';
import 'adjust/freeze/adjust_table_freeze.dart';
import 'adjust/freeze/adjust_table_move_freeze.dart';
import 'adjust/freeze/adjust_freeze_properties.dart';
import 'adjust/scale/adjust_table_scale.dart';
import 'adjust/scale/combi_key.dart';
import 'listeners/inner_change_notifiers.dart';
import 'panels/table_multi_panel_viewport.dart';
import 'panels/table_view_scrollable.dart';
import 'panels/hit_test_stack.dart';
import 'panels/table_scrollbar.dart';

class FlexTable<C extends AbstractCell, M extends AbstractFtModel<C>>
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

  final M model;
  final FtController<C, M>? controller;
  final FtProperties properties;
  final AbstractTableBuilder<C, M> tableBuilder;
  final Color? backgroundColor;
  final ChangeNotifier? rebuildNotifier;
  final List<TableChangeNotifier> tableChangeNotifiers;

  @override
  State<StatefulWidget> createState() => FlexTableState<C, M>();

  static FtViewModel<C, M>?
      viewModelOf<I, C extends AbstractCell, M extends AbstractFtModel<C>>(
          BuildContext context) {
    final TableViewScrollableState<C, M>? result =
        context.findAncestorStateOfType<TableViewScrollableState<C, M>>();

    return result?.viewModel;
  }
}

class FlexTableState<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends State<FlexTable<C, M>> {
  FtController<C, M>? _ftController;

  FtController<C, M> get ftController => _ftController ??= FtController();

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
  void didUpdateWidget(FlexTable<C, M> oldWidget) {
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
    Widget table = TableViewScrollable<C, M>(
        model: widget.model,
        properties: widget.properties,
        tableBuilder: widget.tableBuilder,
        controller: widget.controller ?? ftController,
        innerScrollChangeNotifier: _innerScrollChangeNotifier,
        innerScaleChangeNotifier: _innerScaleChangeNotifier,
        tableChangeNotifiers: widget.tableChangeNotifiers,
        rebuildNotifier: widget.rebuildNotifier,
        viewportBuilder: (BuildContext context, FtViewModel<C, M> viewModel) {
          final theme = Theme.of(context);

          Widget? tableZoom;
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
            // tableZoom = TableScaleMouse(
            //   combiKeyNotification: combiKeyNotification,
            //   properties: TableMouseScaleProperties(),
            //   viewModel: viewModel,
            // );
          }

          final fo = widget.properties.adjustFreeze;
          final so = widget.properties.adjustSplit;

          Widget m = MultiHitStack(children: [
            SelectCell(
              viewModel: viewModel,
            ),
            TableMultiPanel<C, M>(
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
            if (tableZoom != null) tableZoom,
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

          m = Actions(
              dispatcher: const ActionDispatcher(),
              actions: <Type, Action<Intent>>{
                EscapeIntent: EscapeAction(viewModel),
              },
              child: m);

          return m;
        });

    // TODO CombiKey builds everything from the ground instead of a performrebuild

    // if (_combiKeyNotification != null) {
    //   table = CombiKey(
    //     combiKeyNotification: combiKeyNotification,
    //     child: table,
    //   );
    // }

    return widget.backgroundColor == null
        ? table
        : Container(color: widget.backgroundColor, child: table);
  }
}
