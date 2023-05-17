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

import 'package:flutter/material.dart';
import 'cells.dart';

enum TableLineOptions { grid, no, custom }

const _emptyLine = _EmptyLine();
const gridLine = Line.grid();
//const noLine = Line.NoLine();

typedef Merge = LineLinkedListEntry Function(
    LineLinkedListEntry link, LineLinkedListEntry merge);
typedef RequestNewIndex = Index Function(int newIndex);

var check = false;

class TableLineList extends LineLinkedList<TableLineNode> {
  RequestNewIndex requestLevelTwoIndex;

  TableLineList({
    required RequestNewIndex requestLevelOneIndex,
    required this.requestLevelTwoIndex,
  }) : super(requestNewIndex: requestLevelOneIndex);

  addLineNode(
      {var startLevelOneIndex,
      var endLevelOneIndex,
      var startLevelTwoIndex,
      var endLevelTwoIndex,
      required LineNode lineNode,
      addEmpty = false}) {
    // lineNode.setIndex(
    //     startIndex: startLevelTwoIndex is int
    //         ? requestLevelTwoIndex(startLevelTwoIndex)
    //         : requestLevelTwoIndex,
    //     endIndex: endLevelTwoIndex == null
    //         ? null
    //         : (endLevelTwoIndex is int
    //             ? requestLevelTwoIndex(endLevelTwoIndex)
    //             : endLevelTwoIndex));

    add(
        TableLineNode(
            startIndex: startLevelOneIndex is int
                ? requestNewIndex(startLevelOneIndex)
                : startLevelOneIndex,
            endIndex: endLevelOneIndex == null
                ? null
                : (endLevelOneIndex is int
                    ? requestNewIndex(endLevelOneIndex)
                    : endLevelOneIndex),
            lineList: LineNodeList(
                lineNode: lineNode, requestNewIndex: requestLevelTwoIndex)),
        merge,
        addEmpty);
  }

  addList(
      {var startLevelOneIndex,
      var endLevelOneIndex,
      required LineNodeList lineList,
      bool keepNoLine = true,
      addEmpty = false}) {
    // assert(lineList != null, 'LineList is null, maybe: .addLineNode -> ..addLineNode');

    add(
        TableLineNode(
            startIndex: startLevelOneIndex is int
                ? requestNewIndex(startLevelOneIndex)
                : startLevelOneIndex,
            endIndex: endLevelOneIndex == null
                ? null
                : (endLevelOneIndex is int
                    ? requestNewIndex(endLevelOneIndex)
                    : endLevelOneIndex),
            lineList: lineList),
        merge,
        addEmpty);
  }

  TableLineNode merge(LineLinkedListEntry link, LineLinkedListEntry merge) {
    assert(link is TableLineNode);
    assert(merge is TableLineNode);

    final list = (link as TableLineNode).lineList.copy();
    final mergeList = (merge as TableLineNode).lineList;

    var mergeLineNode = mergeList.first;

    while (mergeLineNode != null) {
      list.addLineNode(lineNode: mergeLineNode);
      mergeLineNode = mergeLineNode.next;
    }

    return TableLineNode(
        lineList: list, startIndex: merge.startIndex, endIndex: merge.endIndex);
  }

  LineNodeList createLineNodeList(
      {LineNode? lineNode, var startLevelTwoIndex, var endLevelTwoIndex}) {
    return LineNodeList(
        requestNewIndex: requestLevelTwoIndex,
        lineNode: lineNode,
        startLevelTwoIndex: startLevelTwoIndex,
        endLevelTwoIndex: endLevelTwoIndex);
  }
}

class TableLineNode extends LineLinkedListEntry<TableLineNode> {
  LineNodeList lineList;

  TableLineNode({
    Index? startIndex,
    Index? endIndex,
    required this.lineList,
  }) : super(startIndex: startIndex, endIndex: endIndex);

  @override
  bool operator <(o) => startIndex < o.startIndex;

  @override
  bool operator >(o) => endIndex > o.endIndex;

  @override
  bool goToNext(entry) {
    return endIndex < entry.startIndex &&
        (next != null && next!.startIndex <= entry.startIndex);
  }

