import 'dart:math' as math;
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// إعدادات سهلة التعديل
// ---------------------------------------------------------------------------
const appName = 'سبحتي';
const useArabicDigits = true; // غيّرها إلى false لو عايز الأرقام 123

const _adhkar = <String>[
  'سبحان الله',
  'الحمد لله',
  'الله أكبر',
  'لا إله إلا الله',
  'أستغفر الله',
  'لا حول ولا قوة إلا بالله',
  'اللهم صلِّ على محمد',
];

// الألوان
const _inkTop = Color(0xFF0E2A2D);
const _inkBottom = Color(0xFF071719);
const _disc = Color(0xFF133A3E);
const _discLight = Color(0xFF1B4C51);
const _parchment = Color(0xFFF1E6CF);
const _saffron = Color(0xFFE8A33D);

String _num(int n) {
  final s = n.toString();
  if (!useArabicDigits) return s;
  const a = '٠١٢٣٤٥٦٧٨٩';
  return s.split('').map((c) => a[int.parse(c)]).join();
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: _inkBottom,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const SebhaApp());
}

class SebhaApp extends StatelessWidget {
  const SebhaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appName,
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _inkBottom,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _saffron,
          brightness: Brightness.dark,
        ),
      ),
      home: const CounterPage(),
    );
  }
}

