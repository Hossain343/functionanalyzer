import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'screens/graph_screen.dart';
import 'screens/input_screen.dart';
import 'screens/number_line_screen.dart';
import 'screens/steps_screen.dart';
import 'state/app_state.dart';
import 'ui/theme.dart';

void main() => runApp(const FunctionAnalyzerApp());

class FunctionAnalyzerApp extends StatelessWidget {
  const FunctionAnalyzerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FunctionAnalyzer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(primary: C.amber, surface: C.bg),
        textSelectionTheme: const TextSelectionThemeData(cursorColor: C.amber, selectionHandleColor: C.amber),
      ),
      home: const WatchRoot(),
    );
  }
}

class WatchRoot extends StatefulWidget {
  const WatchRoot({super.key});
  @override
  State<WatchRoot> createState() => _WatchRootState();
}

class _WatchRootState extends State<WatchRoot> {
  final state = AppState();
  int _page = 0;
  double? _side;
  static const names = ['Input', 'Steps', 'Number line', 'Graph'];

  @override
  void initState() {
    super.initState();
    state.analyze();
  }

  void _next() => setState(() => _page = (_page + 1) % names.length);

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom > 0;
    final preview = kIsWeb ||
        const {TargetPlatform.windows, TargetPlatform.macOS, TargetPlatform.linux}.contains(defaultTargetPlatform);
    final pages = <Widget>[
      InputScreen(state: state, onSolved: () => setState(() => _page = 1)),
      StepsScreen(state: state),
      NumberLineScreen(state: state),
      GraphScreen(state: state),
    ];
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(builder: (context, c) {
        // The face is a circle: on a watch it fills the screen; on desktop/phone it is a round preview.
        if (!(kb && _side != null)) {
          _side = math.min(math.min(c.maxWidth, c.maxHeight), preview ? 440.0 : 2000.0);
        }
        final side = _side!;
        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: ClipOval(
              child: Metrics(
                side: side,
                child: Container(
                  color: C.bg,
                  foregroundDecoration: preview
                      ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF30333A), width: 6))
                      : null,
                  child: Column(children: [
                    Expanded(child: ClipRect(child: IndexedStack(index: _page, children: pages))),
                    if (!kb) _NavButton(label: names[(_page + 1) % names.length], height: side * 0.2, onTap: _next),
                  ]),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// One solid button across the whole bottom: goes to the next page, and the 4 pages loop.
class _NavButton extends StatelessWidget {
  const _NavButton({required this.label, required this.height, required this.onTap});
  final String label;
  final double height;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return Material(
      color: C.amber,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Align(
            alignment: const Alignment(0, -0.3),
            child: Text(label, style: sans(context, color: Colors.black, bold: true, scale: 1.25).copyWith(fontSize: m.fs * 1.25)),
          ),
        ),
      ),
    );
  }
}