  @override
  bool goToPrevious(entry) {
    return entry.endIndex < startIndex ||
        (previous != null && entry.startIndex <= previous!.endIndex);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TableLineNode && other.lineList == lineList;
  }

  @override
  int get hashCode => lineList.hashCode;

  @override
  TableLineNode copy() => TableLineNode(
      startIndex: startIndex, endIndex: endIndex, lineList: lineList.copy());

  @override
  bool equalLink(TableLineNode? o) {
    if (identical(this, o)) return true;

    return o != null && lineList == o.lineList;
  }

  @override
  bool get isNotEmpty {
    if (lineList.isEmpty) {
      return false;
    } else {
      var link = lineList.first;

      while (link != null) {
        if (link.isNotEmpty) {
          return true;
        }
        link = link.next;
      }
    }
    return false;
  }

  @override
  String toString() =>
      'Fy(lineList: startIndex $startIndex endIndex $endIndex)';
}

void printTableList(TableLineList list) {
  var link = list.first;

  while (link != null) {
    printList(link.lineList);
    link = link.next;
  }
}

class LineNodeList extends LineLinkedList<LineNode> {
  LineNodeList(
      {LineNode? lineNode,
      var startLevelTwoIndex,
      var endLevelTwoIndex,
      required RequestNewIndex requestNewIndex})
      : super(requestNewIndex: requestNewIndex) {
    if (lineNode != null) {
      if (startLevelTwoIndex != null) {
        assert(startLevelTwoIndex != null);
        setIndex(lineNode, startLevelTwoIndex, endLevelTwoIndex);
      }
      _insertBefore(null, lineNode, updateFirst: false);
    }
  }

  addLineNode(
      {required LineNode lineNode,
      var startLevelTwoIndex,
      var endLevelTwoIndex,
      addEmpty = false}) {
    if (startLevelTwoIndex != null) {
      setIndex(lineNode, startLevelTwoIndex, endLevelTwoIndex);
    }
    if (_length == 0) {
      _insertBefore(null, lineNode, updateFirst: false);
    } else {
      add(lineNode, merge, addEmpty);
    }
  }

  LineNodeList copy() {
    final lineList = LineNodeList(requestNewIndex: requestNewIndex);
    LineNode? link = _first;
    LineNode? entryCopy;

    while (link != null) {
      final copyLink = link.copy();
      lineList._insertAfter(entryCopy, copyLink);
      entryCopy = copyLink;

      link = link.next;
    }

    return lineList;
  }

