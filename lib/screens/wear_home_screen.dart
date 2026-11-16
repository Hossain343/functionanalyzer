import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart' show Expression;
import '../engines/parser_solver_engine.dart';
import '../models/function_problem.dart';
import '../painters/cartesian_graph_painter.dart';
import '../painters/number_line_painter.dart';
import '../widgets/watch_math_keypad.dart';

class _PresetSpec {
  final String label;
  final FunctionInputMode inputMode;
  final String expr;
  final String tableRaw;
  final DomainMode domainMode;
  final String lo;
  final bool loInc;
  final String hi;
  final bool hiInc;
  final String excluded;
  final String discrete;
  final String queries;
  final String targetY;
  final String condX;
  final String condY;
  final String cond2X;
  final String cond2Y;

  const _PresetSpec({
    required this.label,
    this.inputMode = FunctionInputMode.formula,
    required this.expr,
    this.tableRaw = '-2:0, 0:3, 1:-1, 2:2, 4:1',
    required this.domainMode,
    required this.lo,
    required this.loInc,
    required this.hi,
    required this.hiInc,
    this.excluded = '',
    required this.discrete,
    required this.queries,
    this.targetY = '',
    required this.condX,
    required this.condY,
    this.cond2X = '3',
    this.cond2Y = '10',
  });
}

const List<_PresetSpec> _presets = [
  _PresetSpec(
    label: '4x²-3x [-2,3]',
    expr: 'g(x) = 4*x^2 - 3*x',
    domainMode: DomainMode.continuous,
    lo: '-2',
    loInc: true,
    hi: '3',
    hiInc: true,
    discrete: '-2, 0, 1, 2, 4',
    queries: '-2, 1, 5',
    condX: '1',
    condY: '2',
  ),
  _PresetSpec(
    label: 'Solve a: 3x+a',
    expr: 'h(x) = 3*x + a',
    domainMode: DomainMode.continuous,
    lo: '0',
    loInc: true,
    hi: '3',
    hiInc: true,
    discrete: '0, 1, 2, 3',
    queries: '2, 4',
    condX: '1',
    condY: '2',
  ),
  _PresetSpec(
    label: 'a,b: ax+b',
    expr: 'f(x) = a*x + b',
    domainMode: DomainMode.continuous,
    lo: '-2',
    loInc: true,
    hi: '5',
    hiInc: true,
    discrete: '-2, 0, 1, 3',
    queries: '0, 2, 4, 6',
    targetY: '7',
    condX: '1',
    condY: '4',
    cond2X: '3',
    cond2Y: '10',
  ),
  _PresetSpec(
    label: '(0, +∞)',
    expr: 'f(x) = 2*x + 1',
    domainMode: DomainMode.continuous,
    lo: '0',
    loInc: false,
    hi: '+inf',
    hiInc: false,
    discrete: '0, 1, 2',
    queries: '-1, 2, 3',
    targetY: '5',
    condX: '1',
    condY: '3',
  ),
  _PresetSpec(
    label: 'Rational D-{2}',
    expr: 'f(x) = (2*x+1)/(x-2)',
    domainMode: DomainMode.continuous,
    lo: '-1',
    loInc: true,
    hi: '5',
    hiInc: true,
    excluded: '2',
    discrete: '-1, 0, 1, 3',
    queries: '0, 2, 3',
    condX: '1',
    condY: '0',
  ),
  _PresetSpec(
    label: 'Table (x, y)',
    inputMode: FunctionInputMode.table,
    expr: 'f(x) = x - 2',
    tableRaw: '-2:0, 0:3, 1:-1, 2:2, 4:1',
    domainMode: DomainMode.discrete,
    lo: '0',
    loInc: true,
    hi: '4',
    hiInc: true,
    discrete: '-2, 0, 1, 2, 4',
    queries: '0, 1, 4, 5',
    targetY: '3',
    condX: '1',
    condY: '2',
  ),
];

class WearHomeScreen extends StatefulWidget {
  const WearHomeScreen({super.key});

