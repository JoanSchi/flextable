// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/flextable.dart';
import 'package:flutter/widgets.dart';

calculateLinePosition({
  required Canvas canvas,
  required Size size,
  required LayoutPanelIndex tableIndex,
  required int scrollIndexX,
  required int scrollIndexY,
  required double xScroll,
  required double yScroll,
  required double tableScale,
  required bool horizontal,
  required TableLinesOneDirection lineList,
  required List<GridInfo> infoLevelOne,
  required List<GridInfo> infoLevelTwo,
}) {
  if (lineList.isEmpty || infoLevelOne.isEmpty || infoLevelTwo.isEmpty) {
    return;
  }

  int startLevelOne = infoLevelOne.first.index;
  int endLevelOne = infoLevelOne.last.index + 1;
  int startLevelTwo = infoLevelTwo.first.index;
  int endLevelTwo = infoLevelTwo.last.index + 1;

  double positionLevelTwo(int index) {
    int length = infoLevelTwo.length;
    final i = index - startLevelTwo;
    if (i < 0) {
      return infoLevelTwo[0].position;
    } else if (i < length) {
      return infoLevelTwo[i].position;
    } else {
      return infoLevelTwo.last.endPosition;
    }
  }

  LineRange? node =
      lineList.begin(startLevelOne, scrollIndexX, scrollIndexY, false);
  Paint paint = Paint();

  while (node != null && node.start <= endLevelOne) {
    int startDrawOne = node.start < startLevelOne ? startLevelOne : node.start;
    int endDrawOne = node.end > endLevelOne ? endLevelOne : node.end;

    for (int i = startDrawOne; i <= endDrawOne; i++) {
      LineNode? firstNode = node.lineNodeRange
          .begin(startLevelTwo, scrollIndexX, scrollIndexY, false);

      int startWithinBoundery = 0;
      int endWithinboundery;
      double startPosition = 0.0;
      double endPosition = 0.0;

      final positionLevelOne = i != endLevelOne
          ? infoLevelOne[i - startLevelOne].position
          : infoLevelOne.last.endPosition;

      LineNode? secondNode = firstNode.next;

      /// Draw line from the first end to second start
      /// The line is only drawn if the node has a line at the start and end side.
      ///

      single(LineNode node) {
        if (node.end - node.start == 0) {
          return;
        }
        startWithinBoundery =
            node.start < startLevelTwo ? startLevelTwo : node.start;
        endWithinboundery = node.end > endLevelTwo ? endLevelTwo : node.end;

        if (startWithinBoundery < endWithinboundery) {
          startPosition =
              infoLevelTwo[startWithinBoundery - startLevelTwo].position;
          endPosition = positionLevelTwo(endWithinboundery);
          drawLine(
              horizontal: horizontal,
              canvas: canvas,
              paint: paint,
              size: size,
              xScroll: xScroll,
              yScroll: yScroll,
              tableScale: tableScale,
              first: node,
              second: node,
              levelTwoStartPosition: startPosition,
              levelTwoEndPosition: endPosition,
              levelOnePosition: positionLevelOne);
        }
      }

      two(LineNode nodeOne, LineNode nodeTwo) {
        startWithinBoundery =
            nodeOne.end > endLevelTwo ? endLevelTwo : nodeOne.end;

        endWithinboundery =
            nodeTwo.start < startLevelTwo ? startLevelTwo : nodeTwo.start;

        if (startWithinBoundery < endWithinboundery) {
          startPosition = positionLevelTwo(startWithinBoundery);
          endPosition = positionLevelTwo(endWithinboundery);

          drawLine(
              horizontal: horizontal,
              canvas: canvas,
              paint: paint,
              size: size,
              xScroll: xScroll,
              yScroll: yScroll,
              tableScale: tableScale,
              first: nodeOne,
              second: nodeTwo,
              levelTwoStartPosition: startPosition,
              levelTwoEndPosition: endPosition,
              levelOnePosition: positionLevelOne);
        }
      }

      while (firstNode != null) {
        if (firstNode.start < endLevelTwo) {
          single(firstNode);
        } else {
          break;
        }

        if (secondNode != null &&
            firstNode.start < endLevelTwo &&
            secondNode.end >= startLevelTwo) {
          two(firstNode, secondNode);
        } else {
          break;
        }

        firstNode = secondNode;
        secondNode = firstNode.next;
      }
    }

    node = node.next;
  }
}

drawLine(
    {required Canvas canvas,
    Offset? offset,
    required Paint paint,
    required Size size,
    required double xScroll,
    required double yScroll,
    required double tableScale,
    LineNode? first,
    LineNode? second,
    required double levelOnePosition,
    double levelTwoStartPosition = 0.0,
    double levelTwoEndPosition = double.maxFinite,
    required bool horizontal}) {
  final firstAfter = first?.after;
  final secondBefore = second?.before;

  if (firstAfter != null && !firstAfter.isEmpty) {
    paint
      ..color = firstAfter.color!
      ..strokeWidth = firstAfter.widthScaled(tableScale);
  } else if (secondBefore != null && !secondBefore.isEmpty) {
    paint
      ..color = secondBefore.color!
      ..strokeWidth = secondBefore.widthScaled(tableScale);
  } else {
    return;
  }

  final distanceLevelOne = horizontal ? yScroll : xScroll;
  final distanceLevelTwo = horizontal ? xScroll : yScroll;
  final length = horizontal ? size.width : size.height;

  levelTwoStartPosition =
      (levelTwoStartPosition - distanceLevelTwo) * tableScale;

  if (levelTwoStartPosition < 0.0) {
    levelTwoStartPosition = 0.0;
  }

  levelTwoEndPosition = (levelTwoEndPosition - distanceLevelTwo) * tableScale;

  if (levelTwoEndPosition > length) {
    levelTwoEndPosition = length;
  }

  levelOnePosition = (levelOnePosition - distanceLevelOne) * tableScale;

  canvas.drawLine(
      horizontal
          ? Offset(levelTwoStartPosition, levelOnePosition)
          : Offset(levelOnePosition, levelTwoStartPosition),
      horizontal
          ? Offset(levelTwoEndPosition, levelOnePosition)
          : Offset(levelOnePosition, levelTwoEndPosition),
      paint);
}
