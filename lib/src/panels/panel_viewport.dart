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
import 'keyed_cell.dart';
import 'table_layout_iterations.dart';

typedef CellBuilder<C extends AbstractCell, M extends AbstractFtModel<C>>
    = Widget? Function(
  BuildContext context,
  M model,
  FtIndex tableCellIndex,
);

class TablePanel<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends StatelessWidget {
  final FtViewModel<C, M> viewModel;
  final int panelIndex;
  final AbstractTableBuilder<C, M> tableBuilder;
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

    return TablePanelViewport<C, M>(
      viewModel: viewModel,
      panelIndex: panelIndex,
      tableBuilder: tableBuilder,
      tableScale: tableScale,
    );
  }
}

class TablePanelViewport<C extends AbstractCell, M extends AbstractFtModel<C>>
    extends RenderObjectWidget {
  const TablePanelViewport({
    super.key,
    required this.viewModel,
    required this.panelIndex,
    required this.tableBuilder,
    required this.tableScale,
  });

  final FtViewModel<C, M> viewModel;
  final int panelIndex;
  final AbstractTableBuilder<C, M> tableBuilder;
  final double tableScale;

  @override
  TablePanelChildRenderObjectElement<C, M> createElement() =>
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
  TablePanelRenderViewport<C, M> createRenderObject(BuildContext context) {
    final TablePanelRenderChildManager element =
        context as TablePanelRenderChildManager;

    return TablePanelRenderViewport(
      childManager: element,
      viewModel: viewModel,
      panelIndex: panelIndex,
      tableScale: tableScale,
      tableBuilder: tableBuilder,
    );
  }

  LayoutPanelIndex get layoutPanelIndex =>
      viewModel.layoutPanelIndex(panelIndex);
}

