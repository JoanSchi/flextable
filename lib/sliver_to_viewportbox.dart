import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// class Cont extends StatefulWidget {
//   ScrollController scrollController;
//   final sheet;

//   Cont({this.sheet, this.scrollController});

//   @override
//   _ContState createState() => _ContState();
// }

// class _ContState extends State<Cont> {
// ScrollPosition scrollPosition;

//   didChangeDependencies(){
//     super.didChangeDependencies();
//     scrollPosition = widget.scrollController.position;
//     assert(scrollPosition != null);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SliverToViewPortBox(delegate: FlexTableToViewPortBoxDelegate(sheetModelDelegate: widget.sheet,sliverController: widget.scrollController), scrollPosition: scrollPosition,);
//   }
// }

abstract class SliverToViewPortBoxDelegate {
  // double maxExtent;
  // Widget child;

  // SliverToViewPortBoxDelegate({required this.child, required this.maxExtent});

  Widget build(BuildContext context, double shrinkOffset, double paintExtent);

  // Widget build(BuildContext context, double shrinkOffset, double paintExtent) {
  //   return Stack(
  //     children: [
  //       Container(color: Colors.deepPurple),
  //       Positioned(
  //           left: 0,
  //           top: shrinkOffset + 20,
  //           right: 0,
  //           bottom: maxExtent - shrinkOffset - paintExtent + 20.0,
  //           child: Container(color: Colors.yellow)),
  //       Positioned(
  //         left: 20,
  //         top: shrinkOffset + 20,
  //         right: 20,
  //         height: 50,
  //         child: OverflowBox(
  //           alignment: Alignment.topLeft,
  //           minWidth: 0.0,
  //           maxHeight: 50,
  //           child: Column(
  //               crossAxisAlignment: CrossAxisAlignment.start,
  //               children: [Text('maxExtent $maxExtent shrinkOffset $shrinkOffset '), Text('paintExtent $paintExtent')]),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  sliverScroll(double offset);

  bool shouldRebuild(covariant SliverToViewPortBoxDelegate oldDelegate) => true;
}

class SliverToViewPortBox extends RenderObjectWidget {
  final SliverToViewPortBoxDelegate delegate;

  SliverToViewPortBox({Key? key, required this.delegate}) : super(key: key);

  @override
  RenderObject createRenderObject(BuildContext context) => RenderSliverToViewPortBox();

  @override
  SliverToViewPortBoxRenderObjectElement createElement() => SliverToViewPortBoxRenderObjectElement(this);
}

class SliverToViewPortBoxRenderObjectElement extends RenderObjectElement {
  // afgeleid van SingleChildRenderObjectElement
  /// Creates an element that uses the given widget as its configuration.
  SliverToViewPortBoxRenderObjectElement(SliverToViewPortBox widget) : super(widget);

  @override
  SliverToViewPortBox get widget => super.widget as SliverToViewPortBox;

  @override
  RenderSliverToViewPortBox get renderObject => super.renderObject as RenderSliverToViewPortBox;

  Element? _child;

  @override
  void visitChildren(ElementVisitor visitor) {
    if (_child != null) visitor(_child!);
  }

  @override
  void forgetChild(Element child) {
    super.forgetChild(child);

    assert(child == _child);
    _child = null;
  }

  @override
  void mount(Element? parent, dynamic newSlot) {
    super.mount(parent, newSlot);
    renderObject._element = this;
  }

  //origneel
//  @override
//  void mount(Element parent, dynamic newSlot) {
//    super.mount(parent, newSlot);
//    _child = updateChild(_child, widget.child, null);
//  }

  @override
  void unmount() {
    renderObject._element = null;
    super.unmount();
  }

  @override
  void update(SliverToViewPortBox newWidget) {
    final SliverToViewPortBox oldWidget = widget;
    super.update(newWidget);
    final SliverToViewPortBoxDelegate newDelegate = newWidget.delegate;
    final SliverToViewPortBoxDelegate oldDelegate = oldWidget.delegate;
    if (newDelegate != oldDelegate &&
        (newDelegate.runtimeType != oldDelegate.runtimeType || newDelegate.shouldRebuild(oldDelegate))) {
      renderObject.triggerRebuild();
    }
  }

