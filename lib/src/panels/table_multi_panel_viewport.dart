// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:collection';
import 'package:flextable/flextable.dart';

import '../panels/panel_viewport.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../model/properties/flextable_grid_layout.dart';
import 'header_viewport.dart';

typedef TablePanelViewportBuilder = Widget Function(
    BuildContext context, int index);

class TableMultiPanel<T extends AbstractFtModel<C>, C extends AbstractCell>
    extends StatelessWidget {
  const TableMultiPanel(
      {super.key,
      required this.viewModel,
      required this.tableBuilder,
      required this.tableScale});

  final FtViewModel<T, C> viewModel;
  final AbstractTableBuilder<T, C> tableBuilder;
  final double tableScale;

  @override
  Widget build(BuildContext context) {
    return TableMultiPanelViewport(
      viewModel: viewModel,
      tableScale: tableScale,
      tableBuilder: tableBuilder,
      builder: (BuildContext context, int panelIndex) {
        Widget? panel;

        if (panelIndex == 5 ||
            panelIndex == 6 ||
            panelIndex == 9 ||
            panelIndex == 10) {
          panel = TablePanel<T, C>(
            viewModel: viewModel,
            panelIndex: panelIndex,
            tableBuilder: tableBuilder,
            tableScale: tableScale,
          );
        } else if (panelIndex == 0 ||
            panelIndex == 3 ||
            panelIndex == 12 ||
            panelIndex == 15) {
          panel = null;
        } else {
          final layoutIndex = viewModel.layoutPanelIndex(panelIndex);
          final layoutIndexX = layoutIndex.xIndex;

          panel = TableHeader(
              viewModel: viewModel,
              panelIndex: panelIndex,
              tableBuilder: tableBuilder,
              tableScale: tableScale,
              headerScale: (layoutIndexX == 0 || layoutIndexX == 3)
                  ? viewModel.scaleRowHeader
                  : viewModel.scaleColumnHeader);
        }

        return tableBuilder.backgroundPanel(context, panelIndex, panel);
      },
    );
  }
}

class _SplitIterator implements Iterator<int> {
  _SplitIterator(this.delegate);

  FtViewModel delegate;

  int _row = 0;
  int _column = 0;
  int _current = -1;

  @override
  bool moveNext() {
    _current = -1;

    while (_current == -1 && _row < 4) {
      _current = delegate.rowVisible(_row) && delegate.columnVisible(_column)
          ? delegate.panelIndex(_row, _column)
          : -1;

      if (_column < 3) {
        _column += 1;
      } else {
        _row += 1;
        _column = 0;
      }
    }

    return _current != -1;
  }

  reset() {
    _row = 0;
    _column = 0;
  }

  @override
  int get current => _current;
}

