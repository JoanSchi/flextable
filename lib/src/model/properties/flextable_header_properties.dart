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

class HeaderProperties {
  final int index;
  final int digits;
  final double startPosition;
  final double endPosition;

  HeaderProperties({
    required this.index,
    required this.digits,
    required this.startPosition,
    required this.endPosition,
  });

  const HeaderProperties.empty({
    this.index = -1,
    this.digits = 0,
    this.startPosition = -1,
    this.endPosition = -1,
  });

  //index != -1 is empty
  contains(double position) =>
      index != -1 && startPosition <= position && position < endPosition;

  @override
  String toString() {
    return 'HeaderWidthItem(index: $index, digits: $digits, startPosition: $startPosition, endPosition: $endPosition)';
  }
}

const noHeader = HeaderProperties.empty();
