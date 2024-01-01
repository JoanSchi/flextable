// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class SelectionKeepAlive extends StatefulWidget {
  /// Creates a widget that listens to [KeepAliveNotification]s and maintains a
  /// [KeepAlive] widget appropriately.
  const SelectionKeepAlive({
    super.key,
    required this.child,
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<SelectionKeepAlive> createState() => _SelectionKeepAliveState();
}

class _SelectionKeepAliveState extends State<SelectionKeepAlive>
    with AutomaticKeepAliveClientMixin
    implements SelectionRegistrar {
  Set<Selectable>? _selectablesWithSelections;
  Map<Selectable, VoidCallback>? _selectableAttachments;
  SelectionRegistrar? _registrar;

  @override
  bool get wantKeepAlive => _wantKeepAlive;
  bool _wantKeepAlive = false;
  set wantKeepAlive(bool value) {
    if (_wantKeepAlive != value) {
      _wantKeepAlive = value;
      updateKeepAlive();
    }
  }

  VoidCallback listensTo(Selectable selectable) {
    return () {
      if (selectable.value.hasSelection) {
        _updateSelectablesWithSelections(selectable, add: true);
      } else {
        _updateSelectablesWithSelections(selectable, add: false);
      }
    };
  }

  void _updateSelectablesWithSelections(Selectable selectable,
      {required bool add}) {
    if (add) {
      assert(selectable.value.hasSelection);
      _selectablesWithSelections ??= <Selectable>{};
      _selectablesWithSelections!.add(selectable);
    } else {
      _selectablesWithSelections?.remove(selectable);
    }
    wantKeepAlive = _selectablesWithSelections?.isNotEmpty ?? false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final SelectionRegistrar? newRegistrar =
        SelectionContainer.maybeOf(context);
    if (_registrar != newRegistrar) {
      if (_registrar != null) {
        _selectableAttachments?.keys.forEach(_registrar!.remove);
      }
      _registrar = newRegistrar;
      if (_registrar != null) {
        _selectableAttachments?.keys.forEach(_registrar!.add);
      }
    }
  }

  @override
  void add(Selectable selectable) {
    final VoidCallback attachment = listensTo(selectable);
    selectable.addListener(attachment);
    _selectableAttachments ??= <Selectable, VoidCallback>{};
    _selectableAttachments![selectable] = attachment;
    _registrar!.add(selectable);
    if (selectable.value.hasSelection) {
      _updateSelectablesWithSelections(selectable, add: true);
    }
  }

  @override
  void remove(Selectable selectable) {
    if (_selectableAttachments == null) {
      return;
    }
    assert(_selectableAttachments!.containsKey(selectable));
    final VoidCallback attachment = _selectableAttachments!.remove(selectable)!;
    selectable.removeListener(attachment);
    _registrar!.remove(selectable);
    _updateSelectablesWithSelections(selectable, add: false);
  }

  @override
  void dispose() {
    if (_selectableAttachments != null) {
      for (final Selectable selectable in _selectableAttachments!.keys) {
        _registrar!.remove(selectable);
        selectable.removeListener(_selectableAttachments![selectable]!);
      }
      _selectableAttachments = null;
    }
    _selectablesWithSelections = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_registrar == null) {
      return widget.child;
    }
    return SelectionRegistrarScope(
      registrar: this,
      child: widget.child,
    );
  }
}
