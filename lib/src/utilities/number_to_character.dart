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

const int A = 65;

String numberToCharacter(int column) {
  String text = "";

  int first = column % 26;
  text += String.fromCharCode(first + A);

  int second = (column % (26 * 26)) ~/ 26 - 1;

  if (second == -1) {
    return text;
  }
  text = String.fromCharCode(second + A) + text;

  int third = (column % (26 * 26 * 26)) ~/ (26 * 26) - 1;

  if (third == -1) {
    return text;
  }
  text = String.fromCharCode(third + A) + text;

  int fourth = (column % (26 * 26 * 26 * 26)) ~/ (26 * 26 * 26) - 1;
  if (fourth == -1) {
    return text;
  }
  return String.fromCharCode(third + A) + text;
}
