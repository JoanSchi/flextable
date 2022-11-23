import 'dart:async';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'table_drag_details.dart';
import 'table_gesture.dart';
import 'table_model.dart';
import 'table_scroll.dart';
import 'table_scroll_notification.dart';
import 'dart:math' as math;

const double _kMinThumbExtent = 18.0;
const double _kMinThumbHitExtent = 32.0;
const double _kMinInteractiveSize = 48.0;
const double _kHitThickness = 32.0;
const double _kThumbSize = 6.0;
const double _kPaddingOutside = 2.0;
const double _kPaddingTrackOutside = 0.0;
const double _kPaddingTrackInside = 0.0;
const double _kPaddingSeparateTrackOutside = 2.0;
const double _kPaddingSeparateTrackInside = 2.0;
const Duration _kScrollbarFadeDuration = Duration(milliseconds: 300);
const Duration _kScrollbarTimeToFade = Duration(milliseconds: 600);

enum DrawScrollBar { LEFT, TOP, RIGHT, BOTTOM, MULTIPLE, NONE }

class TableScrollbar extends StatefulWidget {
  /// Creates a material design scrollbar that wraps the given [about].
  ///
  /// The [about] should be a source of [TableScrollNotification] notifications,
  /// typically a [Scrollable] widget.
  TableScrollbar({
    Key? key,
    this.isAlwaysShown = false,
    this.scrollBarTrack = false,
    this.thumbSize,
    this.paddingInside,
    this.paddingOutside,
    this.paddingTrackOutside,
    this.paddingTrackInside,
    this.customRadius,
    this.radius = true,
    this.canDrag = true,
    required this.tableModel,
    required this.tableScrollPosition,
    this.platformIndependent = false,
  }) : super(key: key);

  final TableModel tableModel;
  final TableScrollPosition tableScrollPosition;
  final bool isAlwaysShown;
  final double? thumbSize;
  final double? paddingInside;
  final double? paddingOutside;
  final scrollBarTrack;
  final bool radius;
  final Radius? customRadius;
  final canDrag;
  final bool platformIndependent;
  final double? paddingTrackOutside;
  final double? paddingTrackInside;

  @override
  _TableScrollbarState createState() => _TableScrollbarState();
}