class TablePanelChildRenderObjectElement<C extends AbstractCell,
        M extends AbstractFtModel<C>> extends RenderObjectElement
    implements TablePanelRenderChildManager<C> {
  TablePanelChildRenderObjectElement(super.widget);

  final Map<FtIndex, Widget?> _childWidgets = HashMap<FtIndex, Widget?>();
  final SplayTreeMap<FtIndex, Element?> _childElements =
      SplayTreeMap<FtIndex, Element?>();
  final SplayTreeMap<FtIndex, Element?> _keptAliveElements =
      SplayTreeMap<FtIndex, Element?>();
  final HashMap<FtIndex, CellStatus> statusOfCells =
      HashMap<FtIndex, CellStatus>();

  RenderBox? _currentBeforeChild;
  FtIndex? _currentlyUpdatingTableCellIndex;
  CellStatus? _currentUpdatingCellStatus;

  @override
  TablePanelViewport<C, M> get widget =>
      super.widget as TablePanelViewport<C, M>;

  @override
  TablePanelRenderViewport<C, M> get renderObject =>
      super.renderObject as TablePanelRenderViewport<C, M>;

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
    assert(_currentUpdatingCellStatus == null);
    try {
      ///
      ///
      ///
      ///
      ///
      HashMap<FtIndex, CellStatus> oldStatusOfCellMap =
          HashMap<FtIndex, CellStatus>.from(statusOfCells);
      statusOfCells.clear();
      final ftModel = widget.viewModel.model;

      final SplayTreeMap<FtIndex, Element?> newChildren =
          SplayTreeMap<FtIndex, Element?>();

      HashMap<FtIndex, CellStatus> remapStatusOfCell =
          HashMap<FtIndex, CellStatus>();

      for (FtIndex index in _childElements.keys.toList()) {
        ///
        ///
        ///
        final Key? key = _childElements[index]!.widget.key;
        final FtIndex? newIndex =
            key == null ? null : ftModel.findIndexByKey(index, key);

        if (newIndex == index) {
          newChildren[index] = _childElements[index];

          remapStatusOfCell[index] = oldStatusOfCellMap[index]!;
        } else {
          // The layout offset of the child being moved is no longer accurate.
          // if (childParentData != null) {
          //   childParentData.layoutOffset = null;
          // }
          if (newIndex != null) {
            newChildren[newIndex] = _childElements[index];

            remapStatusOfCell[newIndex] =
                oldStatusOfCellMap[index] ?? const CellStatus();
            // We do not want the remapped child to get deactivated during processElement.
            _childElements.remove(index);
          }

          newChildren.putIfAbsent(index, () => null);
        }

        ///
        ///
        ///
        ///
      }

      void processElement(FtIndex index) {
        _currentlyUpdatingTableCellIndex = index;
        _currentUpdatingCellStatus =
            remapStatusOfCell[index] ?? const CellStatus();

        if (_childElements[index] != null &&
            _childElements[index] != newChildren[index]) {
          _childElements[index] =
              updateChild(_childElements[index], null, index);
        }
        final Element? newChild = updateChild(newChildren[index],
            _buildFromIndex(index, _currentUpdatingCellStatus!), index);
        if (newChild != null) {
          _childElements[index] = newChild;
          final TableCellParentData parentData =
              newChild.renderObject!.parentData! as TableCellParentData;
          if (!parentData.keptAlive) {
            _currentBeforeChild = newChild.renderObject as RenderBox?;
          }
        } else {
          _childElements.remove(index);
        }
      }

      renderObject.debugChildIntegrityEnabled =
          false; // Moving children will temporary violate the integrity.

      newChildren.keys.forEach(processElement);
    } finally {
      _currentlyUpdatingTableCellIndex = null;
      _currentUpdatingCellStatus = null;
      renderObject.debugChildIntegrityEnabled = true;
    }
  }

  Widget? _buildFromIndex(FtIndex index, CellStatus cellStatus) {
    C? cell = widget.viewModel.model.cell(row: index.row, column: index.column);

    return cell != null
        ? _build(cell, widget.layoutPanelIndex, index, cellStatus)
        : null;
  }

  @override
  void update(TablePanelViewport<C, M> newWidget) {
    super.update(newWidget);
    // final TablePanelViewport<T, C> oldWidget = widget;

    // final FtViewModel<T, C> newDelegate = newWidget.viewModel;
    // final FtViewModel<T, C> oldDelegate = oldWidget.viewModel;
    // if ((newDelegate != oldDelegate &&
    //         (newDelegate.runtimeType != oldDelegate.runtimeType ||
    //             newDelegate.shouldRebuild(oldDelegate))) ||
    //     oldWidget.tableScale != newWidget.tableScale)
    performRebuild();
  }

  @override
  void createChild(FtIndex tableCellIndex, C cell, CellStatus cellStatus,
      {RenderBox? after}) {
    assert(_currentlyUpdatingTableCellIndex == null);
    assert(_currentUpdatingCellStatus == null);
    owner!.buildScope(this, () {
      final bool insertFirst = after == null;

      if (insertFirst) {
        _currentBeforeChild = null;
      } else {
        final lastKeyBefore = lastKeyBeforeAliveChild(tableCellIndex);
        //_childElements.lastKeyBefore(tableCellIndex);

        assert(lastKeyBefore != null);
        final element = _childElements[lastKeyBefore];
        assert(element != null);
        _currentBeforeChild = element!.renderObject as RenderBox?;
      }

      Element? newChild;
      try {
        _currentlyUpdatingTableCellIndex = tableCellIndex;
        _currentUpdatingCellStatus = cellStatus;
        newChild = updateChild(
            _childElements[tableCellIndex],
            _build(cell, widget.layoutPanelIndex, tableCellIndex, cellStatus),
            tableCellIndex);
      } finally {
        _currentlyUpdatingTableCellIndex = null;
        _currentUpdatingCellStatus = null;
      }
      if (newChild != null) {
        _childElements[tableCellIndex] = newChild;
      } else {
        _childElements.remove(tableCellIndex);
      }
    });
  }

  @override
  bool containsElement(FtIndex key) {
    return _childElements.containsKey(key);
  }

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingTableCellIndex == null);
    assert(_currentUpdatingCellStatus == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingTableCellIndex != null);
    assert(_currentUpdatingCellStatus != null);
    final TableCellParentData childParentData =
        child.parentData as TableCellParentData;
    childParentData.tableCellIndex = _currentlyUpdatingTableCellIndex!;
    childParentData.cellStatus = _currentUpdatingCellStatus!;
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

  FtIndex? lastKeyBeforeAliveChild(FtIndex index) {
    FtIndex? newIndex = _childElements.lastKeyBefore(index);

    while (newIndex != null) {
      if (_childElements[newIndex]?.renderObject?.parentData
          case TableCellParentData t) {
        if (!t.keptAlive) {
          return newIndex;
        }
      }
      newIndex = _childElements.lastKeyBefore(newIndex);
    }
    return newIndex;
  }

  @override
  void insertRenderObjectChild(RenderObject child, FtIndex slot) {
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
    assert(_currentlyUpdatingTableCellIndex == newSlot);
    renderObject.move(child as RenderBox, after: _currentBeforeChild);
  }

  @override
  void removeChild(RenderBox child) {
    final FtIndex index = renderObject.indexOf(child);
    final CellStatus cellStatus = renderObject.cellStatusOf(child);

    assert(_currentlyUpdatingTableCellIndex == null);
    assert(_currentUpdatingCellStatus == null);

    owner!.buildScope(this, () {
      assert(_childElements.containsKey(index) ||
          _keptAliveElements.containsKey(index));
      try {
        _currentlyUpdatingTableCellIndex = index;
        _currentUpdatingCellStatus = cellStatus;
        final Element? result = updateChild(
            _childElements[index] ?? _keptAliveElements[index], null, index);
        assert(result == null);
      } finally {
        _currentlyUpdatingTableCellIndex = null;
        _currentUpdatingCellStatus = null;
      }
      if (_childElements.remove(index) == null) {
        _keptAliveElements.remove(index);
      }

      assert(!_childElements.containsKey(index) ||
          !_keptAliveElements.containsKey(index));

      _childWidgets.remove(index);
      statusOfCells.remove(index);
      // debugPrint('removedWidget $index');

      // assert(removedWidged != null, 'Index $index not found in _childWidgets');
    });
    assert(_keptAliveElements.length < 3,
        '_keptAliveElements alive elements is ${_keptAliveElements.length}');
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
  updateFromTableCellIndex(
      C cell, FtIndex tableCellIndex, CellStatus cellStatus) {
    owner!.buildScope(this, () {
      final lastKeyBefore = lastKeyBeforeAliveChild(tableCellIndex);
      // _childElements.lastKeyBefore(tableCellIndex);

      if (lastKeyBefore != null) {
        final element = _childElements[lastKeyBefore];
        assert(element != null);
        _currentBeforeChild = element!.renderObject as RenderBox?;
      } else {
        _currentBeforeChild = null;
      }
      Element? newChild;
      try {
        _childWidgets.remove(tableCellIndex);
        _currentlyUpdatingTableCellIndex = tableCellIndex;
        _currentUpdatingCellStatus = cellStatus;

        newChild = updateChild(
            _childElements[tableCellIndex],
            _build(cell, widget.layoutPanelIndex, tableCellIndex, cellStatus),
            tableCellIndex);
      } finally {
        _currentlyUpdatingTableCellIndex = null;
        _currentUpdatingCellStatus = null;
      }

      if (newChild != null) {
        _childElements[tableCellIndex] = newChild;
      } else {
        _childElements.remove(tableCellIndex);
      }
    });
  }

  @override
  CellStatus cellStatusOf(FtIndex tableCellIndex) =>
      statusOfCells[tableCellIndex] ?? const CellStatus();

  @override
  void setDidUnderflow(bool value) {}

  Widget? _build(C cell, LayoutPanelIndex layoutPanelIndex, FtIndex cellIndex,
      CellStatus cellStatus) {
    // return widget.tableBuilder.cellBuilder(
    //   this,
    //   widget.viewModel,
    //   cell,
    //   layoutPanelIndex,
    //   cellIndex,
    // );

    statusOfCells[cellIndex] = cellStatus;

    ///
    ///
    ///

    ValueKey? valueKey;

    if (widget.viewModel.model.indexToImmutableIndex(cellIndex)
        case FtIndex ftIndex) {
      valueKey = ValueKey<FtIndex>(ftIndex);
    }

    return _childWidgets.putIfAbsent(cellIndex, () {
      final child = widget.tableBuilder.cellBuilder(
          this,
          widget.viewModel,
          widget.viewModel.tableScale,
          cell,
          layoutPanelIndex,
          cellIndex,
          cellStatus,
          valueKey);

      if (child case Widget c) {
        return KeyedCell.wrap(valueKey, c);
      }
      return child;
    });
  }
}