class TableMultiPanelViewport<T extends AbstractFtModel<C>,
    C extends AbstractCell> extends RenderObjectWidget {
  const TableMultiPanelViewport(
      {super.key,
      required this.viewModel,
      required this.builder,
      required this.tableBuilder,
      required this.tableScale});

  final FtViewModel<T, C> viewModel;
  final TablePanelViewportBuilder builder;
  final AbstractTableBuilder tableBuilder;
  final double tableScale;

  @override
  TableMultiPanelRenderViewport<T, C> createRenderObject(BuildContext context) {
    final TableMultiPanelRenderChildManager element =
        context as TableMultiPanelRenderChildManager;
    return TableMultiPanelRenderViewport(
      viewModel: viewModel,
      childManager: element,
      tableScale: tableScale,
      tableBuilder: tableBuilder,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, TableMultiPanelRenderViewport<T, C> renderObject) {
    renderObject
      ..viewModel = viewModel
      ..tableScale = tableScale
      ..tableBuilder = tableBuilder;
  }

  @override
  TableMultiPanelRenderObjectElement<T, C> createElement() =>
      TableMultiPanelRenderObjectElement(this);
}

class TableMultiPanelRenderObjectElement<T extends AbstractFtModel<C>,
        C extends AbstractCell> extends RenderObjectElement
    implements TableMultiPanelRenderChildManager {
  TableMultiPanelRenderObjectElement(super.widget);

  final Map<int, Widget?> _childWidgets = HashMap<int, Widget?>();
  final SplayTreeMap<int, Element?> _childElements =
      SplayTreeMap<int, Element?>();
  RenderBox? _currentBeforeChild;
  int? _currentlyUpdatingTablePanelIndex;

  @override
  TableMultiPanelViewport get widget => super.widget as TableMultiPanelViewport;

  /// The current list of children of this element.
  ///
  /// This list is filtered to hide elements that have been forgotten (using
  /// [forgetChild]).
  @protected
  @visibleForTesting
  Iterable<Element> get children =>
      _children.where((Element child) => !_forgottenChildren.contains(child));

  final List<Element> _children = [];
  // We keep a set of forgotten children to avoid O(n^2) work walking _children
  // repeatedly to remove children.
  final Set<Element> _forgottenChildren = HashSet<Element>();

  @override
  TableMultiPanelRenderViewport<T, C> get renderObject =>
      super.renderObject as TableMultiPanelRenderViewport<T, C>;

  @override
  void insertRenderObjectChild(RenderObject child, int slot) {
    // assert(slot != null);
    assert(_currentlyUpdatingTablePanelIndex == slot);
    assert(renderObject.debugValidateChild(child));
    renderObject.insert(child as RenderBox, after: _currentBeforeChild);
    assert(() {
      final TablePanelParentData childParentData =
          child.parentData as TablePanelParentData;
      //print('slot $slot tablePanelIndex ${childParentData.tablePanelIndex}');
      assert(slot == childParentData.tablePanelIndex);
      return true;
    }());
  }

  @override
  void moveRenderObjectChild(RenderObject child, int oldSlot, int newSlot) {
    assert(slot != null);
    assert(_currentlyUpdatingTablePanelIndex == newSlot);
    renderObject.move(child as RenderBox, after: _currentBeforeChild);

//    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
//    assert(child.parent == renderObject);
//    renderObject.move(child, after: slot?.renderObject);
//    assert(renderObject == this.renderObject);
  }

  @override
  void removeRenderObjectChild(RenderObject child, int slot) {
    assert(_currentlyUpdatingTablePanelIndex != null);
    renderObject.remove(child as RenderBox);

//    final ContainerRenderObjectMixin<RenderObject, ContainerParentDataMixin<RenderObject>> renderObject = this.renderObject;
//    assert(child.parent == renderObject);
//    renderObject.remove(child);
//    assert(renderObject == this.renderObject);
  }

  @override
  Element? updateChild(Element? child, Widget? newWidget, dynamic newSlot) {
    final TablePanelParentData? oldParentData =
        child?.renderObject?.parentData as TablePanelParentData?;
    final Element? newChild = super.updateChild(child, newWidget, newSlot);
    final TablePanelParentData? newParentData =
        newChild?.renderObject?.parentData as TablePanelParentData?;

    // Preserve the old layoutOffset if the renderObject was swapped out.
    if (oldParentData != newParentData &&
        oldParentData != null &&
        newParentData != null) {
      assert(oldParentData.tablePanelIndex == newParentData.tablePanelIndex,
          'TablePanelIndex not equal, old: ${oldParentData.tablePanelIndex}, new: ${newParentData.tablePanelIndex}');
      newParentData.offset = oldParentData.offset;
    }
    return newChild;
  }

  @override
  void visitChildren(ElementVisitor visitor) {
//    for (Element child in _children) {
//      if (!_forgottenChildren.contains(child))
//        visitor(child);
//    }
    assert(!_childElements.values.any((Element? child) => child == null));
    _childElements.values.cast<Element>().toList().forEach(visitor);
  }

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
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
//    _children = List<Element>(widget.children.length);
//    Element previousChild;
//    for (int i = 0; i < _children.length; i += 1) {
//      final Element newChild = inflateWidget(widget.children[i], previousChild);
//      _children[i] = newChild;
//      previousChild = newChild;
//    }
  }

  @override
  void update(TableMultiPanelViewport newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);

    // Maybe this is not enough if dataModel also changes -> copyWith?
    //
    //
    //
    //
    //  final TableMultiPanelViewport oldWidget = widget;
    // final ViewModel newDelegate = newWidget.viewModel;
    // finalViewModel oldDelegate = oldWidget.viewModel;

    // if ((newDelegate != oldDelegate &&
    //         (newDelegate.runtimeType != oldDelegate.runtimeType ||
    //             newDelegate.shouldRebuild(oldDelegate))) ||
    //     oldWidget.tableScale != newWidget.tableScale) performRebuild();

    performRebuild();

    //print('update TableViewport');
    // _children = updateChildren(_children, widget.children, forgottenChildren: _forgottenChildren);
//    _forgottenChildren.clear();
  }

  @override
  void performRebuild() {
    _childWidgets.clear(); // Reset the cache, as described above.
    super.performRebuild();

    _currentBeforeChild = null;

    assert(_currentlyUpdatingTablePanelIndex == null);
    try {
      final SplayTreeMap<int, Element?> newChildren =
          SplayTreeMap<int, Element?>();

      void processElement(int index) {
        _currentlyUpdatingTablePanelIndex = index;
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
          _currentBeforeChild = newChild.renderObject as RenderBox;
        } else {
          _childElements.remove(index);
        }
      }

      for (int index in _childElements.keys.toList()) {
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
      _currentlyUpdatingTablePanelIndex = null;
      renderObject.debugChildIntegrityEnabled = true;
    }
  }

  @override
  void createChild(int tablePanelIndex, {RenderBox? after}) {
    //print('createChild ${_childElements}');

    assert(_currentlyUpdatingTablePanelIndex == null);
    owner!.buildScope(this, () {
      final bool insertFirst = after == null;

      if (insertFirst) {
        _currentBeforeChild = null;
      } else {
        final lastKeyBefore = _childElements.lastKeyBefore(tablePanelIndex);
        assert(lastKeyBefore != null);
        final element = _childElements[lastKeyBefore];
        assert(element != null);
        _currentBeforeChild = element!.renderObject as RenderBox;
      }

      Element? newChild;
      try {
        _currentlyUpdatingTablePanelIndex = tablePanelIndex;
        newChild = updateChild(_childElements[tablePanelIndex],
            _build(tablePanelIndex), tablePanelIndex);
      } finally {
        _currentlyUpdatingTablePanelIndex = null;
      }
      if (newChild != null) {
        _childElements[tablePanelIndex] = newChild;
      } else {
        _childElements.remove(tablePanelIndex);
      }
    });
  }

  @override
  bool debugAssertChildListLocked() {
    assert(_currentlyUpdatingTablePanelIndex == null);
    return true;
  }

  @override
  void didAdoptChild(RenderBox child) {
    assert(_currentlyUpdatingTablePanelIndex != null);
    final TablePanelParentData childParentData =
        child.parentData as TablePanelParentData;
    childParentData.tablePanelIndex = _currentlyUpdatingTablePanelIndex!;
  }

  @override
  void didFinishLayout() {
    widget.viewModel.didFinishLayout();
  }

  @override
  void didStartLayout() {
    widget.viewModel.didStartLayout();
  }

  @override
  void removeChild(RenderBox child) {
    final int tablePanelIndex = renderObject.panelIndexOf(child);
    assert(_currentlyUpdatingTablePanelIndex == null);

    owner!.buildScope(this, () {
      assert(_childElements.containsKey(tablePanelIndex));
      try {
        _currentlyUpdatingTablePanelIndex = tablePanelIndex;
        final Element? result =
            updateChild(_childElements[tablePanelIndex], null, tablePanelIndex);
        assert(result == null);
      } finally {
        _currentlyUpdatingTablePanelIndex = null;
      }
      _childElements.remove(tablePanelIndex);
      assert(!_childElements.containsKey(tablePanelIndex));
    });
  }

  @override
  void setDidUnderflow(bool value) {}

  Widget? _build(int panelIndex) {
    return _childWidgets.putIfAbsent(panelIndex, () {
      return widget.builder(this, panelIndex);
    });
  }
}