  LineLinkedListEntry merge(lineNode, merge) {
    return (lineNode as LineNode).mergeLineNode(lineIntercept: merge);
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

  RequestNewIndex requestNewIndex;

  LineLinkedList({required this.requestNewIndex});

  add(E link, Merge merge, bool addEmpty) {
    if (link._list != null) {
      link = link.copy();
    }

    assert(link.startIndex <= link.endIndex,
        'StartIndex is not smaller or equal compared to endIndex');

    if (_length == 0) {
      if (link.isNotEmpty || addEmpty) {
        _insertBefore(null, link, updateFirst: false);
      }
    } else {
      E found = findOrBefore(link);

      if (link.endIndex < _first!.startIndex ||
          last!.endIndex < link.startIndex) {
        if (check) {
          debugPrint('0: found $found');
          debugPrint('0: ln $link');
        }
        _addOutside(link, found, addEmpty);
      } else if (found.startIndex <= link.startIndex &&
          found.endIndex >= link.endIndex) {
        _addInside(link, found, merge, addEmpty);
      } else {
        //  found: 1_____  <        2 ______                              1 _____  <     2 ______
        //  li:                 ______________   found go to 2  or                    ______________  found go to 2
        //
        //  found: 1___________                                           found: 1___________
        //  li:           ____________ Nothing to do take found  or                              ____________ found to null

        if (found.endIndex < link.startIndex && found.next != null) {
          found = found.next!;
        }

        final oriFound = found.copy();
        if (check) {
          debugPrint('oriFound $oriFound');
          debugPrint('found $found');
          debugPrint('ln $link');
        }

        while (true) {
          // if(link._list != null){
          //   link = link.copy();
          // }

          // if (found == null) {
          //   if (check) {
          //     print('0: oriFound $oriFound');
          //     print('0: found $found');
          //     print('0: ln $link');
          //   }

          //   //  Found:     ______               Outside and break
          //   //  li:                 ___________

          //   _addOutside(link, last, addEmpty);
          //   break;
          // }

          // Found:   ___  1  __  2  _____
          // li:          ________
          //
          //   1,2 li.startIndex < found.startFound
          // Go to previous found!!

          if (found.startIndex > link.startIndex) {
            if (check) {
              debugPrint('1: oriFound $oriFound');
              debugPrint('1: found $found');
              debugPrint('1: ln $link');
            }

            if (link.endIndex < found.startIndex) {
              // 2
              _addOutside(link, found.previous, addEmpty);
              break;
            } else {
              // 1

              final endLink = link.endIndex;
              final startFound = found.startIndex;

              final newFound = _addOutside(
                  link..endIndex = requestNewIndex(startFound.index - 1),
                  found.previous,
                  addEmpty);

              if (link._list != null) {
                link = link.copy();
              }

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

            if (check) {
              debugPrint('2: oriFound $oriFound');
              debugPrint('2: found $found');
              debugPrint('2: ln $link');
            }
            final endFound = found.endIndex;
            final endLink = link.endIndex;
            assert(link._list == null);
            // assert(found != null);
            found =
                _addInside(link..endIndex = endFound, found, merge, addEmpty);

            if (_length == 0) {
              break;
            }

            // assert(found != null);
            if (link._list != null) {
              link = link.copy();
            }

            link.startIndex = requestNewIndex(endFound.index + 1);
            link.endIndex = endLink;

            assert(link.startIndex <= link.endIndex,
                'start: ${link.startIndex} end: ${link.endIndex}');

            if (check) {
              debugPrint('2: found after $found');
            }
          } else if (link.endIndex <= found.endIndex) {
            //    found:  _______________
            //    li:     ________
            //    break

            if (check) {
              debugPrint('3: oriFound $oriFound');
              debugPrint('3: found $found');
              debugPrint('3: ln $link');
            }

            assert(link._list == null);

            _addInside(link, found, merge, addEmpty);
            break;
          } else {
            assert(false, 'Endless loop in TableLine function add?');
          }

          if (link.startIndex > found.endIndex) {
            if (found.next == null) {
              //  Found:     ______               Outside and break
              //  li:                 ___________

              _addOutside(link, last, addEmpty);
              break;
            }

            found = found.next!;
          }
        }
      }
    }
  }

  E? _addOutside(E link, E? found, bool addEmpty) {
    E? newFound;

    if (found == null || link.endIndex < found.startIndex) {
      if (link.isNotEmpty || addEmpty) {
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
      if (link.isNotEmpty || addEmpty) {
        _insertAfter(found, link);
        assert(link.next == null || link.endIndex < link.next!.startIndex,
            'Overlap is not alought endIndex: ${link.endIndex} startIndex: ${link._next!.startIndex}');
        newFound = shrink(link);
        // assert(newFound != null);
      }
    } else {
      debugPrint('outside: should not happen li: $link');
      debugPrint('outside: should not happen found: $found');
    }

    return newFound;
  }

  E _addInside(E link, E? found, Merge merge, bool addEmpty) {
    E newFound;

    if (found == null) {
      if (link.isNotEmpty || addEmpty) {
        if (link.equalInterceptAndJoined(_first)) {
          _first!.startIndex = link.startIndex;
          newFound = _first!;
        } else {
          _insertBefore(_first, link, updateFirst: true);
          assert(link.next == null || link.endIndex < link.next!.startIndex,
              'Overlap is not alought');
          newFound = link;
        }
      } else {
        newFound = _first!;
      }

      // assert(newFound != null);
    } else if (found.endIndex < link.startIndex) {
      if (link.isNotEmpty || addEmpty) {
        _insertAfter(found, link);
        assert(link.next == null || link.endIndex < link.next!.startIndex,
            'Overlap is not alought endIndex: ${link.endIndex} startIndex: ${link._next!.startIndex}');
        newFound = shrink(link);
      } else {
        newFound = found;
      }

      // assert(newFound != null);
    } else if (found.startIndex == link.startIndex &&
        found.endIndex == link.endIndex) {
      final adjusted = merge(found, link) as E;

      if (adjusted.isNotEmpty || addEmpty) {
        if (adjusted.differentIntercept(found)) {
          replace(found, adjusted);
          newFound = shrink(adjusted);
        } else {
          newFound = found;
        }
      } else {
        newFound = identical(_first, found) ? found._next! : found._previous!;
        _unlink(found);
      }
      // if (newFound == null) print('length $_length found $newFound');
      // assert(_length == 0 || newFound != null);
      //assert(_length == 0);
    } else if (found.startIndex <= link.startIndex &&
        found.endIndex >= link.endIndex) {
      final adjusted = merge(found, link) as E;

      if (adjusted.differentIntercept(found)) {
        if (adjusted.startIndex > found.startIndex &&
            adjusted.endIndex < found.endIndex) {
          final foundLeft = found;
          final foundRight = found.copy();

          foundLeft.endIndex = requestNewIndex(adjusted.startIndex.index - 1);
          foundRight.startIndex = requestNewIndex(adjusted.endIndex.index + 1);

          _insertAfter(foundLeft, foundRight);

          if (adjusted.isNotEmpty || addEmpty) {
            _insertAfter(foundLeft, adjusted);
          }
          newFound = foundRight;

          // assert(newFound != null);
        } else if (adjusted.startIndex == found.startIndex) {
          assert(adjusted.endIndex <= found.endIndex,
              'EndIndex out of bound: ${adjusted.endIndex}, startIndex equal');

          found.startIndex = requestNewIndex(adjusted.endIndex.index + 1);

          if (adjusted.equalInterceptAndJoined(found.previous)) {
            newFound = found..previous!.endIndex = adjusted.endIndex;
          } else if (adjusted.isNotEmpty || addEmpty) {
            //_insertAfter(found.previous, adjusted);
            _insertBefore(found, adjusted,
                updateFirst: identical(found, _first));
            newFound = adjusted;
          } else {
            newFound = found;
          }

          // No shrink Next not necessary, because the previous is different!
          // assert(newFound != null);
        } else if (adjusted.endIndex == found.endIndex) {
          assert(adjusted.startIndex >= found.startIndex,
              'StartIndex out of bound ${adjusted.startIndex}, endIndex equal');

          found.endIndex = requestNewIndex(adjusted.startIndex.index - 1);

          if (adjusted.equalInterceptAndJoined(found.next)) {
            newFound = found..next!.startIndex = adjusted.startIndex;
          } else if (adjusted.isNotEmpty || addEmpty) {
            _insertAfter(found, adjusted);
            newFound = adjusted;
          } else {
            newFound = found;
          }

          // No shrink Previous not necessary, because the previous is different!
          // assert(newFound != null);
        } else {
          newFound = found;
          throw ('StartIndex ${adjusted.startIndex < found.startIndex ? 'out' : 'in'} bound, endIndex ${adjusted.endIndex > found.endIndex ? 'out' : 'in'} bound');
        }
      } else {
        newFound = found;
      }
    } else {
      throw ('No option found to add the link in LineLinkedList function _addInside link startIndex: ${link.startIndex}, endIndex ${link.endIndex}, this is a properly a bug');
    }
    return newFound;
    // throw ('newFound is null');
    // assert(newFound != null, 'should not happen ln: $link and found: $found');
    // return newFound!;
  }

  E shrink(E link) {
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
      while (!identical(begin!._next, _first) && begin.endIndex < index) {
        begin = begin._next;
      }
    } else if (begin.startIndex > index) {
      while (!identical(begin, _first) && begin!._previous!.endIndex >= index) {
        begin = begin._previous;
      }
    }

    return begin!;
  }

  setIndex(E link, var startLevelIndex, var endLevelIndex) {
    assert(startLevelIndex != null,
        'StartIndex can not be null, Where does the list or LineNode start?');
    link.setIndex(
        startIndex: startLevelIndex is int
            ? requestNewIndex(startLevelIndex)
            : startLevelIndex,
        endIndex: endLevelIndex == null
            ? null
            : (endLevelIndex is int
                ? requestNewIndex(endLevelIndex)
                : endLevelIndex));
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
    // operator > (LineIntercept o) => startIndex > o.endIndex;
    // operator < (LineIntercept o) => endIndex < o.startIndex;
    // operator <= (LineIntercept o) => startIndex <= o.startIndex;

    // if (entry < _first) {
    //   return null;
    // }
    assert(_first != null, 'First cannot be null in function findOrBefore');

    _current ??= _first;

    if (_current! < entry) {
      while (!identical(_current!._next, _first) && _current!.goToNext(entry)) {
        _current = _current!._next;
      }
    } else {
      // while(!identical(_current, _first) && _current > entry){
      //   _current = _current.previous;
      // }
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

    // _modificationCount++;

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

class LineNode extends LineLinkedListEntry<LineNode> {
  final Line left;
  final Line top;
  final Line right;
  final Line bottom;

  LineNode({
    this.left = _emptyLine,
    this.top = _emptyLine,
    this.right = _emptyLine,
    this.bottom = _emptyLine,
    var startIndex,
    var endIndex,
  }) : super(startIndex: startIndex, endIndex: endIndex);

  extendRight() {}

  @override
  LineNode copy() {
    return LineNode(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      startIndex: startIndex,
      endIndex: endIndex,
    );
  }

  copyObject(LineNode lineNode) {
    return LineNode(
      left: identical(lineNode.left, _emptyLine)
          ? left
          : left.copyObject(o: lineNode.left),
      top: identical(lineNode.top, _emptyLine)
          ? top
          : top.copyObject(o: lineNode.top),
      right: identical(lineNode.right, _emptyLine)
          ? right
          : right.copyObject(o: lineNode.right),
      bottom: identical(lineNode.bottom, _emptyLine)
          ? bottom
          : bottom.copyObject(o: lineNode.bottom),
      startIndex: lineNode.startIndex,
      endIndex: lineNode.endIndex,
    );
  }

  LineNode mergeLineNode(
      {required LineNode lineIntercept, keepNoLine = false}) {
    return copyObject(lineIntercept);
    // return LineNode(
    //   left: (left == noLine && keepNoLine) ||
    //           identical(lineIntercept.left, _emptyLine)
    //       ? left
    //       : lineIntercept.left,
    //   top: (top == noLine && keepNoLine) ||
    //           identical(lineIntercept.top, _emptyLine)
    //       ? top
    //       : lineIntercept.top,
    //   right: (right == noLine && keepNoLine) ||
    //           identical(lineIntercept.right, _emptyLine)
    //       ? right
    //       : lineIntercept.right,
    //   bottom: (bottom == noLine && keepNoLine) ||
    //           identical(lineIntercept.bottom, _emptyLine)
    //       ? bottom
    //       : lineIntercept.bottom,
    //   startIndex: lineIntercept.startIndex,
    //   endIndex: lineIntercept.endIndex,
    // );
  }

  @override
  bool get isNotEmpty {
    return left != gridLine ||
        top != gridLine ||
        right != gridLine ||
        bottom != gridLine;
  }

  @override
  bool operator >(LineNode o) => startIndex > o.startIndex;

  @override
  bool operator <(LineNode o) => startIndex < o.startIndex;

  @override
  bool equalLink(LineNode? o) {
    if (identical(this, o)) return true;

    return o != null &&
        o.left == left &&
        o.top == top &&
        o.right == right &&
        o.bottom == bottom;
  }

  @override
  String toString() {
    return 'LineNode(startIndex: $startIndex, endIndex: $endIndex, left: $left, top: $top, right: $right, bottom: $bottom)';
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
        other.left == left &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom;
  }

  @override
  int get hashCode {
    return left.hashCode ^ top.hashCode ^ right.hashCode ^ bottom.hashCode;
  }
}

class _EmptyLine extends Line {
  const _EmptyLine()
      : super(
            line: TableLineOptions.no,
            width: 0,
            color: const Color(0xffffffff),
            drawLine: false);
}

class Line {
  final TableLineOptions line;
  final double width;
  final Color color;
  final bool _drawLine;
  final double lowestScale;
  final double highestScale;

  const Line({
    this.line = TableLineOptions.custom,
    this.width = 0.5,
    this.color = const Color(0xFF42A5F5),
    bool drawLine = true,
    this.lowestScale = 0.5,
    this.highestScale = 2.0,
  }) : _drawLine = drawLine;

  const Line.grid({
    this.line = TableLineOptions.grid,
    this.width = 0.0,
    this.color = const Color(0xffbdbdbd),
    bool drawLine = true,
    this.lowestScale = 0.5,
    this.highestScale = 2.0,
  }) : _drawLine = drawLine;

  const Line.noLine({
    this.line = TableLineOptions.no,
    this.width = 0.0,
    this.color = const Color(0xffffffff),
    bool drawLine = false,
    this.lowestScale = 0.5,
    this.highestScale = 2.0,
  }) : _drawLine = drawLine;

  bool get drawLine => _drawLine;

  @override
  String toString() => '$line${drawLine ? '' : '*'}';

  Line copyObject({
    required Line o,
  }) {
    return Line(
      line: o.line,
      width: o.width,
      color: o.color,
      drawLine: o._drawLine,
      lowestScale: o.lowestScale,
      highestScale: o.highestScale,
    );
  }

  widthScaled(double scale) =>
      width *
      (scale < lowestScale
          ? lowestScale
          : (scale > highestScale ? highestScale : scale));

  // @override
  // bool operator ==(Object o) {
  //   if (identical(this, o)) return true;

  //   return o is Line && o.line == line && o.width == width && o.color == color && o.drawLine == drawLine;
  // }

  // @override
  // int get hashCode {
  //   return line.hashCode ^ width.hashCode ^ color.hashCode ^ drawLine.hashCode;
  // }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Line &&
        other.line == line &&
        other.width == width &&
        other.color == color &&
        other._drawLine == _drawLine &&
        other.lowestScale == lowestScale &&
        other.highestScale == highestScale;
  }

  @override
  int get hashCode {
    return line.hashCode ^
        width.hashCode ^
        color.hashCode ^
        _drawLine.hashCode ^
        lowestScale.hashCode ^
        highestScale.hashCode;
  }
}

abstract class LineLinkedListEntry<E extends LineLinkedListEntry<E>> {
  LineLinkedList<E>? _list;
  E? _next;
  E? _previous;
  late Index startIndex;
  late Index endIndex;

  LineLinkedListEntry({Index? startIndex, Index? endIndex}) {
    if (startIndex != null) {
      this.startIndex = startIndex;
      this.endIndex = endIndex ?? startIndex;
    }
  }

  // assert(endIndex == null || startIndex <= endIndex,
  //     'EndIndex ${endIndex.index} is smaller than startIndex ${startIndex.index}! ');

  // Index get startIndex => _startIndex!;

  // Index get endIndex => _endIndex!;

  // set startIndex(value) => _startIndex = value;

  // set endIndex(value) => _endIndex = value;

  int get start => startIndex.index;

  int get end => endIndex.index;

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

  void setIndex({required Index startIndex, Index? endIndex}) {
    assert(_list == null, 'Link is already in use');
    this.startIndex = startIndex;
    this.endIndex = endIndex ?? startIndex;
    assert(this.startIndex <= this.endIndex,
        'EndIndex is smaller than startIndex!');
  }

  bool goToNext(covariant entry);

  bool goToPrevious(covariant entry);

  bool operator >(covariant o);

  bool operator <(covariant o);

  bool equalInterceptAndJoined(covariant o) {
    return equalLink(o) &&
        (startIndex < o.startIndex
            ? endIndex.index + 1 == o.startIndex.index
            : startIndex.index - 1 == o.endIndex.index);
  }

  bool equalLink(E? o);

  bool get isNotEmpty;

  E copy();

  bool differentIntercept(E o) => !equalLink(o);
}

class DummyIndex with Index {
  @override
  final int index;

  DummyIndex(
    this.index,
  );
}

printList(LineNodeList lineList) {
  debugPrint(
      '> LineNode list --------------------------------------------------');
  var t = lineList._first;

  while (t != null) {
    debugPrint(' - $t');
    t = t.next;
  }
}

printListNext(LineNodeList lineList) {
  var t = lineList._first;

  while (t != null) {
    t = t.next;
  }
}

printListPrevious(LineNodeList lineList) {
  var t = lineList.last;

  while (t != null) {
    t = t.previous;
  }
}

// class EmptyIndex with Index {
//   final int index = -1;

//   const EmptyIndex();
// }

// const emptyIndex = EmptyIndex();