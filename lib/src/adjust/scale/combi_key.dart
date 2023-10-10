// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class CombiKeyNotification extends ChangeNotifier {
  bool _focus = false;
  bool control = false;

  setKey(LogicalKeyboardKey key, bool enable) {
    if (key == LogicalKeyboardKey.controlLeft) {
      control = enable;
    }
    notifyListeners();
  }

  set focus(bool value) {
    if (_focus != value) {
      _focus = value;
      notifyListeners();
    }
  }
}

class CombiKey extends StatefulWidget {
  const CombiKey({
    super.key,
    required this.combiKeyNotification,
    required this.child,
  });

  final CombiKeyNotification combiKeyNotification;
  final Widget child;

  @override
  State<CombiKey> createState() => _CombiKeyState();
}

class _CombiKeyState extends State<CombiKey> {
  late final FocusNode _focusNode = FocusNode()
    ..addListener(() {
      widget.combiKeyNotification.focus = true;
    });

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
        onEnter: onEnter,
        onExit: onExit,
        child: GestureDetector(
            onTap: onTap,
            child: KeyboardListener(
                focusNode: _focusNode,
                onKeyEvent: onKeyEvent,
                child: widget.child)));
  }

  onEnter(PointerEnterEvent event) {
    _focusNode.requestFocus();
  }

  onExit(PointerExitEvent event) {
    widget.combiKeyNotification.focus = false;
  }

  onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      widget.combiKeyNotification.setKey(event.logicalKey, true);
    } else if (event is KeyUpEvent) {
      widget.combiKeyNotification.setKey(event.logicalKey, false);
    }
  }

  onTap() {
    _focusNode.requestFocus();
  }
}
