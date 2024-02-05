// ignore_for_file: public_member_api_docs, sort_constructors_first
// Copyright 2023 Joan Schipper. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

import 'package:flutter/widgets.dart';

enum LineOptions { no, line }

const noLine = Line.no();

typedef LineLinkedMerge<E extends LineLinkedListEntry<E>> = E Function(
    E link, E merge);

bool check = false;

class TableLinesOneDirection extends LineLinkedList<LineRange> {
  TableLinesOneDirection() : super(addEmpty: false);

  void addLineRange(
    LineRange lineRange,
  ) {
    _add(
      lineRange,
      merge,
    );
  }

  void addLineRanges(Function(Function(LineRange lineRange) add) create,
      {addEmpty = false}) {
    create((LineRange lineRange) => _add(
          lineRange,
          merge,
        ));
  }

  LineRange merge(LineRange found, LineRange link) {
    // assert(link is LineRange);
    // assert(merge is LineRange);

    final list = link.lineNodeRange;
    final newLineNodeRange = found.lineNodeRange._copy();

    LineNode? node = list.first;

    /// The node is in a list and therefore copy wil be made with
    ///
    ///
    while (node != null) {
      newLineNodeRange.addLineNode(node);
      node = node.next;
    }

    return LineRange(
        lineNodeRange: newLineNodeRange,
        startIndex: link.startIndex,
        endIndex: link.endIndex);
  }

  @override
  String toString() => 'LineRanges in TableLinesOneDirection: ${() {
        LineRange? n = first;
        String toString = n == null ? '\n empty' : '';
        while (n != null) {
          toString += '\n ${n.toString()}';
          n = n.next;
        }

        return toString;
      }()}';
}

class LineRange extends LineLinkedListEntry<LineRange> {
  LineRange({
    required super.startIndex,
    super.endIndex,
    required this.lineNodeRange,
  });

  LineNodeRange lineNodeRange;

  @override
  bool operator <(LineRange o) => startIndex < o.startIndex;

  @override
  bool operator >(LineRange o) => endIndex > o.endIndex;

  @override
  bool goToNext(LineRange entry) {
    return endIndex < entry.startIndex &&
        (next != null && next!.startIndex <= entry.startIndex);
  }

  @override
  bool goToPrevious(LineRange entry) {
    return entry.endIndex < startIndex ||
        (previous != null && entry.startIndex <= previous!.endIndex);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LineRange && other.lineNodeRange == lineNodeRange;
  }

  @override
  int get hashCode => lineNodeRange.hashCode;

  @override
  bool equalLink(LineRange? o) {
    if (identical(this, o)) return true;

    return o != null && lineNodeRange == o.lineNodeRange;
  }

  @override
  bool get isEmpty {
    if (lineNodeRange.isEmpty) {
      return true;
    } else {
      var link = lineNodeRange.first;

      while (link != null) {
        if (link.isNotEmpty) {
          return false;
        }
        link = link.next;
      }
    }
    return true;
  }

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() => '- LineNodeRange $startIndex-$endIndex: $lineNodeRange';

  @override
  LineRange _copy() => LineRange(
      startIndex: startIndex,
      endIndex: endIndex,
      lineNodeRange: lineNodeRange._copy());

  @override
  LineRange _shallowCopy() {
    return LineRange(
      startIndex: startIndex,
      endIndex: endIndex,
      lineNodeRange: lineNodeRange,
    );
  }
}

class LineNodeRange extends LineLinkedList<LineNode> {
  LineNodeRange({
    List<LineNode>? list,
    Function(Function(LineNode lineNode) add)? create,
  }) : super(addEmpty: true) {
    if (list != null) {
      for (LineNode lineNode in list) {
        _add(lineNode, merge);
      }
    }

    create?.call((lineNode) => _add(lineNode, merge));
  }

  LineNodeRange._noEmptyNodes() : super(addEmpty: false);

  addLineNode(
    LineNode lineNode,
  ) {
    _add(
      lineNode,
      merge,
    );
  }

  addLineNodes(
    Function(Function(LineNode lineNode) create) create,
  ) {
    create((lineNode) => _add(lineNode, merge));
  }