abstract class TablePanelRenderChildManager<C extends AbstractCell> {
  void createChild(FtIndex tableCellIndex, C cell, CellStatus cellStatus,
      {required RenderBox? after});

  void removeChild(RenderBox child);

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  void didStartLayout();

  void didFinishLayout();

  bool debugAssertChildListLocked() => true;

  //Added by Joan
  bool containsElement(FtIndex tableCellIndex);

  //Added by Joan
  updateFromTableCellIndex(
      C cell, FtIndex tableCellIndex, CellStatus cellStatus);

  //Added by Joan
  CellStatus cellStatusOf(FtIndex tableCellIndex);
}

class TablePanelRenderViewport<C extends AbstractCell,
        M extends AbstractFtModel<C>> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TableCellParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TableCellParentData> {
  TablePanelRenderViewport({
    required FtViewModel<C, M> viewModel,
    ScrollPosition? sliverPosition,
    required this.childManager,
    required this.panelIndex,
    required double tableScale,
    required AbstractTableBuilder<C, M> tableBuilder,
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
  late TableInterator<C, M> iterator;
  late double xScroll, yScroll;
  double _tableScale;
  late double leftMargin, topMargin, rightMargin, bottomMargin;
  FtViewModel<C, M> _viewModel;
  int garbageCollectRowsFrom = -1;
  int garbageCollectColumnsFrom = -1;
  final Map<FtIndex, RenderBox> _keepAliveBucket = <FtIndex, RenderBox>{};

  FtViewModel<C, M> get viewModel => _viewModel;

  set viewModel(FtViewModel<C, M> value) {
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

  AbstractTableBuilder<C, M> _tableBuilder;

  AbstractTableBuilder<C, M> get tableBuilder => _tableBuilder;

  set tableBuilder(AbstractTableBuilder<C, M> value) {
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

  FtIndex cellIndexOf(RenderBox child) {
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
        lastColumnIndex: iterator.lastColumnIndex,
        editCellIndex: iterator.editCellIndex,
        editCellStatus: iterator.editCellStatus);

    // if (constraints.biggest.shortestSide == 0.0) {
    //   return;
    // }

    child = firstChild;
    bool foundFocusedCell = false;
    while (iterator.next) {
      C? cell = iterator.cell;

      final tableCellIndex = iterator.tableCellIndex;

      if (cell != null) {
        CellStatus cellStatus = iterator.cellStatus;

        if (cellStatus == const CellStatus(edit: true, hasFocus: true)) {
          foundFocusedCell = true;
        }

        if (child == null) {
          assert(firstChild == null);
          child = insertAndLayoutFirstChild(
              after: null,
              index: tableCellIndex,
              cell: cell,
              cellStatus: cellStatus);

          assert(tableCellIndex ==
              (firstChild!.parentData as TableCellParentData).tableCellIndex);
        } else {
          TableCellParentData parentData =
              child.parentData as TableCellParentData;

          if (parentData.tableCellIndex < tableCellIndex) {
            child = findOrInsertForward(
                child: child,
                index: tableCellIndex,
                cell: cell,
                cellStatus: cellStatus);
          } else {
            assert(parentData.tableCellIndex >= tableCellIndex);
            child = findOrInsertBackward(
                child: child,
                index: tableCellIndex,
                cell: cell,
                cellStatus: cellStatus);
          }
        }
        layoutChild(
            child: child,
            left: iterator.left,
            top: iterator.top,
            width: iterator.width,
            height: iterator.height);
      } else {
        assert(
            iterator.editCellIndex == tableCellIndex ||
                find(tableCellIndex) == null,
            'Did you forget to use setState, when the row/column dimensions where changed?. Renderbox removal on layout is not supported. Additional info: EditCellIndex ${iterator.editCellIndex} IndexCellIndex: $tableCellIndex  find(tableCellIndex) ${find(tableCellIndex)}');
      }
    }

    if (!foundFocusedCell) {
      if (iterator.editCellOutsideInteration
          case (
            FtIndex editCellIndex,
            C cell,
            CellStatus cellStatus,
            Rect rect
          )) {
        if (!_keepAliveBucket.containsKey(editCellIndex)) {
          child = firstChild;
          if (child == null) {
            child = insertAndLayoutFirstChild(
                after: null,
                index: editCellIndex,
                cell: cell,
                cellStatus: cellStatus);
            layoutChild(
                child: child, left: 0.0, top: 0.0, width: 80, height: 40);
          } else {
            final TableCellParentData parentData =
                child.parentData as TableCellParentData;

            if (parentData.tableCellIndex < editCellIndex) {
              child = findOrInsertForward(
                  child: child,
                  index: editCellIndex,
                  cell: cell,
                  cellStatus: cellStatus);
            } else {
              assert(parentData.tableCellIndex >= editCellIndex);
              child = findOrInsertBackward(
                  child: child,
                  index: editCellIndex,
                  cell: cell,
                  cellStatus: cellStatus);
            }
            layoutChild(
                child: child,
                left: rect.left,
                top: rect.right,
                width: rect.width,
                height: rect.height);
          }
        }
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
    (parentData as TablePanelParentData).keepAlive =
        _keepAliveBucket.isNotEmpty;

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
    required FtIndex index,
    required CellStatus cellStatus,
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

    child = insertAndLayoutChild(
        after: child, index: index, cell: cell, cellStatus: cellStatus);
    assert(index == (child.parentData as TableCellParentData).tableCellIndex);

    return child;
  }

  RenderBox findOrInsertBackward({
    required RenderBox child,
    required FtIndex index,
    required C cell,
    required CellStatus cellStatus,
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
          after: null, index: index, cell: cell, cellStatus: cellStatus);
    } else {
      shiftChild = insertAndLayoutChild(
          after: shiftChild, index: index, cell: cell, cellStatus: cellStatus);
    }

    assert(
        index == (shiftChild.parentData as TableCellParentData).tableCellIndex);

    return shiftChild;
  }

  RenderBox? find(FtIndex index) {
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
      //childManager.moveKeepAlive(oldIndex, childParentData.tableCellIndex);
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
    required FtIndex index,
    required C cell,
    required CellStatus cellStatus,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, cell, cellStatus, after: after);

    assert(firstChild != null);
    TableCellParentData parentData =
        firstChild!.parentData as TableCellParentData;
    assert(index == parentData.tableCellIndex);

    return firstChild!;
  }

  @protected
  RenderBox insertAndLayoutChild({
    required RenderBox after,
    required FtIndex index,
    required C cell,
    required CellStatus cellStatus,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, cell, cellStatus, after: after);
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
  }

  // columns 1024 -> 1023
  //rows 2^20 1048576 -> 1048575

  garbageCollect({
    bool removeAll = false,
    int firstRowIndex = 0,
    int firstColumnIndex = 0,
    int lastRowIndex = 1048575,
    int lastColumnIndex = 1023,
    required FtIndex editCellIndex,
    required CellStatus editCellStatus,
  }) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      RenderBox? child = firstChild;
      bool hasFocus = iterator.hasFocus;

      for (var MapEntry<FtIndex, RenderBox>(key: index, value: child)
          in Map<FtIndex, RenderBox>.from(_keepAliveBucket).entries) {
        if (viewModel.cellsToRemove.contains(index) ||
            viewModel.cellsToUpdate.contains(index)) {
          _destroyChild(child);
        } else if ((index != editCellIndex) ||
            (index == editCellIndex && !hasFocus)) {
          /// Without render it is not possible to updateFromTableCellIndex, therefore destroy!
          ///
          ///
          ///
          _destroyChild(child);
        }
      }

      while (child != null) {
        TableCellParentData parentData =
            child.parentData as TableCellParentData;
        FtIndex tableCellIndex = parentData.tableCellIndex;
        var rows = 0;
        int columns = 0;
        final childToRemove = child;

        child = parentData.nextSibling;

        if (viewModel.cellsToRemove.contains(FtIndex(
          row: tableCellIndex.row,
          column: tableCellIndex.column,
        ))) {
          _destroyChild(childToRemove);
        } else if (
            //(
            // garbageCollectRowsFrom != -1 &&
            //       garbageCollectRowsFrom <= tableCellIndex.row) ||
            //   (garbageCollectColumnsFrom != -1 &&
            //       garbageCollectColumnsFrom <= tableCellIndex.column) ||
            firstRowIndex > tableCellIndex.row + rows ||
                lastRowIndex < tableCellIndex.row ||
                firstColumnIndex > tableCellIndex.column + columns ||
                lastColumnIndex < tableCellIndex.column) {
          assert(childManager.containsElement(tableCellIndex),
              'Element bestaat niet $tableCellIndex');

          if (parentData.cellStatus.edit && editCellIndex != tableCellIndex) {
            _destroyChild(childToRemove);
          } else {
            _destroyOrCacheChild(childToRemove);
          }
        } else if (editCellIndex == tableCellIndex &&
            parentData.cellStatus != editCellStatus) {
          childManager.updateFromTableCellIndex(
              viewModel.model
                  .cell(row: editCellIndex.row, column: editCellIndex.column)!,
              editCellIndex,
              editCellStatus);
        } else if (parentData.cellStatus.edit &&
            editCellIndex != tableCellIndex) {
          _destroyChild(childToRemove);
        } else if (viewModel.cellsToUpdate.contains(FtIndex(
          row: tableCellIndex.row,
          column: tableCellIndex.column,
        ))) {
          if (viewModel.model
                  .cell(row: tableCellIndex.row, column: tableCellIndex.column)
              case C cell) {
            childManager.updateFromTableCellIndex(
                cell,
                FtIndex(
                  row: tableCellIndex.row,
                  column: tableCellIndex.column,
                ),
                parentData.cellStatus);
          } else {
            _destroyChild(childToRemove);
          }
        }
      }

      assert(
          _debugVerifyChildOrder(), 'Garbage collection: Child order not oke');
    });

    garbageCollectRowsFrom = -1;
    garbageCollectColumnsFrom = -1;
  }

  void _createOrObtainChild(FtIndex index, C cell, CellStatus cellStatus,
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

        insert(child, after: after);
        childParentData.keptAlive = false;
      } else {
        childManager.createChild(index, cell, cellStatus, after: after);
      }
    });
  }

  FtIndex indexOf(RenderBox child) {
    return (child.parentData as TableCellParentData).tableCellIndex;
  }

  CellStatus cellStatusOf(RenderBox child) {
    return (child.parentData as TableCellParentData).cellStatus;
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
      FtIndex index;
      while (child != null) {
        index = cellIndexOf(child);
        child = childAfter(child);
        assert(child == null || cellIndexOf(child) > index,
            'Index $index, next index of next child: ${cellIndexOf(child)} ');
      }
    }
    return true;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);

    _viewModel.addListener(markNeedsLayout);
    for (final RenderBox child in _keepAliveBucket.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
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

      // assert(() {
      //   Color color;
      //   switch (panelIndex) {
      //     case 5:
      //       color = Colors.amber.withAlpha(155);
      //       break;
      //     case 6:
      //       color = Colors.pinkAccent.withAlpha(155);
      //       break;
      //     case 9:
      //       color = Colors.lightGreen.withAlpha(155);
      //       break;
      //     default:
      //       color = Colors.blue.withAlpha(155);
      //       break;
      //   }
      //   Paint paint = Paint();
      //   paint.color = color;
      //   context.canvas.drawCircle(
      //       size.bottomRight(offset + const Offset(-25.0, -25.0)), 20, paint);
      //   return true;
      // }());
    });
  }
}

