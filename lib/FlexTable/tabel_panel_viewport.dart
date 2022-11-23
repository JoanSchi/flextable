import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'table_builder.dart';
import 'TableItems/Cells.dart';
import 'table_iterations.dart';
import 'table_line.dart';
import 'table_multi_panel_portview.dart';
import 'table_model.dart';

class TablePanelViewport extends RenderObjectWidget {
  final TableModel tableModel;
  final int panelIndex;
  final TableBuilder tableBuilder;
  final double tableScale;

  TablePanelViewport(
      {Key? key,
      required this.tableModel,
      required this.panelIndex,
      required this.tableBuilder,
      required this.tableScale})
      : super(key: key);

  @override
  TablePanelChildRenderObjectElement createElement() =>
      TablePanelChildRenderObjectElement(this);

  @override
  void updateRenderObject(
      BuildContext context, TablePanelRenderViewport renderObject) {
    renderObject..tableModel = tableModel;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final TablePanelRenderChildManager element =
        context as TablePanelRenderChildManager;

    return TablePanelRenderViewport(
      childManager: element,
      tableModel: tableModel,
      panelIndex: panelIndex,
    );
  }
}

class TablePanelChildRenderObjectElement extends RenderObjectElement
    implements TablePanelRenderChildManager {
  final Map<TableCellIndex, Widget?> _childWidgets =
      HashMap<TableCellIndex, Widget?>();
  final SplayTreeMap<TableCellIndex, Element?> _childElements =
      SplayTreeMap<TableCellIndex, Element?>();
  RenderBox? _currentBeforeChild;
  TableCellIndex? _currentlyUpdatingTableCellIndex;

  TablePanelChildRenderObjectElement(TablePanelViewport widget) : super(widget);

  @override
  TablePanelViewport get widget => super.widget as TablePanelViewport;

  @override
  TablePanelRenderViewport get renderObject =>
      super.renderObject as TablePanelRenderViewport;

  @protected
  @visibleForTesting
  Iterable<Element> get children =>
      _children.where((Element child) => !_forgottenChildren.contains(child));

  List<Element> _children = [];
  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void performRebuild() {
    _childWidgets.clear(); // Reset the cache, as described above.
    super.performRebuild();

    _currentBeforeChild = null;

    _childElements.keys.forEach((TableCellIndex index) {
      final build = _build(index);
      if (build != null) {
        _childElements[index] =
            updateChild(_childElements[index], _build(index), index);
      }
    });

    _currentBeforeChild = null;
    assert(_currentlyUpdatingTableCellIndex == null);
    try {
      final SplayTreeMap<TableCellIndex, Element?> newChildren =
          SplayTreeMap<TableCellIndex, Element?>();

      void processElement(TableCellIndex index) {
        _currentlyUpdatingTableCellIndex = index;
        if (_childElements[index] != null &&
            _childElements[index] != newChildren[index]) {
          // This index has an old child that isn't used anywhere and should be deactivated.
          _childElements[index] =
              updateChild(_childElements[index], null, index);
        }
        final Element? newChild =
            updateChild(newChildren[index], _build(index), index);
        if (newChild != null) {
          _childElements[index] = newChild;
          _currentBeforeChild = newChild.renderObject as RenderBox?;
        } else {
          _childElements.remove(index);
        }
      }

      for (TableCellIndex index in _childElements.keys.toList()) {
        newChildren.putIfAbsent(index, () => _childElements[index]);
      }

      renderObject.debugChildIntegrityEnabled =
          false; // Moving children will temporary violate the integrity.

      newChildren.keys.forEach(processElement);

//      if (_didUnderflow) {
//        final int lastKey = _childElements.lastKey() ?? -1;
//        final int rightBoundary = lastKey + 1;
//        newChildren[rightBoundary] = _childElements[rightBoundary];
//        processElement(rightBoundary);
//      }
    } finally {
      _currentlyUpdatingTableCellIndex = null;
      renderObject.debugChildIntegrityEnabled = true;
    }
  }

  @override
  void update(covariant TablePanelViewport newWidget) {
    final TablePanelViewport oldWidget = widget;
    super.update(newWidget);
    final TableModel newDelegate = newWidget.tableModel;
    final TableModel oldDelegate = oldWidget.tableModel;
    if ((newDelegate != oldDelegate &&
            (newDelegate.runtimeType != oldDelegate.runtimeType ||
                newDelegate.shouldRebuild(oldDelegate))) ||
        oldWidget.tableScale != newWidget.tableScale) performRebuild();
  }

  @override
  void createChild(TableCellIndex tableCellIndex, {RenderBox? after}) {
    assert(_currentlyUpdatingTableCellIndex == null);
    owner!.buildScope(this, () {
      final bool insertFirst = after == null;

      if (insertFirst) {
        _currentBeforeChild = null;
      } else {
        final lastKeyBefore = _childElements.lastKeyBefore(tableCellIndex);
        assert(lastKeyBefore != null);
        final element = _childElements[lastKeyBefore];
        assert(element != null);
        _currentBeforeChild = element!.renderObject as RenderBox?;
      }

      Element? newChild;
      try {
        _currentlyUpdatingTableCellIndex = tableCellIndex;
        newChild = updateChild(_childElements[tableCellIndex],
            _build(tableCellIndex), tableCellIndex);
      } finally {
        _currentlyUpdatingTableCellIndex = null;
      }
      if (newChild != null) {
        _childElements[tableCellIndex] = newChild;
      } else {
        _childElements.remove(tableCellIndex);
      }
    });
  }

  @override
  bool containsElement(TableCellIndex key) {
    return _childElements.containsKey(key);
  }

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingTableCellIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingTableCellIndex != null);
    final TableCellParentData childParentData =
        child.parentData as TableCellParentData;
    childParentData.tableCellIndex = _currentlyUpdatingTableCellIndex!;
  }

  @override
  void didFinishLayout() {}

  @override
  void didStartLayout() {}

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);
    //    assert(_children.contains(child));
    //    assert(!_forgottenChildren.contains(child));
    //    _forgottenChildren.add(child);
    // assert(child != null);
    assert(child.slot != null);
    assert(_childElements.containsKey(child.slot));
    _childElements.remove(child.slot);
  }

  @override
  void insertRenderObjectChild(RenderObject child, TableCellIndex slot) {
    // assert(slot != null);
    assert(_currentlyUpdatingTableCellIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child as RenderBox, after: _currentBeforeChild);
    assert(() {
      final TableCellParentData childParentData =
          child.parentData as TableCellParentData;
      //print('slot $slot tableCellIndex ${childParentData.tableCellIndex}');
      assert(slot == childParentData.tableCellIndex);
      return true;
    }());
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, dynamic oldSlot, dynamic newSlot) {
    assert(slot != null);
    assert(_currentlyUpdatingTableCellIndex == slot);
    renderObject.move(child as RenderBox, after: _currentBeforeChild);
  }

  @override
  void removeChild(RenderBox child) {
    final TableCellIndex index = renderObject.indexOf(child);
    assert(_currentlyUpdatingTableCellIndex == null);

    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingTableCellIndex = index;
        final Element? result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingTableCellIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    assert(_currentlyUpdatingTableCellIndex != null);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // The toList() is to make a copy so that the underlying list can be modified by
    // the visitor:
    assert(!_childElements.values.any((Element? child) => child == null));
    _childElements.values.cast<Element>().toList().forEach(visitor);
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, dynamic newSlot) {
    final TableCellParentData? oldParentData =
        child?.renderObject?.parentData as TableCellParentData?;

    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final TableCellParentData? newParentData =
        newChild?.renderObject?.parentData as TableCellParentData?;
    // Preserve the old layoutOffset if the renderObject was swapped out.

    if (oldParentData != newParentData &&
        oldParentData != null &&
        newParentData != null) {
      assert(oldParentData.tableCellIndex == newParentData.tableCellIndex,
          'TableCellIndex not equal, old: ${oldParentData.tableCellIndex}, new: ${newParentData.tableCellIndex}');
      newParentData.offset = oldParentData.offset;
    }
    return newChild;
  }

  @override
  void setDidUnderflow(bool value) {}

  Widget? _build(TableCellIndex tableCellIndex) {
    return _childWidgets.putIfAbsent(tableCellIndex, () {
      // return Container(
      //   color: tableCellIndex.row % 2 == 0 ? Colors.grey[50] : Colors.grey[100],
      // );

      // return //RepaintBoundary(
      //     Container(
      //         color: tableCellIndex.row % 2 == 0 ? Colors.grey[50] : Colors.grey[100],
      //         child: Center(child: Text('R${tableCellIndex.row}C${tableCellIndex.column}')));

      return widget.tableBuilder.buildCell(widget.tableScale, tableCellIndex);
    });
  }
}