  @override
  void insertRenderObjectChild(covariant RenderBox child, Object? slot) {
    // final RenderObjectWithChildMixin<RenderObject> renderObject =
    //     this.renderObject;
    // assert(slot == null);
    assert(renderObject.debugValidateChild(child));
    renderObject.child = child;
    assert(renderObject == this.renderObject);
  }

  @override
  void moveRenderObjectChild(RenderObject child, Object? oldSlot, Object? newSlot) {
    assert(false);
  }

  @override
  void removeRenderObjectChild(covariant RenderObject child, Object? slot) {
    final RenderObjectWithChildMixin<RenderObject> renderObject = this.renderObject;
    assert(renderObject.child == child);
    renderObject.child = null;
    assert(renderObject == this.renderObject);
  }

  void _build(double shrinkOffset, double paintExtent) {
    owner?.buildScope(this, () {
      _child = updateChild(_child, widget.delegate.build(this, shrinkOffset, paintExtent), null);
    });
  }
}

class RenderSliverToViewPortBox extends RenderSliverSingleBoxAdapter {
  RenderSliverToViewPortBox({RenderBox? child}) : super(child: child);

  SliverToViewPortBoxRenderObjectElement? _element;

  double get maxExtent => 800; //_element.widget.delegate.maxExtent;