  LineNodeRange _copy() {
    final lineList = LineNodeRange._noEmptyNodes();
    LineNode? link = _first;
    LineNode? entryCopy;

    while (link != null) {
      if (link.isNotEmpty) {
        final copyLink = link._copy();
        lineList._insertAfter(entryCopy, copyLink);
        entryCopy = copyLink;
      }
      link = link.next;
    }

    return lineList;
  }

  LineNode merge(LineNode lineNode, LineNode merge) {
    return lineNode.merge(merge);
  }

  @override
  String toString() {
    LineNode? n = first;
    String toString = n == null ? 'empty' : '';
    while (n != null) {
      toString += '\n -> ${n.toString()}';
      n = n.next;
    }

    return toString;
  }
}

abstract class LineLinkedList<E extends LineLinkedListEntry<E>> {
  // int _modificationCount = 0;
  int _length = 0;
  E? _first;
  E? _current;
  E? d0d0;
  E? d1d0;
  E? d0d1;
  E? d1d1;
  final bool _addEmpty;

  E begin(var index, int demensionOne, int demensionTwo, bool lock) {
    if (demensionOne == 0 || lock) {
      if (demensionTwo == 0) {
        d0d0 = toBegin(index: index, begin: d0d0);
        return d0d0!;
      } else {
        d0d1 = toBegin(index: index, begin: d0d1);
        return d0d1!;
      }
    } else {
      if (demensionTwo == 0) {
        d1d0 = toBegin(index: index, begin: d1d0);
        return d1d0!;
      } else {
        d0d1 = toBegin(index: index, begin: d1d1);
        return d0d1!;
      }
    }
  }

  _unlinkBeginners(E entry) {
    if (identical(entry, d1d0)) {
      d1d0 = null;
    }

    if (identical(entry, d0d1)) {
      d0d1 = null;
    }

    if (identical(entry, d1d1)) {
      d1d1 = null;
    }
  }

  LineLinkedList({required bool addEmpty}) : _addEmpty = addEmpty;

  _add(E link, LineLinkedMerge<E> merge) {
    /// The link is already in used if the list is not null.
    /// To prevent breaking of the the LinkedList the link will be coppied.
    ///

    assert(link.startIndex <= link.endIndex,
        'StartIndex is not smaller or equal compared to endIndex');

    if (_length == 0) {
      if (link.isNotEmpty || _addEmpty) {
        _insertBefore(null, link._copy(), updateFirst: false);
      }
    } else {
      E found = findOrBefore(link);

      if (link.endIndex < _first!.startIndex ||
          last!.endIndex < link.startIndex) {
        _addOutside(
          link,
          found,
        );
      } else if (found.startIndex <= link.startIndex &&
          found.endIndex >= link.endIndex) {
        _addInside(
          link,
          found,
          merge,
        );
      } else {
        //  found: 1_____  <        2 ______                              1 _____  <     2 ______
        //  li:                 ______________   found go to 2  or                    ______________  found go to 2
        //
        //  found: 1___________                                           found: 1___________
        //  li:           ____________ Nothing to do take found  or                              ____________ found to null

        // A shellow copy to prevent change in the indexes in the origal link
        //
        //

        link = link._shallowCopy();

        if (found.endIndex < link.startIndex && found.next != null) {
          found = found.next!;
        }

        while (true) {
          if (found.startIndex > link.startIndex) {
            if (link.endIndex < found.startIndex) {
              // 2
              _addOutside(link, found.previous);
              break;
            } else {
              // 1

              final endLink = link.endIndex;
              final startFound = found.startIndex;

              // At first part of the link before found
              // Reduce the link and merge in the next round
              //

              final newFound = _addOutside(
                link..endIndex = startFound - 1,
                found.previous,
              );

              link.startIndex = startFound;
              link.endIndex = endLink;

              if (newFound != null) {
                found = newFound;
              }
            }
          }

          if (found.endIndex < link.endIndex) {
            //    found:  ___
            //    li:     ________
            //    continue

            final endFound = found.endIndex;
            final endLink = link.endIndex;

            E? nextFound = _addInside(link..endIndex = endFound, found, merge);

            if (_length == 0 || nextFound == null) {
              break;
            }
            found = nextFound;

            link.startIndex = endFound + 1;
            link.endIndex = endLink;

            assert(link.startIndex <= link.endIndex,
                'start: ${link.startIndex} end: ${link.endIndex}');
          } else if (link.endIndex <= found.endIndex) {
            //    found:  _______________
            //    li:     ________
            //    break

            _addInside(link, found, merge);
            break;
          } else {
            assert(false, 'Endless loop in TableLine function add?');
          }

          if (link.startIndex > found.endIndex) {
            if (found.next == null) {
              //  Found:     ______               Outside and break
              //  li:                 ___________

              _addOutside(link, last);
              break;
            }

            found = found.next!;
          }
        }
      }
    }
  }

