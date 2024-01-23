// // ignore_for_file: public_member_api_docs, sort_constructors_first
// // Copyright 2023 Joan Schipper. All rights reserved.
// // Use of this source code is governed by a BSD-style
// // license that can be found in the LICENSE file.

// import 'dart:collection';

// import 'package:flutter/widgets.dart';

// enum LineOptions { no, line }

// const noLine = Line.no();

// typedef LineMerge<Range> = Range Function(Range link, Range merge);

// bool check = false;

// class TableLinesOneDirection extends LineSplayMap<LineRange> {
//   TableLinesOneDirection() : super(addEmpty: false);

//   void addLineRange(
//     LineRange lineRange,
//   ) {
//     _add(
//       lineRange,
//       merge,
//     );
//   }

//   void addLineRanges(Function(Function(LineRange lineRange) add) create,
//       {addEmpty = false}) {
//     create((LineRange lineRange) => _add(
//           lineRange,
//           merge,
//         ));
//   }

//   LineRange merge(LineRange found, LineRange link) {
//     // assert(link is LineRange);
//     // assert(merge is LineRange);

//     final list = link.lineNodeRange;
//     final newLineNodeRange = found.lineNodeRange._copy();

//     LineNode? node = list.first;

//     /// The node is in a list and therefore copy wil be made with
//     ///
//     ///
//     while (node != null) {
//       newLineNodeRange.addLineNode(node);
//       node = node.next;
//     }

//     return LineRange(
//         lineNodeRange: newLineNodeRange,
//         startIndex: link.startIndex,
//         endIndex: link.endIndex);
//   }

//   @override
//   String toString() => 'LineRanges in TableLinesOneDirection: ${() {
//         LineRange? n = first;
//         String toString = n == null ? '\n empty' : '';
//         while (n != null) {
//           toString += '\n ${n.toString()}';
//           n = n.next;
//         }

//         return toString;
//       }()}';
// }

// class LineRange extends Range<LineRange> {
//   LineRange({
//     required super.startIndex,
//     super.endIndex,
//     required this.lineNodeRange,
//   });

//   LineNodeRange lineNodeRange;

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is LineRange && other.lineNodeRange == lineNodeRange;
//   }

//   @override
//   int get hashCode => lineNodeRange.hashCode;

//   @override
//   bool equalLink(covariant LineRange? o) {
//     if (identical(this, o)) return true;

//     return o != null && lineNodeRange == o.lineNodeRange;
//   }

//   @override
//   bool get isEmpty {
//     if (lineNodeRange.map.isEmpty) {
//       return true;
//     } else {
//       for (var MapEntry(:key, :value) in lineNodeRange.map.entries) {
//         if (value.isNotEmpty) {
//           return false;
//         }
//       }
//     }
//     return true;
//   }

//   @override
//   bool get isNotEmpty => !isEmpty;

//   @override
//   String toString() => '- LineNodeRange $startIndex-$endIndex: $lineNodeRange';

//   @override
//   LineRange _copy() => LineRange(
//       startIndex: startIndex,
//       endIndex: endIndex,
//       lineNodeRange: lineNodeRange._copy());

//   @override
//   LineRange _shallowCopy() {
//     return LineRange(
//       startIndex: startIndex,
//       endIndex: endIndex,
//       lineNodeRange: lineNodeRange,
//     );
//   }
  
//   @override
//   LineRange copyWith({int? startIndex, int? endIndex}) {
//     // TODO: implement copyWith
//     throw UnimplementedError();
//   }
// }

// class LineNodeRange extends LineSplayMap<LineNode> {
//   LineNodeRange({
//     List<LineNode>? list,
//     Function(Function(LineNode lineNode) add)? create,
//   }) : super(addEmpty: true) {
//     if (list != null) {
//       for (LineNode lineNode in list) {
//         _add(lineNode, merge);
//       }
//     }

//     create?.call((lineNode) => _add(lineNode, merge));
//   }

//   LineNodeRange._noEmptyNodes() : super(addEmpty: false);

//   addLineNode(
//     LineNode lineNode,
//   ) {
//     _add(
//       lineNode,
//       merge,
//     );
//   }

//   addLineNodes(
//     Function(Function(LineNode lineNode) create) create,
//   ) {
//     create((lineNode) => _add(lineNode, merge));
//   }

