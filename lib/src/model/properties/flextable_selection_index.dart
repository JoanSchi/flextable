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

class SelectionIndex {
  int indexStart, indexLast;
  //int index = -1;

  SelectionIndex({required this.indexStart, required this.indexLast});

  SelectionIndex setIndex(int indexStart, int indexLast) {
    this.indexStart = indexStart;
    this.indexLast = indexLast;
    return this;
  }

  int sum() {
    return indexStart + indexLast;
  }

  int compareTo(SelectionIndex si) {
    return (indexStart + indexLast) - (si.indexStart + si.indexLast);
  }

  SelectionIndex copy() {
    return SelectionIndex(indexStart: indexStart, indexLast: indexLast);
  }

  bool hiddenBand() {
    return indexStart != indexLast;
  }

  @override
  String toString() {
    return 'start_screen $indexStart $indexLast';
  }
}
