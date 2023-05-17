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
  final CombiKeyNotification combiKeyNotification;
  final Widget child;

  const CombiKey({
    Key? key,
    required this.combiKeyNotification,
    required this.child,
  }) : super(key: key);

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
