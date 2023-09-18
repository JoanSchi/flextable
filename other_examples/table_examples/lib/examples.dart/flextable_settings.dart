// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

mixin SettingsBottomSheet {
  PersistentBottomSheetController? persistentBottomSheetController;

  void toggleSheet(globalKey, flexTableController) {
    if (persistentBottomSheetController != null) {
      persistentBottomSheetController!.close();
      return;
    }

    persistentBottomSheetController =
        globalKey.currentState?.showBottomSheet((BuildContext context) {
      return FlexTableSettings(
        flexTableController: flexTableController,
      );
    })
          ?..closed.then((value) {
            persistentBottomSheetController = null;
          });
  }
}

class FlexTableSettings extends StatefulWidget {
  final FlexTableController flexTableController;

  const FlexTableSettings({
    super.key,
    required this.flexTableController,
  });

  @override
  State<FlexTableSettings> createState() => _FlexTableSettingsState();
}

class _FlexTableSettingsState extends State<FlexTableSettings>
    implements FlexTableChangeNotifier {
  FlexTableViewModel? viewModel;
  bool pop = false;

  SplitState splitX = SplitState.noSplit;
  SplitState splitY = SplitState.noSplit;
  bool rowHeader = false;
  bool columnHeader = false;
  bool scrollUnlockX = false;
  bool scrollUnlockY = false;
  bool autoFreezeX = false;
  bool autoFreezeY = false;
  bool hasAutoFreezeX = false;
  bool hasAutoFreezeY = false;
  bool tableFitHeight = false;
  bool tableFitWidth = false;

  @override
  void initState() {
    super.initState();
  }

  FlexTableViewModel? getViewModel() => widget.flexTableController.hasClients
      ? widget.flexTableController.lastViewModel()
      : null;

  @override
  void didChangeDependencies() {
    if (viewModel == null) {
      viewModel = getViewModel();
      if (viewModel == null) {
        schedulePop();
      } else {
        viewModel!.flexTableChangeNotifiers.add(this);
      }
    } else if (viewModel != getViewModel()) {
      schedulePop();
    }

    if (!pop) {
      setValues();
    }

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(covariant FlexTableSettings oldWidget) {
    if (viewModel != getViewModel() || !(viewModel?.mounted ?? false)) {
      schedulePop();
    }
    super.didUpdateWidget(oldWidget);
  }

  schedulePop() {
    if (!pop) {
      scheduleMicrotask(() {
        Navigator.pop(context);
      });
    }
    pop = true;
  }

  setValues() {
    final vm = viewModel!;

    splitX = vm.stateSplitX;
    splitY = vm.stateSplitY;
    rowHeader = vm.rowHeader;
    columnHeader = vm.columnHeader;
    scrollUnlockX = vm.scrollUnlockX;
    scrollUnlockY = vm.scrollUnlockY;
    autoFreezeX = vm.autoFreezeX;
    autoFreezeY = vm.autoFreezeY;
    hasAutoFreezeX = vm.ftm.autoFreezeAreasX.isNotEmpty;
    hasAutoFreezeY = vm.ftm.autoFreezeAreasY.isNotEmpty;
    tableFitHeight = vm.tableFitHeight;
    tableFitWidth = vm.tableFitWidth;
  }

  @override
  void changeFlexTable(FlexTableViewModel flexTableModel) {
    if (flexTableModel != viewModel) {
      schedulePop();
      return;
    }
    final vm = viewModel!;

    if (splitX != vm.stateSplitX ||
        splitY != vm.stateSplitY ||
        rowHeader != vm.rowHeader ||
        columnHeader != vm.columnHeader ||
        scrollUnlockX != vm.scrollUnlockX ||
        scrollUnlockY != vm.scrollUnlockY ||
        autoFreezeX != vm.autoFreezeX ||
        autoFreezeY != vm.autoFreezeY ||
        hasAutoFreezeX != vm.ftm.autoFreezeAreasX.isNotEmpty ||
        hasAutoFreezeY != vm.ftm.autoFreezeAreasY.isNotEmpty ||
        tableFitHeight != vm.tableFitHeight ||
        tableFitWidth != vm.tableFitWidth) {
      setState(() {
        setValues();
      });
    }
  }

  bool get isXsplitted => splitX == SplitState.split;

  bool get isYsplitted => splitY == SplitState.split;

  bool get enableAutoFreezeX => !tableFitWidth && splitX != SplitState.split;

  bool get enableAutoFreezeY => !tableFitHeight && splitY != SplitState.split;

  bool get enableSplitX => !tableFitWidth;

  bool get enableSplitY => !tableFitHeight;

  bool get enableScrollUnlockX =>
      !tableFitHeight &&
      splitY == SplitState.split &&
      (splitX == SplitState.split ||
          (splitX == SplitState.noSplit && !autoFreezeX));

  bool get enableScrollUnlockY =>
      !tableFitWidth &&
      splitX == SplitState.split &&
      (splitY == SplitState.split ||
          (splitY == SplitState.noSplit && !autoFreezeY));

  @override
  dispose() {
    viewModel!.flexTableChangeNotifiers.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = Wrap(
      spacing: 8.0,
      alignment: WrapAlignment.center,
      children: [
        if (hasAutoFreezeX)
          LabeledCheckBox(
            label: 'AutoFreezeX',
            selected: autoFreezeX,
            enable: enableAutoFreezeX,
            onChanged: (value) => safeChange(value, changeHorizontalAutoFreeze),
          ),
        if (hasAutoFreezeY)
          LabeledCheckBox(
            label: 'AutoFreezeY',
            selected: autoFreezeY,
            enable: enableAutoFreezeY,
            onChanged: (value) => safeChange(value, changeVerticalAutoFreeze),
          ),
        LabeledCheckBox(
          label: 'SplitX',
          selected: isXsplitted,
          enable: enableSplitX,
          onChanged: (bool? value) => safeChange(value, changeHorizontalSplit),
        ),
        LabeledCheckBox(
          label: 'SplitY',
          enable: enableSplitY,
          selected: isYsplitted,
          onChanged: (value) => safeChange(value, changeVerticalSplit),
        ),
        LabeledCheckBox(
          label: 'UnlockY',
          selected: scrollUnlockY,
          enable: enableScrollUnlockY,
          onChanged: (value) => safeChange(value, changeVerticalScrollLock),
        ),
        LabeledCheckBox(
          label: 'UnlockX',
          enable: enableScrollUnlockX,
          selected: scrollUnlockX,
          onChanged: (value) => safeChange(value, changeHorizontalScrollLock),
        ),
        LabeledCheckBox(
          label: 'Row H.',
          selected: rowHeader,
          onChanged: (value) => safeChange(value, changeRowHeader),
        ),
        LabeledCheckBox(
          label: 'Column H.',
          selected: columnHeader,
          onChanged: (value) => safeChange(value, changeColumnHeader),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: options,
    );
  }

  void safeChange<T>(T? value, Function(T value) change) {
    if (value == null || !viewModel!.mounted || pop) {
      schedulePop();
      return;
    }

    change(value);
  }

  void changeHorizontalSplit(bool value) {
    viewModel!
      ..setXsplit(
          splitView: value ? SplitState.split : SplitState.noSplit,
          ratioSplit: 0.5)
      ..markNeedsLayout();
  }

  void changeVerticalSplit(bool value) {
    viewModel!
      ..setYsplit(
          splitView: value ? SplitState.split : SplitState.noSplit,
          ratioSplit: 0.5)
      ..markNeedsLayout();
  }

  changeVerticalAutoFreeze(bool value) {
    viewModel!
      ..autoFreezeY = value
      ..markNeedsLayout();
  }

  changeHorizontalAutoFreeze(bool value) {
    viewModel!
      ..autoFreezeX = value
      ..markNeedsLayout();
  }

  changeVerticalScrollLock(bool value) {
    viewModel!
      ..scrollUnlockY = value
      ..markNeedsLayout();
  }

  changeHorizontalScrollLock(bool value) {
    widget.flexTableController.lastViewModel()
      ..scrollUnlockX = value
      ..markNeedsLayout();
  }

  changeRowHeader(bool value) {
    widget.flexTableController.lastViewModel()
      ..rowHeader = value
      ..markNeedsLayout();
  }

  changeColumnHeader(bool value) {
    widget.flexTableController.lastViewModel()
      ..columnHeader = value
      ..markNeedsLayout();
  }
}

class LabeledCheckBox extends StatelessWidget {
  const LabeledCheckBox(
      {super.key,
      required this.label,
      required this.selected,
      this.enable = true,
      required this.onChanged});
  final bool selected;
  final bool enable;
  final String label;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(value: selected, onChanged: enable ? onChanged : null),
        Text(label)
      ],
    );
  }
}