  @override
  State<WearHomeScreen> createState() => _WearHomeScreenState();
}

class _WearHomeScreenState extends State<WearHomeScreen> {
  final PageController _pageController = PageController();
  final ParserSolverEngine _engine = ParserSolverEngine();

  FunctionInputMode _inputMode = FunctionInputMode.formula;
  String _exprText = _presets[0].expr;
  String _tableRaw = _presets[0].tableRaw;
  DomainMode _domainMode = _presets[0].domainMode;
  String _loText = _presets[0].lo;
  bool _loInclusive = _presets[0].loInc;
  String _hiText = _presets[0].hi;
  bool _hiInclusive = _presets[0].hiInc;
  String _excludedText = _presets[0].excluded;
  String _discreteText = _presets[0].discrete;
  String _queriesText = _presets[0].queries;
  String _targetYText = _presets[0].targetY;
  String _condXText = _presets[0].condX;
  String _condYText = _presets[0].condY;
  String _cond2XText = _presets[0].cond2X;
  String _cond2YText = _presets[0].cond2Y;

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _applyPreset(_PresetSpec p) {
    setState(() {
      _inputMode = p.inputMode;
      _exprText = p.expr;
      _tableRaw = p.tableRaw;
      _domainMode = p.domainMode;
      _loText = p.lo;
      _loInclusive = p.loInc;
      _hiText = p.hi;
      _hiInclusive = p.hiInc;
      _excludedText = p.excluded;
      _discreteText = p.discrete;
      _queriesText = p.queries;
      _targetYText = p.targetY;
      _condXText = p.condX;
      _condYText = p.condY;
      _cond2XText = p.cond2X;
      _cond2YText = p.cond2Y;
    });
  }

  Future<void> _editDomainInequality() async {
    final result = await WatchMathKeypadDialog.show(
      context,
      title: 'Domain: e.g. 3≤x<10 or x>0',
      initialValue: '',
    );
    if (result == null || !mounted) return;
    final parsed = _engine.parseDomainExpression(result);
    if (parsed != null && parsed.error == null) {
      setState(() {
        _domainMode = parsed.domainMode;
        _loText = parsed.lo;
        _loInclusive = parsed.loInc;
        _hiText = parsed.hi;
        _hiInclusive = parsed.hiInc;
        _excludedText = parsed.excluded;
        if (parsed.discrete.isNotEmpty) {
          _discreteText = parsed.discrete;
        }
      });
    }
  }

  Future<void> _editWithKeypad({
    required String title,
    required String current,
    required ValueChanged<String> onSave,
  }) async {
    final result = await WatchMathKeypadDialog.show(
      context,
      title: title,
      initialValue: current,
    );
    if (result != null && mounted) {
      setState(() => onSave(result));
    }
  }

  DomainSpec _buildDomain(List<TableEntry> tableEntries) {
    if (_inputMode == FunctionInputMode.table) {
      final xs = tableEntries.map((e) => e.x).toList();
      return DomainSpec.discrete(xs.isEmpty ? [0] : xs);
    }
    if (_domainMode == DomainMode.discrete) {
      final vals = _engine.parseNumberList(_discreteText);
      return DomainSpec.discrete(vals.isEmpty ? [0] : vals);
    }
    final loClean = _engine.normalizeDigitsAndSymbols(_loText).trim().toLowerCase();
    final hiClean = _engine.normalizeDigitsAndSymbols(_hiText).trim().toLowerCase();
    final lo = (loClean.isEmpty || loClean == '-inf' || loClean == '-∞')
        ? null
        : double.tryParse(loClean);
    final hi = (hiClean.isEmpty ||
            hiClean == '+inf' ||
            hiClean == 'inf' ||
            hiClean == '+∞' ||
            hiClean == '∞')
        ? null
        : double.tryParse(hiClean);
    final excluded = _engine.parseNumberList(_excludedText);

    if (lo != null && hi != null && lo > hi) {
      return DomainSpec.continuous(
        lowerBound: hi,
        lowerInclusive: _loInclusive,
        upperBound: lo,
        upperInclusive: _hiInclusive,
        excludedValues: excluded,
      );
    }
    return DomainSpec.continuous(
      lowerBound: lo,
      lowerInclusive: lo != null && _loInclusive,
      upperBound: hi,
      upperInclusive: hi != null && _hiInclusive,
      excludedValues: excluded,
    );
  }

