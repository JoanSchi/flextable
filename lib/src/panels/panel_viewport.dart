// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../builders/abstract_table_builder.dart';
import '../builders/cells.dart';
import '../model/model.dart';
import '../model/view_model.dart';
import '../panels/table_multi_panel_viewport.dart';
import 'table_layout_iterations.dart';

typedef CellBuilder<T extends AbstractFtModel<C>, C extends AbstractCell>
    = Widget? Function(
  BuildContext context,
  T model,
  CellIndex tableCellIndex,
);

class TablePanel<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends StatelessWidget {
  final FtViewModel<T, C> viewModel;
  final int panelIndex;
  final AbstractTableBuilder<T, C> tableBuilder;
  final double tableScale;

  const TablePanel(
      {super.key,
      required this.viewModel,
      required this.panelIndex,
      required this.tableBuilder,
      required this.tableScale});

  @override
  Widget build(BuildContext context) {
    // return tableBuilder.testCellBuilder(context);

    return TablePanelViewport<T, C>(
      viewModel: viewModel,
      panelIndex: panelIndex,
      tableBuilder: tableBuilder,
      tableScale: tableScale,
    );
  }
}

class TablePanelViewport<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends RenderObjectWidget {
  const TablePanelViewport(
      {super.key,
      required this.viewModel,
      required this.panelIndex,
      required this.tableBuilder,
      required this.tableScale,
      this.editCell});

  final FtViewModel<T, C> viewModel;
  final int panelIndex;
  final AbstractTableBuilder<T, C> tableBuilder;
  final double tableScale;
  final CellIndex? editCell;

  @override
  TablePanelChildRenderObjectElement<T, C> createElement() =>
      TablePanelChildRenderObjectElement(this);

  @override
  void updateRenderObject(
      BuildContext context, TablePanelRenderViewport renderObject) {
    renderObject
      ..viewModel = viewModel
      ..tableScale = tableScale
      ..panelIndex = panelIndex;
  }

  @override
  TablePanelRenderViewport<T, C> createRenderObject(BuildContext context) {
    final TablePanelRenderChildManager element =
        context as TablePanelRenderChildManager;

    return TablePanelRenderViewport(
        childManager: element,
        viewModel: viewModel,
        panelIndex: panelIndex,
        tableScale: tableScale,
        tableBuilder: tableBuilder,
        editCell: editCell);
  }

  LayoutPanelIndex get layoutPanelIndex =>
      viewModel.layoutPanelIndex(panelIndex);
}