class TableCellParentData extends ContainerBoxParentData<RenderBox>
    with KeepAliveParentDataMixin {
  FtIndex tableCellIndex = const FtIndex();

  @override
  bool keptAlive = false;

  CellStatus cellStatus = const CellStatus();

  @override
  String toString() {
    return '${super.toString()}, CellIndex: $tableCellIndex';
  }
}

class FtIndex implements Comparable<FtIndex> {
  const FtIndex({
    this.column = -1,
    this.row = -1,
  });

  final int column;
  final int row;

  bool operator >(FtIndex index) {
    return row > index.row || (row == index.row && column > index.column);
  }

  bool operator <(FtIndex index) {
    return row < index.row || (row == index.row && column < index.column);
  }

  bool operator <=(FtIndex index) {
    // Geen row <= index.row maar row < index.row
    return row < index.row || (row == index.row && column <= index.column);
  }

  bool operator >=(FtIndex index) {
    //Geen >= voor row
    return row > index.row || (row == index.row && column >= index.column);
  }

  bool get isIndex => row != -1 && column != -1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FtIndex &&
          runtimeType == other.runtimeType &&
          column == other.column &&
          row == other.row);

  @override
  int get hashCode => column.hashCode ^ row.hashCode;

  @override
  int compareTo(FtIndex other) {
    return (row < other.row || (row == other.row && column < other.column))
        ? -1
        : ((row == other.row && column == other.column) ? 0 : 1);
  }

  FtIndex copyWith({
    int? column,
    int? row,
  }) {
    return FtIndex(
      column: column ?? this.column,
      row: row ?? this.row,
    );
  }

  @override
  String toString() => 'FtIndex(column: $column, row: $row)';
}

