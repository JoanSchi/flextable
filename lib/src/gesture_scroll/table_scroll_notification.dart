// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';
import '../model/scroll_metrics.dart';
import 'table_drag_details.dart';

abstract class TableScrollNotification extends LayoutChangedNotification
    with ViewportNotificationMixin {
  /// Initializes fields for subclasses.
  TableScrollNotification({
    required this.metrics,
    required this.context,
  });

  final TableScrollMetrics metrics;
  final BuildContext? context;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('$metrics');
  }
}

// mixin ViewportNotificationMixin on Notification {
//   int get depth => _depth;
//   int _depth = 0;
//   int _realDepth = 0;

//   @override
//   bool visitAncestor(Element element) {
//     if (element is RenderObjectElement && element.renderObject is RenderAbstractViewport) _depth += 1;
//     _realDepth++;
//     assert(_realDepth < 14, 'The search for TableScrollListener is going to deep!');
//     return super.visitAncestor(element);
//   }

//   @override
//   void debugFillDescription(List<String> description) {
//     super.debugFillDescription(description);
//     description.add('depth: $depth (${depth == 0 ? "local" : "remote"})');
//   }
// }

class TableScrollUpdateNotification extends TableScrollNotification {
  /// Creates a notification that a [Scrollable] widget has changed its scroll
  /// position.
  TableScrollUpdateNotification({
    required super.metrics,
    super.context,
    this.updateDragDetails,
    this.scrollDelta,
  });

  /// If the [Scrollable] changed its scroll position because of a drag, the
  /// details about that drag update.
  ///
  /// Otherwise, null.
  final TableDragUpdateDetails? updateDragDetails;

  /// The distance by which the [Scrollable] was scrolled, in logical pixels.
  final Offset? scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (updateDragDetails != null) description.add('$updateDragDetails');
  }
}

class TableScrollStartNotification extends TableScrollNotification {
  /// Creates a notification that a [Scrollable] widget has changed its scroll
  /// position.
  TableScrollStartNotification({
    required super.metrics,
    super.context,
    this.dragDetails,
    this.scrollDelta,
  });

  /// If the [Scrollable] changed its scroll position because of a drag, the
  /// details about that drag update.
  ///
  /// Otherwise, null.
  final DragStartDetails? dragDetails;

  /// The distance by which the [Scrollable] was scrolled, in logical pixels.
  final Offset? scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (dragDetails != null) description.add('$dragDetails');
  }
}

class TableScrollEndNotification extends TableScrollNotification {
  /// Creates a notification that a [Scrollable] widget has changed its scroll
  /// position.
  TableScrollEndNotification({
    required super.metrics,
    super.context,
    this.endDragDetails,
    this.scrollDelta,
  });

  /// If the [Scrollable] changed its scroll position because of a drag, the
  /// details about that drag update.
  ///
  /// Otherwise, null.
  final TableDragEndDetails? endDragDetails;

  /// The distance by which the [Scrollable] was scrolled, in logical pixels.
  final Offset? scrollDelta;

  @override
  void debugFillDescription(List<String> description) {
    super.debugFillDescription(description);
    description.add('scrollDelta: $scrollDelta');
    if (endDragDetails != null) description.add('$endDragDetails');
  }
}