class TablePanelChildRenderObjectElement<T extends AbstractFtModel<C>,
        C extends AbstractCell> extends RenderObjectElement
    implements TablePanelRenderChildManager<C> {
  TablePanelChildRenderObjectElement(super.widget);

  final Map<CellIndex, Widget?> _childWidgets = HashMap<CellIndex, Widget?>();
  final SplayTreeMap<CellIndex, Element?> _childElements =
      SplayTreeMap<CellIndex, Element?>();
  final SplayTreeMap<CellIndex, Element?> _keptAliveElements =
      SplayTreeMap<CellIndex, Element?>();

  RenderBox? _currentBeforeChild;
  CellIndex? _currentlyUpdatingTableCellIndex;

  @override
  TablePanelViewport<T, C> get widget =>
      super.widget as TablePanelViewport<T, C>;

  @override
  TablePanelRenderViewport<T, C> get renderObject =>
      super.renderObject as TablePanelRenderViewport<T, C>;

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

    // for (var index in _childElements.keys) {
    //   final build = _buildFromIndex(index);

    //   if (build != null) {
    //     _currentlyUpdatingTableCellIndex = index;
    //     _childElements[index] =
    //         updateChild(_childElements[index], build, index);
    //     _currentlyUpdatingTableCellIndex = null;
    //   }
    // }

    _currentBeforeChild = null;
    assert(_currentlyUpdatingTableCellIndex == null);
    try {
      void processElementList(SplayTreeMap<CellIndex, Element?> childElements) {
        final SplayTreeMap<CellIndex, Element?> newChildren =
            SplayTreeMap<CellIndex, Element?>();

        for (CellIndex index in childElements.keys.toList()) {
          newChildren.putIfAbsent(index, () => childElements[index]);
        }

        void processElement(CellIndex index) {
          _currentlyUpdatingTableCellIndex = index;

          //this if will never happen, because the index is always equal!
          if (childElements[index] != null &&
              childElements[index] != newChildren[index]) {
            // This index has an old child that isn't used anywhere and should be deactivated.
            childElements[index] =
                updateChild(childElements[index], null, index);
          }
          final Element? newChild =
              updateChild(newChildren[index], _buildFromIndex(index), index);
          if (newChild != null) {
            childElements[index] = newChild;
            _currentBeforeChild = newChild.renderObject as RenderBox?;
          } else {
            childElements.remove(index);
          }
        }

        newChildren.keys.forEach(processElement);
      }

      processElementList(_childElements);
      processElementList(_keptAliveElements);

      renderObject.debugChildIntegrityEnabled =
          false; // Moving children will temporary violate the integrity.

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

  Widget? _buildFromIndex(CellIndex index) {
    C? cell = widget.viewModel.model.cell(row: index.row, column: index.column);

    return cell != null ? _build(cell, widget.layoutPanelIndex, index) : null;
  }

  @override
  void update(TablePanelViewport<T, C> newWidget) {
    final TablePanelViewport<T, C> oldWidget = widget;
    super.update(newWidget);
    final FtViewModel<T, C> newDelegate = newWidget.viewModel;
    final FtViewModel<T, C> oldDelegate = oldWidget.viewModel;
    if ((newDelegate != oldDelegate &&
            (newDelegate.runtimeType != oldDelegate.runtimeType ||
                newDelegate.shouldRebuild(oldDelegate))) ||
        oldWidget.tableScale != newWidget.tableScale) performRebuild();
  }

  @override
  void createChild(CellIndex tableCellIndex, C cell, {RenderBox? after}) {
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
        newChild = updateChild(
            _childElements[tableCellIndex],
            _build(cell, widget.layoutPanelIndex, tableCellIndex),
            tableCellIndex);
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
  bool containsElement(CellIndex key) {
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
  void insertRenderObjectChild(RenderObject child, CellIndex slot) {
    // assert(slot != null);
    assert(_currentlyUpdatingTableCellIndex == slot,
        'Slot/current not equal: $slot, current $_currentlyUpdatingTableCellIndex ');
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
    final CellIndex index = renderObject.indexOf(child);
    assert(_currentlyUpdatingTableCellIndex == null);

    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index) ||
          _keptAliveElements.containsKey(index));
      try {
        _currentlyUpdatingTableCellIndex = index;
        final Element? result = updateChild(
            _childElements[index] ?? _keptAliveElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingTableCellIndex = null;
      }
      if (_childElements.remove(index) == null) {
        _keptAliveElements.remove(index);
      }

      assert(!_childElements.containsKey(index) ||
          !_keptAliveElements.containsKey(index));
    });
    assert(_keptAliveElements.length < 2,
        '_keptAliveElements alive elements is ${_keptAliveElements.length}');

    debugPrint('keptAliveElements length ${_keptAliveElements.length}');
  }

  @override
  void removeRenderObjectChild(RenderObject child, dynamic slot) {
    //assert(_currentlyUpdatingTableCellIndex != null);
    renderObject.remove(child as RenderBox);
  }

  @override
  void visitChildren(ElementVisitor visitor) {
    // The toList() is to make a copy so that the underlying list can be modified by
    // the visitor:
    assert(!_childElements.values.any((Element? child) => child == null));
    _childElements.values.cast<Element>().toList().forEach(visitor);
    assert(!_keptAliveElements.values.any((Element? child) => child == null));
    _keptAliveElements.values.cast<Element>().toList().forEach(visitor);
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

  Widget? _build(
      C cell, LayoutPanelIndex layoutPanelIndex, CellIndex cellIndex) {
    // return _childWidgets.putIfAbsent(cellIndex, () {
    //   return widget.tableBuilder.cellBuilder(
    //     this,
    //     widget.viewModel,
    //     cell,
    //     layoutPanelIndex,
    //     cellIndex,
    //   );
    // });
    return widget.tableBuilder.cellBuilder(
      this,
      widget.viewModel,
      cell,
      layoutPanelIndex,
      cellIndex,
    );
  }

  @override
  void cellIndexFromElementsToKeepAlive(CellIndex cellIndex) {
    assert(_childElements.containsKey(cellIndex),
        'CellIndex: $cellIndex not found in _childElements');

    if (_childElements.remove(cellIndex) case Element e) {
      _keptAliveElements[cellIndex] = e;
    }
  }

  @override
  void cellIndexFromKeepAliveToElements(CellIndex cellIndex) {
    assert(_keptAliveElements.containsKey(cellIndex),
        'CellIndex: $cellIndex not found in _keptAliveElements');

    if (_keptAliveElements.remove(cellIndex) case Element e) {
      _childElements[cellIndex] = e;
    }
  }

  @override
  void removeKeepAliveElement(CellIndex cellIndex) {
    assert(_keptAliveElements.containsKey(cellIndex),
        'CellIndex: $cellIndex not found in _keptAliveElements');

    _keptAliveElements.remove(cellIndex);
  }
}

abstract class TablePanelRenderChildManager<C extends AbstractCell> {
  void createChild(CellIndex tableCellIndex, C cell,
      {required RenderBox? after});

  void removeChild(RenderBox child);

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  void didStartLayout();

  void didFinishLayout();

  bool debugAssertChildListLocked() => true;

  //Added by Joan
  bool containsElement(CellIndex tableCellIndex);

  //Added by Joan
  void cellIndexFromElementsToKeepAlive(CellIndex cellIndex);

  //Added by Joan
  void cellIndexFromKeepAliveToElements(CellIndex cellIndex);

  //Added by Joan
  void removeKeepAliveElement(CellIndex cellIndex);
}

class TablePanelRenderViewport<T extends AbstractFtModel<C>,
        C extends AbstractCell> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableCellParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableCellParentData> {
  TablePanelRenderViewport({
    required FtViewModel<T, C> viewModel,
    ScrollPosition? sliverPosition,
    required this.childManager,
    required this.panelIndex,
    required double tableScale,
    required AbstractTableBuilder<T, C> tableBuilder,
    required CellIndex? editCell,
  })  : _viewModel = viewModel,
        _tableScale = tableScale,
        _tableBuilder = tableBuilder {
    iterator = TableInterator(viewModel: viewModel);
    assert(() {
      _debugDanglingKeepAlives = <RenderBox>[];
      return true;
    }());
  }
  late List<RenderBox> _debugDanglingKeepAlives;
  TablePanelRenderChildManager childManager;
  int panelIndex;
  late LayoutPanelIndex tpli;
  late TableInterator<T, C> iterator;
  late double xScroll, yScroll;
  double _tableScale;
  late double leftMargin, topMargin, rightMargin, bottomMargin;
  FtViewModel<T, C> _viewModel;
  int garbageCollectRowsFrom = -1;
  int garbageCollectColumnsFrom = -1;
  final Map<CellIndex, RenderBox> _keepAliveBucket = <CellIndex, RenderBox>{};

  FtViewModel<T, C> get viewModel => _viewModel;

  set viewModel(FtViewModel<T, C> value) {
    // assert(value != null);
    if (value == _viewModel) return;
    if (attached) _viewModel.removeListener(markNeedsLayout);
    _viewModel = value;
    if (attached) _viewModel.addListener(markNeedsLayout);

    iterator.viewModel = value;

    garbageCollectRowsFrom = 0;
    garbageCollectColumnsFrom = 0;

    markNeedsLayout();
  }

  double get tableScale => _tableScale;

  set tableScale(double value) {
    if (value == _tableScale) return;

    _tableScale = value;
    markNeedsLayout();
  }

  AbstractTableBuilder<T, C> _tableBuilder;

  AbstractTableBuilder<T, C> get tableBuilder => _tableBuilder;

  set tableBuilder(AbstractTableBuilder<T, C> value) {
    if (value == _tableBuilder) return;

    _tableBuilder = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TableCellParentData) {
      child.parentData = TableCellParentData();
    }
  }

  CellIndex cellIndexOf(RenderBox child) {
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
    tpli = viewModel.layoutPanelIndex(panelIndex);

    xScroll = viewModel.getScrollX(tpli.scrollIndexX, tpli.scrollIndexY);
    yScroll = viewModel.getScrollY(tpli.scrollIndexX, tpli.scrollIndexY);

    final layoutX = viewModel.widthLayoutList[tpli.xIndex];
    leftMargin = layoutX.marginBegin;
    rightMargin = layoutX.marginEnd;

    final layoutY = viewModel.heightLayoutList[tpli.yIndex];
    topMargin = layoutY.marginBegin;
    bottomMargin = layoutY.marginEnd;

    iterator.reset(tpli);

    garbageCollect(
        removeAll: iterator.isEmpty,
        firstRowIndex: iterator.firstRowIndex,
        firstColumnIndex: iterator.firstColumnIndex,
        lastRowIndex: iterator.lastRowIndex,
        lastColumnIndex: iterator.lastColumnIndex);

    child = firstChild;

    while (iterator.next) {
      C? cell = iterator.cell;
      final tableCellIndex = iterator.tableCellIndex;

      if (cell != null) {
        if (child == null) {
          assert(firstChild == null);
          child = insertAndLayoutFirstChild(
              after: null, index: tableCellIndex, cell: cell);

          assert(tableCellIndex ==
              (firstChild!.parentData as TableCellParentData).tableCellIndex);
        } else {
          TableCellParentData parentData =
              child.parentData as TableCellParentData;

          if (parentData.tableCellIndex < tableCellIndex) {
            child = findOrInsertForward(
                child: child, index: tableCellIndex, cell: cell);
          } else {
            assert(parentData.tableCellIndex >= tableCellIndex);
            child = findOrInsertBackward(
                child: child, index: tableCellIndex, cell: cell);
          }
        }
        layoutChild(
            child: child,
            left: iterator.left,
            top: iterator.top,
            width: iterator.width,
            height: iterator.height);
      } else {
        assert(find(tableCellIndex) == null,
            'Renderbox should be removed, but not yet implemented!');
      }
    }

    assert(
      () {
        RenderBox? testChild = firstChild;
        RenderBox? previous;

        while (testChild != null) {
          var parentData = testChild.parentData as TableCellParentData;
          if (previous != null) {
            if (parentData.tableCellIndex <=
                (previous.parentData as TableCellParentData).tableCellIndex) {
              debugPrint('The tableCellIndex is not right!');
              return false;
            }
          }
          previous = testChild;
          testChild = parentData.nextSibling;
        }

        if (previous != lastChild) {
          debugPrint('The last child in the link does not math lastChild');
          return false;
        }
        return true;
      }(),
    );

    childManager.didFinishLayout();
  }

  // @override
  // bool hitTest(BoxHitTestResult result, {required Offset position}) {
  //   bool isHit = super.hitTest(result, position: position);
  //   return isHit;
  // }

  @override
  bool hitTestSelf(Offset position) => false;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }

  void layoutChild({
    required RenderBox child,
    required double left,
    required double top,
    required double width,
    required double height,
    bool parentUsesSize = true,
  }) {
    BoxConstraints constraints = BoxConstraints.tightFor(
        width: width * tableScale, height: height * tableScale);

    child.layout(constraints, parentUsesSize: parentUsesSize);

    final TableCellParentData parentData =
        child.parentData as TableCellParentData;

    parentData.offset =
        Offset((left - xScroll) * tableScale, (top - yScroll) * tableScale);
    assert(!xScroll.isNaN, 'xScroll NaN');
    assert(!yScroll.isNaN, 'yScroll NaN');
    assert(!left.isNaN, 'Cell left NaN');
    assert(!top.isNaN, 'Cell top NaN');
    assert(!parentData.offset.dx.isNaN, 'Blb x NaN');
    assert(!parentData.offset.dy.isNaN, 'Blb2 y NaN');
  }

  RenderBox findOrInsertForward({
    required RenderBox child,
    required CellIndex index,
    required C cell,
  }) {
    // assert(child != null);
    assert(child.parent == this);
    TableCellParentData parentData = child.parentData as TableCellParentData;

    if (parentData.tableCellIndex == index) {
      return child;
    }

    RenderBox? shiftChild = parentData.nextSibling;

    while (shiftChild != null) {
      parentData = shiftChild.parentData as TableCellParentData;

      if (parentData.tableCellIndex < index) {
        child = shiftChild;
      } else if (parentData.tableCellIndex == index) {
        return shiftChild;
      } else {
        break;
      }

      shiftChild = parentData.nextSibling;
    }
    assert((child.parentData as TableCellParentData).tableCellIndex < index);

    child = insertAndLayoutChild(after: child, index: index, cell: cell);
    assert(index == (child.parentData as TableCellParentData).tableCellIndex);

    return child;
  }

  RenderBox findOrInsertBackward({
    required RenderBox child,
    required CellIndex index,
    required C cell,
  }) {
    // assert(child != null);
    assert(child.parent == this);

    TableCellParentData parentData = child.parentData as TableCellParentData;

    if (parentData.tableCellIndex == index) {
      return child;
    }

    RenderBox? shiftChild = child;

    while (shiftChild != null) {
      parentData = shiftChild.parentData as TableCellParentData;

      if (index == parentData.tableCellIndex) {
        return shiftChild;
      } else if (index > parentData.tableCellIndex) {
        break;
      }

      shiftChild = parentData.previousSibling;
    }

    assert(
        shiftChild == null ||
            index >
                (shiftChild.parentData as TableCellParentData).tableCellIndex,
        'Index: $index TableCellIndex ${(child.parentData as TableCellParentData).tableCellIndex}');

    if (shiftChild == null) {
      shiftChild = insertAndLayoutFirstChild(
        after: null,
        index: index,
        cell: cell,
      );
    } else {
      shiftChild =
          insertAndLayoutChild(after: shiftChild, index: index, cell: cell);
    }

    assert(
        index == (shiftChild.parentData as TableCellParentData).tableCellIndex);

    return shiftChild;
  }

  RenderBox? find(CellIndex index) {
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
  void move(RenderBox child, {RenderBox? after}) {
    assert(false, 'Move not implemented correctly');
    // There are two scenarios:
    //
    // 1. The child is not keptAlive.
    // The child is in the childList maintained by ContainerRenderObjectMixin.
    // We can call super.move and update parentData with the new slot.
    //
    // 2. The child is keptAlive.
    // In this case, the child is no longer in the childList but might be stored in
    // [_keepAliveBucket]. We need to update the location of the child in the bucket.
    final TableCellParentData childParentData =
        child.parentData! as TableCellParentData;
    if (!childParentData.keptAlive) {
      super.move(child, after: after);
      childManager.didAdoptChild(child); // updates the slot in the parentData
      // Its slot may change even if super.move does not change the position.
      // In this case, we still want to mark as needs layout.
      markNeedsLayout();
    } else {
      // If the child in the bucket is not current child, that means someone has
      // already moved and replaced current child, and we cannot remove this child.
      if (_keepAliveBucket[childParentData.tableCellIndex] == child) {
        _keepAliveBucket.remove(childParentData.tableCellIndex);
      }
      assert(() {
        _debugDanglingKeepAlives.remove(child);
        return true;
      }());
      // Update the slot and reinsert back to _keepAliveBucket in the new slot.
      childManager.didAdoptChild(child);
      // If there is an existing child in the new slot, that mean that child will
      // be moved to other index. In other cases, the existing child should have been
      // removed by updateChild. Thus, it is ok to overwrite it.
      assert(() {
        if (_keepAliveBucket.containsKey(childParentData.tableCellIndex)) {
          _debugDanglingKeepAlives
              .add(_keepAliveBucket[childParentData.tableCellIndex]!);
        }
        return true;
      }());
      _keepAliveBucket[childParentData.tableCellIndex] = child;
    }
  }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    final TableCellParentData childParentData =
        child.parentData as TableCellParentData;
    if (!childParentData.keptAlive) {
      childManager.didAdoptChild(child as RenderBox);
    }
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
    required CellIndex index,
    required C cell,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, cell, after: after);

    assert(firstChild != null);
    TableCellParentData parentData =
        firstChild!.parentData as TableCellParentData;
    assert(index == parentData.tableCellIndex);

    return firstChild!;
  }

  @protected
  RenderBox insertAndLayoutChild({
    required RenderBox after,
    required CellIndex index,
    required C cell,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, cell, after: after);
    final RenderBox? child = childAfter(after);

    assert(child != null, 'insertAndLayoutChild child is null');

    assert(child != null && cellIndexOf(child) == index,
        'insertAndLayoutChild child after has cellIndex: ${cellIndexOf(child!)} should be  $index');

    return child!;
  }

  @override
  void insert(RenderBox child, {RenderBox? after}) {
    assert(!_keepAliveBucket.containsValue(child));

    super.insert(child, after: after);
    assert(firstChild != null);
    assert(_debugVerifyChildOrder());
  }

  @override
  void remove(RenderBox child) {
    final TableCellParentData childParentData =
        child.parentData! as TableCellParentData;
    if (!childParentData.keptAlive) {
      super.remove(child);
      return;
    }
    assert(_keepAliveBucket[childParentData.tableCellIndex] == child);
    assert(() {
      _debugDanglingKeepAlives.remove(child);
      return true;
    }());
    _keepAliveBucket.remove(childParentData.tableCellIndex);
    childManager.removeKeepAliveElement(childParentData.tableCellIndex);
    dropChild(child);
  }

  @override
  void removeAll() {
    super.removeAll();
    _keepAliveBucket.values.forEach(dropChild);
    _keepAliveBucket.clear();
  }

  void _destroyOrCacheChild(RenderBox child) {
    final TableCellParentData childParentData =
        child.parentData! as TableCellParentData;
    if (childParentData.keepAlive) {
      assert(!childParentData.keptAlive);
      remove(child);
      _keepAliveBucket[childParentData.tableCellIndex] = child;
      child.parentData = childParentData;
      super.adoptChild(child);
      childParentData.keptAlive = true;
      childManager
          .cellIndexFromElementsToKeepAlive(childParentData.tableCellIndex);
    } else {
      assert(child.parent == this);
      childManager.removeChild(child);
      assert(child.parent == null);
    }
  }

  void _destroyChild(RenderBox child) {
    // final TableCellParentData childParentData =
    //     child.parentData! as TableCellParentData;

    // final index = childParentData.tableCellIndex;

    // if (_keepAliveBucket.containsKey(index)) {
    //   _keepAliveBucket.remove(index)!;

    //   // dropChild(child);

    //   // Added by Joan
    //   //childManager.removeKeepAliveElement(index);
    // }
    assert(child.parent == this);
    childManager.removeChild(child);
    assert(child.parent == null);

    // if (childParentData.keepAlive) {
    //   assert(!childParentData.keptAlive);
    //   remove(child);
    //   _keepAliveBucket[childParentData.tableCellIndex] = child;
    //   child.parentData = childParentData;
    //   super.adoptChild(child);
    //   childParentData.keptAlive = true;
    //   childManager
    //       .cellIndexFromElementsToKeepAlive(childParentData.tableCellIndex);
    // } else {
    //   assert(child.parent == this);
    //   childManager.removeChild(child);
    //   assert(child.parent == null);
    // }
    assert(_keepAliveBucket.length < 2,
        '_keepAliveBucket is ${_keepAliveBucket.length}');

    debugPrint('KeepAliveBucket length ${_keepAliveBucket.length}');
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

      for (var MapEntry(key: index, value: child)
          in Map.from(_keepAliveBucket).entries) {
        if (viewModel.cellsToRemove.contains(index)) {
          _destroyChild(child);
        }
      }

      while (child != null) {
        TableCellParentData parentData =
            child.parentData as TableCellParentData;
        CellIndex tableCellIndex = parentData.tableCellIndex;
        var rows = 0;
        int columns = 0;
        final childToRemove = child;

        child = parentData.nextSibling;

        if (viewModel.cellsToRemove.contains(tableCellIndex)) {
          _destroyChild(childToRemove);
        } else if (removeAll ||
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

          _destroyOrCacheChild(childToRemove);
        }
      }

      assert(
          _debugVerifyChildOrder(), 'Garbage collection: Child order not oke');
    });

    garbageCollectRowsFrom = -1;
    garbageCollectColumnsFrom = -1;
  }

  // garbageCollect() {
  //   invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
  //     RenderBox? child = firstChild;

  //     iterator.reset(tpli);

  //     TableCellIndex tableCellIndex = TableCellIndex();

  //     while (iterator.next) {
  //       tableCellIndex = iterator.tableCellIndex;
  //       final cell = iterator.cell;

  //       while (child != null &&
  //           (child.parentData as TableCellParentData).tableCellIndex <=
  //               tableCellIndex) {
  //         final t = (child.parentData as TableCellParentData).tableCellIndex;

  //         if (t < tableCellIndex || (cell == null && t == tableCellIndex)) {
  //           final childToRemove = child;
  //           child = (child.parentData as TableCellParentData).nextSibling;

  //           childManager.removeChild(childToRemove);
  //         } else {
  //           child = (child.parentData as TableCellParentData).nextSibling;
  //         }
  //       }
  //     }
  //     while (child != null) {
  //       final childToRemove = child;
  //       child = (child.parentData as TableCellParentData).nextSibling;
  //       childManager.removeChild(childToRemove);
  //     }

  //     assert(() {
  //       var debugChild = firstChild;
  //       int i = 0;
  //       int c = 0;

  //       while (debugChild != null) {
  //         c++;
  //         debugChild =
  //             (debugChild.parentData as TableCellParentData).nextSibling;
  //       }

  //       iterator.reset(tpli);

  //       while (iterator.next) {
  //         if (iterator.cell != null) {
  //           i++;
  //         }
  //       }

  //       if (c > i) {
  //         debugPrint(
  //             'After garbage collection the number of children should be equal or lower than cells iterated by iterator');
  //       }

  //       return c <= i;
  //     }(), 'Error garbage collection!');
  //   });
  // }

  // void _createOrObtainChild(CellIndex index, C cell,
  //     {required RenderBox? after}) {
  //   invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
  //     assert(constraints == this.constraints);
  //     childManager.createChild(index, cell, after: after);
  //   });
  // }

  void _createOrObtainChild(CellIndex index, C cell,
      {required RenderBox? after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      if (_keepAliveBucket.containsKey(index)) {
        final RenderBox child = _keepAliveBucket.remove(index)!;
        final TableCellParentData childParentData =
            child.parentData! as TableCellParentData;
        assert(childParentData.keptAlive);
        dropChild(child);
        child.parentData = childParentData;
        // Added by Joan
        childManager.cellIndexFromKeepAliveToElements(index);

        insert(child, after: after);
        childParentData.keptAlive = false;
      } else {
        childManager.createChild(index, cell, after: after);
      }
    });
  }

  CellIndex indexOf(RenderBox child) {
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
      CellIndex index;
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
    for (final RenderBox child in _keepAliveBucket.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    // _offset.removeListener(markNeedsLayout);
    // _sliverPosition?.removeListener(markNeedsLayout);

    _viewModel.removeListener(markNeedsLayout);
    super.detach();

    for (final RenderBox child in _keepAliveBucket.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() {
    super.redepthChildren();
    _keepAliveBucket.values.forEach(redepthChild);
  }

  @override
  void visitChildren(RenderObjectVisitor visitor) {
    super.visitChildren(visitor);
    _keepAliveBucket.values.forEach(visitor);
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

      tableBuilder.finalPaintPanel(
        context,
        offset,
        size,
        viewModel,
        tpli,
        iterator.rowInfoList,
        iterator.columnInfoList,
      );

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
            size.bottomRight(offset + const Offset(-25.0, -25.0)), 20, paint);
        return true;
      }());
    });
  }
}