  E? _addOutside(E link, E? found) {
    E? newFound;

    link = link._copy();

    if (found == null || link.endIndex < found.startIndex) {
      if (link.isNotEmpty || _addEmpty) {
        if (link.equalInterceptAndJoined(_first)) {
          _first!.startIndex = link.startIndex;
          newFound = _first;
        } else {
          _insertBefore(_first, link, updateFirst: true);
          assert(link.next == null || link.endIndex < link.next!.startIndex,
              'Overlap is not alought');
          newFound = link;
        }
      }
    } else if (found.endIndex < link.startIndex) {
      if (link.isNotEmpty || _addEmpty) {
        _insertAfter(found, link);
        assert(link.next == null || link.endIndex < link.next!.startIndex,
            'Overlap is not alought endIndex: ${link.endIndex} startIndex: ${link._next!.startIndex}');
        newFound = assimilate(link);
      }
    } else {
      assert(false,
          'Not ouside with _AddOutside, this should not happen link: $link, found $found');
    }

    return newFound;
  }

  E? _addInside(E link, E found, LineLinkedMerge<E> merge) {
    E? newFound;

    if (found.startIndex == link.startIndex &&
        found.endIndex == link.endIndex) {
      final adjusted = merge(found, link);

      if (adjusted.isNotEmpty || _addEmpty) {
        if (adjusted.differentIntercept(found)) {
          replace(found, adjusted);
          newFound = assimilate(adjusted);
        } else {
          newFound = found;
        }
      } else {
        newFound = found._next;
        _unlink(found);
      }
    } else if (found.startIndex <= link.startIndex &&
        found.endIndex >= link.endIndex) {
      final adjusted = merge(found, link);

      if (adjusted.startIndex > found.startIndex &&
          adjusted.endIndex < found.endIndex) {
        final foundLeft = found;
        final foundRight = found._copy();

        foundLeft.endIndex = adjusted.startIndex - 1;
        foundRight.startIndex = adjusted.endIndex + 1;

        _insertAfter(foundLeft, foundRight);

        if (adjusted.isNotEmpty || _addEmpty) {
          _insertAfter(foundLeft, adjusted);
        }
        newFound = foundRight;
      } else if (adjusted.startIndex == found.startIndex) {
        assert(adjusted.endIndex <= found.endIndex,
            'EndIndex out of bound: ${adjusted.endIndex}, startIndex equal');

        found.startIndex = adjusted.endIndex + 1;

        if (adjusted.equalInterceptAndJoined(found.previous)) {
          newFound = found..previous!.endIndex = adjusted.endIndex;
        } else if (adjusted.isNotEmpty || _addEmpty) {
          _insertBefore(found, adjusted, updateFirst: identical(found, _first));
          newFound = adjusted;
        } else {
          newFound = found;
        }
      } else if (adjusted.endIndex == found.endIndex) {
        assert(adjusted.startIndex >= found.startIndex,
            'StartIndex out of bound ${adjusted.startIndex}, endIndex equal');

        found.endIndex = adjusted.startIndex - 1;

        if (adjusted.equalInterceptAndJoined(found.next)) {
          newFound = found..next!.startIndex = adjusted.startIndex;
        } else if (adjusted.isNotEmpty || _addEmpty) {
          _insertAfter(found, adjusted);
          newFound = adjusted;
        } else {
          newFound = found;
        }
      } else {
        newFound = found;
        throw ('StartIndex ${adjusted.startIndex < found.startIndex ? 'out' : 'in'} bound, endIndex ${adjusted.endIndex > found.endIndex ? 'out' : 'in'} bound');
      }
    } else {
      throw ('No option found to add the link in LineLinkedList function _addInside link startIndex: ${link.startIndex}, endIndex ${link.endIndex}, this is a properly a bug');
    }
    return newFound;
  }