  void _goToPage(int page) {
    if (page < 0 || page > 3) return;
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableEntries = _engine.parseTableEntries(_tableRaw);
    final parsed = _engine.tryParseFunction(_exprText);
    final fallbackExpr = _engine.parseExpression('4*x^2 - 3*x');
    final activeExpr = parsed.expression ?? fallbackExpr;
    final activeRhs = parsed.expression != null ? parsed.rhsText : '4*x^2 - 3*x';
    final domain = _buildDomain(tableEntries);
    final queries = _engine.parseNumberList(_queriesText);

    ParameterSolveOutput? paramOut;
    double aVal = 0.0;
    double bVal = 0.0;
    if (_inputMode == FunctionInputMode.formula &&
        (parsed.hasParameterA || parsed.hasParameterB) &&
        parsed.expression != null) {
      paramOut = _engine.solveParametersWithSteps(
        fnName: parsed.fnName,
        expr: activeExpr,
        rawRhs: activeRhs,
        hasA: parsed.hasParameterA,
        hasB: parsed.hasParameterB,
        x1: double.tryParse(_engine.normalizeDigitsAndSymbols(_condXText).trim()),
        y1: double.tryParse(_engine.normalizeDigitsAndSymbols(_condYText).trim()),
        x2: double.tryParse(_engine.normalizeDigitsAndSymbols(_cond2XText).trim()),
        y2: double.tryParse(_engine.normalizeDigitsAndSymbols(_cond2YText).trim()),
      );
      aVal = paramOut.solvedA ?? 0.0;
      bVal = paramOut.solvedB ?? 0.0;
    }

    final evaluations = _inputMode == FunctionInputMode.table
        ? queries
            .map(
              (q) => _engine.evaluateTablePoint(
                fnName: 'f',
                table: tableEntries,
                x: q,
              ),
            )
            .toList()
        : queries
            .map(
              (q) => _engine.evaluatePoint(
                fnName: parsed.fnName,
                expr: activeExpr,
                rawExpr: activeRhs,
                domain: domain,
                x: q,
                a: aVal,
                b: bVal,
              ),
            )
            .toList();

    final targetCond = _targetYText.trim().isNotEmpty
        ? _engine.solveTargetCondition(
            fnName: _inputMode == FunctionInputMode.table ? 'f' : parsed.fnName,
            inputMode: _inputMode,
            expr: activeExpr,
            table: tableEntries,
            domain: domain,
            rawCondition: _targetYText,
            a: aVal,
            b: bVal,
          )
        : null;

    final keyPoints = _inputMode == FunctionInputMode.table
        ? tableEntries
            .map((e) => KeyPoint(x: e.x, y: e.y, role: 'Table'))
            .toList()
        : _engine.computeKeyPoints(activeExpr, domain, a: aVal, b: bVal);

    final range = _inputMode == FunctionInputMode.table
        ? _engine.computeTableRange(tableEntries)
        : _engine.computeRange(activeExpr, domain, a: aVal, b: bVal);

    final size = MediaQuery.of(context).size;
    final isWatchViewport =
        size.shortestSide <= 460 && (size.width - size.height).abs() < 48;
    // Circular watch safe inset: (1 - sqrt(2)/2) / 2 ≈ 14.64%
    final safePad = isWatchViewport ? size.shortestSide * 0.146 : 16.0;

    const pageTitles = [
      '1/4 Input Studio',
      '2/4 Step Solver',
      '3/4 Number Line',
      '4/4 2D Graph',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(safePad),
          child: Column(
            children: [
              Text(
                pageTitles[_currentPage],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF38BDF8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  children: [
                    _buildInputScreen(
                      parsed,
                      paramOut,
                      domain,
                      range,
                      tableEntries,
                    ),
                    _buildSolverScreen(
                      _inputMode == FunctionInputMode.table ? 'f' : parsed.fnName,
                      paramOut,
                      targetCond,
                      evaluations,
                      keyPoints,
                    ),
                    _buildNumberLineScreen(domain, evaluations),
                    _buildGraphScreen(
                      activeExpr,
                      tableEntries,
                      domain,
                      range,
                      aVal,
                      bVal,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Clean navigation bar with < dots >
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () => _goToPage((_currentPage + 3) % 4),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: Icon(
                        Icons.chevron_left,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  ...List.generate(4, (i) {
                    final active = i == _currentPage;
                    return GestureDetector(
                      onTap: () => _goToPage(i),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.5),
                        width: active ? 12 : 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF334155),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    );
                  }),
                  InkWell(
                    onTap: () => _goToPage((_currentPage + 1) % 4),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      child: Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tapField({
    required String label,
    required String value,
    required VoidCallback onTap,
    Color valueColor = Colors.white,
  }) {
    return Material(
      color: const Color(0xFF111827),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Row(
            children: [
              Text(
                '$label: ',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.edit, size: 12, color: Color(0xFF38BDF8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputScreen(
    ParsedFunctionResult parsed,
    ParameterSolveOutput? paramOut,
    DomainSpec domain,
    RangeSpec range,
    List<TableEntry> tableEntries,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 2),
      children: [
        // Presets row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _presets.map((p) {
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: GestureDetector(
                  onTap: () => _applyPreset(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      p.label,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 6),

        // Mode Switch: Formula vs Table (x:y pairs)
        Row(
          children: [
            Expanded(
              child: _modeChip(
                'Formula f(x)',
                _inputMode == FunctionInputMode.formula,
                () => setState(() => _inputMode = FunctionInputMode.formula),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _modeChip(
                'Table (x:y)',
                _inputMode == FunctionInputMode.table,
                () => setState(() => _inputMode = FunctionInputMode.table),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (_inputMode == FunctionInputMode.formula) ...[
          _tapField(
            label: 'f(x)',
            value: _exprText,
            onTap: () => _editWithKeypad(
              title: 'Edit Function',
              current: _exprText,
              onSave: (v) => _exprText = v,
            ),
          ),
          if (parsed.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                parsed.error!,
                style: const TextStyle(color: Color(0xFFF87171), fontSize: 9.5),
              ),
            ),

          if (parsed.hasParameterA || parsed.hasParameterB) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(
                  child: _tapField(
                    label: parsed.hasParameterA && parsed.hasParameterB ? 'x₁' : 'x₀',
                    value: _condXText,
                    valueColor: const Color(0xFFFCD34D),
                    onTap: () => _editWithKeypad(
                      title: 'Condition 1: Input x',
                      current: _condXText,
                      onSave: (v) => _condXText = v,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: _tapField(
                    label: parsed.hasParameterA && parsed.hasParameterB ? 'y₁' : 'y₀',
                    value: _condYText,
                    valueColor: const Color(0xFFFCD34D),
                    onTap: () => _editWithKeypad(
                      title: 'Condition 1: ${parsed.fnName}(x)',
                      current: _condYText,
                      onSave: (v) => _condYText = v,
                    ),
                  ),
                ),
              ],
            ),
            if (parsed.hasParameterA && parsed.hasParameterB) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: _tapField(
                      label: 'x₂',
                      value: _cond2XText,
                      valueColor: const Color(0xFFFCD34D),
                      onTap: () => _editWithKeypad(
                        title: 'Condition 2: Input x₂',
                        current: _cond2XText,
                        onSave: (v) => _cond2XText = v,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: _tapField(
                      label: 'y₂',
                      value: _cond2YText,
                      valueColor: const Color(0xFFFCD34D),
                      onTap: () => _editWithKeypad(
                        title: 'Condition 2: ${parsed.fnName}(x₂)',
                        current: _cond2YText,
                        onSave: (v) => _cond2YText = v,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (paramOut?.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  paramOut!.error!,
                  style: const TextStyle(color: Color(0xFFF87171), fontSize: 9.5),
                ),
              )
            else if (paramOut?.solvedA != null || paramOut?.solvedB != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  [
                    if (paramOut?.solvedA != null)
                      'a = ${formatCompactNum(paramOut!.solvedA!)}',
                    if (paramOut?.solvedB != null)
                      'b = ${formatCompactNum(paramOut!.solvedB!)}',
                  ].join(' , '),
                  style: const TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],

          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _modeChip(
                  'Interval',
                  _domainMode == DomainMode.continuous,
                  () => setState(() => _domainMode = DomainMode.continuous),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _modeChip(
                  'Discrete Set',
                  _domainMode == DomainMode.discrete,
                  () => setState(() => _domainMode = DomainMode.discrete),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _tapField(
            label: 'Ineq Df',
            value: 'Tap to type e.g. 3≤x<10 or x>0',
            valueColor: const Color(0xFF7DD3FC),
            onTap: _editDomainInequality,
          ),
          const SizedBox(height: 5),

          if (_domainMode == DomainMode.continuous) ...[
            Row(
              children: [
                _bracketButton(
                  _loInclusive ? '[' : '(',
                  () => setState(() => _loInclusive = !_loInclusive),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _tapField(
                    label: 'Min',
                    value: _loText,
                    onTap: () => _editWithKeypad(
                      title: 'Lower Bound (-inf allowed)',
                      current: _loText,
                      onSave: (v) => _loText = v,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _tapField(
                    label: 'Max',
                    value: _hiText,
                    onTap: () => _editWithKeypad(
                      title: 'Upper Bound (+inf allowed)',
                      current: _hiText,
                      onSave: (v) => _hiText = v,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                _bracketButton(
                  _hiInclusive ? ']' : ')',
                  () => setState(() => _hiInclusive = !_hiInclusive),
                ),
              ],
            ),
            const SizedBox(height: 4),
            _tapField(
              label: 'Excl',
              value: _excludedText.isEmpty ? 'none' : _excludedText,
              valueColor: _excludedText.isEmpty
                  ? const Color(0xFF64748B)
                  : const Color(0xFFF87171),
              onTap: () => _editWithKeypad(
                title: 'Excluded Points D-{...} (optional)',
                current: _excludedText,
                onSave: (v) => _excludedText = v,
              ),
            ),
          ] else
            _tapField(
              label: 'D',
              value: _discreteText,
              onTap: () => _editWithKeypad(
                title: 'Discrete Set (e.g. -2,0,1,2,4)',
                current: _discreteText,
                onSave: (v) => _discreteText = v,
              ),
            ),
        ] else ...[
          _tapField(
            label: 'Pairs',
            value: _tableRaw,
            onTap: () => _editWithKeypad(
              title: 'Table Pairs x:y (e.g. -2:0, 0:3)',
              current: _tableRaw,
              onSave: (v) => _tableRaw = v,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${tableEntries.length} points loaded · Df = ${domain.toIntervalNotation()}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
          ),
        ],

        const SizedBox(height: 5),
        _tapField(
          label: 'Query x',
          value: _queriesText,
          onTap: () => _editWithKeypad(
            title: 'Query Points (comma-separated)',
            current: _queriesText,
            onSave: (v) => _queriesText = v,
          ),
        ),
        const SizedBox(height: 4),
        _tapField(
          label: 'f(x)□k',
          value: _targetYText.isEmpty ? 'none' : _targetYText,
          valueColor: _targetYText.isEmpty
              ? const Color(0xFF64748B)
              : const Color(0xFF38BDF8),
          onTap: () => _editWithKeypad(
            title: 'Solve f(x) =, <, ≤, >, ≥ k',
            current: _targetYText,
            onSave: (v) => _targetYText = v,
          ),
        ),

        const SizedBox(height: 6),
        Text(
          'Df: ${domain.toIntervalNotation()}  ·  Rf: ${range.toNotation(domain.mode)}',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF34D399),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _modeChip(String text, bool active, VoidCallback onTap) {
    return Material(
      color: active ? const Color(0xFF0C4A6E) : const Color(0xFF111827),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? const Color(0xFF38BDF8) : const Color(0xFF1E293B),
            ),
          ),
          child: Center(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _bracketButton(String text, VoidCallback onTap) {
    return Material(
      color: const Color(0xFF1E293B),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          width: 28,
          height: 30,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolverScreen(
    String fnName,
    ParameterSolveOutput? paramOut,
    TargetConditionResult? targetCond,
    List<EvaluationStepResult> evaluations,
    List<KeyPoint> keyPoints,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 2),
      children: [
        if (paramOut != null && paramOut.steps.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: paramOut.steps
                  .map(
                    (s) => Text(
                      s,
                      style: const TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 10,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
        if (targetCond != null) ...[
          Container(
            padding: const EdgeInsets.all(6),
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0C2D48),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF0369A1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solve $fnName(x) ${targetCond.op == '<=' ? '≤' : targetCond.op == '>=' ? '≥' : targetCond.op} ${formatCompactNum(targetCond.targetY)}:',
                  style: const TextStyle(
                    color: Color(0xFF7DD3FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (targetCond.op == '=') ...[
                  if (targetCond.equalitySolutions.isEmpty)
                    const Text(
                      'No solution x ∈ Df',
                      style: TextStyle(color: Color(0xFFFCA5A5), fontSize: 10),
                    )
                  else
                    ...targetCond.equalitySolutions.map(
                      (sol) => Text(
                        sol.steps.first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ] else
                  Text(
                    'x ∈ ${targetCond.notation}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
        ...evaluations.map((res) {
          return Container(
            margin: const EdgeInsets.only(bottom: 5),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: res.inDomain
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF7F1D1D),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: res.steps
                  .asMap()
                  .entries
                  .map(
                    (entry) => Text(
                      entry.value,
                      style: TextStyle(
                        color: entry.key == res.steps.length - 1
                            ? (res.inDomain
                                ? const Color(0xFF34D399)
                                : const Color(0xFFF87171))
                            : Colors.white,
                        fontSize: 10.5,
                        fontWeight: entry.key == res.steps.length - 1
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  )
                  .toList(),
            ),
          );
        }),
        const SizedBox(height: 3),
        const Text(
          'Key Points Table',
          style: TextStyle(
            color: Color(0xFF94A3B8),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        ...keyPoints.map((pt) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 0.6),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'x=${formatCompactNum(pt.x)}',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    '$fnName=${pt.y != null ? formatCompactNum(pt.y!) : 'Undef'}',
                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 10),
                  ),
                ),
                Text(
                  pt.role,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNumberLineScreen(
    DomainSpec domain,
    List<EvaluationStepResult> evaluations,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Interval: ${domain.toIntervalNotation()}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          domain.toSetBuilderNotation(),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: CustomPaint(
            painter: NumberLinePainter(
              domain: domain,
              evaluations: evaluations,
            ),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }

  Widget _buildGraphScreen(
    Expression activeExpr,
    List<TableEntry> tableEntries,
    DomainSpec domain,
    RangeSpec range,
    double aVal,
    double bVal,
  ) {
    return Column(
      children: [
        Text(
          (_inputMode == FunctionInputMode.table ||
                  domain.mode == DomainMode.discrete)
              ? 'Discrete Points + Projections'
              : 'Continuous Curve + Projections',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9.5),
        ),
        const SizedBox(height: 3),
        Expanded(
          child: CustomPaint(
            painter: CartesianGraphPainter(
              inputMode: _inputMode,
              expression: activeExpr,
              tableEntries: tableEntries,
              domain: domain,
              range: range,
              parameterA: aVal,
              parameterB: bVal,
              engine: _engine,
            ),
            size: Size.infinite,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Rf: ${range.toNotation(domain.mode)}',
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF34D399),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