class TableCellParentData extends ContainerBoxParentData<RenderBox>
    with KeepAliveParentDataMixin {
  CellIndex tableCellIndex = const CellIndex();

  @override
  bool keptAlive = false;

  @override
  String toString() {
    return '${super.toString()}, CellIndex: $tableCellIndex';
  }
}

class FtIndex {
  const FtIndex({
    required this.column,
    required this.row,
  });

  final int column;
  final int row;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FtIndex &&
          runtimeType == other.runtimeType &&
          column == other.column &&
          row == other.row;

  @override
  int get hashCode => column.hashCode ^ row.hashCode;

  bool get isIndex => column >= 0 && row >= 0;
}

class CellIndex extends FtIndex implements Comparable<CellIndex> {
  const CellIndex(
      {super.column = -1,
      super.row = -1,
      this.columns = 1,
      this.rows = 1,
      this.edit = false});

  final int columns;
  final int rows;
  final bool edit;

  bool operator >(CellIndex index) {
    return row > index.row || (row == index.row && column > index.column);
  }

  bool operator <(CellIndex index) {
    return row < index.row || (row == index.row && column < index.column);
  }

  bool operator <=(CellIndex index) {
    // Geen row <= index.row maar row < index.row
    return row < index.row || (row == index.row && column <= index.column);
  }

