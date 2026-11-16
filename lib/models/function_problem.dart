enum FunctionInputMode { formula, table }

enum DomainMode { continuous, discrete }

class TableEntry {
  final double x;
  final double y;

  const TableEntry({required this.x, required this.y});
}

class DomainSpec {
  final DomainMode mode;
  final double? lowerBound; // null => -infinity
  final bool lowerInclusive;
  final double? upperBound; // null => +infinity
  final bool upperInclusive;
  final List<double> discreteValues;
  final List<double> excludedValues;

  const DomainSpec.continuous({
    this.lowerBound,
    this.lowerInclusive = true,
    this.upperBound,
    this.upperInclusive = true,
    this.excludedValues = const [],
  })  : mode = DomainMode.continuous,
        discreteValues = const [];

  const DomainSpec.discrete(this.discreteValues)
      : mode = DomainMode.discrete,
        lowerBound = null,
        lowerInclusive = false,
        upperBound = null,
        upperInclusive = false,
        excludedValues = const [];

  bool contains(double x, {double eps = 1e-7}) {
    if (!x.isFinite) return false;
    if (mode == DomainMode.discrete) {
      return discreteValues.any((v) => (v - x).abs() < eps);
    }
    if (excludedValues.any((ex) => (ex - x).abs() < eps)) {
      return false;
    }
    if (lowerBound != null) {
      if (lowerInclusive ? x < lowerBound! - eps : x <= lowerBound! + eps) {
        return false;
      }
    }
    if (upperBound != null) {
      if (upperInclusive ? x > upperBound! + eps : x >= upperBound! - eps) {
        return false;
      }
    }
    return true;
  }

  String toIntervalNotation() {
    if (mode == DomainMode.discrete) {
      return '{${discreteValues.map(formatCompactNum).join(', ')}}';
    }
    final lb = lowerBound == null ? '(' : (lowerInclusive ? '[' : '(');
    final lv = lowerBound == null ? '-∞' : formatCompactNum(lowerBound!);
    final rv = upperBound == null ? '+∞' : formatCompactNum(upperBound!);
    final rb = upperBound == null ? ')' : (upperInclusive ? ']' : ')');
    final base = (lowerBound == null && upperBound == null) ? 'ℝ' : '$lb$lv, $rv$rb';
    if (excludedValues.isNotEmpty) {
      return '$base - {${excludedValues.map(formatCompactNum).join(', ')}}';
    }
    return base;
  }

  String toSetBuilderNotation() {
    if (mode == DomainMode.discrete) {
      return '{x ∈ ℝ | x ∈ {${discreteValues.map(formatCompactNum).join(', ')}}}';
    }
    final excl = excludedValues.isNotEmpty
        ? ', x ≠ ${excludedValues.map(formatCompactNum).join(', ')}'
        : '';
    if (lowerBound == null && upperBound == null) {
      return excl.isNotEmpty
          ? '{x ∈ ℝ | x ≠ ${excludedValues.map(formatCompactNum).join(', ')}}'
          : '{x ∈ ℝ}';
    }
    if (lowerBound != null && upperBound != null) {
      final op1 = lowerInclusive ? '≤' : '<';
      final op2 = upperInclusive ? '≤' : '<';
      return '{x ∈ ℝ | ${formatCompactNum(lowerBound!)} $op1 x $op2 ${formatCompactNum(upperBound!)}$excl}';
    }
    if (lowerBound != null) {
      return '{x ∈ ℝ | x ${lowerInclusive ? '≥' : '>'} ${formatCompactNum(lowerBound!)}$excl}';
    }
    return '{x ∈ ℝ | x ${upperInclusive ? '≤' : '<'} ${formatCompactNum(upperBound!)}$excl}';
  }
}

String formatCompactNum(double v) {
  if (!v.isFinite) return v > 0 ? '+∞' : '-∞';
  final clean = v.abs() < 1e-9 ? 0.0 : v;
  if ((clean - clean.roundToDouble()).abs() < 1e-7) {
    return clean.round().toString();
  }
  final s = clean.toStringAsFixed(4);
  return s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

class EvaluationStepResult {
  final double x;
  final bool inDomain;
  final double? y;
  final List<String> steps;

  const EvaluationStepResult({
    required this.x,
    required this.inDomain,
    required this.y,
    required this.steps,
  });
}

class InverseSolution {
  final double x;
  final List<String> steps;

  const InverseSolution({
    required this.x,
    required this.steps,
  });
}

class KeyPoint {
  final double x;
  final double? y;
  final bool isEndpoint;
  final bool isOpenEndpoint;
  final bool isExtremum;
  final String role;

  const KeyPoint({
    required this.x,
    required this.y,
    this.isEndpoint = false,
    this.isOpenEndpoint = false,
    this.isExtremum = false,
    required this.role,
  });
}

class RangeSpec {
  final double? min;
  final bool minInclusive;
  final double? max;
  final bool maxInclusive;
  final List<double> discreteOutputs;

  const RangeSpec({
    this.min,
    this.minInclusive = true,
    this.max,
    this.maxInclusive = true,
    this.discreteOutputs = const [],
  });

  String toNotation(DomainMode mode) {
    if (mode == DomainMode.discrete) {
      return '{${discreteOutputs.map(formatCompactNum).join(', ')}}';
    }
    final lb = min == null ? '(' : (minInclusive ? '[' : '(');
    final lv = min == null ? '-∞' : formatCompactNum(min!);
    final rv = max == null ? '+∞' : formatCompactNum(max!);
    final rb = max == null ? ')' : (maxInclusive ? ']' : ')');
    return '$lb$lv, $rv$rb';
  }

  String toSetBuilderNotation(DomainMode mode) {
    if (mode == DomainMode.discrete) {
      return '{y ∈ ℝ | y ∈ {${discreteOutputs.map(formatCompactNum).join(', ')}}}';
    }
    if (min == null && max == null) return '{y ∈ ℝ}';
    if (min != null && max != null) {
      final op1 = minInclusive ? '≤' : '<';
      final op2 = maxInclusive ? '≤' : '<';
      return '{y ∈ ℝ | ${formatCompactNum(min!)} $op1 y $op2 ${formatCompactNum(max!)}}';
    }
    if (min != null) {
      return '{y ∈ ℝ | y ${minInclusive ? '≥' : '>'} ${formatCompactNum(min!)}}';
    }
    return '{y ∈ ℝ | y ${maxInclusive ? '≤' : '<'} ${formatCompactNum(max!)}}';
  }
}
