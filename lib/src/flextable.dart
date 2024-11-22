// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flextable/flextable.dart';
import 'package:flextable/src/keys/escape.dart';
import 'package:flextable/src/panels/flextable_context.dart';
import 'package:flextable/src/widgets/ignore_pointer_callback.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'adjust/select_cell/select_cell.dart';
import 'adjust/split/adjust_table_split.dart';
import 'adjust/freeze/adjust_table_freeze.dart';
import 'adjust/freeze/adjust_table_move_freeze.dart';
import 'adjust/freeze/adjust_freeze_properties.dart';
import 'adjust/scale/adjust_table_scale.dart';
import 'gesture_scroll/table_scroll_physics.dart';
import 'listeners/inner_change_notifiers.dart';
import 'panels/table_multi_panel_viewport.dart';
import 'panels/table_view_scrollable.dart';
import 'panels/hit_test_stack.dart';
import 'panels/table_scrollbar.dart';

FtViewModel<C, M> defaultCreateViewModel<C extends AbstractCell,
        M extends AbstractFtModel<C>>(
    TableScrollPhysics physics,
    FlexTableContext context,
    FtViewModel<C, M>? oldViewModel,
    M model,
    AbstractTableBuilder tableBuilder,
    InnerScrollChangeNotifier scrollChangeNotifier,
    List<TableChangeNotifier> tableChangeNotifiers,
    FtProperties properties,
    ChangedCellValueCallback<C, M>? changedCellValue,
    FtScaleChangeNotifier scaleChangeNotifier,
    ScrollableState? sliverScrollable,
    bool softKeyboard) {
  return FtViewModel<C, M>(
      physics: physics,
      context: context,
      oldPosition: oldViewModel,
      model: model,
      tableBuilder: tableBuilder,
      scrollChangeNotifier: scrollChangeNotifier,
      tableChangeNotifiers: tableChangeNotifiers,
      properties: properties,
      changedCellValue: changedCellValue,
      scaleChangeNotifier: scaleChangeNotifier,
      sliverScrollable: sliverScrollable,
      softKeyboard: softKeyboard);
}

class FlexTable<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatefulWidget {
  FlexTable(
      {super.key,
      required this.model,
      this.controller,
      this.properties = const FtProperties(
          minimalSizeDividedWindow: 20.0,
          adjustSplit: AdjustSplitProperties(),
          adjustFreeze: AdjustFreezeProperties()),
      required this.tableBuilder,
      this.backgroundColor,
      List<TableChangeNotifier>? tableChangeNotifiers,
      this.changeCellValue,
      this.selectedCell,
      this.ignoreCell,
      this.scaleChangeNotifier,
      this.softKeyboard})
      : tableChangeNotifiers = tableChangeNotifiers ?? [];

  final M model;
  final FtController<C, M>? controller;
  final FtScaleChangeNotifier? scaleChangeNotifier;
  final FtProperties properties;
  final AbstractTableBuilder<C, M> tableBuilder;
  final Color? backgroundColor;
  final List<TableChangeNotifier> tableChangeNotifiers;
  final ChangedCellValueCallback<C, M>? changeCellValue;
  final SelectedCellCallback<C, M>? selectedCell;
  final IgnoreCellCallback<C, M>? ignoreCell;
  final bool? softKeyboard;

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

  FtController<C, M> get ftController => _ftController ??= FtController<C, M>();

  final InnerScrollChangeNotifier _innerScrollChangeNotifier =
      InnerScrollChangeNotifier();
  FtScaleChangeNotifier? _scaleChangeNotifier;
  FtScaleChangeNotifier get scaleChangeNotifier =>
      _scaleChangeNotifier ??= FtScaleChangeNotifier(
          scale: widget.model.tableScale,
          min: widget.properties.minTableScale,
          max: widget.properties.maxTableScale);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(FlexTable<C, M> oldWidget) {
    if ((widget.controller, _ftController)
        case (FtController(), FtController fc)) {
      scheduleMicrotask(() {
        fc.dispose();
      });

      _ftController = null;
    }

    if ((widget.scaleChangeNotifier, _scaleChangeNotifier)
        case (FtScaleChangeNotifier(), FtScaleChangeNotifier sc)) {
      scheduleMicrotask(() {
        sc.dispose();
      });

      _scaleChangeNotifier = null;
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _ftController?.dispose();
    _scaleChangeNotifier?.dispose();
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
    final softKeyboard = widget.softKeyboard ??
        switch (defaultTargetPlatform) {
          (TargetPlatform.iOS ||
                TargetPlatform.android ||
                TargetPlatform.fuchsia) =>
            true,
          (_) => false
        };

    Widget table = TableViewScrollable<C, M>(
        model: widget.model,
        properties: widget.properties,
        tableBuilder: widget.tableBuilder,
        controller: widget.controller ?? ftController,
        innerScrollChangeNotifier: _innerScrollChangeNotifier,
        scaleChangeNotifier: widget.scaleChangeNotifier ?? scaleChangeNotifier,
        tableChangeNotifiers: widget.tableChangeNotifiers,
        createViewModel: defaultCreateViewModel<C, M>,
        changeCellValue: widget.changeCellValue,
        softKeyboard: softKeyboard,
        viewportBuilder: (BuildContext context, FtViewModel<C, M> viewModel) {
          final theme = Theme.of(context);

          Widget? tableZoom;
          switch (theme.platform) {
            case (TargetPlatform.iOS ||
                  TargetPlatform.android ||
                  TargetPlatform.fuchsia):
              {
                tableZoom = TableScaleTouch(
                  viewModel: viewModel,
                );
                break;
              }
            default:
              {}
          }

          final fo = widget.properties.adjustFreeze;
          final so = widget.properties.adjustSplit;

          Widget m = MultiHitStack(children: [
            SelectCell(
              selectedCell: widget.selectedCell,
              ignoreCell: widget.ignoreCell,
              viewModel: viewModel,
            ),
            IgnorePointerCallback(
              ignoring: widget.ignoreCell,
              viewModel: viewModel,
              child: TableMultiPanel<C, M>(
                viewModel: viewModel,
                tableBuilder: widget.tableBuilder,
                tableScale: viewModel.tableScale,
              ),
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

    return table;
  }
}
