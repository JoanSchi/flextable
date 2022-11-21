import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'TableScroll.dart';

typedef TableScrollCallback = Function(String notification);
typedef TableScaleCallback = Function(double scale);

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final VoidCallback listener;
}

class _ScrollListenerEntry extends LinkedListEntry<_ScrollListenerEntry> {
  _ScrollListenerEntry(this.listener);
  final TableScrollCallback listener;
}

class _TableScaleListenerEntry extends LinkedListEntry<_TableScaleListenerEntry> {
  _TableScaleListenerEntry(this.listener);
  final TableScaleCallback listener;
}

class TableChangeNotifier {
  ScrollPosition? _sliverScrollPosition;
  late TableScrollPosition tableScrollPosition;
  LinkedList<_ListenerEntry> _listeners = LinkedList<_ListenerEntry>();
  LinkedList<_ScrollListenerEntry> _scrollListeners = LinkedList<_ScrollListenerEntry>();
  LinkedList<_TableScaleListenerEntry> _tableScaleListeners = LinkedList<_TableScaleListenerEntry>();
  VoidCallback? updateScrollBar;

  set sliverScrollPosition(ScrollPosition? value) {
    if (_sliverScrollPosition != value) {
      _sliverScrollPosition?.removeListener(notifyListeners);
      _sliverScrollPosition = value;
      _sliverScrollPosition?.addListener(notifyListeners);
    }
  }

  ScrollPosition? get sliverScrollPosition => _sliverScrollPosition;

  bool get hasListeners {
    return _listeners.isNotEmpty;
  }

  void addListener(VoidCallback listener) {
    _listeners.add(_ListenerEntry(listener));
  }

  void addScrollListener(TableScrollCallback listener) {
    _scrollListeners.add(_ScrollListenerEntry((listener)));
  }

  void addTableScaleListener(TableScaleCallback listener) {
    _tableScaleListeners.add(_TableScaleListenerEntry((listener)));
  }

  void removeListener(VoidCallback listener) {
    for (final _ListenerEntry entry in _listeners) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  void removeScrollListener(TableScrollCallback listener) {
    for (final _ScrollListenerEntry entry in _scrollListeners) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  void removeTableScaleListener(TableScaleCallback listener) {
    for (final _TableScaleListenerEntry entry in _tableScaleListeners) {
      if (entry.listener == listener) {
        entry.unlink();
        return;
      }
    }
  }

  /// Discards any resources used by the object. After this is called, the
  /// object is not in a usable state and should be discarded (calls to
  /// [addListener] and [removeListener] will throw after the object is
  /// disposed).
  ///
  /// This method should only be called by the object's owner.
  @mustCallSuper
  void dispose() {
    assert(_listeners.isEmpty, 'The list of _listeners contains ${_listeners.length} listeners');
    assert(_scrollListeners.isEmpty, 'The list of _scrollListeners contains ${_scrollListeners.length} listeners');
    // assert(
    //     _tableScaleListeners.isEmpty, 'The list of _zoomStateListeners contains ${_scrollListeners.length} listeners');
    _listeners.clear();
    _scrollListeners.clear();
    _tableScaleListeners.clear();
    _sliverScrollPosition?.removeListener(notifyListeners);
    _sliverScrollPosition = null;
  }

  void notifyListeners() {
    if (_listeners.isEmpty) return;

    final List<_ListenerEntry> localListeners = List<_ListenerEntry>.from(_listeners);

    for (final _ListenerEntry entry in localListeners) {
      try {
        if (entry.list != null) entry.listener();
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'foundation library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<TableChangeNotifier>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }

  void notifyScrollListeners(String notifier) {
    if (_listeners.isEmpty) return;

    final List<_ScrollListenerEntry> localListeners = List<_ScrollListenerEntry>.from(_scrollListeners);

    for (final _ScrollListenerEntry entry in localListeners) {
      try {
        if (entry.list != null) entry.listener(notifier);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'foundation library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<TableChangeNotifier>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }

  void notifyTableScaleListeners(double tableScale) {
    if (_listeners.isEmpty) return;

    final List<_TableScaleListenerEntry> localListeners = List<_TableScaleListenerEntry>.from(_tableScaleListeners);

    for (final _TableScaleListenerEntry entry in localListeners) {
      try {
        if (entry.list != null) entry.listener(tableScale);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'foundation library',
          context: ErrorDescription('while dispatching notifications for $runtimeType'),
          informationCollector: () sync* {
            yield DiagnosticsProperty<TableChangeNotifier>(
              'The $runtimeType sending notification was',
              this,
              style: DiagnosticsTreeStyle.errorProperty,
            );
          },
        ));
      }
    }
  }

  void notifyScrollBarListeners() {
    if (updateScrollBar != null) {
      updateScrollBar!();
    }
  }
}
