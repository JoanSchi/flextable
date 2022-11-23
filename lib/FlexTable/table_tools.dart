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
