import 'package:flutter/foundation.dart';
import '../core/analysis.dart';
import '../core/domain.dart';
import '../core/engine.dart';

class AppState extends ChangeNotifier {
  String expr = 'f(x) = 4x^2 - 3x';
  bool discrete = true;
  String setText = '-2, 0, 1, 2, 4';
  String loText = '-2', hiText = '3';
  bool loClosed = true, hiClosed = false, loInf = false, hiInf = false;
  String query = '-2, 1, 5';
  String condition = '';

  Analysis? analysis;
  String? error;

  void analyze() {
    try {
      final Domain dom;
      if (discrete) {
        dom = Domain.parseSet(setText);
      } else {
        final lo = loInf ? null : parseConstant(loText);
        final hi = hiInf ? null : parseConstant(hiText);
        dom = Domain.interval(lo: lo, hi: hi, loClosed: loClosed && !loInf, hiClosed: hiClosed && !hiInf);
      }
      analysis = Analysis.run(exprText: expr, domain: dom, condition: condition, queryText: query);
      error = null;
    } on FormatException catch (e) {
      analysis = null;
      error = e.message;
    } catch (_) {
      analysis = null;
      error = 'Could not read the input';
    }
    notifyListeners();
  }

  void preset(String id) {
    condition = '';
    loInf = false;
    hiInf = false;
    query = '-2, 1, 5';
    expr = 'f(x) = 4x^2 - 3x';
    switch (id) {
      case 'Quadratic':
        discrete = false;
        loText = '-2';
        hiText = '3';
        loClosed = true;
        hiClosed = true;
        break;
      case 'Solve a':
        expr = 'h(x) = 3x + a';
        condition = 'h(1) = 2';
        discrete = false;
        loText = '-1';
        hiText = '4';
        loClosed = true;
        hiClosed = true;
        query = '-1, 2, 5';
        break;
      case 'Discrete':
        discrete = true;
        setText = '-2, 0, 1, 2, 4';
        break;
      case 'Half-open':
        discrete = false;
        loText = '-2';
        hiText = '3';
        loClosed = true;
        hiClosed = false;
        break;
    }
    analyze();
  }
}
