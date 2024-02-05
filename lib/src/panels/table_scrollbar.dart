// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:ui';
import '../../flextable.dart';
import '../listeners/inner_change_notifiers.dart';
import '../model/view_model.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../gesture_scroll/table_drag_details.dart';
import '../gesture_scroll/table_gesture.dart';
import '../model/scroll_metrics.dart';
import 'dart:math' as math;

const double _kMinThumbExtent = 18.0;
const double _kMinThumbHitExtent = 32.0;
const double _kMinInteractiveSize = 48.0;

//const double _kHitThickness = 32.0;
const double _kThumbSize = 6.0;
const double _kPaddingOutside = 2.0;
const double _kPaddingTrackOutside = 0.0;
const double _kPaddingTrackInside = 0.0;
const double _kPaddingSeparateTrackOutside = 2.0;
const double _kPaddingSeparateTrackInside = 2.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

class TableScrollbar extends StatefulWidget {
  const TableScrollbar({
    super.key,
    this.isAlwaysShown = false,
    this.scrollBarTrack = false,
    this.thumbSize,
    this.paddingInside,
    this.paddingOutside,
    this.paddingTrackOutside,
    this.paddingTrackInside,
    this.radius,
    this.roundedCorners = true,
    this.canDrag = true,
    required this.viewModel,
    required this.scrollChangeNotifier,
    this.platformIndependent = false,
  });

  final FtViewModel viewModel;
  final InnerScrollChangeNotifier scrollChangeNotifier;
  final bool isAlwaysShown;
  final double? thumbSize;
  final double? paddingInside;
  final double? paddingOutside;
  final bool scrollBarTrack;
  final bool roundedCorners;
  final Radius? radius;
  final bool canDrag;
  final bool platformIndependent;
  final double? paddingTrackOutside;
  final double? paddingTrackInside;

  @override
  State<TableScrollbar> createState() => _TableScrollbarState();
}

