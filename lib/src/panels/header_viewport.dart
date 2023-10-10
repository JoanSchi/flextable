// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';
import '../model/model.dart';
import '../model/view_model.dart';
import 'package:flextable/src/panels/table_multi_panel_viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../model/properties/flextable_grid_info.dart';
import '../builders/abstract_table_builder.dart';

typedef HeaderIndexBuilder<T extends AbstractFtModel> = Widget Function(
    BuildContext context,
    T model,
    TableHeaderIndex tableHeaderIndex,
    double scale);

class TableHeader extends StatelessWidget {
  const TableHeader(
      {super.key,
      required this.viewModel,
      required this.panelIndex,
      required this.tableBuilder,
      required this.tableScale,
      required this.headerScale});

  final FtViewModel viewModel;
  final int panelIndex;
  final AbstractTableBuilder tableBuilder;
  final double tableScale;
  final double headerScale;

  @override
  Widget build(BuildContext context) {
    return TableHeaderViewport(
      viewModel: viewModel,
      panelIndex: panelIndex,
      tableScale: tableScale,
      headerScale: headerScale,
      headerIndexBuilder: tableBuilder.buildHeaderIndex,
      divider: tableBuilder.lineHeader(viewModel, panelIndex),
    );
  }
}

class TableHeaderViewport extends RenderObjectWidget {
  const TableHeaderViewport(
      {super.key,
      required this.viewModel,
      required this.panelIndex,
      required this.headerIndexBuilder,
      required this.tableScale,
      required this.headerScale,
      required this.divider});

  final FtViewModel viewModel;
  final int panelIndex;
  final HeaderIndexBuilder headerIndexBuilder;
  final double tableScale;
  final double headerScale;
  final LineHeader divider;

  @override
  TableHeaderChildRenderObjectElement createElement() =>
      TableHeaderChildRenderObjectElement(this);

  @override
  void updateRenderObject(
      BuildContext context, TableHeaderRenderViewport renderObject) {
    renderObject
      ..viewModel = viewModel
      ..tableScale = tableScale
      ..headerScale = headerScale
      ..divider = divider;
  }

  @override
  RenderObject createRenderObject(BuildContext context) {
    final TableHeaderRenderChildManager element =
        context as TableHeaderRenderChildManager;

    return TableHeaderRenderViewport(
        childManager: element,
        viewModel: viewModel,
        panelIndex: panelIndex,
        tableScale: tableScale,
        headerScale: headerScale,
        divider: divider);
  }
}