class TableMultiPanelRenderViewport<T extends AbstractFtModel<C>,
        C extends AbstractCell> extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, TablePanelParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, TablePanelParentData> {
  TableMultiPanelRenderViewport({
    required FtViewModel<T, C> viewModel,
    required this.childManager,
    required double tableScale,
    required AbstractTableBuilder tableBuilder,
  })  : _viewModel = viewModel,
        _tableScale = tableScale,
        _tableBuilder = tableBuilder;

  TableMultiPanelRenderChildManager childManager;
  FtViewModel<T, C> _viewModel;
  double _tableScale;
  AbstractTableBuilder _tableBuilder;

  FtViewModel<T, C> get viewModel => _viewModel;

  set viewModel(FtViewModel<T, C> value) {
    if (value == _viewModel) return;
    if (attached) _viewModel.removeListener(markNeedsLayout);
    _viewModel = value;
    if (attached) _viewModel.addListener(markNeedsLayout);

    markNeedsLayout();
  }

  double get tableScale => _tableScale;

  set tableScale(double value) {
    if (value == _tableScale) return;
    _tableScale = value;
    markNeedsLayout();
  }

  AbstractTableBuilder get tableBuilder => _tableBuilder;

  set tableBuilder(AbstractTableBuilder value) {
    if (value == _tableBuilder) return;
    _tableBuilder = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! TablePanelParentData) {
      child.parentData = TablePanelParentData();
    }
  }

  @override
  void performResize() {
    super.performResize();
    // default behavior for subclasses that have sizedByParent = true
    assert(size.isFinite);
  }

  @override
  void performLayout() {
    size = constraints.biggest;

    childManager.didStartLayout();
    childManager.setDidUnderflow(false);

    viewModel.calculate(
        width: constraints.maxWidth, height: constraints.maxHeight);

    if (firstChild != null) {
      collectGarbage();
    }

    RenderBox? child;

    late int indexFirstChild;

    if (firstChild != null) {
      child = firstChild;
      indexFirstChild =
          (firstChild!.parentData as TablePanelParentData).tablePanelIndex;
    }

    final splitIterator = _SplitIterator(viewModel);

    while (splitIterator.moveNext()) {
      final tablePanelIndex = splitIterator.current;
      final layoutIndex = _viewModel.layoutPanelIndex(tablePanelIndex);

      GridLayout layoutX = viewModel.widthLayoutList[layoutIndex.xIndex];
      GridLayout layoutY = viewModel.heightLayoutList[layoutIndex.yIndex];

      if (firstChild == null) {
        child = insertAndLayoutFirstChild(after: null, index: tablePanelIndex);
        indexFirstChild = tablePanelIndex;

        assert(tablePanelIndex ==
            (firstChild!.parentData as TablePanelParentData).tablePanelIndex);
      } else {
        assert(child != null,
            'child can not be null in next $tablePanelIndex ${firstChild == null}');
        TablePanelParentData parentData =
            child!.parentData as TablePanelParentData;

        if (parentData.tablePanelIndex < tablePanelIndex) {
          child =
              findOrInsert(child: child, index: tablePanelIndex, forward: true);
        } else if (tablePanelIndex < indexFirstChild) {
          child =
              insertAndLayoutFirstChild(after: null, index: tablePanelIndex);
          indexFirstChild = tablePanelIndex;

          assert(tablePanelIndex ==
              (firstChild!.parentData as TablePanelParentData).tablePanelIndex);
        } else {
          child = findOrInsert(
              child: child, index: tablePanelIndex, forward: false);
        }
      }

      layoutChild(
          child: child,
          x: layoutX.gridPosition,
          y: layoutY.gridPosition,
          width: layoutX.gridLength,
          height: layoutY.gridLength);
    }

    // scrollPosition.applyTableDimensions(layoutX: tableModel.widthLayoutList, layoutY: tableModel.heightLayoutList);

    childManager.didFinishLayout();

    // Clean the for the viewPanels the refresh.
    viewModel.cellsToRemove.clear();
  }

  // RenderBox findOrInsert({required RenderBox child, required int index, required bool forward}) {
  //   // assert(child != null);
  //   assert(child.parent == this);

  //   final shiftSibling = forward
  //       ? (TablePanelParentData parentData) => parentData.nextSibling
  //       : (TablePanelParentData parentData) => parentData.previousSibling;
  //   final compare =
  //       forward ? (index, parentIndex) => parentIndex < index : (index, parentIndex) => index <= parentIndex;

  //   TablePanelParentData parentData = child.parentData as TablePanelParentData;
  //   RenderBox? shiftChild = shiftSibling(parentData);

  //   while (shiftChild != null) {
  //     parentData = shiftChild.parentData as TablePanelParentData;

  //     if (compare(index, parentData.tablePanelIndex)) {
  //       child = shiftChild;
  //     } else {
  //       break;
  //     }

  //     shiftChild = shiftSibling(parentData);
  //   }

  //   if ((child.parentData as TablePanelParentData).tablePanelIndex != index) {
  //     child = insertAndLayoutChild(after: child, index: index);
  //     assert(index == (child.parentData as TablePanelParentData).tablePanelIndex);
  //   }

  //   return child;
  // }

  RenderBox findOrInsert(
      {required RenderBox child, required int index, required bool forward}) {
    // assert(child != null);
    assert(child.parent == this);

    TablePanelParentData parentData = child.parentData as TablePanelParentData;

    if (parentData.tablePanelIndex == index) {
      return child;
    }

    RenderBox? shiftChild;

    if (forward) {
      shiftChild = parentData.nextSibling;

      while (shiftChild != null) {
        parentData = shiftChild.parentData as TablePanelParentData;

        if (parentData.tablePanelIndex <= index) {
          child = shiftChild;
        } else {
          break;
        }

        shiftChild = parentData.nextSibling;
      }
      assert(
          (child.parentData as TablePanelParentData).tablePanelIndex <= index);
    } else {
      shiftChild = parentData.previousSibling;
      while (shiftChild != null) {
        parentData = shiftChild.parentData as TablePanelParentData;

        if (index >= parentData.tablePanelIndex) {
          child = shiftChild;
          break;
        }

        shiftChild = parentData.previousSibling;
      }

      assert(
          index >= (child.parentData as TablePanelParentData).tablePanelIndex);
    }

    if ((child.parentData as TablePanelParentData).tablePanelIndex != index) {
      child = insertAndLayoutChild(after: child, index: index);
      assert(
          index == (child.parentData as TablePanelParentData).tablePanelIndex);
    }

    return child;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    RenderBox? child = lastChild;

    // zie defaultHitTestChildren

    while (child != null) {
      final TablePanelParentData tablePanelParentData =
          child.parentData as TablePanelParentData;

      final bool isHit = result.addWithPaintOffset(
        offset: tablePanelParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          assert(transformed == position - tablePanelParentData.offset);
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) return true;
      child = tablePanelParentData.previousSibling;
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @protected
  RenderBox insertAndLayoutFirstChild({
    required RenderBox? after,
    required int index,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, after: after);

    assert(firstChild != null);
    TablePanelParentData parentData =
        firstChild!.parentData as TablePanelParentData;
    assert(index == parentData.tablePanelIndex);

    return firstChild!;
  }

  @protected
  RenderBox insertAndLayoutChild({
    required RenderBox after,
    required int index,
    bool parentUsesSize = false,
  }) {
    assert(_debugAssertChildListLocked());

    _createOrObtainChild(index, after: after);
    final RenderBox? child = childAfter(after);

    assert(
        child != null && panelIndexOf(child) == index,
        (child == null)
            ? 'insertAndLayoutChild is null'
            : 'insertAndLayoutChild child after has panelIndex: ${panelIndexOf(child)} should be  $index');

    return child!;
  }

  void layoutChild({
    required RenderBox child,
    required double x,
    required double y,
    required double width,
    required double height,
    bool parentUsesSize = false,
  }) {
    //print('width $width height $height');
    BoxConstraints constraints =
        BoxConstraints.tightFor(width: width, height: height);
    child.layout(constraints, parentUsesSize: parentUsesSize);
    final TablePanelParentData parentData =
        child.parentData as TablePanelParentData;
    parentData.offset = Offset(x, y);
  }

  void _createOrObtainChild(int index, {RenderBox? after}) {
    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      assert(constraints == this.constraints);
      childManager.createChild(index, after: after);
    });
  }

  // RenderBox findChildByIndex({RenderBox child, TablePanelIndex index}) {
  //   child = childAfter(child);

  //   while (child != null && index < (child.parentData as TablePanelParentData).tablePanelIndex) {
  //     child = childAfter(child);
  //   }

  //   return child;
  // }

  @override
  void adoptChild(RenderObject child) {
    super.adoptChild(child);
    //final TablePanelParentData childParentData = child.parentData;
    //if (!childParentData._keptAlive)
    childManager.didAdoptChild(child as RenderBox);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return viewModel.computeMaxIntrinsicWidth(height);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return viewModel.computeMaxIntrinsicHeight(width);
  }

  void collectGarbage() {
    assert(_debugAssertChildListLocked());

    invokeLayoutCallback<BoxConstraints>((BoxConstraints constraints) {
      RenderBox? child = firstChild;

      while (child != null) {
        final parentData = child.parentData as TablePanelParentData;
        final layoutIndex =
            _viewModel.layoutPanelIndex(parentData.tablePanelIndex);
        final nextChild = childAfter(child);

        if (!(viewModel.rowVisible(layoutIndex.yIndex) &&
            viewModel.columnVisible(layoutIndex.xIndex))) {
          childManager.removeChild(child);
        }

        child = nextChild;
      }
    });
  }

  bool _debugAssertChildListLocked() =>
      childManager.debugAssertChildListLocked();

  int panelIndexOf(RenderBox child) {
    // assert(child != null);
    final TablePanelParentData childParentData =
        child.parentData as TablePanelParentData;
    // assert(childParentData.tablePanelIndex != null);
    return childParentData.tablePanelIndex;
  }

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
      int index;
      while (child != null) {
        index = panelIndexOf(child);
        child = childAfter(child);
        assert(child == null || panelIndexOf(child) > index);
      }
    }
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);

    tableBuilder.finalPaintMainPanel(_viewModel, context, offset, size);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _viewModel.addListener(markNeedsLayout);
  }

  @override
  void detach() {
    _viewModel.removeListener(markNeedsLayout);
    super.detach();
  }
}