class _TableScrollbarState extends State<TableScrollbar>
    with TickerProviderStateMixin {
  Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};
  TableScrollDirection _lastScrollDirection = TableScrollDirection.unknown;
  bool _lastCanDrag = false;
  Color _thumbColor = Colors.blue;
  Color _trackColor = const Color.fromARGB(255, 245, 245, 245);
  late AnimationController _fadeoutAnimationController;
  late Animation<double> _fadeoutOpacityAnimation;
  late ScrollbarPainter _scrollbarPainter;
  late ScrollBarSelection scrollBarSelection;
  TableDrag? _drag;
  Timer? _fadeoutTimer;
  Radius? radius;
  bool _isAlwaysShown = false;
  double _thumbSize = _kThumbSize;
  double _paddingOutside = _kPaddingOutside;
  // double _paddingInside = 0.0;
  double _paddingTrackInside = 0.0;
  double _paddingTrackOutside = 0.0;
  DeviceGestureSettings? _mediaQueryGestureSettings;
  late FtViewModel _viewModel;
  late InnerScrollChangeNotifier _scrollChangeNotifier;
  bool scrolling = false;

  @override
  void initState() {
    _viewModel = widget.viewModel;
    scrolling = _viewModel.scrolling;

    _scrollChangeNotifier = widget.scrollChangeNotifier
      ..addListener(changeScroll);

    scrollBarSelection = ScrollBarSelection();

    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _scrollbarPainter = _buildMaterialScrollbarPainter();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    _mediaQueryGestureSettings = MediaQuery.maybeGestureSettingsOf(context);
    updateValues();
    updateScrollBarPainter();

    super.didChangeDependencies();
  }

  @override
  void didUpdateWidget(TableScrollbar oldWidget) {
    if (_viewModel != widget.viewModel) {
      _viewModel = widget.viewModel;
    }

    if (_scrollChangeNotifier != widget.scrollChangeNotifier) {
      _scrollChangeNotifier.removeListener(changeScroll);
      _scrollChangeNotifier = widget.scrollChangeNotifier
        ..addListener(changeScroll);
    }

    _scrollbarPainter.viewModel = _viewModel;

    updateValues();
    updateScrollBarPainter();
    super.didUpdateWidget(oldWidget);
  }

  updateValues() {
    final ThemeData theme = Theme.of(context);

    if (widget.platformIndependent) {
      _isAlwaysShown = widget.isAlwaysShown;
      _thumbSize = _viewModel.thumbSize;

      _paddingOutside = _viewModel.paddingOutside;

      final scrollBarTrack = widget.scrollBarTrack;

      _paddingTrackOutside = widget.paddingTrackOutside ??
          (scrollBarTrack
              ? _kPaddingSeparateTrackOutside
              : _kPaddingTrackOutside);
      _paddingTrackInside = widget.paddingTrackInside ??
          (scrollBarTrack
              ? _kPaddingSeparateTrackInside
              : _kPaddingTrackInside);

      if (widget.roundedCorners) {
        radius = widget.radius ?? Radius.circular(_thumbSize / 2.0);
      }

      _thumbColor = Colors.grey[500]!.withOpacity(0.8);
    } else {
      switch (theme.platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          {
            _fadeoutAnimationController.value = 0.0;
            _isAlwaysShown = false;
            _thumbSize = _viewModel.thumbSize;
            _paddingOutside = _viewModel.paddingOutside;

            _paddingTrackOutside = widget.paddingTrackOutside ??
                _paddingOutside +
                    _thumbSize / 2.0 +
                    math.sqrt(math.pow(_thumbSize / 2.0, 2.0) / 2.0);
            _paddingTrackInside =
                widget.paddingTrackInside ?? _kPaddingTrackInside;
            if (widget.roundedCorners) {
              radius = widget.radius ?? Radius.circular(_thumbSize / 2.0);
            }

            _thumbColor = Colors.grey[500]!.withOpacity(0.8);

            break;
          }

        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          {
            _isAlwaysShown = true;
            _thumbSize = _viewModel.thumbSize;
            _paddingOutside = _viewModel.paddingOutside;

            _paddingTrackOutside =
                widget.paddingTrackOutside ?? _kPaddingSeparateTrackOutside;
            _paddingTrackInside =
                widget.paddingTrackInside ?? _kPaddingSeparateTrackInside;

            if (widget.roundedCorners) {
              radius = widget.radius ?? Radius.circular(_thumbSize / 2.0);
            }

            _fadeoutAnimationController.animateTo(1.0);

            _trackColor = const Color.fromARGB(255, 245, 245, 245);
            _thumbColor = Colors.grey[500]!.withOpacity(1.0);
          }
          break;
      }
    }
  }

  updateScrollBarPainter() {
    _scrollbarPainter
      ..color = _thumbColor
      ..trackColor = _trackColor
      ..thickness = _thumbSize
      ..padding = _paddingOutside
      ..radius = radius
      .._viewModel = _viewModel
      ..paddingTrackOutside = _paddingTrackOutside
      ..paddingTrackInside = _paddingTrackInside;
  }

  @override
  void dispose() {
    _fadeoutTimer?.cancel();
    _fadeoutTimer = null;
    _scrollbarPainter.dispose();
    _fadeoutAnimationController.dispose();

    // _verticalSideBarController?.dispose();
    // _horizontalSideBarController?.dispose();
    _viewModel.removeListener(updateScrollBarPainter);
    _scrollChangeNotifier.removeListener(changeScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    setDragDirection(widget.canDrag, TableScrollDirection.both);
    return RawGestureDetector(
      gestures: _gestureRecognizers,
      // behavior: HitTestBehavior.opaque,
      child:
          CustomPaint(foregroundPainter: _scrollbarPainter, child: Container()),
    );
  }

  ScrollbarPainter _buildMaterialScrollbarPainter() {
    return ScrollbarPainter(
      color: _thumbColor,
      trackColor: _trackColor,
      thickness: _thumbSize,
      padding: _paddingOutside,
      radius: radius,
      fadeoutOpacityAnimation: _fadeoutOpacityAnimation,
      viewModel: _viewModel,
      scrollBarSelection: scrollBarSelection,
      paddingTrackOutside: _paddingTrackOutside,
      paddingTrackInside: _paddingTrackInside,
      hitThickness: _viewModel.properties.hitScrollBarThickness,
    );
  }

  void setDragDirection(bool canDrag, TableScrollDirection direction) {
    if (canDrag == _lastCanDrag && _lastScrollDirection == direction) return;
    if (!canDrag) {
      _gestureRecognizers = const <Type, GestureRecognizerFactory>{};
    } else {
      _gestureRecognizers = <Type, GestureRecognizerFactory>{};

      _gestureRecognizers[TableGestureRecognizer] =
          GestureRecognizerFactoryWithHandlers<TableGestureRecognizer>(
        () => TableGestureRecognizer(),
        (TableGestureRecognizer instance) {
          instance
            ..onDown = _handleDragDown
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..selectionDragDirection = directionGesture
            ..onEnd = _handleDragEnd(TableScrollDirection.vertical)
            ..onCancel = _handleDragCancel(TableScrollDirection.vertical)
            ..hitSlope = computeHitScrollBarSlop
            ..gestureSettings = _mediaQueryGestureSettings;
        },
      );
      _lastScrollDirection = direction;
    }
    _lastCanDrag = widget.canDrag;
  }

  double computeHitScrollBarSlop(
      PointerDeviceKind kind, DeviceGestureSettings? gestureSettings) {
    return computeHitSlop(kind, gestureSettings) / 4.0 * 3.0;
  }

  TableScrollDirection directionGesture(DragDownDetails details) {
    return scrollBarSelection.scrollDirection;
  }

  _handleDragDown(DragDownDetails details) {
    assert(_drag == null);
    scrollBarSelection.dragDownDetails = details;
  }

  _handleDragStart(DragStartDetails details) {
    final it = _scrollbarPainter.applySelectedIndex();

    scrollBarSelection
      ..evaluateDirection(details)
      ..active = true;

    _drag = widget.viewModel
        .dragScrollBar(details, _disposeDrag, it.scrollIndexX, it.scrollIndexY);

    _fadeoutTimer?.cancel();
  }

  _handleDragUpdate(TableDragUpdateDetails details) {
    TableDragUpdateDetails tableDragUpdateDetails;

    final IterateScrollable it = _scrollbarPainter.applySelectedIndex();

    switch (scrollBarSelection.selected) {
      case DrawScrollBar.top:
      case DrawScrollBar.bottom:
        final double scrollOffsetLocal = it.getTrackToScrollX(details.delta.dx);
        final double scrollOffsetGlobal = it.pixelsX + scrollOffsetLocal;

        if (!it.allowScrollOutsideX(details)) {
          return;
        }

        tableDragUpdateDetails = TableDragUpdateDetails(
          globalPosition: Offset(scrollOffsetGlobal, 0.0),
          delta: Offset(-scrollOffsetLocal, 0.0),
          primaryDelta: -scrollOffsetLocal,
        );
        break;
      case DrawScrollBar.left:
      case DrawScrollBar.right:
        {
          final double scrollOffsetLocal =
              it.getTrackToScrollY(details.delta.dy);
          final double scrollOffsetGlobal = it.pixelsY + scrollOffsetLocal;

          if (!it.allowScrollOutsideY(details)) {
            return;
          }

          tableDragUpdateDetails = TableDragUpdateDetails(
            globalPosition: Offset(0.0, scrollOffsetGlobal),
            delta: Offset(0.0, -scrollOffsetLocal),
            primaryDelta: -scrollOffsetLocal,
          );

          break;
        }
      default:
        {
          throw ('TableScrollDirection not horizontal, vertical ${scrollBarSelection.selected}');
        }
    }
    _drag!.update(tableDragUpdateDetails);
  }

  _handleDragEnd(TableScrollDirection direction) =>
      (TableDragEndDetails details) {
        scrollBarSelection.active = false;
        _drag!.end(details);
        _endScrollBarDrag();
      };

  _handleDragCancel(TableScrollDirection direction) => () {
        _drag?.cancel();
        _endScrollBarDrag();
        scrollBarSelection.active = false;
      };

  void _disposeDrag() {
    _drag = null;
  }

  _endScrollBarDrag() {
    scrollBarSelection.reset();
    _scrollbarPainter.repaintScrollbar();
    fade();
  }

  void changeScroll() {
    if (_scrollChangeNotifier.scrolling != scrolling) {
      scrolling = _scrollChangeNotifier.scrolling;

      if (scrolling) {
        _fadeoutAnimationController.forward();
      } else {
        fade();
      }
    }
  }

  // @override
  // didStartScroll(TableScrollMetrics metrics, BuildContext? context) {
  //   _fadeoutAnimationController.forward();
  // }

  // @override
  // didEndScroll(TableScrollMetrics metrics, BuildContext? context) {
  //   fade();
  // }

  fade() {
    if (!_isAlwaysShown) {
      _fadeoutTimer?.cancel();
      _fadeoutTimer = Timer(_kScrollbarTimeToFade * 2.0, () {
        _fadeoutAnimationController.reverse();
        _fadeoutTimer = null;
      });
    }
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ScrollbarPainter extends ChangeNotifier implements CustomPainter {
  /// Creates a scrollbar with customizations given by construction arguments.
  ScrollbarPainter({
    required FtViewModel viewModel,
    required Color color,
    required Color trackColor,
    required this.thickness,
    required this.padding,
    required double paddingTrackOutside,
    required double paddingTrackInside,
    required this.fadeoutOpacityAnimation,
    required this.scrollBarSelection,
    this.radius,
    this.minThumbLength = _kMinThumbExtent,
    this.mimimalThumbHitLength = _kMinThumbHitExtent,
    required this.hitThickness,
    double? minOverscrollLength,
  })  : _viewModel = viewModel,
        _color = color,
        _trackColor = trackColor,
        minOverscrollLength = minOverscrollLength ?? minThumbLength {
    fadeoutOpacityAnimation.addListener(notifyListeners);
    _viewModel.addListener(notifyListeners);

    it = IterateScrollable(
        metrics: _viewModel,
        minThumbLength: minThumbLength,
        mimimalThumbHitLength: mimimalThumbHitLength,
        paddingTrackOutside: paddingTrackOutside,
        paddingTrackInside: paddingTrackInside);
  }

  /// [Color] of the thumb. Mustn't be null.
  Color get color => _color;
  Color _color;

  Color get trackColor => _trackColor;
  Color _trackColor;

  set color(Color value) {
    if (color == value) return;
    _color = value;
    notifyListeners();
  }

  set trackColor(Color value) {
    if (_trackColor == value) return;
    _trackColor = value;
    notifyListeners();
  }

  set paddingTrackOutside(value) {
    it.paddingTrackOutside = value;
  }

  set paddingTrackInside(value) {
    it.paddingTrackInside = value;
  }

  void repaintScrollbar() {
    notifyListeners();
  }

  Size _size = Size.zero;
  late IterateScrollable it;
  ScrollBarSelection scrollBarSelection;

  set viewModel(FtViewModel value) {
    if (_viewModel != value) {
      _viewModel.removeListener(notifyListeners);
      _viewModel = value..addListener(notifyListeners);
      it.metrics = value;
    }
  }

  applySelectedIndex() {
    return it
      ..setScrollIndex(
          scrollBarSelection.scrollIndexX, scrollBarSelection.scrollIndexY);
  }

  /// Thickness of the scrollbar in its cross-axis in logical pixels. Mustn't be null.
  double padding;
  double thickness;
  double hitThickness = 48.0;

  /// An opacity [Animation] that dictates the opacity of the thumb.
  /// Changes in value of this [Listenable] will automatically trigger repaints.
  /// Mustn't be null.
  final Animation<double> fadeoutOpacityAnimation;

  Radius? radius;

  /// The preferred smallest size the scrollbar can shrink to when the total
  /// scrollable extent is large, the current visible viewport is small, and the
  /// viewport is not overscrolled.
  ///
  /// The size of the scrollbar may shrink to a smaller size than [minThumbLength] to
  /// fit in the available paint area. E.g., when [minThumbLength] is
  /// `double.infinity`, it will not be respected if
  /// [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// Mustn't be null and the value has to be within the range of 0 to
  /// [minOverscrollLength], inclusive. Defaults to 18.0.
  final double minThumbLength;
  final double mimimalThumbHitLength;

  /// The preferred smallest size the scrollbar can shrink to when viewport is
  /// overscrolled.
  ///
  /// When overscrolling, the size of the scrollbar may shrink to a smaller size
  /// than [minOverscrollLength] to fit in the available paint area. E.g., when
  /// [minOverscrollLength] is `double.infinity`, it will not be respected if
  /// the [ScrollMetrics.viewportDimension] and [mainAxisMargin] are finite.
  ///
  /// The value is less than or equal to [minThumbLength] and greater than or equal to 0.
  /// If unspecified or set to null, it will defaults to the value of [minThumbLength].
  final double minOverscrollLength;

  FtViewModel _viewModel;
  Rect? _thumbRect;

  /// Update with new [ScrollMetrics]. The scrollbar will show and redraw itself
  /// based on these new metrics.
  ///
  /// The scrollbar will remain on screen.

  /// Update and redraw with new scrollbar thickness and radius.
  void updateThickness(double nextThickness, Radius nextRadius) {
    thickness = nextThickness;
    radius = nextRadius;
    notifyListeners();
  }

  Paint _paint(bool highligted) {
    return Paint()
      ..color = (highligted ? Colors.blue[700]! : color)
          .withOpacity(color.opacity * fadeoutOpacityAnimation.value);
  }

  Paint get _paintTrack {
    return Paint()..color = _trackColor;
  }

  void _paintThumbCrossAxis(Canvas canvas, Size size, double thumbOffset,
      double thumbExtent, DrawScrollBar direction, bool highligthed) {
    double x, y;
    Size thumbSize;

    switch (direction) {
      case DrawScrollBar.right:
      case DrawScrollBar.left:
        thumbSize = Size(thickness, thumbExtent);
        x = (direction == DrawScrollBar.right)
            ? size.width -
                (thickness + padding) * _viewModel.ratioVerticalScrollBarTrack
            : padding -
                (padding + thickness) +
                (padding + thickness) *
                    _viewModel.ratioVerticalScrollBarTrack *
                    _viewModel.ratioSizeAnimatedSplitChangeX;
        y = thumbOffset;
        break;
      default:
        thumbSize = Size(thumbExtent, thickness);
        x = thumbOffset;
        y = (direction == DrawScrollBar.bottom)
            ? size.height -
                (thickness + padding) * _viewModel.ratioHorizontalScrollBarTrack
            : padding -
                (padding + thickness) +
                (padding + thickness) *
                    _viewModel.ratioHorizontalScrollBarTrack *
                    _viewModel.ratioSizeAnimatedSplitChangeY;
    }

    _thumbRect = Offset(x, y) & thumbSize;
    if (radius == null) {
      canvas.drawRect(_thumbRect!, _paint(highligthed));
    } else {
      canvas.drawRRect(
          RRect.fromRectAndRadius(_thumbRect!, radius!), _paint(highligthed));
    }
  }

  void _paintTrackCrossAxis(Canvas canvas, Size size, double position,
      double length, DrawScrollBar direction) {
    double x, y;
    double height, width;

    switch (direction) {
      case DrawScrollBar.right:
      case DrawScrollBar.left:
        width = (direction == DrawScrollBar.right)
            ? _viewModel.sizeScrollBarRight
            : _viewModel.sizeScrollBarLeft;
        height = length;
        x = (direction == DrawScrollBar.right) ? size.width - width : 0.0;
        y = position;

        break;
      default:
        width = length;
        height = (direction == DrawScrollBar.bottom)
            ? _viewModel.sizeScrollBarBottom
            : _viewModel.sizeScrollBarTop;
        x = position;
        y = (direction == DrawScrollBar.bottom) ? size.height - height : 0.0;
    }
    final rect = Rect.fromLTWH(x, y, width, height);
    canvas.drawRect(rect, _paintTrack);
  }

  @override
  void dispose() {
    fadeoutOpacityAnimation.removeListener(notifyListeners);
    super.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    _size = size;

    it.reset();

    final selected = scrollBarSelection.active
        ? scrollBarSelection.selected
        : DrawScrollBar.none;
    final isMultiple = selected == DrawScrollBar.multiple;

    while (it.next) {
      final panelIsVerticalScrolling =
          _viewModel.stateSplitY != SplitState.split ||
              scrollBarSelection.scrollIndexY == it.scrollIndexY;
      final panelIsHorizontalScrolling =
          _viewModel.stateSplitX != SplitState.split ||
              scrollBarSelection.scrollIndexX == it.scrollIndexX;

      // Vertical scrollbar
      //
      //

      if (it.drawVerticalScrollBarTrack != DrawScrollBar.none) {
        _paintTrackCrossAxis(canvas, size, it.trackPositionY,
            it.trackDimensionY, it.drawVerticalScrollBarTrack);
      }

      final drawVerticalScrollBar =
          (it.drawVerticalScrollBar != DrawScrollBar.none)
              ? it.drawVerticalScrollBar
              : it.drawVerticalScrollBarTrack;

      if (drawVerticalScrollBar != DrawScrollBar.none) {
        final thumbExtent = it.thumbExtentY;
        final thumbOffsetLocal = it.getScrollToTrackY(thumbExtent);

        final thumbOffset =
            it.trackPositionY + it.paddingTrackBeginY + thumbOffsetLocal;

        _paintThumbCrossAxis(
            canvas,
            size,
            thumbOffset,
            thumbExtent,
            drawVerticalScrollBar,
            panelIsVerticalScrolling &&
                (isMultiple || drawVerticalScrollBar == selected));
      }

      // Horizontal scrollbar
      //
      //

      if (it.drawHorizontalScrollBarTrack != DrawScrollBar.none) {
        _paintTrackCrossAxis(canvas, size, it.trackPositionX,
            it.trackDimensionX, it.drawHorizontalScrollBarTrack);
      }

      var drawHorizontalScrollBar =
          (it.drawHorizontalScrollBar != DrawScrollBar.none)
              ? it.drawHorizontalScrollBar
              : it.drawHorizontalScrollBarTrack;

      if (drawHorizontalScrollBar != DrawScrollBar.none) {
        final thumbExtent = it.thumbExtentX;
        final thumbOffsetLocal = it.getScrollToTrackX(thumbExtent);
        final thumbOffset =
            it.trackPositionX + it.paddingTrackBeginX + thumbOffsetLocal;

        _paintThumbCrossAxis(
            canvas,
            size,
            thumbOffset,
            thumbExtent,
            drawHorizontalScrollBar,
            panelIsHorizontalScrolling &&
                (isMultiple || drawHorizontalScrollBar == selected));
      }
    }

    // final double beforePadding = _isVertical ? padding.top : padding.left;
    // final double thumbExtent = _thumbExtent();
    // final double thumbOffsetLocal = _getScrollToTrack(_lastMetrics, thumbExtent);
    // final double thumbOffset = thumbOffsetLocal + mainAxisMargin + beforePadding;

    // return _paintThumbCrossAxis(canvas, size, thumbOffset, thumbExtent, _lastAxisDirection);
  }

  /// Same as hitTest, but includes some padding to make sure that the region
  /// isn't too small to be interacted with by the user.
  bool hitTestInteractive(Offset position) {
    if (_thumbRect == null) {
      return false;
    }
    // The thumb is not able to be hit when transparent.
    if (fadeoutOpacityAnimation.value == 0.0) {
      return false;
    }
    final Rect interactiveThumbRect = _thumbRect!.expandToInclude(
      Rect.fromCircle(
          center: _thumbRect!.center, radius: _kMinInteractiveSize / 2),
    );
    return interactiveThumbRect.contains(position);
  }

  @override
  bool? hitTest(Offset position) {
    hitScrollBar(position);
    bool hit = scrollBarSelection.isSelected;
    return hit;
  }

  hitScrollBar(Offset position) {
    scrollBarSelection.reset();

    if (fadeoutOpacityAnimation.value == 0.0) return scrollBarSelection;

    it.reset();

    while (it.next) {
      switch (it.drawVerticalScrollBar) {
        case DrawScrollBar.right:
          {
            if (_size.width - hitThickness < position.dx) {
              if (it.hitThumbY(position.dy)) {
                scrollBarSelection.vertical = DrawScrollBar.right;
              }
            }
            break;
          }
        case DrawScrollBar.left:
          {
            if (position.dx < hitThickness) {
              if (it.hitThumbY(position.dy)) {
                scrollBarSelection.vertical = DrawScrollBar.left;
              }
            }
            break;
          }
        default:
      }

      switch (it.drawHorizontalScrollBar) {
        case DrawScrollBar.bottom:
          {
            if (_size.height - hitThickness < position.dy) {
              if (it.hitThumbX(position.dx)) {
                scrollBarSelection.horizontal = DrawScrollBar.bottom;
              }
            }
            break;
          }
        case DrawScrollBar.top:
          {
            if (position.dy < hitThickness) {
              if (it.hitThumbX(position.dx)) {
                scrollBarSelection.horizontal = DrawScrollBar.top;
              }
            }
            break;
          }
        default:
      }

      scrollBarSelection.evaluate();

      if (scrollBarSelection.isSelected) {
        scrollBarSelection.setIndex(it.scrollIndexX, it.scrollIndexY);
        return;
      }
    }
  }

  @override
  bool shouldRepaint(ScrollbarPainter old) {
    // Should repaint if any properties changed.
    return color != old.color ||
        // textDirection != old.textDirection ||
        thickness != old.thickness ||
        fadeoutOpacityAnimation != old.fadeoutOpacityAnimation ||
        radius != old.radius ||
        minThumbLength != old.minThumbLength ||
        padding != old.padding;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) => false;

  @override
  SemanticsBuilderCallback? get semanticsBuilder => null;
}

class IterateScrollable {
  IterateScrollable({
    required this.metrics,
    required this.minThumbLength,
    required this.mimimalThumbHitLength,
    this.paddingTrackOutside = 0.0,
    this.paddingTrackInside = 0.0,
  });

  int scrollIndexX = 0;
  int scrollIndexY = 0;
  int _startX = 0;
  int _startY = 0;
  int _lengthX = 0;
  int _lengthY = 0;
  int _count = 0;
  int _length = 0;
  TableScrollMetrics metrics;
  double minThumbLength;
  double mimimalThumbHitLength;
  double paddingTrackOutside;
  double paddingTrackInside;

  setScrollIndex(scrollIndexX, scrollIndexY) {
    this.scrollIndexX = scrollIndexX;
    this.scrollIndexY = scrollIndexY;
  }

  reset() {
    _count = 0;

    switch (metrics.stateSplitX) {
      case SplitState.freezeSplit:
        {
          _startX = 1;
          _lengthX = 2;
          break;
        }
      case SplitState.split:
        {
          _startX = 0;
          _lengthX = 2;
          break;
        }
      default:
        {
          _startX = 0;
          _lengthX = 1;
        }
    }

    switch (metrics.stateSplitY) {
      case SplitState.freezeSplit:
        {
          _startY = 1;
          _lengthY = 2;
          break;
        }
      case SplitState.split:
        {
          _startY = 0;
          _lengthY = 2;
          break;
        }
      default:
        {
          _startY = 0;
          _lengthY = 1;
        }
    }
    _length = (_lengthY - _startY) * (_lengthX - _startX);
    _count = 0;
  }

  bool get next {
    if (_count < _length) {
      scrollIndexY = _startY + _count ~/ (_lengthX - _startX);
      scrollIndexX = _startX + _count % (_lengthX - _startX);
      _count++;
      return true;
    } else {
      return false;
    }
  }

  bool containsPositionX(double position) =>
      metrics.containsPositionX(scrollIndexX, position);

  bool containsPositionY(double position) =>
      metrics.containsPositionY(scrollIndexY, position);

  bool allowScrollOutsideX(TableDragUpdateDetails details) {
    final position = details.localPosition.dx;
    final delta = details.delta.dx;
    final x = trackPositionX;

    return (delta > 0)
        ? position >= x + paddingTrackBeginX
        : position <= x + trackDimensionX - paddingTrackEndX;
  }

  bool allowScrollOutsideY(TableDragUpdateDetails details) {
    final position = details.localPosition.dy;
    final delta = details.delta.dy;
    final y = trackPositionY;

    return (delta > 0)
        ? position >= y + paddingTrackBeginY
        : position <= y + trackDimensionY - paddingTrackEndY;
  }

  bool hitThumbX(double position) {
    double thumbExtent = thumbExtentX;
    double thumbOffsetLocal = getScrollToTrackX(thumbExtent);

    if (thumbExtent < mimimalThumbHitLength && thumbExtent < trackExtentX) {
      thumbOffsetLocal -= (mimimalThumbHitLength - thumbExtent) / 2.0;

      if (thumbOffsetLocal < 0.0) {
        thumbOffsetLocal = 0.0;
      }

      thumbExtent = mimimalThumbHitLength;
    }

    final thumbOffset = trackPositionX + paddingTrackBeginX + thumbOffsetLocal;

    return thumbOffset <= position && position <= thumbOffset + thumbExtent;
  }

  bool hitThumbY(double position) {
    double thumbExtent = thumbExtentY;
    double thumbOffsetLocal = getScrollToTrackY(thumbExtent);

    if (thumbExtent < mimimalThumbHitLength && thumbExtent < trackExtentY) {
      thumbOffsetLocal -= (mimimalThumbHitLength - thumbExtent) / 2.0;

      if (thumbOffsetLocal < 0.0) {
        thumbOffsetLocal = 0.0;
      }

      thumbExtent = mimimalThumbHitLength;
    }

    final thumbOffset = trackPositionY + paddingTrackBeginY + thumbOffsetLocal;

    return thumbOffset <= position && position <= thumbOffset + thumbExtent;
  }

  DrawScrollBar get drawVerticalScrollBar =>
      metrics.drawVerticalScrollBar(scrollIndexX, scrollIndexY);

  DrawScrollBar get drawHorizontalScrollBar =>
      metrics.drawHorizontalScrollBar(scrollIndexX, scrollIndexY);

  DrawScrollBar get drawVerticalScrollBarTrack =>
      metrics.drawVerticalScrollBarTrack(scrollIndexX, scrollIndexY);

  DrawScrollBar get drawHorizontalScrollBarTrack =>
      metrics.drawHorizontalScrollBarTrack(scrollIndexX, scrollIndexY);

  double get viewportPositionX => metrics.viewportPositionX(scrollIndexX);

  double get viewportPositionY => metrics.viewportPositionY(scrollIndexY);

  double get trackPositionX => metrics.trackPositionX(scrollIndexX);

  double get trackPositionY => metrics.trackPositionY(scrollIndexY);

  double get viewportDimensionX => metrics.viewportDimensionX(scrollIndexX);

  double get viewportDimensionY => metrics.viewportDimensionY(scrollIndexY);

  double get trackDimensionX => metrics.trackDimensionX(scrollIndexX);

  double get trackDimensionY => metrics.trackDimensionY(scrollIndexY);

  double get minScrollExtentX => metrics.minScrollExtentX(scrollIndexX);

  double get minScrollExtentY => metrics.minScrollExtentY(scrollIndexY);

  double get maxScrollExtentX => metrics.maxScrollExtentX(scrollIndexX);

  double get maxScrollExtentY => metrics.maxScrollExtentY(scrollIndexY);

  double get pixelsX => metrics.scrollPixelsX(scrollIndexX, scrollIndexY);

  double get pixelsY => metrics.scrollPixelsY(scrollIndexX, scrollIndexY);

  double get trackExtentX =>
      trackDimensionX - paddingTrackBeginX - paddingTrackEndX;

  double get trackExtentY =>
      trackDimensionY - paddingTrackBeginY - paddingTrackEndY;

  double get paddingTrackBeginX => metrics.stateSplitX == SplitState.split
      ? (scrollIndexX == 0 ? paddingTrackOutside : paddingTrackInside)
      : paddingTrackOutside;

  double get paddingTrackEndX => metrics.stateSplitX == SplitState.split
      ? (scrollIndexX == 0 ? paddingTrackInside : paddingTrackOutside)
      : paddingTrackOutside;

  double get paddingTrackBeginY => metrics.stateSplitY == SplitState.split
      ? (scrollIndexY == 0 ? paddingTrackOutside : paddingTrackInside)
      : paddingTrackOutside;

  double get paddingTrackEndY => metrics.stateSplitY == SplitState.split
      ? (scrollIndexY == 0 ? paddingTrackInside : paddingTrackOutside)
      : paddingTrackOutside;

  double get totalContentExtentX {
    return maxScrollExtentX - minScrollExtentX + viewportDimensionX;
  }

  double get totalContentExtentY {
    return maxScrollExtentY - minScrollExtentY + viewportDimensionY;
  }

  double get thumbExtentX {
    final trackExtent = trackExtentX;
    final double fractionVisible =
        (trackExtent / totalContentExtentX).clamp(0.0, 1.0);

    final double thumbExtent = math.max(
      math.min(trackExtent, minThumbLength),
      trackExtent * fractionVisible,
    );

    return thumbExtent;
  }

  double get thumbExtentY {
    final trackExtent = trackExtentY;
    final double fractionVisible =
        (trackExtent / totalContentExtentY).clamp(0.0, 1.0);

    final double thumbExtent = math.max(
      math.min(trackExtent, minThumbLength),
      trackExtent * fractionVisible,
    );

    return thumbExtent;
  }

  double getScrollToTrackX(double thumbExtent) {
    final double scrollableExtent = maxScrollExtentX - minScrollExtentX;

    final double fractionPast = (scrollableExtent > 0)
        ? ((pixelsX - minScrollExtentX) / scrollableExtent).clamp(0.0, 1.0)
        : 0.0;

    return fractionPast * (trackExtentX - thumbExtent);
  }

  double getScrollToTrackY(double thumbExtent) {
    final double scrollableExtent = maxScrollExtentY - minScrollExtentY;

    final double fractionPast = (scrollableExtent > 0)
        ? ((pixelsY - minScrollExtentY) / scrollableExtent).clamp(0.0, 1.0)
        : 0.0;
    return fractionPast * (trackExtentY - thumbExtent);
  }

  double getTrackToScrollX(double thumbOffsetLocal) {
    final double scrollableExtent = maxScrollExtentX - minScrollExtentX;
    final double thumbMovableExtent = trackExtentX - thumbExtentX;

    return scrollableExtent * thumbOffsetLocal / thumbMovableExtent;
  }

  double getTrackToScrollY(double thumbOffsetLocal) {
    final double scrollableExtent = maxScrollExtentY - minScrollExtentY;
    final double thumbMovableExtent = trackExtentY - thumbExtentY;

    return scrollableExtent * thumbOffsetLocal / thumbMovableExtent;
  }

  // SelectedScrollBar get selectedX =>
  //     SelectedScrollBar(scrollIndexX: scrollIndexX, scrollIndexY: scrollIndexY, selected: drawHorizontalScrollBar);
}

typedef HandleTableMetrics = void Function(TableScrollMetrics metrics);

class ScrollBarSelection {
  int scrollIndexX = 0;
  int scrollIndexY = 0;
  DrawScrollBar selected = DrawScrollBar.none;
  DrawScrollBar vertical = DrawScrollBar.none;
  DrawScrollBar horizontal = DrawScrollBar.none;
  late DragDownDetails dragDownDetails;
  bool active = false;

  setIndex(int scrollIndexX, int scrollIndexY) {
    this.scrollIndexX = scrollIndexX;
    this.scrollIndexY = scrollIndexY;
  }

  reset() {
    scrollIndexX = 0;
    scrollIndexY = 0;
    selected = DrawScrollBar.none;
    vertical = DrawScrollBar.none;
    horizontal = DrawScrollBar.none;
  }

  evaluate() {
    if (vertical != DrawScrollBar.none && horizontal != DrawScrollBar.none) {
      selected = DrawScrollBar.multiple;
    } else if (vertical != DrawScrollBar.none) {
      selected = vertical;
    } else if (horizontal != DrawScrollBar.none) {
      selected = horizontal;
    }
  }

  evaluateDirection(DragStartDetails dragStartDetails) {
    if (selected == DrawScrollBar.multiple) {
      Offset delta =
          (dragDownDetails.localPosition - dragStartDetails.localPosition);
      selected = delta.dy.abs() > delta.dx.abs() ? vertical : horizontal;
    }
  }

  bool get isSelected => selected != DrawScrollBar.none;

  TableScrollDirection get scrollDirection {
    TableScrollDirection direction;

    switch (selected) {
      case DrawScrollBar.left:
      case DrawScrollBar.right:
        {
          direction = TableScrollDirection.vertical;
          break;
        }
      case DrawScrollBar.top:
      case DrawScrollBar.bottom:
        {
          direction = TableScrollDirection.horizontal;
          break;
        }
      case DrawScrollBar.multiple:
        direction = TableScrollDirection.both;
        break;
      default:
        direction = TableScrollDirection.unknown;
    }

    return direction;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ScrollBarSelection &&
        other.scrollIndexX == scrollIndexX &&
        other.scrollIndexY == scrollIndexY;
  }

  @override
  int get hashCode =>
      scrollIndexX.hashCode ^ scrollIndexY.hashCode ^ selected.hashCode;

  @override
  String toString() =>
      'SelectedScrollBar(scrollIndexX: $scrollIndexX, scrollIndexY: $scrollIndexY, selected: $selected)';
}