class TableHeaderChildRenderObjectElement extends RenderObjectElement
    implements TableHeaderRenderChildManager {
  TableHeaderChildRenderObjectElement(TableHeaderViewport widget)
      : super(widget);

  final Map<TableHeaderIndex, Widget?> _childWidgets =
      HashMap<TableHeaderIndex, Widget?>();
  final SplayTreeMap<TableHeaderIndex, Element?> _childElements =
      SplayTreeMap<TableHeaderIndex, Element?>();
  RenderBox? _currentBeforeChild;
  TableHeaderIndex? _currentlyUpdatingTableHeaderIndex;

  @override
  TableHeaderViewport get widget => super.widget as TableHeaderViewport;

  @override
  TableHeaderRenderViewport get renderObject =>
      super.renderObject as TableHeaderRenderViewport;

  @protected
  @visibleForTesting
  Iterable<Element> get children =>
      _children.where((Element child) => !_forgottenChildren.contains(child));

  final List<Element> _children = [];
  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  void performRebuild() {
    _childWidgets.clear(); // Reset the cache, as described above.
    super.performRebuild();

    _currentBeforeChild = null;
    assert(_currentlyUpdatingTableHeaderIndex == null);
    try {
      final SplayTreeMap<TableHeaderIndex, Element?> newChildren =
          SplayTreeMap<TableHeaderIndex, Element?>();

      void processElement(TableHeaderIndex index) {
        _currentlyUpdatingTableHeaderIndex = index;
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

      for (TableHeaderIndex index in _childElements.keys.toList()) {
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
      _currentlyUpdatingTableHeaderIndex = null;
      renderObject.debugChildIntegrityEnabled = true;
    }
  }

  @override
  void update(covariant TableHeaderViewport newWidget) {
    final TableHeaderViewport oldWidget = widget;
    super.update(newWidget);
    final FtViewModel newDelegate = newWidget.viewModel;
    final FtViewModel oldDelegate = oldWidget.viewModel;
    if ((newDelegate != oldDelegate &&
            (newDelegate.runtimeType != oldDelegate.runtimeType ||
                newDelegate.shouldRebuild(oldDelegate))) ||
        oldWidget.tableScale != newWidget.tableScale ||
        oldWidget.headerScale != newWidget.headerScale) performRebuild();
  }

  @override
  void createChild(TableHeaderIndex tableHeaderIndex, {RenderBox? after}) {
    assert(_currentlyUpdatingTableHeaderIndex == null);
    owner!.buildScope(this, () {
      final bool insertFirst = after == null;

      if (insertFirst) {
        _currentBeforeChild = null;
      } else {
        final lastKeyBefore = _childElements.lastKeyBefore(tableHeaderIndex);
        assert(lastKeyBefore != null);
        final element = _childElements[lastKeyBefore];
        assert(element != null);
        _currentBeforeChild = element!.renderObject as RenderBox?;
      }

      Element? newChild;
      try {
        _currentlyUpdatingTableHeaderIndex = tableHeaderIndex;
        newChild = updateChild(_childElements[tableHeaderIndex],
            _build(tableHeaderIndex), tableHeaderIndex);
      } finally {
        _currentlyUpdatingTableHeaderIndex = null;
      }
      if (newChild != null) {
        _childElements[tableHeaderIndex] = newChild;
      } else {
        _childElements.remove(tableHeaderIndex);
      }
    });
  }

  @override
  bool containsElement(TableHeaderIndex key) {
    return _childElements.containsKey(key);
  }

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingTableHeaderIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingTableHeaderIndex != null);
    final TableHeaderParentData childParentData =
        child.parentData! as TableHeaderParentData;
    childParentData.tableHeaderIndex = _currentlyUpdatingTableHeaderIndex!;
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
  void insertRenderObjectChild(RenderObject child, TableHeaderIndex slot) {
    // assert(slot != null);
    assert(_currentlyUpdatingTableHeaderIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child as RenderBox, after: _currentBeforeChild);
    assert(() {
      final TableHeaderParentData childParentData =
          child.parentData as TableHeaderParentData;
      //print('slot $slot tableCellIndex ${childParentData.tableCellIndex}');
      assert(slot == childParentData.tableHeaderIndex);
      return true;
    }());
  }

  @override
  void moveRenderObjectChild(
      RenderObject child, TableHeaderIndex oldSlot, TableHeaderIndex newSlot) {
    assert(slot != null);
    assert(_currentlyUpdatingTableHeaderIndex == newSlot);
    renderObject.move(child as RenderBox, after: _currentBeforeChild);
  }

  @override
  void removeChild(RenderBox child) {
    final TableHeaderIndex index = renderObject.indexOf(child);
    assert(_currentlyUpdatingTableHeaderIndex == null);

    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index));
      try {
        _currentlyUpdatingTableHeaderIndex = index;
        final Element? result = updateChild(_childElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingTableHeaderIndex = null;
      }
      _childElements.remove(index);
      assert(!_childElements.containsKey(index));
    });
  }

  @override
  void removeRenderObjectChild(RenderObject child, TableHeaderIndex slot) {
    assert(_currentlyUpdatingTableHeaderIndex != null);
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
    final TableHeaderParentData? oldParentData =
        child?.renderObject?.parentData as TableHeaderParentData?;
    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final TableHeaderParentData? newParentData =
        newChild?.renderObject?.parentData as TableHeaderParentData?;
    // Preserve the old layoutOffset if the renderObject was swapped out.

    if (oldParentData != newParentData &&
        oldParentData != null &&
        newParentData != null) {
      assert(oldParentData.tableHeaderIndex == newParentData.tableHeaderIndex,
          'TableHeaderIndex not equal, old: ${oldParentData.tableHeaderIndex}, new: ${newParentData.tableHeaderIndex}');
      newParentData.offset = oldParentData.offset;
    }
    return newChild;
  }

  @override
  void setDidUnderflow(bool value) {}

  Widget? _build(TableHeaderIndex tableHeaderIndex) {
    return _childWidgets.putIfAbsent(tableHeaderIndex, () {
      return widget.headerIndexBuilder(
        this,
        widget.viewModel.model,
        tableHeaderIndex,
        widget.viewModel.scaleHeader(tableHeaderIndex),
      );
    });
  }
}

abstract class TableHeaderRenderChildManager {
  void createChild(TableHeaderIndex tableCellIndex, {RenderBox? after});

