// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flextable/src/builders/table_line.dart';
import 'package:flutter/material.dart';

void main() {
  const blueLine = Line(
    width: 0.5,
    color: Color(0xFF42A5F5),
  );

  debugPrint('Example --1--');

  TableLinesOneDirection horizontalLines = TableLinesOneDirection();

  /// 0: --  --
  /// 1: --  --
  /// 2: --  --
  ///
  horizontalLines.addLineRange(LineRange(
      startIndex: 0,
      endIndex: 2,
      lineNodeRange: LineNodeRange(list: [
        LineNode(startIndex: 0, after: blueLine),
        LineNode(startIndex: 2, before: blueLine),
        LineNode(startIndex: 4, after: blueLine),
        LineNode(startIndex: 6, before: blueLine),
      ])));

  debugPrint(horizontalLines.toString());

  debugPrint('Example --2--');

  /// 0: --  --
  /// 1:   --
  /// 2: --  --
  ///

  horizontalLines.addLineRange(LineRange(
      startIndex: 1,
      lineNodeRange: LineNodeRange(
        list: [
          // remove line
          EmptyLineNode(startIndex: 0, endIndex: 6),
          //add new line
          LineNode(startIndex: 2, after: blueLine),
          LineNode(startIndex: 4, before: blueLine),
        ],
      )));

  debugPrint(horizontalLines.toString());

  debugPrint('Example --3--');

  /// 0: ------
  /// 1:   --
  /// 2: ------
  ///
  /// Change all lines to: width = 2.0, color = green

  horizontalLines.addLineRanges((add) {
    // replace complete line
    add(LineRange(
        startIndex: 0,
        lineNodeRange: LineNodeRange(
          list: [
            LineNode(
              startIndex: 0,
              after: blueLine,
            ),
            LineNode(
              startIndex: 1,
              endIndex: 5,
              before: blueLine,
              after: blueLine,
            ),
            LineNode(startIndex: 6, before: blueLine),
          ],
        )));

    // remove middle part of the line
    add(LineRange(
        startIndex: 2,
        lineNodeRange: LineNodeRange(
          list: [
            EmptyLineNode(
              startIndex: 2,
              endIndex: 4,
            ),
          ],
        )));

    // Merge changes to existing lines:
    add(LineRange(
        startIndex: 0,
        endIndex: 2,
        lineNodeRange: LineNodeRange(
          list: [
            LineNode(
                startIndex: 0,
                endIndex: 6,
                before: const Line.change(
                    width: 2.0, color: Color.fromARGB(255, 142, 212, 63)),
                after: const Line.change(
                    width: 2.0, color: Color.fromARGB(255, 142, 212, 63))),
          ],
        )));
  });

  debugPrint(horizontalLines.toString());

  debugPrint('Example --4--');

  /// 0: remove
  /// 1:   --
  /// 2: remove
  ///
  horizontalLines.addLineRanges((add) {
    // Reuse of emptyLineNodeRange to remove row 0 and 2

    final emptyLineNodeRange = LineNodeRange(
      list: [EmptyLineNode(startIndex: 0, endIndex: 6)],
    );

    for (int i in [0, 2]) {
      add(LineRange(startIndex: i, lineNodeRange: emptyLineNodeRange));
    }
  });
  debugPrint(horizontalLines.toString());

  // final calculator = Calculator();
  // expect(calculator.addOne(2), 3);
  // expect(calculator.addOne(-7), -6);
  // expect(calculator.addOne(0), 1);
}
