import 'package:flutter/material.dart';
import '../../flextable.dart';

class TableScaleSlider extends StatefulWidget {
  const TableScaleSlider(
      {super.key,
      required this.scaleChangeNotifier,
      this.maxWidthSlider = 200.0});

  final FtScaleChangeNotifier scaleChangeNotifier;
  final double maxWidthSlider;

  @override
  State<TableScaleSlider> createState() => _TableScaleSliderState();
}

class _TableScaleSliderState extends State<TableScaleSlider> {
  late FtScaleChangeNotifier scaleChangeNotifier;
  double scale = 1.0;
  @override
  void initState() {
    scaleChangeNotifier = widget.scaleChangeNotifier..addListener(changeScale);
    scale = scaleChangeNotifier.scale;

    super.initState();
  }

  @override
  void didUpdateWidget(TableScaleSlider oldWidget) {
    if (scaleChangeNotifier != widget.scaleChangeNotifier) {
      scaleChangeNotifier.removeListener(changeScale);
      scaleChangeNotifier = widget.scaleChangeNotifier
        ..addListener(changeScale);
    }
    super.didUpdateWidget(oldWidget);
  }

  changeScale() {
    setState(() {
      scale = widget.scaleChangeNotifier.scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: widget.maxWidthSlider,
        child: Slider(
          min: scaleChangeNotifier.min,
          max: scaleChangeNotifier.max,
          value: scale,
          onChanged: (double value) {
            scaleChangeNotifier.changeScale(scaleValue: value);
          },
          onChangeEnd: (double value) {
            scaleChangeNotifier.changeScale(scaleValue: value, scaleEnd: true);
          },
        ));
  }
}
