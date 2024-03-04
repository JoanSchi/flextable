import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef RequestNextFocusCallback = bool Function(String value);
typedef UnfocusCallback<T> = Function(
    UnfocusDisposition disposition, T value, bool escape);

enum FtTextEditInputType { digits, decimal, text }

typedef ObtainSharedTextEditController = TextEditingController Function(
    String text);
typedef RemoveSharedTextEditController = Function();

class FtEditText extends StatefulWidget {
  const FtEditText(
      {super.key,
      required this.requestFocus,
      required this.requestNextFocusCallback,
      required this.requestNextFocus,
      required this.focus,
      required this.unFocus,
      this.textStyle,
      this.text = '',
      this.textAlign = TextAlign.start,
      this.onValueChanged,
      this.editInputType = FtTextEditInputType.text,
      this.obtainSharedTextEditController,
      this.removeSharedTextEditController})
      : assert(
            (obtainSharedTextEditController == null &&
                    removeSharedTextEditController == null) ||
                (obtainSharedTextEditController != null &&
                    removeSharedTextEditController != null),
            'Both obtainSharedTextEditController or removeSharedTextEditController should not be null, or both null if the default textController is desired!');

  final bool requestFocus;
  final RequestNextFocusCallback? requestNextFocusCallback;
  final bool requestNextFocus;
  final VoidCallback focus;
  final UnfocusCallback<String> unFocus;
  final TextStyle? textStyle;
  final String text;
  final TextAlign textAlign;
  final ValueChanged<String>? onValueChanged;
  final FtTextEditInputType editInputType;
  final ObtainSharedTextEditController? obtainSharedTextEditController;
  final RemoveSharedTextEditController? removeSharedTextEditController;

  @override
  State<FtEditText> createState() => _FtEditTextState();
}

class _FtEditTextState extends State<FtEditText> {
  bool hasFocus = false;

  late TextEditingController tec;
  late final SkipFocusNode focusNode =
      SkipFocusNode(requestNextFocusCallback: () {
    if ((widget.requestNextFocus, widget.requestNextFocusCallback)
        case (true, RequestNextFocusCallback v)) {
      return v(tec.text);
    }
    return false;
  }, unfocusCallback: (UnfocusDisposition unfocusDisposition, bool escape) {
    widget.unFocus(unfocusDisposition, tec.text, escape);
  });

  ObtainSharedTextEditController? obtainSharedTextEditController;
  RemoveSharedTextEditController? removeSharedTextEditController;

  @override
  void initState() {
    obtainSharedTextEditController = widget.obtainSharedTextEditController;
    removeSharedTextEditController = widget.removeSharedTextEditController;

    tec = obtainSharedTextEditController?.call(widget.text) ??
        TextEditingController(text: widget.text);

    focusNode.addListener(() {
      if (focusNode.hasFocus && !hasFocus) {
        widget.focus();
      }
      hasFocus = focusNode.hasFocus;
    });

    /// If the request is scheduled then the keyboard is to fast and widget is lost before focus
    ///
    ///
    focusNode.requestFocus();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant FtEditText oldWidget) {
    // if (widget.requestNextFocusCallback != oldWidget.requestNextFocusCallback) {
    //   focusNode.requestNextFocusCallback = widget.requestNextFocusCallback;
    // }
    // scheduleRequestFocus();
    // focusNode.requestFocus();
    focusNode.safetyStop = false;
    super.didUpdateWidget(oldWidget);
  }

  void scheduleRequestFocus() {
    if (!focusNode.hasFocus) {
      scheduleMicrotask(() {
        focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    if (removeSharedTextEditController
        case RemoveSharedTextEditController removeSharedTextEditor) {
      removeSharedTextEditor();
    } else {
      tec.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      keyboardType: switch (widget.editInputType) {
        FtTextEditInputType.digits =>
          const TextInputType.numberWithOptions(decimal: false),
        FtTextEditInputType.decimal =>
          const TextInputType.numberWithOptions(decimal: true),
        FtTextEditInputType.text => TextInputType.text,
      },
      inputFormatters: switch (widget.editInputType) {
        FtTextEditInputType.digits => <TextInputFormatter>[
            FilteringTextInputFormatter.digitsOnly
          ],
        FtTextEditInputType.decimal => <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
          ],
        FtTextEditInputType.text => null,
      },
      textAlign: widget.textAlign,
      style: widget.textStyle,
      focusNode: focusNode,
      canRequestFocus: true,
      controller: tec,
      textInputAction:
          widget.requestNextFocus ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (String value) {
        widget.onValueChanged?.call(value);
      },
    );
  }
}

class SkipFocusNode extends FocusNode {
  bool Function()? requestNextFocusCallback;
  Function(UnfocusDisposition disposition, bool escape) unfocusCallback;

  bool skipUnfocusCallback = false;
  bool escape = false;
  bool safetyStop = false;

  SkipFocusNode(
      {required this.requestNextFocusCallback, required this.unfocusCallback});

  @override
  bool nextFocus() {
    skipUnfocusCallback = requestNextFocusCallback?.call() ?? false;
    return false;

    //return super.nextFocus();
  }

  @override
  void requestFocus([FocusNode? node]) {
    super.requestFocus();
  }

  @override
  void unfocus({
    UnfocusDisposition disposition = UnfocusDisposition.scope,
  }) {
    super.unfocus(disposition: disposition);

    /// If enclosingScope == null, then widget out of tree, disposed skip call?
    ///
    ///
    if (enclosingScope == null) {
      return;
    }
    if (skipUnfocusCallback) {
      skipUnfocusCallback = false;
    } else {
      unfocusCallback(disposition, escape || safetyStop);
      escape = false;
    }
  }
}
