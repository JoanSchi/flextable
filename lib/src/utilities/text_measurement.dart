import 'package:flextable/flextable.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;

final _splitReg = RegExp(r' |/|-');

List<String> _textToSegments(String text) {
  List<String> list = [];
  int start = 0;
  int textBreakIndex = text.indexOf(_splitReg, start);

  while (textBreakIndex != -1) {
    list.add(text.substring(start, textBreakIndex));
    list.add(text[textBreakIndex]);
    start = textBreakIndex + 1;
    textBreakIndex = text.indexOf(_splitReg, start);
  }
  if (start < text.length) {
    list.add(text.substring(start));
  }
  return list;
}

Size measureTextCellDimension(
    {required BuildContext context,
    required String text,
    TextScaler? textScaler,
    required CellStyle? cellStyle,
    double? preferredWidth,
    double? maxWidth,
    bool twoLines = true,
    double inaccuracyCompensation = 0.1}) {
  textScaler ??= MediaQuery.textScalerOf(context);
  Size paddingSize = cellStyle?.padding?.collapsedSize ?? Size.zero;
  preferredWidth ??= 0.0;

  Size measureSegment(String textSegment) {
    final textSpan = TextSpan(
      style: switch (cellStyle) {
        (HeaderCellStyle(textStyle: TextStyle t)) => t,
        (TextCellStyle(textStyle: TextStyle t)) => t,
        (_) => null
      },
      text: textSegment,
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textScaler: textScaler!,
    );
    tp.layout();
    return tp.size;
  }

  if (!twoLines) {
    Size size = measureSegment(text);
    double width = math.max(size.width, preferredWidth);
    if (maxWidth case double m) {
      width;
      math.min(width, m);
    }
    return Size(width + paddingSize.width + inaccuracyCompensation,
        size.height + paddingSize.height + inaccuracyCompensation);
  }

  List<String> textSegments = _textToSegments(text);

  var sizedSegments = [
    for (String textSegment in textSegments) measureSegment(textSegment)
  ];

  double widthFirstLine = 0.0;
  double widthSecondLine = 0.0;
  double heightFirstLine = 0.0;
  double heightSecondLine = 0.0;
  int start = 0;
  int end = sizedSegments.length - 1;

  while (start <= end) {
    if (sizedSegments[start] case Size s
        when widthFirstLine + s.width <= preferredWidth) {
      widthFirstLine += s.width;
      start++;

      if (heightFirstLine < s.height) {
        heightFirstLine = s.height;
      }
    } else if (sizedSegments[end] case Size e
        when widthSecondLine + e.width <= preferredWidth) {
      widthSecondLine += e.width;
      end--;

      if (heightSecondLine < e.height) {
        heightSecondLine = e.height;
      }
    } else if ((sizedSegments[start], sizedSegments[end]) case (Size s, Size e)
        when widthFirstLine + s.width <= widthSecondLine + e.width) {
      widthFirstLine += s.width;
      start++;

      if (heightFirstLine < s.height) {
        heightFirstLine = s.height;
      }
    } else {
      final e = sizedSegments[end];
      widthSecondLine += e.width;
      end--;

      if (heightSecondLine < e.height) {
        heightSecondLine = e.height;
      }
    }
  }

  /// +0.1 for double inaccuracy
  ///
  double width = [widthFirstLine + 0.1, widthSecondLine + 0.1, preferredWidth]
      .fold(0.0, (previousValue, element) => math.max(previousValue, element));

  if (maxWidth case double m) {
    width = math.min(width, m);
  }
  return Size(width + paddingSize.width,
      heightFirstLine + heightSecondLine + paddingSize.height);
}
