// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MultiHitStack extends MultiChildRenderObjectWidget {
  /// Creates a stack layout widget.
  ///
  /// By default, the non-positioned children of the stack are aligned by their
  /// top left corners.
  const MultiHitStack({
    super.key,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.fit = StackFit.loose,
    this.clipBehavior = Clip.hardEdge,
    super.children,
  });

  /// How to align the non-positioned and partially-positioned children in the
  /// stack.
  ///
  /// The non-positioned children are placed relative to each other such that
  /// the points determined by [alignment] are co-located. For example, if the
  /// [alignment] is [Alignment.topLeft], then the top left corner of
  /// each non-positioned child will be located at the same global coordinate.
  ///
  /// Partially-positioned children, those that do not specify an alignment in a
  /// particular axis (e.g. that have neither `top` nor `bottom` set), use the
  /// alignment to determine how they should be positioned in that
  /// under-specified axis.
  ///
  /// Defaults to [AlignmentDirectional.topStart].
  ///
  /// See also:
  ///
  ///  * [Alignment], a class with convenient constants typically used to
  ///    specify an [AlignmentGeometry].
  ///  * [AlignmentDirectional], like [Alignment] for specifying alignments
  ///    relative to text direction.
  final AlignmentGeometry alignment;

  /// The text direction with which to resolve [alignment].
  ///
  /// Defaults to the ambient [Directionality].
  final TextDirection? textDirection;

  /// How to size the non-positioned children in the stack.
  ///
  /// The constraints passed into the [Stack] from its parent are either
  /// loosened ([StackFit.loose]) or tightened to their biggest size
  /// ([StackFit.expand]).
  final StackFit fit;

  /// {@macro flutter.material.Material.clipBehavior}
  ///
  /// Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  bool _debugCheckHasDirectionality(BuildContext context) {
    if (alignment is AlignmentDirectional && textDirection == null) {
      assert(
        debugCheckHasDirectionality(context,
            why: 'to resolve the \'alignment\' argument',
            hint: alignment == AlignmentDirectional.topStart
                ? 'The default value for \'alignment\' is AlignmentDirectional.topStart, which requires a text direction.'
                : null,
            alternative:
                'Instead of providing a Directionality widget, another solution would be passing a non-directional \'alignment\', or an explicit \'textDirection\', to the $runtimeType.'),
      );
    }
    return true;
  }

  @override
  RenderStack createRenderObject(BuildContext context) {
    assert(_debugCheckHasDirectionality(context));
    return MultiHitRenderStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, MultiHitRenderStack renderObject) {
    assert(_debugCheckHasDirectionality(context));
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<AlignmentGeometry>('alignment', alignment));
    properties.add(EnumProperty<TextDirection>('textDirection', textDirection,
        defaultValue: null));
    properties.add(EnumProperty<StackFit>('fit', fit));
    properties.add(EnumProperty<Clip>('clipBehavior', clipBehavior,
        defaultValue: Clip.hardEdge));
  }
}

class MultiHitRenderStack extends RenderStack {
  /// Creates a stack render object.
  ///
  /// By default, the non-positioned children of the stack are aligned by their
  /// top left corners.
  MultiHitRenderStack({
    super.children,
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // return defaultHitTestChildren(result, position: position);

    bool oneOfMoreHit = false;

    RenderBox? child = lastChild;
    while (child != null) {
      final StackParentData childParentData =
          child.parentData! as StackParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: childParentData.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset? transformed) {
          assert(transformed == position - childParentData.offset);
          return child!.hitTest(result, position: transformed!);
        },
      );
      if (isHit) oneOfMoreHit = true;
      child = childParentData.previousSibling;
    }
    return oneOfMoreHit;
  }
}