  E assimilate(E link) {
    if (link.equalInterceptAndJoined(link.previous)) {
      final previous = link.previous!..endIndex = link.endIndex;
      _unlink(link);
      link = previous;
    }

    if (link.equalInterceptAndJoined(link.next)) {
      final next = link.next!..startIndex = link.startIndex;
      _unlink(link);
      return next;
    }

    return link;
  }

  E toBegin({E? begin, var index}) {
    if (begin?._list == null) {
      begin = _current ?? _first;
    }

    if (begin!.startIndex < index) {
      while (
          !identical(begin!._next, first) && begin._next!.endIndex <= index) {
        begin = begin._next;
      }
    } else if (begin.startIndex > index) {
      while (!identical(begin!._previous, last) && begin.startIndex > index) {
        begin = begin._previous;
      }
    }

    return begin;
  }

  /* Default linked list functions
   *
   * 
   * 
   * 
   * 
   * 
   * 
   * 
   * 
   * 
   */

  void _insertBefore(E? entry, E newEntry, {required bool updateFirst}) {
    if (newEntry.list != null) {
      throw StateError('LinkedListEntry is already in a LinkedList');
    }
    // _modificationCount++;

    newEntry._list = this;
    if (isEmpty) {
      assert(entry == null);
      newEntry._previous = newEntry._next = newEntry;
      _first = newEntry;
      _length++;
      return;
    }
    E predecessor = entry!._previous!;
    E successor = entry;
    newEntry._previous = predecessor;
    newEntry._next = successor;
    predecessor._next = newEntry;
    successor._previous = newEntry;
    if (updateFirst && identical(entry, _first)) {
      _first = newEntry;
    }
    _length++;
  }

  void _insertAfter(E? entry, E newEntry) {
    if (newEntry.list != null) {
      throw StateError('LinkedListEntry is already in a LinkedList');
    }
    // _modificationCount++;

    newEntry._list = this;
    if (isEmpty) {
      newEntry._previous = newEntry._next = newEntry;
      _first = newEntry;
      _length++;
      return;
    }

    if (entry == null) throw ('Entry can only be null if the list is null');

    E predecessor = entry;
    E successor = entry._next!;

    newEntry._previous = entry;
    newEntry._next = successor;
    predecessor._next = newEntry;
    successor._previous = newEntry;

    _length++;
  }

  void _unlink(E entry) {
    // _modificationCount++;

    entry._next!._previous = entry._previous;
    E? next = entry._previous!._next = entry._next;
    _length--;
    entry._list = entry._next = entry._previous = null;

    if (isEmpty) {
      _first = null;
    } else if (identical(entry, _first)) {
      _first = next;
    }

    //added Joan
    if (identical(_current, entry)) {
      _current = next;
    }
    _unlinkBeginners(entry);
  }

  bool get isEmpty => _length == 0;

  findOrBefore(E entry) {
    assert(_first != null, 'First cannot be null in function findOrBefore');

    _current ??= _first;

    if (_current! < entry) {
      while (!identical(_current!._next, _first) && _current!.goToNext(entry)) {
        _current = _current!._next;
      }
    } else {
      while (!identical(_current, _first) && _current!.goToPrevious(entry)) {
        _current = _current!._previous;
      }
    }

    return _current;
  }

  replace(E replace, E entry) {
    if (entry.list != null) {
      throw StateError('LinkedListEntry is already in a LinkedList');
    }

    entry._list = this;
    replace._next!._previous = entry;
    entry._next = replace._next;

    replace._previous!._next = entry;
    entry._previous = replace._previous;

    replace._list = replace._next = replace._previous = null;

    if (identical(_first, replace)) {
      _first = entry;
    }

    if (identical(_current, replace)) {
      _current = entry;
    }
  }