class _TableScrollbarState extends State<TableScrollbar>
    with TickerProviderStateMixin {
  Map<Type, GestureRecognizerFactory> _gestureRecognizers =
      const <Type, GestureRecognizerFactory>{};
  TableScrollDirection _lastScrollDirection = TableScrollDirection.unknown;
  bool _lastCanDrag = false;
  late Color _thumbColor;
  Color _trackColor = Colors.grey[400]!;
  late AnimationController _fadeoutAnimationController;
  late AnimationController _verticalSideBarController;
  late AnimationController _horizontalSideBarController;
  late Animation<double> _fadeoutOpacityAnimation;
  late ScrollbarPainter _scrollbarPainter;
  late ScrollBarSelection scrollBarSelection;
  TableDrag? _drag;
  Timer? _fadeoutTimer;
  late TableModel _tableModel;
  Radius? radius;
  bool _isAlwaysShown = false;
  double _thumbSize = _kThumbSize;
  double _paddingOutside = _kPaddingOutside;
  double _paddingInside = 0.0;
  double _paddingTrackInside = 0.0;
  double _paddingTrackOutside = 0.0;

  @override
  void initState() {
    _tableModel = widget.tableModel;
    _tableModel.addScrollListener(_handleScrollNotification);
    _tableModel.updateScrollBar = updateScrollBar;

    scrollBarSelection = ScrollBarSelection();

    _fadeoutAnimationController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );
    _fadeoutOpacityAnimation = CurvedAnimation(
      parent: _fadeoutAnimationController,
      curve: Curves.fastOutSlowIn,
    );

    _verticalSideBarController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );

    _verticalSideBarController.addListener(() {
      _tableModel.ratioVerticalScrollBarTrack =
          _verticalSideBarController.value;
      _tableModel.notifyListeners();
    });

    _horizontalSideBarController = AnimationController(
      vsync: this,
      duration: _kScrollbarFadeDuration,
    );

    _horizontalSideBarController.addListener(() {
      _tableModel.ratioHorizontalScrollBarTrack =
          _horizontalSideBarController.value;
      _tableModel.notifyListeners();
    });

    super.initState();
  }

  @override
  void didChangeDependencies() {
    updateValues();
    _scrollbarPainter = _buildMaterialScrollbarPainter();
    super.didChangeDependencies();
  }

  void didUpdateWidget(TableScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_tableModel != widget.tableModel) {
      _tableModel.removeScrollListener(_handleScrollNotification);
      _tableModel = widget.tableModel;
      _tableModel.addScrollListener(_handleScrollNotification);
    }

    _tableModel.updateScrollBar = updateScrollBar;

    updateValues();
    updateScrollBarPainter();
  }

  updateValues() {
    final ThemeData theme = Theme.of(context);

    if (widget.platformIndependent) {
      _isAlwaysShown = widget.isAlwaysShown;
      _thumbSize = widget.thumbSize ?? _kThumbSize;
      _paddingOutside = widget.paddingOutside ?? _kPaddingOutside;
      _paddingInside = widget.paddingInside ?? _kPaddingOutside;

      final scrollBarTrack = widget.scrollBarTrack;

      _paddingTrackOutside = widget.paddingTrackOutside ??
          (scrollBarTrack
              ? _kPaddingSeparateTrackOutside
              : _kPaddingTrackOutside);
      _paddingTrackInside = widget.paddingTrackInside ??
          (scrollBarTrack
              ? _kPaddingSeparateTrackInside
              : _kPaddingTrackInside);

      _tableModel.scrollBarTrack = widget.scrollBarTrack;
      _tableModel.sizeScrollBarTrack = widget.scrollBarTrack
          ? (_thumbSize + _paddingOutside + _paddingInside)
          : 0.0;

      if (widget.radius) {
        radius = widget.customRadius ?? Radius.circular(_thumbSize / 2.0);
      }

      _thumbColor = Colors.grey[500]!.withOpacity(0.8);
    } else {
      switch (theme.platform) {
        case TargetPlatform.iOS:
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          {
            _isAlwaysShown = false;
            _thumbSize = widget.thumbSize ?? _kThumbSize;
            _paddingOutside = widget.paddingOutside ?? _kPaddingOutside;
            _tableModel.scrollBarTrack = false;
            _tableModel.sizeScrollBarTrack = 0.0;
            _tableModel.sizeScrollBarTrack = 0.0;
            _paddingTrackOutside = widget.paddingTrackOutside ??
                _paddingOutside +
                    _thumbSize / 2.0 +
                    math.sqrt(math.pow(_thumbSize / 2.0, 2.0) / 2.0);
            _paddingTrackInside =
                widget.paddingTrackInside ?? _kPaddingTrackInside;
            if (widget.radius) {
              radius = widget.customRadius ?? Radius.circular(_thumbSize / 2.0);
            }

            _thumbColor = Colors.grey[500]!.withOpacity(0.8);

            break;
          }

        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          {
            _isAlwaysShown = true;
            _thumbSize = widget.thumbSize ?? _kThumbSize;
            _paddingOutside = widget.paddingInside ?? _kPaddingOutside;
            _paddingInside = widget.paddingInside ?? _kPaddingOutside;
            _tableModel.scrollBarTrack = true;
            _tableModel.sizeScrollBarTrack =
                _thumbSize + _paddingOutside + _paddingInside;
            _paddingTrackOutside =
                widget.paddingTrackOutside ?? _kPaddingSeparateTrackOutside;
            _paddingTrackInside =
                widget.paddingTrackInside ?? _kPaddingSeparateTrackInside;

            if (widget.radius)
              radius = widget.customRadius ?? Radius.circular(_thumbSize / 2.0);

            _fadeoutAnimationController.animateTo(1.0);

            _trackColor = Colors.grey[300]!;
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
      ..tableModel = _tableModel
      ..paddingTrackOutside = _paddingTrackOutside
      ..paddingTrackInside = _paddingTrackInside;
  }

  void dispose() {
    _fadeoutTimer?.cancel();
    _fadeoutTimer = null;
    _fadeoutAnimationController.dispose();
    _verticalSideBarController.dispose();
    _horizontalSideBarController.dispose();
    _tableModel.removeScrollListener(_handleScrollNotification);
    _tableModel.updateScrollBar = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //Let op CustomPaint heeft child nodig voor hittest
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
      tableModel: _tableModel,
      scrollBarSelection: scrollBarSelection,
      paddingTrackOutside: _paddingTrackOutside,
      paddingTrackInside: _paddingTrackInside,
    );
  }

  bool _handleScrollNotification(String notification) {
    if (notification == 'update') {
      if (_fadeoutAnimationController.status != AnimationStatus.forward) {
        _fadeoutAnimationController.forward();
      }
    } else if (notification == 'start') {
    } else if (notification == 'end') {
      if (!_isAlwaysShown) {
        _fadeoutTimer?.cancel();
        _fadeoutTimer = Timer(_kScrollbarTimeToFade * 2.0, () {
          _fadeoutAnimationController.reverse();
          _fadeoutTimer = null;
        });
      }
    }
    return true;
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
            ..hitSlope = computeHitScrollBarSlop;

          // ..minFlingDistance = 0.0 //_physics?.minFlingDistance
          // ..minFlingVelocity = 0.0 //_physics?.minFlingVelocity
          // ..maxFlingVelocity = 0.0  //physics?.maxFlingVelocity
          // ..velocityTrackerBuilder = _configuration.velocityTrackerBuilder(context)
          // ..dragStartBehavior = widget.dragStartBehavior;
        },
      );
      _lastScrollDirection = direction;
    }
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

    scrollBarSelection.evaluateDirection(details);

    _drag = widget.tableScrollPosition
        .dragScrollBar(details, _disposeDrag, it.scrollIndexX, it.scrollIndexY);
  }

  _handleDragUpdate(TableDragUpdateDetails details) {
    TableDragUpdateDetails tableDragUpdateDetails;

    final IterateScrollable it = _scrollbarPainter.applySelectedIndex();

    switch (scrollBarSelection.selected) {
      case DrawScrollBar.TOP:
      case DrawScrollBar.BOTTOM:
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
      case DrawScrollBar.LEFT:
      case DrawScrollBar.RIGHT:
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
        _drag!.end(details);
        _endScrollBarDrag();
      };

  _handleDragCancel(TableScrollDirection direction) => () {
        _drag?.cancel();
        _endScrollBarDrag();
      };

  void _disposeDrag() {
    _drag = null;
  }

  verticalBar(double ratio) {
    if (ratio != _tableModel.ratioVerticalScrollBarTrack) {
      if (!(ratio == 1.0 &&
              _verticalSideBarController.status == AnimationStatus.forward ||
          ratio == 0.0 &&
              _verticalSideBarController.status == AnimationStatus.reverse)) {
        if (ratio == 1.0) {
          _verticalSideBarController.value = 0.0;
          _verticalSideBarController.forward();
        } else {
          _verticalSideBarController.value = 1.0;
          _verticalSideBarController.reverse();
        }
      }
    }
  }

  horizontalBar(double ratio) {
    if (ratio != _tableModel.ratioHorizontalScrollBarTrack) {
      if (!(ratio == 1.0 &&
              _horizontalSideBarController.status == AnimationStatus.forward ||
          ratio == 0.0 &&
              _horizontalSideBarController.status == AnimationStatus.reverse)) {
        if (ratio == 1.0) {
          _horizontalSideBarController.value = 0.0;
          _horizontalSideBarController.forward();
        } else {
          _horizontalSideBarController.value = 1.0;
          _horizontalSideBarController.reverse();
        }
      }
    }
  }

  updateScrollBar() {
    if (_tableModel.scrollBarTrack) {
      final widthLayout =
          List.generate(4, (i) => GridLayout(), growable: false);
      final heightLayout =
          List.generate(4, (i) => GridLayout(), growable: false);

      _tableModel.calculateScrollBarTrack(
          width: _tableModel.widthMainPanel,
          height: _tableModel.heightMainPanel,
          widthLayout: widthLayout,
          heightLayout: heightLayout,
          setRatioHorizontal: horizontalBar,
          setRatioVertical: verticalBar);
    }
  }

  _endScrollBarDrag() {
    scrollBarSelection.reset();
    _scrollbarPainter.repaintScrollbar();
  }
}

// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

class ScrollbarPainter extends ChangeNotifier implements CustomPainter {
  /// Creates a scrollbar with customizations given by construction arguments.
  ScrollbarPainter({
    required TableModel tableModel,
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
    this.hitThickness = _kHitThickness,
    double? minOverscrollLength,
  })  : _tableModel = tableModel,
        // assert(textDirection != null),
        // assert(thickness != null),
        // assert(fadeoutOpacityAnimation != null),
        // assert(mainAxisMargin != null),
        // assert(crossAxisMargin != null),
        // assert(minLength != null),
        // assert(minLength >= 0),
        // assert(minOverscrollLength == null || minOverscrollLength <= minLength),
        // assert(minOverscrollLength == null || minOverscrollLength >= 0),
        // assert(padding != null),
        // assert(padding.isNonNegative),
        _color = color,
        _trackColor = trackColor,
        minOverscrollLength = minOverscrollLength ?? minThumbLength {
    fadeoutOpacityAnimation.addListener(notifyListeners);
    it = IterateScrollable(
        metrics: _tableModel,
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

  /// [TextDirection] of the [BuildContext] which dictates the side of the
  /// screen the scrollbar appears in (the trailing side). Mustn't be null.
  // TextDirection get textDirection => _textDirection;
  // TextDirection _textDirection;
  // set textDirection(TextDirection value) {
  //   assert(value != null);
  //   if (textDirection == value) return;

  //   _textDirection = value;
  //   notifyListeners();
  // }

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

  set tableModel(TableModel value) {
    if (_tableModel != value) {
      _tableModel = value;
      it.metrics = value;
    }
  }

  TableModel _tableModel;
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
      case DrawScrollBar.RIGHT:
      case DrawScrollBar.LEFT:
        thumbSize = Size(thickness, thumbExtent);
        x = (direction == DrawScrollBar.RIGHT)
            ? size.width -
                (thickness + padding) * _tableModel.ratioVerticalScrollBarTrack
            : padding -
                (padding + thickness) +
                (padding + thickness) *
                    _tableModel.ratioVerticalScrollBarTrack *
                    _tableModel.ratioSizeAnimatedSplitChangeX;
        y = thumbOffset;
        break;
      default:
        thumbSize = Size(thumbExtent, thickness);
        x = thumbOffset;
        y = (direction == DrawScrollBar.BOTTOM)
            ? size.height -
                (thickness + padding) *
                    _tableModel.ratioHorizontalScrollBarTrack
            : padding -
                (padding + thickness) +
                (padding + thickness) *
                    _tableModel.ratioHorizontalScrollBarTrack *
                    _tableModel.ratioSizeAnimatedSplitChangeY;
    }

    _thumbRect = Offset(x, y) & thumbSize;
    if (radius == null)
      canvas.drawRect(_thumbRect!, _paint(highligthed));
    else
      canvas.drawRRect(
          RRect.fromRectAndRadius(_thumbRect!, radius!), _paint(highligthed));
  }