class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int count = 0;
  int target = 33; // 0 = بدون حد
  int laps = 0;
  int total = 0;
  int dhikr = 0;
  bool haptic = true;
  bool sound = true;
  bool pressed = false;
  SharedPreferences? prefs;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      prefs = p;
      count = p.getInt('count') ?? 0;
      target = p.getInt('target') ?? 33;
      laps = p.getInt('laps') ?? 0;
      total = p.getInt('total') ?? 0;
      dhikr = (p.getInt('dhikr') ?? 0).clamp(0, _adhkar.length - 1);
      haptic = p.getBool('haptic') ?? true;
      sound = p.getBool('sound') ?? true;
    });
  }

  void _save() {
    final p = prefs;
    if (p == null) return;
    p.setInt('count', count);
    p.setInt('target', target);
    p.setInt('laps', laps);
    p.setInt('total', total);
    p.setInt('dhikr', dhikr);
    p.setBool('haptic', haptic);
    p.setBool('sound', sound);
  }

  // عدد الخرزات المرسومة وعدد المضاءة منها
  int get beads => (target > 0 && target <= 100) ? target : 33;

  int get lit {
    if (target > 0 && target <= 100) return count;
    if (count == 0) return 0;
    final r = count % 33;
    return r == 0 ? 33 : r;
  }

  void _tap() {
    setState(() {
      if (target > 0 && count >= target) count = 0;
      count++;
      total++;
      if (target > 0 && count == target) {
        laps++;
        if (haptic) HapticFeedback.heavyImpact();
      } else if (haptic) {
        HapticFeedback.lightImpact();
      }
      if (sound) SystemSound.play(SystemSoundType.click);
    });
    _save();
  }

  void _resetCount() {
    setState(() => count = 0);
    _save();
  }

  void _setTarget(int t) {
    setState(() {
      target = t;
      if (target > 0 && count > target) count = 0;
    });
    _save();
  }

  Future<void> _customTarget() async {
    final controller = TextEditingController();
    final value = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حدد الهدف'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(hintText: 'مثلاً 500'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text)),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
    if (value != null && value > 0) _setTarget(value);
  }

  Future<void> _confirmResetAll() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تصفير كل شيء؟'),
        content: const Text('هيتم تصفير العدّاد والدورات والإجمالي.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        count = 0;
        laps = 0;
        total = 0;
      });
      _save();
    }
  }

  Future<void> _pickDhikr() async {
    final i = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _disc,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (var k = 0; k < _adhkar.length; k++)
              ListTile(
                title: Text(_adhkar[k], style: const TextStyle(fontSize: 18)),
                trailing: k == dhikr
                    ? const Icon(Icons.check, color: _saffron)
                    : null,
                onTap: () => Navigator.pop(ctx, k),
              ),
          ],
        ),
      ),
    );
    if (i != null) {
      setState(() => dhikr = i);
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_inkTop, _inkBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(child: Center(child: _ring())),
              _targets(),
              const SizedBox(height: 14),
              _bottomBar(),
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        children: [
          Text(
            appName,
            style: TextStyle(
              fontSize: 15,
              color: _parchment.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _pickDhikr,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      _adhkar[dhikr],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: _parchment,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.expand_more,
                      color: _parchment.withOpacity(0.5), size: 22),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ring() {
    return LayoutBuilder(builder: (context, c) {
      final side = math.min(c.maxWidth, c.maxHeight - 8).clamp(220.0, 420.0);
      final done = target > 0 && count >= target;
      final inner = (side / 2 - 18 - 26) * 1.5;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => setState(() => pressed = true),
        onTapUp: (_) => setState(() => pressed = false),
        onTapCancel: () => setState(() => pressed = false),
        onTap: _tap,
        child: AnimatedScale(
          scale: pressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 90),
          child: SizedBox(
            width: side,
            height: side,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(side, side),
                  painter: _RingPainter(beads: beads, lit: lit),
                ),
                SizedBox(
                  width: inner,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _num(count),
                          style: TextStyle(
                            fontSize: 92,
                            fontWeight: FontWeight.w300,
                            height: 1.1,
                            color: done ? _saffron : _parchment,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      Text(
                        target > 0 ? 'من ${_num(target)}' : 'بدون حد',
                        style: TextStyle(
                          fontSize: 15,
                          color: _parchment.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'الدورات ${_num(laps)}  ·  الإجمالي ${_num(total)}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: _parchment.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _saffron : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _saffron : _parchment.withOpacity(0.25),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected ? const Color(0xFF2A1A00) : _parchment,
          ),
        ),
      ),
    );
  }

  Widget _targets() {
    const presets = [33, 99, 100];
    final isCustom = target != 0 && !presets.contains(target);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        for (final t in presets) _pill(_num(t), target == t, () => _setTarget(t)),
        _pill('∞', target == 0, () => _setTarget(0)),
        _pill(isCustom ? _num(target) : 'مخصص', isCustom, _customTarget),
      ],
    );
  }

  Widget _bottomBar() {
    Widget btn(IconData icon, String tip, VoidCallback onTap, {bool on = true}) {
      return IconButton(
        tooltip: tip,
        onPressed: onTap,
        iconSize: 24,
        color: on ? _parchment : _parchment.withOpacity(0.35),
        icon: Icon(icon),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _parchment.withOpacity(0.06),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(Icons.refresh, 'إعادة العدّ', _resetCount),
          btn(Icons.vibration, 'الاهتزاز', () {
            setState(() => haptic = !haptic);
            _save();
          }, on: haptic),
          btn(sound ? Icons.volume_up : Icons.volume_off, 'الصوت', () {
            setState(() => sound = !sound);
            _save();
          }, on: sound),
          btn(Icons.delete_sweep_outlined, 'تصفير الكل', _confirmResetAll),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// رسم حلقة الخرزات
// ---------------------------------------------------------------------------
class _RingPainter extends CustomPainter {
  _RingPainter({required this.beads, required this.lit});

  final int beads;
  final int lit;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final R = size.width / 2 - 18;

    // القرص الداخلي
    canvas.drawCircle(
      c,
      R - 26,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: [_discLight, _disc],
        ).createShader(Rect.fromCircle(center: c, radius: R)),
    );

    // الخيط
    canvas.drawCircle(
      c,
      R,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = _parchment.withOpacity(0.12),
    );

    final r = math.min(13.0, math.pi * R / beads * 0.62);
    for (var i = 0; i < beads; i++) {
      final a = -math.pi / 2 + 2 * math.pi * i / beads;
      final p = c + Offset(math.cos(a), math.sin(a)) * R;
      if (i < lit) {
        if (i == lit - 1) {
          canvas.drawCircle(
            p,
            r * 1.9,
            Paint()
              ..color = _saffron.withOpacity(0.28)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
          );
        }
        canvas.drawCircle(p, r, Paint()..color = _saffron);
        canvas.drawCircle(
          p + Offset(-r * 0.3, -r * 0.3),
          r * 0.28,
          Paint()..color = Colors.white.withOpacity(0.35),
        );
      } else {
        canvas.drawCircle(p, r, Paint()..color = _parchment.withOpacity(0.16));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.beads != beads || old.lit != lit;
}