//   LineNodeRange _copy() {
//     final lineList = LineNodeRange._noEmptyNodes();
//     LineNode? link = _first;
//     LineNode? entryCopy;

//     while (link != null) {
//       if (link.isNotEmpty) {
//         final copyLink = link._copy();
//         lineList._insertAfter(entryCopy, copyLink);
//         entryCopy = copyLink;
//       }
//       link = link.next;
//     }

//     return lineList;
//   }

//   LineNode merge(LineNode lineNode, LineNode merge) {
//     return lineNode.merge(merge);
//   }
// }

// abstract class LineSplayMap<E extends Range<E>> {
//   final map = SplayTreeMap<int, E>();
//   // int _modificationCount = 0;

//   final bool _addEmpty;

//   LineSplayMap({required bool addEmpty}) : _addEmpty = addEmpty;

//   _add(E? link, LineMerge<E> merge) {
//     /// The link is already in used if the list is not null.
//     /// To prevent breaking of the the LinkedList the link will be coppied.
//     ///
//     ///

//     assert(link != null && link.startIndex <= link.endIndex,
//         'StartIndex is not smaller or equal compared to endIndex');

//     if (link == null) return;

//     E? previous;
//     E? range;
//     if (map.lastKeyBefore(link.startIndex) ?? map.firstKey() case int i) {
//       range = map[i];
//     }

//     if (range == null) {
//       map[link.startIndex] = link._copy();
//       return;
//     }

//     while (range != null) {
//       if (link == null) {
//         previous = melt(previous, range);
//         break;
//       } else if (range.endIndex < link.startIndex) {
//         previous = range;
//       } else if (range.startIndex <= link.startIndex) {
//         if (range.startIndex < link.startIndex) {
//           ///
//           ///

//           previous = range;
//           range = range.copyWith(startIndex: link.startIndex);

//           previous.endIndex = link.startIndex - 1;

//           map[range.startIndex] = range;
//         }
//         if (link.endIndex < range.end) {
//           E adjusted = merge(range, link);

//           map.remove(range.startIndex);
//           range.startIndex = link.endIndex + 1;
//           map[range.startIndex] = range;
//           if (_addEmpty || link.isNotEmpty) {
//             map[adjusted.startIndex] = adjusted;

//             //melt
//             previous = melt(previous, adjusted);

//             link = null;
//             break;
//           } else {
//             link = null;
//           }

//           //melt
//           previous = melt(previous, range);
//         } else if (link.endIndex == range.end) {
//           E adjusted = merge(range, link);

//           if (_addEmpty || adjusted.isNotEmpty) {
//             map[adjusted.startIndex] = adjusted;
//             //melt
//             previous = melt(previous, adjusted);
//             link = null;
//             break;
//           } else {
//             link = null;
//           }
//         } else {
//           E adjusted = merge(range, link);
//           if (_addEmpty && adjusted.isNotEmpty) {
//             range = adjusted.copyWith(endIndex: range.endIndex);
//             map[range.startIndex] = range;
//             //melt
//             previous = melt(previous, range);
//           } else {
//             map.remove(range.startIndex);
//           }

//           link.startIndex = range.endIndex + 1;
//           //
//         }
//       }

//       if (map.firstKeyAfter(range.startIndex) case int i) {
//         range = map[i];
//       }
//     }
//     if (link != null) {
//       map[link.startIndex] = link;
//       melt(previous, link);
//     }
//   }

//   E melt(E? previous, E range) {
//     if (previous != null &&
//         range.startIndex - previous.endIndex == 1 &&
//         range.equalLink(previous)) {
//       previous.endIndex == range.endIndex;
//       map.remove(range.startIndex);
//       range = previous;
//     }
//     return range;
//   }

//   /* Default linked list functions
//    *
//    * 
//    * 
//    * 
//    * 
//    * 
//    * 
//    * 
//    * 
//    * 
//    */
// }

// class EmptyLineNode extends LineNode {
//   EmptyLineNode({
//     required int startIndex,
//     int? endIndex,
//   }) : super(
//             startIndex: startIndex,
//             endIndex: endIndex,
//             before: noLine,
//             after: noLine);
// }

// class LineNode extends Range<LineNode> {
//   LineNode({
//     required super.startIndex,
//     super.endIndex,
//     this.before,
//     this.after,
//   });

//   final Line? before;
//   final Line? after;

