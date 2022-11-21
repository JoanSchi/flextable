import 'dart:math' as math;
import 'package:flutter/material.dart';

class About extends StatefulWidget {
  final Widget about;
  final Widget body;
  final AboutNotification notification;

  const About({
    Key? key,
    required this.about,
    required this.body,
    required this.notification,
  }) : super(key: key);

  @override
  State<About> createState() => _AboutState();
}

class _AboutState extends State<About> with SingleTickerProviderStateMixin {
  late final AnimationController _animationController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  late final Animation _animation =
      CurveTween(curve: Curves.easeInOut).animate(_animationController);

  @override
  void initState() {
    _animationController.value = widget.notification.visible ? 0.0 : 1.0;
    widget.notification.addListener(change);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  dispose() {
    widget.notification.removeListener(change);
    super.dispose();
  }

  change() {
    if (widget.notification.visible) {
      _animationController.reverse();
    } else {
      _animationController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final height = constraints.maxHeight;

      double minHeight = math.max(height / 5.0, 64.0);

      if (minHeight > height / 2.0) {
        minHeight = height / 2.0;
      }

      return AnimatedBuilder(
          animation: _animationController,
          builder: (BuildContext context, Widget? child) {
            return CustomMultiChildLayout(
              delegate: AboutDelegate(
                  animationValue: _animation.value, minHeight: minHeight),
              children: [
                if (_animation.value != 1.0)
                  LayoutId(
                      key: const Key('about'),
                      id: 'about',
                      child: widget.about),
                if (_animation.value != 1.0)
                  LayoutId(
                    key: const Key('show'),
                    id: 'show',
                    child: Material(
                        color: theme.primaryColor,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.0)),
                        child: InkWell(
                            onTap: show,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: 12.0, horizontal: 16.0),
                              child: Text('Show me'),
                            ))),
                  ),
                LayoutId(
                  key: const Key('body'),
                  id: 'body',
                  child: widget.body,
                ),
              ],
            );
          });
    });
  }

  show() {
    widget.notification.visible = false;
  }
}

class AboutDelegate extends MultiChildLayoutDelegate {
  double animationValue;
  double minHeight;

  AboutDelegate({
    required this.animationValue,
    required this.minHeight,
  });

  @override
  void performLayout(Size size) {
    final width = size.width;
    final height = size.height;
    final heightBottom = minHeight + (height - minHeight) * animationValue;

    if (hasChild('about')) {
      final sizeAbout = layoutChild('about',
          BoxConstraints(maxWidth: size.width, maxHeight: height - minHeight));
      positionChild('show', Offset((width - sizeAbout.width) / 2.0, 0.0));
    }

    if (hasChild('show')) {
      final sizeShow = layoutChild(
          'show', BoxConstraints(maxWidth: size.width, maxHeight: size.height));
      positionChild(
          'show',
          Offset((width - sizeShow.width) / 2.0,
              height - minHeight - sizeShow.height - 8.0));
    }

    final sizeBottom = layoutChild(
        'body', BoxConstraints(maxWidth: size.width, maxHeight: heightBottom));
    positionChild('body', Offset(0.0, height - sizeBottom.height));
  }

  @override
  bool shouldRelayout(AboutDelegate oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        minHeight != oldDelegate.animationValue;
  }
}

class AboutNotification extends ChangeNotifier {
  bool _visible = true;

  changeVisible() {
    _visible = !_visible;
    notifyListeners();
  }

  set visible(bool value) {
    if (value != _visible) {
      _visible = value;
      notifyListeners();
    }
  }

  bool get visible => _visible;
}