class TablePanelParentData extends ContainerBoxParentData<RenderBox> {
  int tablePanelIndex = 0;
  double leftMargin = 0.0;
  double topMargin = 0.0;
  double rightMargin = 0.0;
  double bottomMargin = 0.0;
}

class LayoutPanelIndex implements Comparable<LayoutPanelIndex> {
  int xIndex;
  int yIndex;

  LayoutPanelIndex({required this.xIndex, required this.yIndex});

  bool operator >(LayoutPanelIndex index) {
    return yIndex > index.yIndex ||
        (yIndex == index.yIndex && xIndex > index.xIndex);
  }

  bool operator <=(LayoutPanelIndex index) {
    return yIndex < index.yIndex ||
        (yIndex == index.yIndex && xIndex <= index.xIndex);
  }

  bool operator <(LayoutPanelIndex index) {
    return yIndex < index.yIndex ||
        (yIndex == index.yIndex && xIndex < index.xIndex);
  }

  int get scrollIndexX => xIndex < 2 ? 0 : 1;

  int get scrollIndexY => yIndex < 2 ? 0 : 1;

  bool get isRowHeader => xIndex == 0 || xIndex == 3;

  bool get isColumnHeader => yIndex == 0 || yIndex == 3;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LayoutPanelIndex &&
          runtimeType == other.runtimeType &&
          xIndex == other.xIndex &&
          yIndex == other.yIndex;

  @override
  int get hashCode => xIndex.hashCode ^ yIndex.hashCode;

  @override
  String toString() {
    return 'TablePanelIndex{IndexX: $xIndex, indexY: $yIndex}';
  }

  @override
  int compareTo(LayoutPanelIndex other) {
    return (yIndex < other.yIndex ||
            (yIndex == other.yIndex && xIndex < other.xIndex))
        ? -1
        : ((yIndex == other.yIndex && xIndex == other.xIndex) ? 0 : 1);
  }
}

abstract class TableMultiPanelRenderChildManager {
  void createChild(int tablePanelIndex, {required RenderBox? after});

  void removeChild(RenderBox child);

  void didAdoptChild(RenderBox child);

  void setDidUnderflow(bool value);

  void didStartLayout();

  void didFinishLayout();

  bool debugAssertChildListLocked() => true;
}