  E? get last => _first!._previous;

  E? get first => _first;

  setCurrentToFirst() {
    _current = _first;
  }

  setCurrentToLast() {
    _current = _first!._previous;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    if (other is LineLinkedList<E> && other._length == _length) {
      var element = _first;
      var elementObject = other._first;

      while (element != null) {
        if (element == elementObject) {
          element = element.next;
          elementObject = elementObject?.next;
        } else {
          return false;
        }
      }
      return true;
    }

    return false;
  }

  @override
  int get hashCode {
    var hashCode = _length.hashCode;

    var element = _first;

    while (element != null) {
      hashCode = hashCode ^ element.hashCode;
    }

    return hashCode;
  }
}

class EmptyLineNode extends LineNode {
  EmptyLineNode({
    required super.startIndex,
    super.endIndex,
  }) : super(before: noLine, after: noLine);
}

class LineNode extends LineLinkedListEntry<LineNode> {
  LineNode({
    required super.startIndex,
    super.endIndex,
    this.before,
    this.after,
  });

  final Line? before;
  final Line? after;

  LineNode merge(LineNode lineNode) {
    return LineNode(
      before: before?.merge(lineNode.before) ?? lineNode.before,
      after: after?.merge(lineNode.after) ?? lineNode.after,
      startIndex: lineNode.startIndex,
      endIndex: lineNode.endIndex,
    );
  }

  @override
  bool get isEmpty {
    return (before?.isEmpty ?? true) && (after?.isEmpty ?? true);
  }

  @override
  bool get isNotEmpty => !isEmpty;

  @override
  bool operator >(LineNode o) => startIndex > o.startIndex;

  @override
  bool operator <(LineNode o) => startIndex < o.startIndex;

  @override
  bool equalLink(LineNode? o) {
    if (identical(this, o)) return true;

    return o != null && o.before == before && o.after == after;
  }

  @override
  String toString() {
    return 'LineNode $startIndex-$endIndex: before: $before, after: $after';
  }

  // entry.endIndex < startIndex
  //  - this in list  :  1 ____ <    2 ____ <                      3 ____ <                                1 ____ <    2 ____ <                      3 ____ <
  //  - entry         :                          ______________                jump to 2 (see below)                              ..............             jump to 3
  //
  // entry.startIndex <= previous.startIndex
  //  - this in list  :             1 <= next ___    2 <= next ____
  //  - entry         :          _____________________________________           go to 1
  //
  @override
  bool goToNext(LineNode entry) {
    return endIndex < entry.startIndex &&
        (next != null) &&
        next!.startIndex <= entry.startIndex;
  }

  // entry.endIndex < startIndex
  //  - this in list  :     < ____ 1                    < ____ 2     < ____ 3                                    < ____ 1                < ____ 2     < ____ 3
  //  - entry         :                _____________                              jump to 2 see below     or              ...........                             jump to 1
  //
  // entry.startIndex <= previous.endIndex
  //  - this in list  :            <=  previous __ 1  <=  previous___2            < ____
  //  - entry         :          ______________________________________________           go to 1
  //
  @override
  goToPrevious(LineNode entry) {
    return entry.endIndex < startIndex ||
        (previous != null && entry.startIndex <= previous!.endIndex);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LineNode &&
        other.startIndex == startIndex &&
        other.endIndex == endIndex &&
        other.before == before &&
        other.after == after;
  }

  @override
  int get hashCode {
    return before.hashCode ^ after.hashCode;
  }

