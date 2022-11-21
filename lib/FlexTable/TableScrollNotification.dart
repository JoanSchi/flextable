import 'package:flutter/widgets.dart';
import 'TableDragDetails.dart';
import 'TableScroll.dart';

abstract class TableScrollNotification extends LayoutChangedNotification with ViewportNotificationMixin {
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
    required TableScrollMetrics metrics,
    BuildContext? context,
    this.updateDragDetails,
    this.scrollDelta,
  }) : super(metrics: metrics, context: context);

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
    required TableScrollMetrics metrics,
    BuildContext? context,
    this.dragDetails,
    this.scrollDelta,
  }) : super(metrics: metrics, context: context);

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
    required TableScrollMetrics metrics,
    BuildContext? context,
    this.endDragDetails,
    this.scrollDelta,
  }) : super(metrics: metrics, context: context);

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
