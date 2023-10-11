<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

# FlexTable

FlexTable is a customizable table with headers, splitView, freezeView, autoFreeze, zoom and scrollbars. The table consist of a model, a viewmodel and builders. Fig. 1 shows some options. Flextable supports two-way scrolling. If the scroll direction deviates less than 22.5 degrees over a length of 30 in the vertical or horizontal direction the scroll stabiliser kicks in to prevent drifting over several pages with enthusiastic scrolling. The stabiliser corrects the drift in the cross scroll direction, so you see probability a small wobbling. The scrollbars can be used if they appear after the drag starts. (mobile)'

It is also possible to place the FlexTable in a customScrollView by wrapping the FlexTable in a adaptive sliver, wrapped in a sliver the table can only scroll in one direction at the same time.

[Web App Example](https://js-lab.nl/flextable) | [Source code](https://github.com/JoanSchi/flextable/tree/main/other_examples/table_examples)

<img src="https://js-lab.nl/flextable/flextable_options.png" width="800" >

Fig. 1: Option: **A.** scroll direction, **B.** Drag to initiate splitView, **C.** Freeze/unfreeze, **D.** Change freeze position

## Usage
To use this plugin, add flextable as a dependency in your pubspec.yaml file.


## Getting started
To make a simple flextable, make a model (DefaultFtModel) at some lines and place the model in the  DefaultFlexTable widget.


### Model
The DefaultFtModel (FtModel\<Cell\>) contains the data, lines, cell dimensions, split options, autofreeze etc. The Cell contains the value and some basic CellAttr: { textStyle, alignment, background, percentagBackground, rotate }.

```dart
  final model = DefaultFtModel(
      defaultWidthCell: 120.0,
      defaultHeightCell: 50.0,
    );


    model.addCell(row: 0, column: 0, cell: Cell(value: 'Hello!', attr: {
        
          CellAttr.textStyle: const TextStyle(
              fontSize: 20, color: Colors.blue)
     }, ));

    // Add lines (see Table Lines paragraph)
    model.horizontalLineList.addLineRange(...)
```


### FlexTable
The DefaultFlexTable (FlexTable\<FtModel\<Cell\>,Cell\>), needs the DefaultFtModel and DefaultTableBuilder. By default zoom, freeze and split (drag from: rigth,top corner) is enabled. It is possible to at FtController to FlexTable to obtain the FtViewModel to change for example scale, split, unlock etc ([flextable settings](https://github.com/JoanSchi/flextable/blob/main/other_examples/table_examples/lib/examples.dart/flextable_settings.dart),
[TableScaleSlider](https://github.com/JoanSchi/flextable/blob/main/other_examples/table_examples/lib/examples.dart/example_fruit.dart)).


```Dart
@override
  Widget build(BuildContext context) {
    return DefaultFlexTable(model: model,tableBuilder: DefaultTableBuilder(),);
  }
```

### FlexTable in CustomScrollView
FlexTable can be placed in a CustomScrollView with FlexTableToSliverBox. How does work: From FlexTableToSliverBox (RenderSliverSingleBoxAdapter) the scroll of the table can be determined with constraints.scrollOffset + overlap and the window size is determined by paintedChildSize. Two directional scrolling is not possible in CustomScrollView at the moment.

```Dart
 final ftController = DefaultFtController();

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(slivers: <Widget>[
      // Other slivers...,
      FlexTableToSliverBox(
          ftController: ftController,
          child: DefaultFlexTable(
            model: model,
            tableBuilder: DefaultTableBuilder(),
            ftController: ftController,
          ))
    ]);
  }
```

### Costumize FlexTable
The Default is at the moment quite basic, nevertheless the following classes can be extended to change cell properties, cell build, table measurements, how the cell properties is received, etc:  
- FtModel\<C extends AbstractCell\> extends AbstractFtModel\<C\>
- AbstractTableBuilder\<T extends AbstractFtModel\<C\>,C extends AbstractCell\>
- FlexTable\<T extends AbstractFtModel\<C\>, C extends AbstractCell\>
- FtController\<T extends AbstractFtModel\<C\>, C extends AbstractCell\>
- AbstractCell

### Table Lines
The vertical and horizontal lines are added seperatedly to the table in ranges to minimize objects for large tables. The TableLinesOneDirection object contains a LineLinkedList with LineRanges which contains a LineLinkedList with LineNodeRanges for one direction.
The TableLinesOneDirection object will merge added LineRanges and the containing LineNodes. Equal ranges besides each other will merge into a bigger range. 
Lines or parts of the line can be deleted by adding EmptyLineNodes (LineNode with noLines) over the desired range. 
The TableLinesOneDirection will remove the lines where the EmptyLineNode are merged. If the LineRange is empty, the LineRange will be removed automatical.
A LineNodeRange or LineNode object can be reused for loops, because they are coppied or merged by TableLinesOneDirection object.

It is possible to change the width and color of the existing lines over a large range by using Line.change(width:.., color..). The new properties will merge with the existing lines.


```dart
TableLinesOneDirection horizontalLines = TableLinesOneDirection();
// or with initialized FtModel -> ftModel.horizontalLines

const blueLine = Line(
    width: 0.5,
    color: Color(0xFF42A5F5),
  );

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
 ```
Output:

LineRanges in TableLinesOneDirection: 
- LineNodeRange 0-2: 
  - LineNode 0-0: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 2-2: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
  - LineNode 4-4: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null

```
  Change to:

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
```
Output:

LineRanges in TableLinesOneDirection: 
- LineNodeRange 0-0: 
  - LineNode 0-0: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 2-2: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
  - LineNode 4-4: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
- LineNodeRange 1-1: 
  - LineNode 2-2: before: Line(o:LineOptions.no, w:null, c:null), after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 4-4: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: Line(o:LineOptions.no, w:null, c:null)
- LineNodeRange 2-2: 
  - LineNode 0-0: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 2-2: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null
  - LineNode 4-4: before: null, after: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:0.5, c:Color(0xff42a5f5)), after: null

```
  Change to:

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
```
Output:

LineRanges in TableLinesOneDirection: 
- LineNodeRange 0-0: 
  - LineNode 0-0: before: Line(o:null, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 1-5: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:null, w:2.0, c:Color(0xff8ed43f))
- LineNodeRange 1-1: 
  - LineNode 2-2: before: Line(o:LineOptions.no, w:null, c:null), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 4-4: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.no, w:null, c:null)
- LineNodeRange 2-2: 
  - LineNode 0-0: before: Line(o:null, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 6-6: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:null, w:2.0, c:Color(0xff8ed43f))

```
  Change to:

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
```

Output:
LineRanges in TableLinesOneDirection: 
- LineNodeRange 1-1: 
  - LineNode 2-2: before: Line(o:LineOptions.no, w:null, c:null), after: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f))
  - LineNode 4-4: before: Line(o:LineOptions.line, w:2.0, c:Color(0xff8ed43f)), after: Line(o:LineOptions.no, w:null, c:null)


### ToDo
- Cell press listener.
- Keep cell alive.
- Scroll to.
- More cell options and add get Widget for special cases.


