// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/material.dart';

class TableBottomBar extends StatefulWidget {
  const TableBottomBar({
    super.key,
    required this.scaleChangeNotifier,
    required this.flexTableController,
    this.showScaleValue = true,
    this.maxWidthSlider,
    this.trackHeight = 2.0,
    this.thumbRadius = 5.0,
    this.overlayRadius = 10.0,
  });

  final FlexTableController flexTableController;
  final bool showScaleValue;
  final double? maxWidthSlider;
  final double trackHeight;
  final double thumbRadius;
  final double overlayRadius;
  final FlexTableScaleChangeNotifier scaleChangeNotifier;

  @override
  State<StatefulWidget> createState() => TableBottomBarState();
}

class TableBottomBarState extends State<TableBottomBar>
    implements FlexTableScaleNotification {
  late FlexTableScaleChangeNotifier _scaleChangeNotifier;
  late FlexTableController _flexTableController;

  @override
  void initState() {
    _flexTableController = widget.flexTableController;
    _scaleChangeNotifier = widget.scaleChangeNotifier..addListener(this);
    super.initState();
  }

  @override
  void didUpdateWidget(TableBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_flexTableController != widget.flexTableController) {
      _flexTableController = widget.flexTableController;
    }

    if (_scaleChangeNotifier != widget.scaleChangeNotifier) {
      _scaleChangeNotifier.removeListener(this);
      _scaleChangeNotifier = widget.scaleChangeNotifier..addListener(this);
    }
  }

  @override
  void dispose() {
    _scaleChangeNotifier.removeListener(this);
    super.dispose();
  }

  setScale(double value) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double scale = _flexTableController.lastViewModel().tableScale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        widget.maxWidthSlider != null
            ? SizedBox(
                width: widget.maxWidthSlider, child: buildSlider(context))
            : Expanded(child: buildSlider(context)),
        if (widget.showScaleValue)
          Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 5.0),
              width: 45.0,
              child: Text('${(scale * 100).round()}%')),
      ],
    );
  }

  Widget buildSlider(BuildContext context) {
    final ftm = _flexTableController.lastViewModel().ftm;
    double min = ftm.minTableScale;
    double max = ftm.maxTableScale;
    double scale = ftm.tableScale;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        // activeTrackColor: Colors.red,
        // inactiveTrackColor: Colors.orange,
        trackHeight: widget.trackHeight,
        // thumbColor: Colors.yellow,
        thumbShape:
            RoundSliderThumbShape(enabledThumbRadius: widget.thumbRadius),
        // overlayColor: Colors.purple.withAlpha(32),
        overlayShape:
            RoundSliderOverlayShape(overlayRadius: widget.overlayRadius),
      ),
      child: Slider(
        value: scale < 1.0 ? 2.0 - 1.0 / scale : scale,
        min: min < 1.0 ? 2.0 - 1.0 / min : min,
        max: max,
        onChanged: (double value) {
          final newScale = (value < 1.0) ? 1.0 / (2.0 - value) : value;
          _flexTableController.lastViewModel().setScaleTable(newScale);
        },
        onChangeEnd: (double value) {
          _flexTableController.lastViewModel().correctOffScroll(0, 0);
        },
      ),
    );
  }

  @override
  scaleChange(FlexTableModel flexTableModel) {
    setState(() {});
  }
}