//   LineNode merge(LineNode lineNode) {
//     return LineNode(
//       before: before?.merge(lineNode.before) ?? lineNode.before,
//       after: after?.merge(lineNode.after) ?? lineNode.after,
//       startIndex: lineNode.startIndex,
//       endIndex: lineNode.endIndex,
//     );
//   }

//   @override
//   bool get isEmpty {
//     return (before?.isEmpty ?? true) && (after?.isEmpty ?? true);
//   }

//   @override
//   bool get isNotEmpty => !isEmpty;

//   @override
//   bool equalLink(LineNode? o) {
//     if (identical(this, o)) return true;

//     return o != null && o.before == before && o.after == after;
//   }

//   @override
//   String toString() {
//     return 'LineNode $startIndex-$endIndex: before: $before, after: $after';
//   }

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is LineNode &&
//         other.startIndex == startIndex &&
//         other.endIndex == endIndex &&
//         other.before == before &&
//         other.after == after;
//   }

//   @override
//   int get hashCode {
//     return before.hashCode ^ after.hashCode;
//   }

//   @override
//   LineNode _copy() {
//     return LineNode(
//       before: before,
//       after: after,
//       startIndex: startIndex,
//       endIndex: endIndex,
//     );
//   }

//   @override
//   LineNode _shallowCopy() {
//     return LineNode(
//       startIndex: startIndex,
//       endIndex: endIndex,
//       before: before,
//       after: after,
//     );
//   }

//   @override
//   LineNode copyWith(
//       {int? startIndex, int? endIndex, Line? before, Line? after}) {
//     return LineNode(
//         startIndex: startIndex ?? this.startIndex,
//         endIndex: endIndex ?? this.endIndex,
//         before: before ?? this.before,
//         after: after ?? this.after);
//   }
// }

// class Line {
//   const Line({
//     this.line = LineOptions.line,
//     this.width,
//     this.color,
//     this.lowestScale = 0.5,
//     this.highestScale = 2.0,
//   }) : assert(
//             (line == null || line == LineOptions.no) ||
//                 (line == LineOptions.line && width != null && color != null),
//             'Width and color can not be null if tableLineOption is a line.');

//   const Line.change({
//     this.width,
//     this.color,
//     this.lowestScale = 0.5,
//     this.highestScale = 2.0,
//   }) : line = null;

//   const Line.no()
//       : line = LineOptions.no,
//         width = null,
//         color = null,
//         lowestScale = 0.5,
//         highestScale = 2.0;

//   final LineOptions? line;
//   final double? width;
//   final Color? color;
//   final double lowestScale;
//   final double highestScale;

//   @override
//   String toString() => 'Line(o:$line, w:$width, c:$color)';

//   Line merge(Line? o) {
//     if ((line == null || line == LineOptions.no) && o?.line == null) {
//       return Line(line: line);
//     } else if (o?.line == LineOptions.no) {
//       return const Line(line: LineOptions.no);
//     }

//     return Line(
//         line: o?.line ?? line,
//         width: o?.width ?? width,
//         color: o?.color ?? color,
//         lowestScale: o?.lowestScale ?? lowestScale,
//         highestScale: o?.highestScale ?? highestScale);
//   }

//   bool get isEmpty =>
//       line == null || line == LineOptions.no || width == 0.0 || color == null;

//   widthScaled(double scale) =>
//       width ??
//       1.0 *
//           (scale < lowestScale
//               ? lowestScale
//               : (scale > highestScale ? highestScale : scale));

//   @override
//   bool operator ==(Object other) {
//     if (identical(this, other)) return true;

//     return other is Line &&
//         other.line == line &&
//         other.width == width &&
//         other.color == color &&
//         other.lowestScale == lowestScale &&
//         other.highestScale == highestScale;
//   }

//   @override
//   int get hashCode {
//     return line.hashCode ^
//         width.hashCode ^
//         color.hashCode ^
//         lowestScale.hashCode ^
//         highestScale.hashCode;
//   }
// }

// abstract class Range<E> {
//   Range({required this.startIndex, int? endIndex})
//       : endIndex = endIndex ?? startIndex;

//   int startIndex;
//   int endIndex;

//   int get start => startIndex;

//   int get end => endIndex;

//   bool equalLink(E? o);

//   bool get isEmpty;

//   bool get isNotEmpty;

//   bool differentIntercept(E o) => !equalLink(o);

//   E _copy();

//   E _shallowCopy();

//   E copyWith({int? startIndex, int? endIndex});
// }