  void removeChild(RenderBox child);

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  void didStartLayout();

  void didFinishLayout();

  bool debugAssertChildListLocked() => true;

  //Added by Joan
  bool containsElement(TableHeaderIndex tableCellIndex);
}

class TableHeaderRenderViewport extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableHeaderParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableHeaderParentData> {
  TableHeaderRenderViewport({
    required FtViewModel viewModel,
    required this.childManager,
    required this.panelIndex,
    required double tableScale,
    required double headerScale,
    required this.divider,
  })  : _viewModel = viewModel,
        _tableScale = tableScale,
        _headerScale = headerScale {
    iterator =
        TableHeaderIterator(viewModel: viewModel, panelIndex: panelIndex);
  }

  // TableScrollPosition _offset;
  // ScrollPosition? _sliverPosition;
  TableHeaderRenderChildManager childManager;
  int panelIndex;
  late LayoutPanelIndex tpli;
  late TableHeaderIterator iterator;
  late double xScroll, yScroll;
  double _tableScale;
  double _headerScale;
  // late double panelWidth, panelHeight;
  // late double leftMargin, topMargin, rightMargin, bottomMargin;
  FtViewModel _viewModel;
  int garbageCollectFrom = -1;
  LineHeader divider;

  FtViewModel get viewModel => _viewModel;

  set viewModel(FtViewModel value) {
    if (value == _viewModel) return;
    if (attached) _viewModel.removeListener(markNeedsLayout);
    _viewModel = value;
    if (attached) _viewModel.addListener(markNeedsLayout);

    iterator.viewModel = value;

    garbageCollectFrom = 0;

    markNeedsLayout();
  }

  double get tableScale => _tableScale;

  set tableScale(double value) {
    if (value == _tableScale) return;

    _tableScale = value;
    markNeedsLayout();
  }

  double get headerScale => _headerScale;