  void _paintTrackCrossAxis(Canvas canvas, Size size, double position,
      double length, DrawScrollBar direction) {
    double x, y;
    double height, width;

    switch (direction) {
      case DrawScrollBar.RIGHT:
      case DrawScrollBar.LEFT:
        width = (direction == DrawScrollBar.RIGHT)
            ? _tableModel.sizeScrollBarRight
            : _tableModel.sizeScrollBarLeft;
        height = length;
        x = (direction == DrawScrollBar.RIGHT) ? size.width - width : 0.0;
        y = position;
        break;
      default:
        width = length;
        height = (direction == DrawScrollBar.BOTTOM)
            ? _tableModel.sizeScrollBarBottom
            : _tableModel.sizeScrollBarTop;
        x = position;
        y = (direction == DrawScrollBar.BOTTOM) ? size.height - height : 0.0;
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

    final selected = scrollBarSelection.selected;
    final isMultiple = selected == DrawScrollBar.MULTIPLE;

    while (it.next) {
      final panelIsVerticalScrolling =
          _tableModel.stateSplitY != SplitState.SPLIT ||
              scrollBarSelection.scrollIndexY == it.scrollIndexY;
      final panelIsHorizontalScrolling =
          _tableModel.stateSplitX != SplitState.SPLIT ||
              scrollBarSelection.scrollIndexX == it.scrollIndexX;

      final drawVerticalScrollBar = it.drawVerticalScrollBar;

      final drawTrack = (drawVerticalScrollBar != DrawScrollBar.NONE)
          ? drawVerticalScrollBar
          : it.drawVerticalScrollBarTrack;

      if (_tableModel.scrollBarTrack) {
        _paintTrackCrossAxis(
            canvas, size, it.trackPositionY, it.trackDimensionY, drawTrack);
      }

      if (drawVerticalScrollBar != DrawScrollBar.NONE) {
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

      var drawHorizontalScrollBar = it.drawHorizontalScrollBar;

      if (_tableModel.scrollBarTrack) {
        final drawTrack = (drawHorizontalScrollBar != DrawScrollBar.NONE)
            ? drawHorizontalScrollBar
            : it.drawHorizontalScrollBarTrack;

        if (drawTrack != DrawScrollBar.NONE)
          _paintTrackCrossAxis(
              canvas, size, it.trackPositionX, it.trackDimensionX, drawTrack);
      }

      if (drawHorizontalScrollBar != DrawScrollBar.NONE) {
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
        case DrawScrollBar.RIGHT:
          {
            if (_size.width - hitThickness < position.dx) {
              if (it.hitThumbY(position.dy))
                scrollBarSelection.vertical = DrawScrollBar.RIGHT;
            }
            break;
          }
        case DrawScrollBar.LEFT:
          {
            if (position.dx < hitThickness) {
              if (it.hitThumbY(position.dy))
                scrollBarSelection.vertical = DrawScrollBar.LEFT;
            }
            break;
          }
        default:
      }

      switch (it.drawHorizontalScrollBar) {
        case DrawScrollBar.BOTTOM:
          {
            if (_size.height - hitThickness < position.dy) {
              if (it.hitThumbX(position.dx))
                scrollBarSelection.horizontal = DrawScrollBar.BOTTOM;
            }
            break;
          }
        case DrawScrollBar.TOP:
          {
            if (position.dy < hitThickness) {
              if (it.hitThumbX(position.dx))
                scrollBarSelection.horizontal = DrawScrollBar.TOP;
            }
            break;
          }
        default:
      }

      scrollBarSelection.evaluate();

      if (scrollBarSelection.isSelected) {
        scrollBarSelection..setIndex(it.scrollIndexX, it.scrollIndexY);
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

  IterateScrollable({
    required this.metrics,
    required this.minThumbLength,
    required this.mimimalThumbHitLength,
    this.paddingTrackOutside = 0.0,
    this.paddingTrackInside = 0.0,
  });

  setScrollIndex(scrollIndexX, scrollIndexY) {
    this.scrollIndexX = scrollIndexX;
    this.scrollIndexY = scrollIndexY;
  }

  reset() {
    _count = 0;

    switch (metrics.stateSplitX) {
      case SplitState.FREEZE_SPLIT:
        {
          _startX = 1;
          _lengthX = 2;
          break;
        }
      case SplitState.SPLIT:
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
      case SplitState.FREEZE_SPLIT:
        {
          _startY = 1;
          _lengthY = 2;
          break;
        }
      case SplitState.SPLIT:
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

  double get paddingTrackBeginX => metrics.noSplitX
      ? paddingTrackOutside
      : (scrollIndexX == 0 ? paddingTrackOutside : paddingTrackInside);

  double get paddingTrackEndX => metrics.noSplitX
      ? paddingTrackOutside
      : (scrollIndexX == 0 ? paddingTrackInside : paddingTrackOutside);

  double get paddingTrackBeginY => metrics.noSplitY
      ? paddingTrackOutside
      : (scrollIndexY == 0 ? paddingTrackOutside : paddingTrackInside);

  double get paddingTrackEndY => metrics.noSplitY
      ? paddingTrackOutside
      : (scrollIndexY == 0 ? paddingTrackInside : paddingTrackOutside);

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
  DrawScrollBar selected = DrawScrollBar.NONE;
  DrawScrollBar vertical = DrawScrollBar.NONE;
  DrawScrollBar horizontal = DrawScrollBar.NONE;
  late DragDownDetails dragDownDetails;

  setIndex(int scrollIndexX, int scrollIndexY) {
    this.scrollIndexX = scrollIndexX;
    this.scrollIndexY = scrollIndexY;
  }

  reset() {
    scrollIndexX = 0;
    scrollIndexY = 0;
    selected = DrawScrollBar.NONE;
    vertical = DrawScrollBar.NONE;
    horizontal = DrawScrollBar.NONE;
  }

  evaluate() {
    if (vertical != DrawScrollBar.NONE && horizontal != DrawScrollBar.NONE) {
      selected = DrawScrollBar.MULTIPLE;
    } else if (vertical != DrawScrollBar.NONE) {
      selected = vertical;
    } else if (horizontal != DrawScrollBar.NONE) {
      selected = horizontal;
    }
  }

  evaluateDirection(DragStartDetails dragStartDetails) {
    if (selected == DrawScrollBar.MULTIPLE) {
      Offset delta =
          (dragDownDetails.localPosition - dragStartDetails.localPosition);
      selected = delta.dy.abs() > delta.dx.abs() ? vertical : horizontal;
    }
  }

  bool get isSelected => selected != DrawScrollBar.NONE;

  TableScrollDirection get scrollDirection {
    TableScrollDirection direction;

    switch (selected) {
      case DrawScrollBar.LEFT:
      case DrawScrollBar.RIGHT:
        {
          direction = TableScrollDirection.vertical;
          break;
        }
      case DrawScrollBar.TOP:
      case DrawScrollBar.BOTTOM:
        {
          direction = TableScrollDirection.horizontal;
          break;
        }
      case DrawScrollBar.MULTIPLE:
        direction = TableScrollDirection.both;
        break;
      default:
        direction = TableScrollDirection.unknown;
    }

    return direction;
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is ScrollBarSelection &&
        o.scrollIndexX == scrollIndexX &&
        o.scrollIndexY == scrollIndexY;
  }

  @override
  int get hashCode =>
      scrollIndexX.hashCode ^ scrollIndexY.hashCode ^ selected.hashCode;

  @override
  String toString() =>
      'SelectedScrollBar(scrollIndexX: $scrollIndexX, scrollIndexY: $scrollIndexY, selected: $selected)';
}
