import 'package:flutter/material.dart';

class WatchMathKeypadDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const WatchMathKeypadDialog({
    super.key,
    required this.title,
    required this.initialValue,
  });

  static Future<String?> show(
    BuildContext context, {
    required String title,
    required String initialValue,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => WatchMathKeypadDialog(
        title: title,
        initialValue: initialValue,
      ),
    );
  }

  @override
  State<WatchMathKeypadDialog> createState() => _WatchMathKeypadDialogState();
}

class _WatchMathKeypadDialogState extends State<WatchMathKeypadDialog> {
  late String _value;
  int _tab = 0; // 0 = Numbers/Core, 1 = Letters/Symbols

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  void _append(String token) {
    setState(() => _value += token);
  }

  void _backspace() {
    if (_value.isEmpty) return;
    setState(() => _value = _value.substring(0, _value.length - 1));
  }

  void _clear() {
    setState(() => _value = '');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWatch =
        size.shortestSide <= 460 && (size.width - size.height).abs() < 48;
    final pad = isWatch ? size.shortestSide * 0.135 : 20.0;

    return Scaffold(
      backgroundColor: const Color(0xFF070B12),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            children: [
              // Title & Close/Save row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Color(0xFFF87171), fontSize: 10),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Live Display Box
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF38BDF8)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Text(
                    _value.isEmpty ? ' ' : _value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),

              // Keypad Page Switch + Backspace + OK
              Row(
                children: [
                  Expanded(
                    child: _actionKey(
                      _tab == 0 ? 'abc / ∞' : '123 / ^',
                      const Color(0xFF1E293B),
                      const Color(0xFF38BDF8),
                      () => setState(() => _tab = _tab == 0 ? 1 : 0),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _actionKey(
                      '⌫',
                      const Color(0xFF1E293B),
                      Colors.white,
                      _backspace,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _actionKey(
                      'CLR',
                      const Color(0xFF3F1D24),
                      const Color(0xFFFCA5A5),
                      _clear,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: _actionKey(
                      'OK',
                      const Color(0xFF065F46),
                      const Color(0xFF6EE7B7),
                      () => Navigator.of(context).pop(_value),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Keypad Rows (big touch targets, zero crowding)
              Expanded(
                child: _tab == 0 ? _buildCoreGrid() : _buildSymbolGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoreGrid() {
    const rows = [
      ['7', '8', '9', '+', '-'],
      ['4', '5', '6', '*', '/'],
      ['1', '2', '3', '^', '('],
      ['0', '.', ',', 'x', ')'],
    ];
    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: row.map((k) {
                final isVar = k == 'x';
                final isOp = ['+', '-', '*', '/', '^', '(', ')'].contains(k);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: _keyButton(
                      k,
                      isVar
                          ? const Color(0xFF0C4A6E)
                          : isOp
                              ? const Color(0xFF1E293B)
                              : const Color(0xFF111827),
                      isVar ? const Color(0xFF7DD3FC) : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSymbolGrid() {
    const rows = [
      ['a', 'b', 'f(x)=', 'g(x)=', 'h(x)='],
      ['<', '≤', '=', '≥', '>'],
      ['|', 'sqrt(', ':', '-inf', '+inf'],
      ['x^2', 'x^3', '[', ']', ','],
    ];
    return Column(
      children: rows.map((row) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              children: row.map((k) {
                final isSpecial =
                    k == 'a' || k == 'b' || k == '-inf' || k == '+inf';
                final isCompare =
                    ['<', '≤', '=', '≥', '>'].contains(k);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: _keyButton(
                      k,
                      isSpecial
                          ? const Color(0xFF451A03)
                          : isCompare
                              ? const Color(0xFF0C4A6E)
                              : const Color(0xFF1E293B),
                      isSpecial
                          ? const Color(0xFFFCD34D)
                          : isCompare
                              ? const Color(0xFF7DD3FC)
                              : Colors.white,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _keyButton(String label, Color bg, Color fg) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _append(label),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionKey(String label, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(
      height: 26,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: fg,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