class PanelCellIndex extends FtIndex {
  final int panelIndexX;
  final int panelIndexY;
  final int rows;
  final int columns;

  const PanelCellIndex({
    this.panelIndexX = -1,
    this.panelIndexY = -1,
    super.column = -1,
    super.row = -1,
    this.rows = 1,
    this.columns = 1,
  });

  PanelCellIndex.from({
    required FtIndex ftIndex,
    this.panelIndexX = -1,
    this.panelIndexY = -1,
    int rows = 1,
    int columns = 1,
    AbstractCell? cell,
  })  : rows = cell?.merged?.rows ?? rows,
        columns = cell?.merged?.columns ?? rows,
        super(
          row: ftIndex.row,
          column: ftIndex.column,
        );

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
          row == other.row;
    }
    return other is FtIndex && column == other.column && row == other.row;
  }

  bool sameIndex(FtIndex index) => index.row == row && index.column == column;

  bool samePanel(LayoutPanelIndex index) =>
      index.xIndex == panelIndexX && index.yIndex == panelIndexY;

  @override
  int get hashCode => column.hashCode ^ row.hashCode;

  @override
  PanelCellIndex copyWith(
      {int? panelIndexX,
      int? panelIndexY,
      FtIndex? index,
      int? column,
      int? row,
      int? columns,
      int? rows}) {
    assert(!(index != null && row != null),
        'To set row, choice between index or row, not both!');
    assert(!(index != null && column != null),
        'To set column, choice between index or column, not both!');
    return PanelCellIndex(
      panelIndexX: panelIndexX ?? this.panelIndexX,
      panelIndexY: panelIndexY ?? this.panelIndexY,
      column: column ?? index?.column ?? this.column,
      row: row ?? index?.row ?? this.row,
      columns: columns ?? this.columns,
      rows: rows ?? this.rows,
    );
  }

  @override
  String toString() {
    return 'PanelCellIndex(panelIndexX: $panelIndexX, panelIndexY: $panelIndexY, rows: $rows, columns: $columns)';
  }
}

class CellStatus {
  final bool hasFocus;
  final bool edit;

  const CellStatus({
    this.hasFocus = false,
    this.edit = false,
  });
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CellStatus &&
        other.hasFocus == hasFocus &&
        other.edit == edit;
  }

  @override
  int get hashCode => hasFocus.hashCode ^ edit.hashCode;
}
