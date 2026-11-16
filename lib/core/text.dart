import 'dart:math' as math;
import 'rational.dart';

const String _supDigits = '⁰¹²³⁴⁵⁶⁷⁸⁹';

/// 2 -> ², 12 -> ¹²
String sup(int n) => n.toString().split('').map((c) => _supDigits[int.parse(c)]).join();

/// Cleans what a watch keyboard may produce: Persian/Arabic digits and punctuation,
/// unicode minus/dashes, multiplication/division signs, superscripts, RTL marks.
String normalizeInput(String raw) {
  var s = raw.replaceAll(RegExp('[\u200B-\u200F\u202A-\u202E\u2066-\u2069]'), '');
  s = s.replaceAllMapped(RegExp('[\u06F0-\u06F9\u0660-\u0669]'), (m) {
    final c = m[0]!.codeUnitAt(0);
    return String.fromCharCode(c >= 0x06F0 ? c - 0x06F0 + 48 : c - 0x0660 + 48);
  });
  const map = {
    '٫': '.', '٬': ',', '،': ',', '؛': ';', '，': ',',
    '−': '-', '–': '-', '—': '-', '‐': '-', '‑': '-', '﹣': '-', '－': '-',
    '＋': '+', '×': '*', '·': '*', '⋅': '*', '∙': '*', '＊': '*',
    '÷': '/', '／': '/', '＾': '^', '＝': '=',
    '（': '(', '）': ')', '［': '[', '］': ']', '｛': '{', '｝': '}',
  };
  map.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAllMapped(RegExp('[⁰¹²³⁴⁵⁶⁷⁸⁹]+'),
      (m) => '^${m[0]!.split('').map((c) => _supDigits.indexOf(c).toString()).join()}');
  return s.trim();
}

/// Value used inside a substitution: negatives and fractions get parentheses.
String fmtVal(Rational x) => (x.isNegative || !x.isInteger) ? '($x)' : '$x';

/// Axis labels (double).
String fmtAxis(double v) {
  if (v.isNaN || v.isInfinite) return '';
  if ((v - v.roundToDouble()).abs() < 1e-9) return v.round().toString();
  final s = v.toStringAsFixed(4).replaceFirst(RegExp(r'0+$'), '');
  return s.replaceFirst(RegExp(r'\.$'), '');
}

double niceStep(double raw) {
  if (!raw.isFinite || raw <= 0) return 1;
  final mag = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final n = raw / mag;
  final m = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10;
  return m * mag;
}