  @override
  LineNode _copy() {
    return LineNode(
      before: before,
      after: after,
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  @override
  LineNode _shallowCopy() {
    return LineNode(
      startIndex: startIndex,
      endIndex: endIndex,
      before: before,
      after: after,
    );
  }
}

class Line {
  const Line({
    this.line = LineOptions.line,
    this.width,
    this.color,
    this.lowestScale = 0.5,
    this.highestScale = 2.0,
  }) : assert(
            (line == null || line == LineOptions.no) ||
                (line == LineOptions.line && width != null && color != null),
            'Width and color can not be null if tableLineOption is a line.');

  const Line.change({
    this.width,
    this.color,
    this.lowestScale = 0.5,
    this.highestScale = 2.0,
  }) : line = null;

  const Line.no()
      : line = LineOptions.no,
        width = null,
        color = null,
        lowestScale = 0.5,
        highestScale = 2.0;

  final LineOptions? line;
  final double? width;
  final Color? color;
  final double lowestScale;
  final double highestScale;

  @override
  String toString() => 'Line(o:$line, w:$width, c:$color)';

  Line merge(Line? o) {
    if ((line == null || line == LineOptions.no) && o?.line == null) {
      return Line(line: line);
    } else if (o?.line == LineOptions.no) {
      return const Line(line: LineOptions.no);
    }

    return Line(
        line: o?.line ?? line,
        width: o?.width ?? width,
        color: o?.color ?? color,
        lowestScale: o?.lowestScale ?? lowestScale,
        highestScale: o?.highestScale ?? highestScale);
  }

  bool get isEmpty =>
      line == null || line == LineOptions.no || width == 0.0 || color == null;

  widthScaled(double scale) =>
      width ??
      1.0 *
          (scale < lowestScale
              ? lowestScale
              : (scale > highestScale ? highestScale : scale));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Line &&
        other.line == line &&
        other.width == width &&
        other.color == color &&
        other.lowestScale == lowestScale &&
        other.highestScale == highestScale;
  }

  @override
  int get hashCode {
    return line.hashCode ^
        width.hashCode ^
        color.hashCode ^
        lowestScale.hashCode ^
        highestScale.hashCode;
  }
}

abstract class LineLinkedListEntry<E extends LineLinkedListEntry<E>> {
  LineLinkedListEntry({required this.startIndex, int? endIndex})
      : endIndex = endIndex ?? startIndex;

  LineLinkedList<E>? _list;
  E? _next;
  E? _previous;
  int startIndex;
  int endIndex;

  int get start => startIndex;

  int get end => endIndex;

  /// Get the linked list containing this element.
  ///
  /// Returns `null` if this entry is not currently in any list.
  LineLinkedList<E>? get list => _list;

  /// Unlink the element from its linked list.
  ///
  /// The entry must currently be in a linked list when this method is called.
  void unlink() {
    _list!._unlink(this as E);
  }

  /// Return the successor of this element in its linked list.
  ///
  /// Returns `null` if there is no successor in the linked list, or if this
  /// entry is not currently in any list.
  E? get next {
    if (_list == null || identical(_list!._first, _next)) return null;
    return _next;
  }

  /// Return the predecessor of this element in its linked list.
  ///
  /// Returns `null` if there is no predecessor in the linked list, or if this
  /// entry is not currently in any list.
  E? get previous {
    if (_list == null || identical(this, _list!._first)) return null;
    return _previous;
  }

  /// Insert an element after this element in this element's linked list.
  ///
  /// This entry must be in a linked list when this method is called.
  /// The [entry] must not be in a linked list.
  void insertAfter(E entry) {
    _list!._insertBefore(_next, entry, updateFirst: false);
  }

  /// Insert an element before this element in this element's linked list.
  ///
  /// This entry must be in a linked list when this method is called.
  /// The [entry] must not be in a linked list.
  void insertBefore(E entry) {
    _list!._insertBefore(this as E, entry, updateFirst: true);
  }

  bool goToNext(E entry);

  bool goToPrevious(E entry);

  bool operator >(E o);

  bool operator <(E o);

  bool equalInterceptAndJoined(E? o) {
    return (o != null) &&
        equalLink(o) &&
        (startIndex < o.startIndex
            ? endIndex + 1 == o.startIndex
            : startIndex - 1 == o.endIndex);
  }

  bool equalLink(E? o);

  bool get isEmpty;

  bool get isNotEmpty;

  E _copy();

  bool differentIntercept(E o) => !equalLink(o);

  E _shallowCopy();
}
