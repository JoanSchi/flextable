import 'package:flutter/material.dart';
import '../../flextable.dart';

class TableScaleSlider extends StatefulWidget {
  const TableScaleSlider(
      {super.key,
      required this.scaleChangeNotifier,
      this.maxWidthSlider,
      this.showScaleValue = true});

  final FtScaleChangeNotifier scaleChangeNotifier;
  final double? maxWidthSlider;
  final bool showScaleValue;

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

  @override
  void dispose() {
    scaleChangeNotifier.removeListener(changeScale);
    super.dispose();
  }

  changeScale() {
    setState(() {
      scale = widget.scaleChangeNotifier.scale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slider = Slider(
      min: scaleChangeNotifier.min,
      max: scaleChangeNotifier.max,
      value: scale,
      onChanged: (double value) {
        scaleChangeNotifier.changeScale(scaleValue: value);
      },
      onChangeEnd: (double value) {
        scaleChangeNotifier.changeScale(scaleValue: value, scaleEnd: true);
      },
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        switch (widget.maxWidthSlider) {
          (double width) => SizedBox(
              width: width,
              child: slider,
            ),
          (_) => Expanded(
              child: slider,
            )
        },
        if (widget.showScaleValue)
          Container(
              alignment: Alignment.centerRight,
              width: 35.0,
              child: Text('${(scale * 100).round()}%')),
        if (widget.showScaleValue)
          const SizedBox(
            width: 8.0,
          )
      ],
    );
  }
}