  set headerScale(double value) {
    if (value == _headerScale) return;

    _headerScale = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TableHeaderParentData) {
      child.parentData = TableHeaderParentData();
    }
  }

  TableHeaderIndex cellIndexOf(RenderBox child) {
    // assert(child != null);
    final TableHeaderParentData childParentData =
        child.parentData as TableHeaderParentData;
    // assert(childParentData?.tableHeaderIndex != null);
    return childParentData.tableHeaderIndex;
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

    final tableScale = viewModel.tableScale;

    tpli = _viewModel.layoutPanelIndex(panelIndex);
    xScroll = viewModel.getScrollX(tpli.scrollIndexX, tpli.scrollIndexY);
    yScroll = viewModel.getScrollY(tpli.scrollIndexX, tpli.scrollIndexY);

    final layoutX = viewModel.widthLayoutList[tpli.xIndex];
    final layoutY = viewModel.heightLayoutList[tpli.yIndex];

    iterator.reset(tpli);

    garbageCollect(
        removeAll: iterator.isEmpty,
        firstIndex: iterator.firstIndex,
        lastIndex: iterator.lastIndex);

    late TableHeaderIndex indexFirstChild;

    if (firstChild != null) {
      indexFirstChild =
          (firstChild!.parentData as TableHeaderParentData).tableHeaderIndex;
      child = firstChild!;
    }

    while (iterator.next) {
      GridInfo gridInfo = iterator.gridInfo;
      final tableHeaderIndex = iterator.tableHeaderIndex;

      if (firstChild == null) {
        child = insertAndLayoutFirstChild(after: null, index: tableHeaderIndex);
        indexFirstChild = tableHeaderIndex;

        assert(tableHeaderIndex ==
            (firstChild!.parentData as TableHeaderParentData).tableHeaderIndex);
      } else {
        assert(child != null,
            'child can not be null in next $tableHeaderIndex ${firstChild == null}');

        TableHeaderParentData parentData =
            child!.parentData as TableHeaderParentData;

        if (parentData.tableHeaderIndex < tableHeaderIndex) {
          child = findOrInsert(child: child, index: tableHeaderIndex);
        } else if (tableHeaderIndex < indexFirstChild) {
          child =
              insertAndLayoutFirstChild(after: null, index: tableHeaderIndex);
          indexFirstChild = tableHeaderIndex;

          assert(tableHeaderIndex ==
              (firstChild!.parentData as TableHeaderParentData)
                  .tableHeaderIndex);
        } else {
          assert(indexFirstChild == tableHeaderIndex,
              'Only first child is equal to tableHeaderIndex');
        }
      }

      if (panelIndex <= 3 || panelIndex >= 12) {
        layoutChild(
            child: child,
            left: layoutX.layoutPosition,
            width: layoutX.layoutLength,
            top: layoutY.marginBegin +
                (gridInfo.position - yScroll) * tableScale,
            height: gridInfo.length * tableScale);
      } else {
        layoutChild(
            child: child,
            left: layoutX.marginBegin +
                (gridInfo.position - xScroll) * tableScale,
            width: gridInfo.length * tableScale,
            top: layoutY.layoutPosition,
            height: layoutY.layoutLength);
      }
    }

    child = firstChild;

    childManager.didFinishLayout();
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    bool isHit = super.hitTest(result, position: position);
    return isHit;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  void layoutChild({
    required RenderBox child,
    required double left,
    required double top,
    required double width,
    required double height,
    bool parentUsesSize = true,
  }) {
    BoxConstraints constraints =
        BoxConstraints.tightFor(width: width, height: height);
    child.layout(constraints, parentUsesSize: parentUsesSize);

    final TableHeaderParentData parentData =
        child.parentData as TableHeaderParentData;

    parentData.offset = Offset(left, top);
  }

  RenderBox findOrInsert(
      {required RenderBox child, required TableHeaderIndex index}) {
    assert(child.parent == this);

    TableHeaderParentData parentData =
        child.parentData as TableHeaderParentData;
    RenderBox? nextChild = parentData.nextSibling;

    if (nextChild != null &&
        (nextChild.parentData as TableHeaderParentData).tableHeaderIndex <=
            index) {
      child = nextChild;
    }

    if ((child.parentData as TableHeaderParentData).tableHeaderIndex != index) {
      child = insertAndLayoutChild(after: child, index: index)!;
    }

    assert(
        index == (child.parentData as TableHeaderParentData).tableHeaderIndex);

    return child;
  }

  RenderBox? find(TableHeaderIndex index) {
    RenderBox? child = firstChild;

    while (child != null) {
      TableHeaderParentData parentData =
          child.parentData as TableHeaderParentData;
      if (parentData.tableHeaderIndex == index) {
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
    required TableHeaderIndex index,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, after: after);

    assert(firstChild != null);
    TableHeaderParentData parentData =
        firstChild!.parentData as TableHeaderParentData;
    assert(index == parentData.tableHeaderIndex);

    return firstChild!;
  }

  @protected
  RenderBox? insertAndLayoutChild({
    required RenderBox after,
    required TableHeaderIndex index,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());
    // assert(after != null);

    _createOrObtainChild(index, after: after);
    final RenderBox? child = childAfter(after);

    if (child != null && cellIndexOf(child) == index) {
      return child;
    }

    assert(child == null || cellIndexOf(child) == index,
        'insertAndLayoutChild child after has index: ${cellIndexOf(child)} should be  $index');

    return null;
  }

  garbageCollect(
      {bool removeAll = false, int firstIndex = 0, int lastIndex = 0}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      RenderBox? child = firstChild;

      while (child != null) {
        TableHeaderParentData parentData =
            child.parentData as TableHeaderParentData;
        TableHeaderIndex tableHeaderIndex = parentData.tableHeaderIndex;

        final childToRemove = child;

        child = parentData.nextSibling;

        if (removeAll ||
            (garbageCollectFrom != -1 &&
                garbageCollectFrom <= tableHeaderIndex.index) ||
            firstIndex > tableHeaderIndex.index ||
            lastIndex < tableHeaderIndex.index) {
          assert(childManager.containsElement(tableHeaderIndex),
              'Element does not exist in header: panelIndex: $panelIndex, index: $tableHeaderIndex');

          childManager.removeChild(childToRemove);
        }
      }
    });

    garbageCollectFrom = -1;
  }

  void _createOrObtainChild(TableHeaderIndex index, {RenderBox? after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  TableHeaderIndex indexOf(RenderBox child) {
    return (child.parentData as TableHeaderParentData).tableHeaderIndex;
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
      TableHeaderIndex index;
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
    _viewModel.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    // _offset.removeListener(markNeedsLayout);
    // _sliverPosition?.removeListener(markNeedsLayout);
    _viewModel.removeListener(markNeedsLayout);
    super.detach();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    context.pushClipRect(needsCompositing, offset,
        Rect.fromLTWH(0.0, 0.0, size.width, size.height), (context, offset) {
      // offset = offset.translate(leftMargin, topMargin);
      defaultPaint(context, offset);
      paintLines(context, offset);
    });
  }

  paintLines(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final paint = Paint();
    final tableScale = viewModel.tableScale;
    paint.color = divider.color;
    paint.strokeWidth = divider.width;

    canvas.save();
    late int debugPreviousCanvasSaveCount;

    if (offset != Offset.zero) canvas.translate(offset.dx, offset.dy);

    if (tpli.isRowHeader) {
      const x1 = 0.0;
      final x2 = size.width;
      final marginBegin = viewModel.heightLayoutList[tpli.yIndex].marginBegin;

      iterator.reset(tpli);
      while (iterator.next) {
        final y =
            marginBegin + (iterator.gridInfo.position - yScroll) * tableScale;

        canvas.drawLine(Offset(x1, y), Offset(x2, y), paint);
      }
    } else if (tpli.isColumnHeader) {
      const y1 = 0.0;
      final y2 = size.height;
      final marginBegin = viewModel.widthLayoutList[tpli.xIndex].marginBegin;

      iterator.reset(tpli);

      while (iterator.next) {
        final x =
            marginBegin + (iterator.gridInfo.position - xScroll) * tableScale;
        canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
      }
    }

    assert(() {
      debugPreviousCanvasSaveCount = canvas.getSaveCount();
      return true;
    }());

    assert(() {
      final int debugNewCanvasSaveCount = canvas.getSaveCount();
      return debugNewCanvasSaveCount == debugPreviousCanvasSaveCount;
    }(), 'Previous canvas count is different from the current canvas count!');

    canvas.restore();
  }
}

class TableHeaderParentData extends ContainerBoxParentData<RenderBox> {
  TableHeaderIndex tableHeaderIndex = TableHeaderIndex();
}

class TableHeaderIndex implements Comparable<TableHeaderIndex> {
  TableHeaderIndex({
    this.panelIndex = -1,
    this.index = -1,
  });

  int index;
  int panelIndex;

  bool operator >(TableHeaderIndex headerIndex) {
    return index > headerIndex.index;
  }

  bool operator <(TableHeaderIndex headerIndex) {
    return index < headerIndex.index;
  }

  bool operator <=(TableHeaderIndex headerIndex) {
    return index <= headerIndex.index;
  }

  bool operator >=(TableHeaderIndex headerIndex) {
    return index >= headerIndex.index;
  }

  @override
  String toString() {
    return 'TableHeaderIndex{Index: $index}';
  }

  @override
  int compareTo(TableHeaderIndex other) {
    return index < other.index ? -1 : (index == other.index ? 0 : 1);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TableHeaderIndex &&
        other.index == index &&
        other.panelIndex == panelIndex;
  }

  @override
  int get hashCode => index.hashCode ^ panelIndex.hashCode;
}

class TableHeaderIterator {
  TableHeaderIterator(
      {required FtViewModel viewModel, required this.panelIndex})
      : _viewModel = viewModel;

  FtViewModel _viewModel;
  late List<GridInfo> headerInfoList;
  int panelIndex;
  int index = 0;
  int count = 0;
  int length = 0;
  int firstIndex = 0;
  int lastIndex = 0;

  set viewModel(value) {
    if (_viewModel != value) {
      _viewModel = value;
    }
  }

  reset(LayoutPanelIndex tpli) {
    count = 0;

    if (tpli.isRowHeader) {
      headerInfoList =
          _viewModel.getRowInfoList(tpli.scrollIndexX, tpli.scrollIndexY);
    } else {
      headerInfoList =
          _viewModel.getColumnInfoList(tpli.scrollIndexX, tpli.scrollIndexY);
    }

    length = headerInfoList.length;

    if (tpli.xIndex == 0 || tpli.xIndex == 3) {
      headerInfoList =
          _viewModel.getRowInfoList(tpli.scrollIndexX, tpli.scrollIndexY);
    } else {
      headerInfoList =
          _viewModel.getColumnInfoList(tpli.scrollIndexX, tpli.scrollIndexY);
    }

    if (length > 0) {
      firstIndex = headerInfoList.first.index;
      lastIndex = headerInfoList.last.index;
    }
  }

  bool get next {
    index = count;
    return count++ < length;
  }

  GridInfo get gridInfo => headerInfoList[index];

  TableHeaderIndex get tableHeaderIndex =>
      TableHeaderIndex(panelIndex: panelIndex, index: gridInfo.index);

  bool get isEmpty => length == 0;
}
