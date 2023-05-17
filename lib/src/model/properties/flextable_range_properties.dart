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

class RangeProperties {
  bool collapsed = false;
  bool hidden = false;
  double? length;

  int min;
  int max;

  setRange(int min, int max) {
    this.min = min;
    this.max = max;
    assert(min <= max,
        'The max in the propertiesRange can not be smaller than min');
  }

  int compareRange(RangeProperties another) {
    if (min == another.min && max == another.max) {
      return 0;
    } else {
      return max - another.min;
    }
  }

  bool contains(int index) {
    return index >= min && index <= max;
  }

  RangeProperties(
      {this.length,
      required this.min,
      int? max,
      this.collapsed = false,
      this.hidden = false})
      : assert(min <= (max ?? min),
            'The max in the propertiesRange can not be smaller than min'),
        max = max ?? min;
}
