import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';

abstract class FlexTableContext {
  BuildContext? get notificationContext;

  BuildContext get storageContext;

  /// A [TickerProvider] to use when animating the scroll position.
  TickerProvider get vsync;

  /// The direction in which the widget scrolls.
  AxisDirection get axisDirection;

  /// The [FlutterView.devicePixelRatio] of the view that the [Scrollable] this
  /// [FlexTableContext] is associated with is drawn into.
  double get devicePixelRatio;

  void setState(VoidCallback fn);

  void setIgnorePointer(bool value);

  /// Whether the user can drag the widget, for example to initiate a scroll.
  void setCanDrag(bool value);

  /// Set the [SemanticsAction]s that should be expose to the semantics tree.
  void setSemanticsActions(Set<SemanticsAction> actions);

  /// Called by the [ScrollPosition] whenever scrolling ends to persist the
  /// provided scroll `offset` for state restoration purposes.
  ///
  /// The [FlexTableContext] may pass the value back to a [ScrollPosition] by
  /// calling [ScrollPosition.restoreOffset] at a later point in time or after
  /// the application has restarted to restore the scroll offset.
  void saveOffset(double offset);
}