  Function(double offset) get sliverScroll => _element!.widget.delegate.sliverScroll;

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalParentData) child.parentData = SliverPhysicalParentData();
  }

  void updateChild(double shrinkOffset, double paintExtent) {
    assert(_element != null);
    _element!._build(shrinkOffset, paintExtent);
  }

  //Belangrijk voor hittest!

  @override
  double childMainAxisPosition(RenderBox child) {
    return 0.0;
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
  }

  @override
  void detach() {
    super.detach();
  }

  //  @override
  // bool hitTestChildren(SliverHitTestResult result, { @required double mainAxisPosition, @required double crossAxisPosition }) {
  //   //super.hitTest(result, mainAxisPosition: null, crossAxisPosition: null)
  //   assert(geometry.hitTestExtent > 0.0);
  //   //mainAxisPosition -= constraints.scrollOffset;
  //  print('mainAxisPosition $mainAxisPosition crossAxisPosition $crossAxisPosition $constraints.scrollOffset');
  //  //result.pushTransform(Matrix4.zero()..translate(0.0, -constraints.scrollOffset));
  //  bool hit = false;
  //   if (child != null){
  //     hit = hitTestBoxChild(BoxHitTestResult.wrap(result), child, mainAxisPosition: mainAxisPosition, crossAxisPosition: crossAxisPosition);
  //   }
  //   print('hit_______________> $hit');
  //   return hit;
  // }

  @override
  void performLayout() {
    // if (child == null) {
    //   geometry = SliverGeometry.zero;
    //   return;
    // }
//
//
//
//    child.layout(constraints.asBoxConstraints(maxExtent: 200), parentUsesSize: true);
//    double childExtent;
//    switch (constraints.axis) {
//      case Axis.horizontal:
//        childExtent = child.size.width;
//        break;
//      case Axis.vertical:
//        childExtent = child.size.height;
//        break;
//    }
//    childExtent = 500;
//    assert(childExtent != null);
//    final double paintedChildSize =
//        calculatePaintOffset(constraints, from: 0.0, to: childExtent);
//    final double cacheExtent =
//        calculateCacheOffset(constraints, from: 0.0, to: childExtent);
//
//    assert(paintedChildSize.isFinite);
//    assert(paintedChildSize >= 0.0);
//    geometry = SliverGeometry(
//      scrollExtent: childExtent,
//      paintExtent: paintedChildSize,
//      cacheExtent: cacheExtent,
//      maxPaintExtent: childExtent,
//      hitTestExtent: paintedChildSize,
//      hasVisualOverflow: childExtent > constraints.remainingPaintExtent ||
//          constraints.scrollOffset > 0.0,
//    );
//
//    final e = (geometry.paintExtent > 100.0) ? geometry.paintExtent - 50.0 : geometry.paintExtent;
//
//    child.layout(constraints.asBoxConstraints(maxExtent: e), parentUsesSize: true);
//
//
//
//    setChildParentData(child, constraints, geometry);
//
//    final g = parentData as SliverPhysicalParentData;
//    print('parentdata ${parentData} ${g.paintOffset}');
//
//    final i = (child.parentData as SliverPhysicalParentData);
//    print('paintOffset ${i.paintOffset}, paintExtent ${geometry.paintExtent}');

    _updateChild(0, 0);
    //print('height ${child.getMaxIntrinsicHeight(2000)}');

    double min = child!.getMinIntrinsicHeight(0);
    double maxExtent = child!.getMaxIntrinsicHeight(0);

    double innerSliverScroll = maxExtent - min;

    if (constraints.scrollOffset < innerSliverScroll) {
      innerSliverScroll = constraints.scrollOffset;
    }

    sliverScroll(innerSliverScroll);

    double childExtent = maxExtent;

    // assert(childExtent != null);
    final double paintedChildSize = calculatePaintOffset(constraints, from: 0.0, to: childExtent);
    final double cacheExtent = calculateCacheOffset(constraints, from: 0.0, to: childExtent);

    //print('paintedChildSize $paintedChildSize');
    geometry = SliverGeometry(
        scrollExtent: childExtent,
        paintExtent: paintedChildSize,
        cacheExtent: cacheExtent,
        maxPaintExtent: childExtent,
        hitTestExtent: paintedChildSize,
        hasVisualOverflow: false);

    layoutChild(constraints.scrollOffset, paintedChildSize);
    //SetChildParentData moet na layoutchild!
    setChildParentData(child!, constraints, geometry!);
  }

  @protected
  void setChildParentData(RenderObject child, SliverConstraints constraints, SliverGeometry geometry) {
    final SliverPhysicalParentData childParentData = child.parentData as SliverPhysicalParentData;
    // assert(constraints.axisDirection != null);
    // assert(constraints.growthDirection != null);

    // switch (applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection)) {
    //   case AxisDirection.up:
    //     childParentData.paintOffset = Offset(0.0, -(geometry.scrollExtent - (geometry.paintExtent + constraints.scrollOffset)));
    //     break;
    //   case AxisDirection.right:
    //     childParentData.paintOffset = Offset(-constraints.scrollOffset, 0.0);
    //     break;
    //   case AxisDirection.down:
    //     childParentData.paintOffset = Offset(0.0, constraints.scrollOffset);
    //     break;
    //   case AxisDirection.left:
    //     childParentData.paintOffset = Offset(-(geometry.scrollExtent - (geometry.paintExtent + constraints.scrollOffset)), 0.0);
    //     break;
    // }

    assert(
        applyGrowthDirectionToAxisDirection(constraints.axisDirection, constraints.growthDirection) ==
            AxisDirection.down,
        'Only Axis direction down is supported');
    childParentData.paintOffset = Offset(0.0, 0.0);
  }

  void _updateChild(double scrollOffset, double paintExtent) {
    invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
      assert(constraints == this.constraints);
      updateChild(scrollOffset, paintExtent);
    });
  }

  @protected
  void layoutChild(double scrollOffset, double paintExtent) {
    //print('layout scrollOffset $scrollOffset paintExtent $paintExtent');

    final SliverPhysicalParentData parentData = child!.parentData as SliverPhysicalParentData;

    parentData.paintOffset = Offset(0.0, scrollOffset);

    child!.layout(
      constraints.asBoxConstraints(maxExtent: paintExtent),
      parentUsesSize: true,
    );

//    final double shrinkOffset = math.min(scrollOffset, maxExtent);
//    if (_needsUpdateChild || _lastShrinkOffset != shrinkOffset || _lastOverlapsContent != overlapsContent) {
//      invokeLayoutCallback<SliverConstraints>((SliverConstraints constraints) {
//        assert(constraints == this.constraints);
//        updateChild(shrinkOffset, overlapsContent);
//      });
//      _lastShrinkOffset = shrinkOffset;
//      _lastOverlapsContent = overlapsContent;
//      _needsUpdateChild = false;
//    }
//    assert(minExtent != null);
//    assert(() {
//      if (minExtent <= maxExtent)
//        return true;
//      throw FlutterError(
//          'The maxExtent for this $runtimeType is less than its minExtent.\n'
//              'The specified maxExtent was: ${maxExtent.toStringAsFixed(1)}\n'
//              'The specified minExtent was: ${minExtent.toStringAsFixed(1)}\n'
//      );
//    }());
//
//    child?.layout(
//      constraints.asBoxConstraints(maxExtent: math.max(minExtent, maxExtent - shrinkOffset)),
//      parentUsesSize: true,
//    );
  }

  @protected
  void triggerRebuild() {
    markNeedsLayout();
  }
}