  bool operator >=(CellIndex index) {
    //Geen >= voor row
    return row > index.row || (row == index.row && column >= index.column);
  }

  bool get hasIndex => row != -1 && column != -1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellIndex &&
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
  int compareTo(CellIndex other) {
    return (row < other.row || (row == other.row && column < other.column))
        ? -1
        : ((row == other.row && column == other.column) ? 0 : 1);
  }

  CellIndex copyWith({
    int? column,
    int? row,
    int? columns,
    int? rows,
    bool? edit,
  }) {
    return CellIndex(
      column: column ?? this.column,
      row: row ?? this.row,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      edit: edit ?? this.edit,
    );
  }
}

class PanelCellIndex extends CellIndex {
  final int panelIndexX;
  final int panelIndexY;

  const PanelCellIndex(
      {this.panelIndexX = -1,
      this.panelIndexY = -1,
      super.column = -1,
      super.row = -1,
      super.columns = 1,
      super.rows = 1,
      super.edit = false});

  PanelCellIndex.from(
      {required CellIndex cellIndex,
      this.panelIndexX = -1,
      this.panelIndexY = -1,
      bool? edit})
      : super(
            row: cellIndex.row,
            column: cellIndex.column,
            rows: cellIndex.rows,
            columns: cellIndex.columns,
            edit: edit ?? cellIndex.edit);

  bool get isPanel =>
      panelIndexX > 0 && panelIndexX < 3 && panelIndexY > 0 && panelIndexY < 3;

  int get scrollIndexX => panelIndexX == 1 ? 0 : 1;

  int get scrollIndexY => panelIndexY == 1 ? 0 : 1;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is PanelCellIndex) {
      return other.panelIndexX == panelIndexX &&
          other.panelIndexY == panelIndexY &&
          runtimeType == other.runtimeType &&
          column == other.column &&
          row == other.row &&
          columns == other.columns &&
          rows == other.rows &&
          edit == other.edit;
    }
    return other is FtIndex && column == other.column && row == other.row;
  }

  @override
  int get hashCode => column.hashCode ^ row.hashCode;

  @override
  PanelCellIndex copyWith({
    int? panelIndexX,
    int? panelIndexY,
    int? column,
    int? row,
    int? columns,
    int? rows,
    bool? edit,
  }) {
    return PanelCellIndex(
      panelIndexX: panelIndexX ?? this.panelIndexX,
      panelIndexY: panelIndexY ?? this.panelIndexY,
      column: column ?? this.column,
      row: row ?? this.row,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
      edit: edit ?? this.edit,
    );
  }
}