abstract class TablePanelRenderChildManager {
  void createChild(TableCellIndex tableCellIndex, {required RenderBox? after});

  void removeChild(RenderBox child);

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  void didStartLayout();

  void didFinishLayout();

  bool debugAssertChildListLocked() => true;

  //Added by Joan
  bool containsElement(TableCellIndex tableCellIndex);
}

class TablePanelRenderViewport extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableCellParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableCellParentData> {
  TablePanelRenderChildManager childManager;
  int panelIndex;
  late TablePanelLayoutIndex tpli;
  late TableInterator iterator;
  late double xScroll, yScroll;
  late double scaleAndZoom;
  late double leftMargin, topMargin, rightMargin, bottomMargin;
  TableModel _tableModel;
  int garbageCollectRowsFrom = -1;
  int garbageCollectColumnsFrom = -1;

  TablePanelRenderViewport({
    required TableModel tableModel,
    ScrollPosition? sliverPosition,
    required this.childManager,
    required this.panelIndex,
  }) : _tableModel = tableModel {
    iterator = TableInterator(tableModel: tableModel);
  }

  TableModel get tableModel => _tableModel;

  set tableModel(TableModel value) {
    // assert(value != null);
    if (value == _tableModel) return;
    if (attached) _tableModel.removeListener(markNeedsLayout);
    _tableModel = value;
    if (attached) _tableModel.addListener(markNeedsLayout);

    iterator.tableModel = value;

    garbageCollectRowsFrom = 0;
    garbageCollectColumnsFrom = 0;

    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TableCellParentData)
      child.parentData = TableCellParentData();
  }

  TableCellIndex cellIndexOf(RenderBox child) {
    // assert(child != null);
    final TableCellParentData childParentData =
        child.parentData as TableCellParentData;
    // assert(childParentData.tableCellIndex != null);
    return childParentData.tableCellIndex;
  }

  @override
  void performResize() {
    super.performResize();
    // default behavior for subclasses that have sizedByParent = true
    assert(size.isFinite);
  }

  //int count = 0;

  @override
  void performLayout() {
    childManager.didStartLayout();
    size = constraints.biggest;

    RenderBox? child;
    tpli = tableModel.layoutIndex(panelIndex);

    xScroll = tableModel.getScrollX(tpli.scrollIndexX, tpli.scrollIndexY);
    yScroll = tableModel.getScrollY(tpli.scrollIndexX, tpli.scrollIndexY);
    scaleAndZoom = tableModel.tableScale;

    final layoutX = tableModel.widthLayoutList[tpli.xIndex];
    leftMargin = layoutX.marginBegin;
    rightMargin = layoutX.marginEnd;

    final layoutY = tableModel.heightLayoutList[tpli.yIndex];
    topMargin = layoutY.marginBegin;
    bottomMargin = layoutY.marginEnd;

    iterator.reset(tpli);

    garbageCollect(
        removeAll: iterator.isEmpty,
        firstRowIndex: iterator.firstRowIndex,
        firstColumnIndex: iterator.firstColumnIndex,
        lastRowIndex: iterator.lastRowIndex,
        lastColumnIndex: iterator.lastColumnIndex);

    var indexFirstChild;

    if (firstChild != null) {
      indexFirstChild =
          (firstChild!.parentData as TableCellParentData).tableCellIndex;
      child = firstChild;
    }

    while (iterator.next) {
      var cell = iterator.cell;
      final tableCellIndex = iterator.tableCellIndex;

      if (cell != null) {
        if (firstChild == null) {
          child = insertAndLayoutFirstChild(after: null, index: tableCellIndex);
          indexFirstChild = tableCellIndex;

          assert(tableCellIndex ==
              (firstChild!.parentData as TableCellParentData).tableCellIndex);
        } else {
          assert(child != null,
              'child can not be null in next $tableCellIndex ${firstChild == null}');

          TableCellParentData parentData =
              child!.parentData as TableCellParentData;

          if (parentData.tableCellIndex < tableCellIndex) {
            child = findOrInsert(
                child: child, index: tableCellIndex, forward: true);
          } else if (tableCellIndex < indexFirstChild) {
            child =
                insertAndLayoutFirstChild(after: null, index: tableCellIndex);
            indexFirstChild = tableCellIndex;

            assert(tableCellIndex ==
                (firstChild!.parentData as TableCellParentData).tableCellIndex);
          } else {
            child = findOrInsert(
                child: child, index: tableCellIndex, forward: false);
          }
        }
        layoutChild(child: child, cell: cell);
      } else {
        assert(find(tableCellIndex) == null,
            'Renderbox should be removed, but not yet implemented!');
      }
    }

    child = firstChild;

    childManager.didFinishLayout();
  }

  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    bool isHit = super.hitTest(result, position: position);
    return isHit;
  }

  @protected
  bool hitTestSelf(Offset position) => true;

  void layoutChild({
    required RenderBox child,
    required Cell cell,
    bool parentUsesSize = true,
  }) {
    BoxConstraints constraints = BoxConstraints.tightFor(
        width: cell.width * scaleAndZoom, height: cell.height * scaleAndZoom);

    child.layout(constraints, parentUsesSize: parentUsesSize);

    final TableCellParentData parentData =
        child.parentData as TableCellParentData;

    parentData.offset = Offset((cell.left - xScroll) * scaleAndZoom,
        (cell.top - yScroll) * scaleAndZoom);
    assert(!xScroll.isNaN, 'xScroll NaN');
    assert(!yScroll.isNaN, 'yScroll NaN');
    assert(!cell.left.isNaN, 'Cell left NaN');
    assert(!cell.top.isNaN, 'Cell top NaN');
    assert(!parentData.offset.dx.isNaN, 'Blb x NaN');
    assert(!parentData.offset.dy.isNaN, 'Blb2 y NaN');
  }

  RenderBox findOrInsert(
      {required RenderBox child,
      required TableCellIndex index,
      required bool forward}) {
    // assert(child != null);
    assert(child.parent == this);

    TableCellParentData parentData = child.parentData as TableCellParentData;

    if (parentData.tableCellIndex == index) {
      return child;
    }

    RenderBox? shiftChild;

    if (forward) {
      shiftChild = parentData.nextSibling;

      while (shiftChild != null) {
        parentData = shiftChild.parentData as TableCellParentData;

        if (parentData.tableCellIndex <= index) {
          child = shiftChild;
        } else {
          break;
        }

        shiftChild = parentData.nextSibling;
      }
      assert((child.parentData as TableCellParentData).tableCellIndex <= index);
    } else {
      shiftChild = parentData.previousSibling;
      while (shiftChild != null) {
        parentData = shiftChild.parentData as TableCellParentData;

        if (index >= parentData.tableCellIndex) {
          child = shiftChild;
          break;
        }

        shiftChild = parentData.previousSibling;
      }

      assert(index >= (child.parentData as TableCellParentData).tableCellIndex);
    }

    if ((child.parentData as TableCellParentData).tableCellIndex != index) {
      child = insertAndLayoutChild(after: child, index: index);
      assert(index == (child.parentData as TableCellParentData).tableCellIndex);
    }

    return child;
  }

  RenderBox? find(TableCellIndex index) {
    RenderBox? child = firstChild;

    while (child != null) {
      TableCellParentData parentData = child.parentData as TableCellParentData;
      if (parentData.tableCellIndex == index) {
        return child;
      }
      child = parentData.nextSibling;
    }

    return null;
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    //final TablePanelParentData childParentData = child.parentData;
    //if (!childParentData._keptAlive)
    childManager.didAdoptChild(child as RenderBox);
  }

  int scrollIndex(int panelIndex) {
    if (panelIndex == 0) {
      return 0;
    } else if (panelIndex == 3) {
      return 1;
    } else {
      return panelIndex - 1;
    }
  }

  @protected
  RenderBox insertAndLayoutFirstChild({
    required RenderBox? after,
    required TableCellIndex index,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, after: after);

    assert(firstChild != null);
    TableCellParentData parentData =
        firstChild!.parentData as TableCellParentData;
    assert(index == parentData.tableCellIndex);

    return firstChild!;
  }

  @protected
  RenderBox insertAndLayoutChild({
    required RenderBox after,
    required TableCellIndex index,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, after: after);
    final RenderBox? child = childAfter(after);

    assert(child != null, 'insertAndLayoutChild child is null');

    assert(child != null && cellIndexOf(child) == index,
        'insertAndLayoutChild child after has cellIndex: ${cellIndexOf(child!)} should be  $index');

    return child!;
  }

  // columns 1024 -> 1023
  //rows 2^20 1048576 -> 1048575

  garbageCollect(
      {bool removeAll = false,
      int firstRowIndex = 0,
      int firstColumnIndex = 0,
      int lastRowIndex = 1048575,
      int lastColumnIndex = 1023}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      RenderBox? child = firstChild;

      while (child != null) {
        TableCellParentData parentData =
            child.parentData as TableCellParentData;
        TableCellIndex tableCellIndex = parentData.tableCellIndex;
        var rows = 0;
        int columns = 0;
        final childToRemove = child;

        child = parentData.nextSibling;

        if (removeAll ||
            (garbageCollectRowsFrom != -1 &&
                garbageCollectRowsFrom <= tableCellIndex.row) ||
            (garbageCollectColumnsFrom != -1 &&
                garbageCollectColumnsFrom <= tableCellIndex.column) ||
            firstRowIndex > tableCellIndex.row + rows ||
            lastRowIndex < tableCellIndex.row ||
            firstColumnIndex > tableCellIndex.column + columns ||
            lastColumnIndex < tableCellIndex.column) {
          assert(childManager.containsElement(tableCellIndex),
              'Element bestaat niet $tableCellIndex');

          childManager.removeChild(childToRemove);
        }
      }
    });

    garbageCollectRowsFrom = -1;
    garbageCollectColumnsFrom = -1;
  }

  void _createOrObtainChild(TableCellIndex index, {required RenderBox? after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  TableCellIndex indexOf(RenderBox child) {
    return (child.parentData as TableCellParentData).tableCellIndex;
  }

  bool _debugAssertChildListLocked() =>
      childManager.debugAssertChildListLocked();

  bool get debugChildIntegrityEnabled => _debugChildIntegrityEnabled;

  bool _debugChildIntegrityEnabled = true;
  set debugChildIntegrityEnabled(bool enabled) {
    // assert(enabled != null);
    assert(() {
      _debugChildIntegrityEnabled = enabled;
      return _debugVerifyChildOrder() || !_debugChildIntegrityEnabled;
    }());
  }

  bool _debugVerifyChildOrder() {
    if (_debugChildIntegrityEnabled) {
      RenderBox? child = firstChild;
      TableCellIndex index;
      while (child != null) {
        index = cellIndexOf(child);
        child = childAfter(child);
        assert(child == null || cellIndexOf(child) > index);
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    // _offset.addListener(markNeedsLayout);
    // _sliverPosition?.addListener(markNeedsLayout);
    _tableModel.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    // _offset.removeListener(markNeedsLayout);
    // _sliverPosition?.removeListener(markNeedsLayout);
    _tableModel.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    // final leftMargin = (panelIndexX == 1) ? tableModel.leftMargin : 0.0;
    // final topMargin = (panelIndexY == 1) ? tableModel.topMargin : 0.0;
    // final rightMargin = ((panelIndexX == 1 && tableModel.stateSplitX == SplitState.NO_SPLITE) || panelIndexX == 2)
    //     ? tableModel.rightMargin
    //     : 0.0;
    // final bottomMargin = ((panelIndexY == 1 && tableModel.stateSplitY == SplitState.NO_SPLITE) || panelIndexY == 2)
    //     ? tableModel.bottomMargin
    //     : 0.0;

    context.pushClipRect(needsCompositing, offset,
        Rect.fromLTWH(0.0, 0.0, size.width, size.height), (context, offset) {
      offset = offset.translate(leftMargin, topMargin);
      defaultPaint(context, offset);

      if (!iterator.isEmpty) {
        paintLines(context, offset);
      }

      assert(() {
        Color color;
        switch (panelIndex) {
          case 5:
            color = Colors.amber.withAlpha(155);
            break;
          case 6:
            color = Colors.pinkAccent.withAlpha(155);
            break;
          case 9:
            color = Colors.lightGreen.withAlpha(155);
            break;
          default:
            color = Colors.blue.withAlpha(155);
            break;
        }
        Paint paint = Paint();
        paint.color = color;
        context.canvas.drawCircle(
            size.bottomRight(offset + Offset(-25.0, -25.0)), 20, paint);
        return true;
      }());
    });
  }

  paintLines(PaintingContext context, Offset offset) {
    final startRow = iterator.firstRowIndex;
    final endRow = iterator.lastRowIndex;

    final startColumn = iterator.firstColumnIndex;
    final endColumn = iterator.lastColumnIndex;

    Canvas canvas = context.canvas;

    canvas.save();
    int debugPreviousCanvasSaveCount = 0;

    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());

    if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);

    calculateLinePosition(
        canvas: canvas,
        startLevelOne: startRow,
        endLevelOne: endRow,
        startLevelTwo: startColumn,
        endLevelTwo: endColumn + 1,
        lineList: tableModel.dataTable.horizontalLineList,
        infoLevelOne: iterator.rowInfoList,
        infoLevelTwo: iterator.columnInfoList,
        crossNode: (b) => false,
        drawLineOneDirection: drawHorizontalLine);

    calculateLinePosition(
        canvas: canvas,
        startLevelOne: startColumn,
        endLevelOne: endColumn,
        startLevelTwo: startRow,
        endLevelTwo: endRow + 1,
        lineList: tableModel.dataTable.verticalLineList,
        infoLevelOne: iterator.columnInfoList,
        infoLevelTwo: iterator.rowInfoList,
        crossNode: (b) => false,
        drawLineOneDirection: drawVerticalLine);

    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }(), 'Previous canvas count is different from the current canvas count!');

    canvas.restore();
  }

  calculateLinePosition(
      {required Canvas canvas,
      required int startLevelOne,
      required int endLevelOne,
      required int startLevelTwo,
      required int endLevelTwo,
      required TableLineList lineList,
      required List<GridInfo> infoLevelOne,
      required List<GridInfo> infoLevelTwo,
      required CrossNode crossNode,
      required DrawLineOneDirection drawLineOneDirection}) {
    if (lineList.isEmpty) {
      return;
    }

    positionLevelTwo(int index) {
      int length = infoLevelTwo.length;

      return index < length + startLevelTwo
          ? infoLevelTwo[index - startLevelTwo].position
          : infoLevelTwo.last.endPosition;
    }

    int scrollIndexX = tpli.scrollIndexX;
    int scrollIndexY = tpli.scrollIndexY;

    TableLineNode? node =
        lineList.begin(startLevelOne, scrollIndexX, scrollIndexY, false);
    Paint paint = Paint();

    while (node != null &&
        node.startIndex <= endLevelOne &&
        node.endIndex >= startLevelOne) {
      int startDrawOne =
          node.start < startLevelOne ? startLevelOne : node.start;
      int endDrawOne = node.end > endLevelOne ? endLevelOne : node.end;

      for (int i = startDrawOne; i <= endDrawOne; i++) {
        LineNode firstNode = node.lineList
            .begin(startLevelTwo, scrollIndexX, scrollIndexY, false);
        LineNode? secondNode = firstNode.next;

        int startWithinBoundery = 0;
        int endWithinboundery;
        double startPosition = 0.0;
        double endPosition = 0.0;

        final positionLevelOne = infoLevelOne[i - startLevelOne].position;

        if (startLevelTwo < firstNode.start) {
          endWithinboundery =
              firstNode.start > endLevelTwo ? endLevelTwo : firstNode.start;
          endPosition = positionLevelTwo(endWithinboundery);
          drawLineOneDirection(
              canvas: canvas,
              paint: paint,
              second: firstNode,
              levelTwoEndPosition: endPosition,
              levelOnePosition: positionLevelOne);
        }

        while (secondNode != null &&
            firstNode.start <= endLevelTwo &&
            secondNode.end >= startLevelTwo) {
          startWithinBoundery =
              firstNode.start < startLevelTwo ? startLevelTwo : firstNode.start;
          endWithinboundery =
              firstNode.end > endLevelTwo ? endLevelTwo : firstNode.end;
          // int endWithoutBoundery =
          //     firstNode.end > endLevelTwo ? endLevelTwo + 1 : firstNode.end;

          // More than one node:  startLevelTwo < previous.end
          //
          //

          //assert(startWithinBoundery <= endWithinboundery);

          if (startWithinBoundery < endWithinboundery &&
              !crossNode(firstNode)) {
            for (int j = startWithinBoundery; j < endWithinboundery; j++) {
              startPosition = infoLevelTwo[j - startLevelTwo].position;
              endPosition = positionLevelTwo(j + 1);

              drawLineOneDirection(
                  canvas: canvas,
                  paint: paint,
                  first: firstNode,
                  second: firstNode,
                  levelTwoStartPosition: startPosition,
                  levelTwoEndPosition: endPosition,
                  levelOnePosition: positionLevelOne);
            }

            if (endLevelTwo <= endWithinboundery) {
              startPosition = endPosition;
              endPosition = infoLevelTwo.last.endPosition;
              drawLineOneDirection(
                  canvas: canvas,
                  paint: paint,
                  first: firstNode,
                  second: firstNode,
                  levelTwoStartPosition: startPosition,
                  levelTwoEndPosition: endPosition,
                  levelOnePosition: positionLevelOne);
              break;
            }

            startWithinBoundery = endWithinboundery;
          }

          startPosition = positionLevelTwo(startWithinBoundery);

          endWithinboundery = secondNode.start < startLevelTwo
              ? startLevelTwo
              : (secondNode.start > endLevelTwo
                  ? endLevelTwo
                  : secondNode.start);

          if (secondNode.start > endLevelTwo) {
            endPosition = infoLevelTwo.last.endPosition;
            drawLineOneDirection(
                canvas: canvas,
                paint: paint,
                first: firstNode,
                second: secondNode,
                levelTwoStartPosition: startPosition,
                levelTwoEndPosition: endPosition,
                levelOnePosition: positionLevelOne);
            break;
          } else {
            endWithinboundery = secondNode.start < startLevelTwo
                ? startLevelTwo
                : secondNode.start;
            endPosition = positionLevelTwo(endWithinboundery);
            assert(startWithinBoundery <= endWithinboundery);
            drawLineOneDirection(
                canvas: canvas,
                paint: paint,
                first: firstNode,
                second: secondNode,
                levelTwoStartPosition: startPosition,
                levelTwoEndPosition: endPosition,
                levelOnePosition: positionLevelOne);
          }

          firstNode = secondNode;
          secondNode = secondNode.next;
        }

        if (secondNode == null && firstNode.start <= endLevelTwo) {
          startWithinBoundery =
              firstNode.start < startLevelTwo ? startLevelTwo : firstNode.start;
          endWithinboundery =
              firstNode.end > endLevelTwo ? endLevelTwo : firstNode.end;

          if (!crossNode(firstNode) &&
              startWithinBoundery < endWithinboundery) {
            for (int j = startWithinBoundery; j < endWithinboundery; j++) {
              startPosition = infoLevelTwo[j - startLevelTwo].position;
              endPosition = positionLevelTwo(j + 1);
              drawLineOneDirection(
                  canvas: canvas,
                  paint: paint,
                  first: firstNode,
                  second: firstNode,
                  levelTwoStartPosition: startPosition,
                  levelTwoEndPosition: endPosition,
                  levelOnePosition: positionLevelOne);
            }
            startPosition = endPosition;
            endPosition = infoLevelTwo.last.endPosition;
            drawLineOneDirection(
                canvas: canvas,
                paint: paint,
                first: firstNode,
                levelTwoStartPosition: startPosition,
                levelTwoEndPosition: endPosition,
                levelOnePosition: positionLevelOne);
          } else if (startWithinBoundery < endLevelTwo) {
            startPosition =
                infoLevelTwo[startWithinBoundery - startLevelTwo].position;
            endPosition = infoLevelTwo.last.endPosition;
            drawLineOneDirection(
                canvas: canvas,
                paint: paint,
                first: firstNode,
                levelTwoStartPosition: startPosition,
                levelTwoEndPosition: endPosition,
                levelOnePosition: positionLevelOne);
          }
        }
      }

      node = node.next;
    }
  }

  drawHorizontalLine(
      {required Canvas canvas,
      Offset? offset,
      required Paint paint,
      LineNode? first,
      LineNode? second,
      required double levelOnePosition,
      double levelTwoStartPosition = 0.0,
      double levelTwoEndPosition = double.maxFinite}) {
    levelTwoStartPosition = (levelTwoStartPosition - xScroll) * scaleAndZoom;

    // if(levelTwoStartPosition < 0.0){
    //   levelTwoStartPosition = 0.0;
    // }

    levelTwoEndPosition = (levelTwoEndPosition - xScroll) * scaleAndZoom;

    // if(levelTwoEndPosition > size.width){
    //   levelTwoEndPosition = size.width;
    // }

    levelOnePosition = (levelOnePosition - yScroll) * scaleAndZoom;

    if (first != null) {
      if (first.right.line == TableLineOptions.NO) {
        return;
      }
      // assert(first.right.color != null,
      //     'No right color startIndex ${first.startIndex.index} endIndex ${first.endIndex.index}');
      // assert(first.right.width != null,
      //     'No right width startIndex ${first.startIndex.index} endIndex ${first.endIndex.index}');

      paint.color = first.right.color;
      paint.strokeWidth = first.right.widthScaled(scaleAndZoom);
    } else if (second != null) {
      if (second.left.line == TableLineOptions.NO) {
        return;
      }
      // assert(second.left.color != null,
      //     'No left color startIndex ${first.startIndex.index} endIndex ${first.endIndex.index}');
      // assert(second.left.width != null,
      //     'No left width startIndex ${first.startIndex.index} endIndex ${first.endIndex.index}');

      paint.color = second.left.color;
      paint.strokeWidth = second.left.widthScaled(scaleAndZoom);
    }
    //paint.color = Color(0xFFFF9000);

    if (!(first == null || first.right.drawLine) ||
        !(second == null || second.left.drawLine)) {
      return;
    } else if ((first == null || first.right.line == TableLineOptions.GRID) &&
        (second == null || second.left.line == TableLineOptions.GRID)) {
      canvas.drawLine(Offset(levelTwoStartPosition, levelOnePosition),
          Offset(levelTwoEndPosition, levelOnePosition), paint);
    } else {
      canvas.drawLine(Offset(levelTwoStartPosition, levelOnePosition),
          Offset(levelTwoEndPosition, levelOnePosition), paint);
    }
  }

  drawVerticalLine(
      {required Canvas canvas,
      Offset? offset,
      required Paint paint,
      LineNode? first,
      LineNode? second,
      required double levelOnePosition,
      double levelTwoStartPosition = 0.0,
      double levelTwoEndPosition = double.maxFinite}) {
    levelTwoStartPosition = (levelTwoStartPosition - yScroll) * scaleAndZoom;

    if (first != null) {
      if (first.bottom.line == TableLineOptions.NO) {
        return;
      }
      // assert(first.bottom.color != null,
      //     'No bottom color startIndex ${first.startIndex.index} endIndex ${first.endIndex.index}');
      // assert(first.bottom.width != null,
      //     'No bottom width startIndex ${first.startIndex.index} endIndex ${first.endIndex.index}');

      paint.color = first.bottom.color;
      paint.strokeWidth = first.bottom.widthScaled(scaleAndZoom);
    } else if (second != null) {
      if (second.top.line == TableLineOptions.NO) {
        return;
      }
      // assert(second.top.color != null,
      //     'No top color startIndex ${second.startIndex.index} endIndex ${second.endIndex.index}');
      // assert(second.top.width != null,
      //     'No top width startIndex ${second.startIndex.index} endIndex ${second.endIndex.index}');

      paint.color = second.top.color;
      paint.strokeWidth = second.top.widthScaled(scaleAndZoom);
    }

    if (levelTwoStartPosition < 0.0) {
      levelTwoStartPosition = 0.0;
    }

    levelTwoEndPosition = (levelTwoEndPosition - yScroll) * scaleAndZoom;

    if (levelTwoEndPosition > size.height) {
      levelTwoEndPosition = size.height;
    }

    levelOnePosition = (levelOnePosition - xScroll) * scaleAndZoom;

    //print('levelTwoStartPosition $levelTwoStartPosition levelTwoEndPosition $levelTwoEndPosition levelOnePosition $levelOnePosition');
    // canvas.drawLine(Offset(levelOnePosition, levelTwoStartPosition), Offset(levelOnePosition, levelTwoEndPosition), paint);

    if (!(first == null || first.bottom.drawLine) ||
        !(second == null || second.top.drawLine)) {
      return;
    } else if ((first == null || first.bottom.line == TableLineOptions.GRID) &&
        (second == null || second.top.line == TableLineOptions.GRID)) {
      //canvas.drawLine(Offset(x1 - xScroll, y - yScroll), Offset(x2 - xScroll,y - yScroll), paint);
    } else {
      canvas.drawLine(Offset(levelOnePosition, levelTwoStartPosition),
          Offset(levelOnePosition, levelTwoEndPosition), paint);
    }
  }
}

