// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef HitTestCallback = bool Function(Offset position);

class HitBox extends SingleChildRenderObjectWidget {
  const HitBox({
    super.key,
    required this.hit,
    super.child,
  });

  final HitTestCallback hit;

  @override
  RenderHitContainer createRenderObject(BuildContext context) {
    return RenderHitContainer(hit: hit);
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderHitContainer renderObject) {
    renderObject.hit = hit;
  }
}

class RenderHitContainer extends RenderProxyBox {
  HitTestCallback _hit;

  RenderHitContainer({
    RenderBox? child,
    required HitTestCallback hit,
  })  : _hit = hit,
        super(child);

  set hit(HitTestCallback value) {
    if (value == _hit) return;
    _hit = value;
  }

  @override
  void performLayout() {
    if (child != null) {
      final Constraints tight = BoxConstraints.tight(constraints.biggest);
      child!.layout(tight, parentUsesSize: true);
      size = child!.size;
    } else {
      size = constraints.biggest;
    }
  }

  // @override
  // bool hitTest(BoxHitTestResult result, {required Offset position}) {
  //   if (_hitDelegate.hit(position) && hitTestChildren(result, position: position)) {
  //     result.add(BoxHitTestEntry(this, position));
  //     return true;
  //   }

  //   return false;
  // }

  @override
  bool hitTestSelf(Offset position) => _hit(position);
}
