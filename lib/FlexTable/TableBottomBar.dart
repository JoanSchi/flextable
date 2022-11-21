import 'package:flutter/material.dart';

import 'TableModel.dart';

class TableBottomBar extends StatefulWidget {
  final TableModel tableModel;
  final bool showScaleValue;
  final double? maxWidthSlider;
  final double trackHeight;
  final double thumbRadius;
  final double overlayRadius;

  const TableBottomBar({
    Key? key,
    required this.tableModel,
    this.showScaleValue = true,
    this.maxWidthSlider,
    this.trackHeight = 2.0,
    this.thumbRadius = 5.0,
    this.overlayRadius = 10.0,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => TableBottomBarState();
}

class TableBottomBarState extends State<TableBottomBar> {
  late TableModel _tableModel;

  @override
  void initState() {
    _tableModel = widget.tableModel;
    _tableModel.addTableScaleListener(setScale);
    super.initState();
  }

  void didUpdateWidget(TableBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_tableModel != widget.tableModel) {
      _tableModel.removeTableScaleListener(setScale);
      _tableModel = widget.tableModel;
      _tableModel.addTableScaleListener(setScale);
    }
  }

  void dispose() {
    _tableModel.removeTableScaleListener(setScale);
    super.dispose();
  }

  setScale(double value) {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    double scale = _tableModel.tableScale;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        widget.maxWidthSlider != null
            ? SizedBox(width: widget.maxWidthSlider, child: buildSlider(context))
            : Expanded(child: buildSlider(context)),
        if (widget.showScaleValue)
          Container(
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 5.0),
              width: 45.0,
              child: Text('${(scale * 100).round()}%')),
      ],
    );
  }

  Widget buildSlider(BuildContext context) {
    double min = _tableModel.minTableScale;
    double max = _tableModel.maxTableScale;
    double scale = _tableModel.tableScale;

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        // activeTrackColor: Colors.red,
        // inactiveTrackColor: Colors.orange,
        trackHeight: widget.trackHeight,
        // thumbColor: Colors.yellow,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: widget.thumbRadius),
        // overlayColor: Colors.purple.withAlpha(32),
        overlayShape: RoundSliderOverlayShape(overlayRadius: widget.overlayRadius),
      ),
      child: Slider(
        value: scale < 1.0 ? 2.0 - 1.0 / scale : scale,
        min: min < 1.0 ? 2.0 - 1.0 / min : min,
        max: max,
        onChanged: (double value) {
          final newScale = (value < 1.0) ? 1.0 / (2.0 - value) : value;
          if (_tableModel.setScaleTable(newScale)) {
            _tableModel.notifyTableScaleListeners(newScale);
            _tableModel.notifyListeners();
            _tableModel.notifyScrollBarListeners();
          }
        },
        onChangeEnd: (double value) {
          _tableModel.tableScrollPosition.correctOffScroll(0, 0);
        },
      ),
    );
  }
}
