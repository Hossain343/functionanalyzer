import 'package:flutter/material.dart';

class C {
  static const bg = Color(0xFF0A0B0D);
  static const card = Color(0xFF17181C);
  static const border = Color(0xFF2B2D33);
  static const amber = Color(0xFFF0A100);
  static const text = Color(0xFFEDE9E2);
  static const muted = Color(0xFF9B988F);
  static const label = Color(0xFFBDB9AF);
  static const grid = Color(0xFF202127);
  static const axis = Color(0xFFF1EEE7);
  static const dim = Color(0xFF55565B);
}

/// Size of the round watch face; everything scales from it.
class Metrics extends InheritedWidget {
  const Metrics({super.key, required this.side, required super.child});
  final double side;
  double get fs => (side * 0.058).clamp(12.0, 17.0).toDouble();
  double get btn => fs * 3.5;
  static Metrics of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Metrics>()!;
  @override
  bool updateShouldNotify(Metrics o) => o.side != side;
}

TextStyle mono(BuildContext c, {Color color = C.text, bool bold = false, double scale = 1}) => TextStyle(
      fontFamily: 'Consolas',
      fontFamilyFallback: const ['monospace', 'Courier New'],
      fontSize: Metrics.of(c).fs * scale,
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      height: 1.3,
    );

TextStyle sans(BuildContext c,
        {Color color = C.text, bool bold = false, double scale = 1, double spacing = 0}) =>
    TextStyle(
      fontSize: Metrics.of(c).fs * scale,
      color: color,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      letterSpacing: spacing,
      height: 1.25,
    );

class Lbl extends StatelessWidget {
  const Lbl(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return Padding(
      padding: EdgeInsets.only(top: m.fs * 0.9, bottom: m.fs * 0.4),
      child: Text(text.toUpperCase(), style: sans(context, color: C.label, bold: true, scale: 0.8, spacing: 1.4)),
    );
  }
}

class WCard extends StatelessWidget {
  const WCard({super.key, required this.child, this.borderColor = C.border, this.padding});
  final Widget child;
  final Color borderColor;
  final EdgeInsets? padding;
  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: m.fs * 0.7),
      padding: padding ?? EdgeInsets.all(m.fs * 0.9),
      decoration: BoxDecoration(
        color: C.card,
        borderRadius: BorderRadius.circular(m.fs * 1.4),
        border: Border.all(color: borderColor),
      ),
      child: child,
    );
  }
}

class DarkBtn extends StatelessWidget {
  const DarkBtn({
    super.key,
    this.label,
    required this.onTap,
    this.active = false,
    this.enabled = true,
    this.width,
    this.scale = 1,
  });
  final String? label;
  final VoidCallback onTap;
  final bool active, enabled;
  final double? width;
  final double scale;
  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    final on = active && enabled;
    final fg = !enabled ? C.dim : (on ? Colors.black : C.text);
    return SizedBox(
      height: m.btn,
      width: width,
      child: Material(
        color: on ? C.amber : C.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(m.fs * 1.2),
          side: BorderSide(color: on ? C.amber : C.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Center(child: Text(label ?? '', style: sans(context, color: fg, bold: true, scale: 1.05 * scale))),
        ),
      ),
    );
  }
}

/// Title + scrolling content. Content is clipped above the bottom button, so nothing can overlap it.
class WatchPage extends StatefulWidget {
  const WatchPage({super.key, required this.title, required this.children, this.physics});
  final String title;
  final List<Widget> children;
  final ScrollPhysics? physics;
  @override
  State<WatchPage> createState() => _WatchPageState();
}

class _WatchPageState extends State<WatchPage> {
  final _sc = ScrollController();
  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = Metrics.of(context);
    final px = m.side * 0.115;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Column(children: [
      SizedBox(height: m.side * 0.075),
      Text(widget.title.toUpperCase(), style: sans(context, color: C.label, bold: true, scale: 0.9, spacing: 1.6)),
      SizedBox(height: m.side * 0.02),
      Expanded(
        child: ClipRect(
          child: Stack(children: [
            ListView(
              controller: _sc,
              physics: widget.physics,
              padding: EdgeInsets.fromLTRB(px, 4, px, m.side * 0.05 + kb),
              children: widget.children,
            ),
            Positioned(
              right: m.side * 0.07,
              top: 0,
              bottom: 0,
              child: AnimatedBuilder(
                animation: _sc,
                builder: (context, _) => _Thumb(controller: _sc),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.controller});
  final ScrollController controller;
  @override
  Widget build(BuildContext context) {
    if (!controller.hasClients || !controller.position.hasContentDimensions) return const SizedBox(width: 5);
    final p = controller.position;
    if (p.maxScrollExtent <= 0) return const SizedBox(width: 5);
    return LayoutBuilder(builder: (context, box) {
      final track = box.maxHeight * 0.7;
      final top0 = box.maxHeight * 0.1;
      final th = (track * p.viewportDimension / (p.viewportDimension + p.maxScrollExtent)).clamp(24.0, track).toDouble();
      final pos = (p.pixels / p.maxScrollExtent).clamp(0.0, 1.0) * (track - th);
      return SizedBox(
        width: 5,
        child: Stack(children: [
          Positioned(
            top: top0 + pos,
            height: th,
            left: 0,
            right: 0,
            child: DecoratedBox(
              decoration: BoxDecoration(color: const Color(0xFF3A3D44), borderRadius: BorderRadius.circular(3)),
            ),
          ),
        ]),
      );
    });
  }
}
