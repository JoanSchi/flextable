// Copyright (C) 2023 Joan Schipper
// 
// This file is part of flextable.
// 
// flextable is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// flextable is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with flextable.  If not, see <http://www.gnu.org/licenses/>.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

typedef HitTestCallback = bool Function(Offset position);

class FlexTableHit extends SingleChildRenderObjectWidget {
  final HitTestCallback hit;

  const FlexTableHit({
    Key? key,
    required this.hit,
    Widget? child,
  }) : super(key: key, child: child);

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