typedef CrossNode = bool Function(LineNode lineNode);
typedef DrawLineOneDirection = Function(
    {required Canvas canvas,
    Offset offset,
    required Paint paint,
    LineNode? first,
    LineNode? second,
    required double levelOnePosition,
    double levelTwoStartPosition,
    double levelTwoEndPosition});

class TableCellParentData extends ContainerBoxParentData<RenderBox> {
  TableCellIndex tableCellIndex = TableCellIndex();
}

class TableCellIndex extends Comparable<TableCellIndex> {
  int column;
  int row;
  int columns;
  int rows;
  int panelIndexX;
  int panelIndexY;

  TableCellIndex({
    this.panelIndexX: -1,
    this.panelIndexY: -1,
    this.column = -1,
    this.row = -1,
    this.columns = 1,
    this.rows = 1,
  });

  bool operator >(TableCellIndex index) {
    return row > index.row || (row == index.row && column > index.column);
  }

  bool operator <(TableCellIndex index) {
    return row < index.row || (row == index.row && column < index.column);
  }

  bool operator <=(TableCellIndex index) {
    // Geen row <= index.row maar row < index.row
    return row < index.row || (row == index.row && column <= index.column);
  }

  bool operator >=(TableCellIndex index) {
    //Geen >= voor row
    return row > index.row || (row == index.row && column >= index.column);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableCellIndex &&
          runtimeType == other.runtimeType &&
          column == other.column &&
          row == other.row;

  @override
  int get hashCode => column.hashCode ^ row.hashCode;

  @override
  String toString() {
    return 'TableCellIndex{column: $column, row: $row}';
  }

  @override
  int compareTo(TableCellIndex other) {
    return (row < other.row || (row == other.row && column < other.column))
        ? -1
        : ((row == other.row && column == other.column) ? 0 : 1);
  }

  TableCellIndex copyWith({
    int? panelIndexX,
    int? panelIndexY,
    int? column,
    int? row,
    int? columns,
    int? rows,
  }) {
    return TableCellIndex(
      panelIndexX: panelIndexX ?? this.panelIndexX,
      panelIndexY: panelIndexY ?? this.panelIndexY,
      column: column ?? this.column,
      row: row ?? this.row,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
    );
  }
}
