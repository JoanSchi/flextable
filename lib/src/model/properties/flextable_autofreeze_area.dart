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

typedef AutoFreezeGetPosition = double Function(int index);

class AutoFreezeArea {
  int startIndex;
  int freezeIndex;
  int endIndex;
  double? customSplitSize;

  double startPosition = 0.0;
  double freezePosition = 0.0;
  double endPosition = 0.0;

  AutoFreezeArea({
    required this.startIndex,
    required this.freezeIndex,
    required this.endIndex,
    this.customSplitSize,
  });

  double spaceSplit(double spaceSplitFreeze) {
    return customSplitSize ?? spaceSplitFreeze;
  }

  double get header => freezePosition - startPosition;

  double get d => endPosition - freezePosition + startPosition;

  AutoFreezeArea.noArea(
      {this.startIndex = -1, this.freezeIndex = -1, this.endIndex = -1});

  bool get freeze => freezeIndex > 0;

  constains(position) => startPosition < position && position < endPosition;

  setPosition(AutoFreezeGetPosition position) {
    startPosition = position(startIndex);
    freezePosition = position(freezeIndex);
    endPosition = position(endIndex);
  }
}
