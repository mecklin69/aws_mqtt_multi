import 'dart:io';
import 'package:Elevate/services/amplify_service.dart';
import 'package:Elevate/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ Add this
import 'package:Elevate/services/aws_iot_services.dart';
import 'package:Elevate/services/storage_service.dart';
import 'constants/app_colors.dart' as app_colors;
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize local storage
try{
  if(Platform.isWindows) {
    await NotificationService.init();
  }
}catch(e){}
  await StorageService.init();
  await AmplifyService.configure();
  // ✅ Initialize notifications

if (Platform.isAndroid) {
  await NotificationService.init();}

  // ✅ Handle notification permissions cross-platform
  if (Platform.isAndroid) {
    // Android 13+ (API 33) needs explicit permission
    final status = await Permission.notification.request();
    if (status.isGranted) {
      print('✅ Notification permission granted');
    } else {
      print('⚠️ Notification permission denied');
    }

  } else if (Platform.isIOS) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    final iosImplementation = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await iosImplementation?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // ✅ Initialize AWS IoT service before app runs
  final AwsIotService awsService = Get.put(AwsIotService());

    await awsService.connect();


  // ✅ Determine login state before app starts
  final bool isUserLoggedIn = StorageService.isLoggedIn();

  runApp(ThingerDashboardApp(isUserLoggedIn: isUserLoggedIn));
}

class ThingerDashboardApp extends StatelessWidget {
  final bool isUserLoggedIn;
  const ThingerDashboardApp({super.key, required this.isUserLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Elevate Cloud Services',
      theme: ThemeData(
        scaffoldBackgroundColor: app_colors.lightGrey,
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      // ✅ Conditionally show dashboard or login based on stored login
      home: isUserLoggedIn ? const DashboardScreen() : const LoginPage(),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const DashboardScreen()),
      ],
    );
  }
}




// import 'dart:math';
// import 'dart:async';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
//
// void main() {
//   runApp(const ECGMonitorApp());
// }
//
// // ─── THEME COLORS ────────────────────────────────────────────────────────────
// class ECGColors {
//   static const bg          = Color(0xFF080A0C);
//   static const surface     = Color(0xFF0D1117);
//   static const border      = Color(0xFF1A2535);
//   static const gridMinor   = Color(0x12004D29);
//   static const gridMajor   = Color(0x26006B38);
//   static const sweepCursor = Color(0x4064B4FF);
//   static const accentBlue  = Color(0xFF4A9EFF);
//   static const textPrimary = Color(0xFFE0E8F0);
//   static const textMuted   = Color(0xFF6B7A8D);
//   // Vitals
//   static const hrGreen    = Color(0xFF00E676);
//   static const spo2Blue   = Color(0xFF29B6F6);
//   static const nibpOrange = Color(0xFFFF7043);
//   static const rrPurple   = Color(0xFFAB47BC);
//   static const tempYellow = Color(0xFFFFCA28);
//   static const etco2Cyan  = Color(0xFF26C6DA);
// }
//
// // ─── UNIQUE COLOR PER LEAD ───────────────────────────────────────────────────
// const Map<String, Color> kLeadColors = {
//   'I':   Color(0xFF00E676), // bright green
//   'II':  Color(0xFF1DE9B6), // teal-green
//   'III': Color(0xFF64FFDA), // seafoam
//   'aVR': Color(0xFF40C4FF), // sky blue
//   'aVL': Color(0xFF448AFF), // blue
//   'aVF': Color(0xFF7C4DFF), // violet
//   'V1':  Color(0xFFFFD740), // amber
//   'V2':  Color(0xFFFFAB40), // orange
//   'V3':  Color(0xFFFF6E40), // deep orange
//   'V4':  Color(0xFFFF4081), // pink
//   'V5':  Color(0xFFEA80FC), // orchid
//   'V6':  Color(0xFFCCFF90), // lime
// };
// Color leadColor(String l) => kLeadColors[l] ?? const Color(0xFFE0E8F0);
//
// const List<String> kLeads = [
//   'I','II','III','aVR','aVL','aVF','V1','V2','V3','V4','V5','V6'
// ];
//
// // ─── WAVEFORM MATH ───────────────────────────────────────────────────────────
// // Gaussian bump: time t and sigma in normalised beat fraction [0,1].
// class _G {
//   final double t, s, a;
//   const _G(this.t, this.s, this.a);
//   @pragma('vm:prefer-inline')
//   double v(double x) {
//     final d = x - t;
//     return a * exp(-(d * d) / (2.0 * s * s));
//   }
// }
//
// // Physiologically correct 12-lead morphologies.
// // Times: P ~0.12, Q ~0.28, R ~0.30, S ~0.33, T ~0.53 (normalised beat).
// // Amplitudes in mV.
// const Map<String, List<_G>> kMorphs = {
//   'I':   [_G(0.12,0.020, 0.10),_G(0.28,0.007,-0.07),_G(0.30,0.011, 0.85),_G(0.33,0.007,-0.18),_G(0.52,0.034, 0.20)],
//   'II':  [_G(0.12,0.022, 0.15),_G(0.28,0.006,-0.08),_G(0.30,0.012, 1.20),_G(0.33,0.007,-0.12),_G(0.53,0.037, 0.30)],
//   'III': [_G(0.12,0.020, 0.05),_G(0.28,0.008,-0.10),_G(0.30,0.011, 0.50),_G(0.33,0.008,-0.22),_G(0.54,0.037, 0.12)],
//   'aVR': [_G(0.12,0.020,-0.12),_G(0.28,0.007, 0.06),_G(0.30,0.012,-0.95),_G(0.33,0.007, 0.10),_G(0.53,0.035,-0.22)],
//   'aVL': [_G(0.12,0.018, 0.04),_G(0.28,0.008,-0.12),_G(0.30,0.011, 0.55),_G(0.33,0.008,-0.28),_G(0.52,0.033, 0.16)],
//   'aVF': [_G(0.12,0.021, 0.12),_G(0.28,0.007,-0.07),_G(0.30,0.012, 0.80),_G(0.33,0.007,-0.14),_G(0.53,0.036, 0.26)],
//   'V1':  [_G(0.12,0.020, 0.06),_G(0.30,0.009, 0.18),_G(0.33,0.010,-0.88),_G(0.53,0.030,-0.12)],
//   'V2':  [_G(0.12,0.021, 0.08),_G(0.30,0.011, 0.42),_G(0.33,0.010,-0.70),_G(0.53,0.033, 0.22)],
//   'V3':  [_G(0.12,0.021, 0.10),_G(0.30,0.012, 0.70),_G(0.33,0.010,-0.50),_G(0.53,0.035, 0.32)],
//   'V4':  [_G(0.12,0.021, 0.12),_G(0.28,0.005,-0.05),_G(0.30,0.012, 1.00),_G(0.33,0.008,-0.28),_G(0.53,0.036, 0.36)],
//   'V5':  [_G(0.12,0.022, 0.12),_G(0.28,0.005,-0.04),_G(0.30,0.012, 1.28),_G(0.33,0.007,-0.14),_G(0.53,0.036, 0.34)],
//   'V6':  [_G(0.12,0.022, 0.12),_G(0.28,0.005,-0.03),_G(0.30,0.012, 1.08),_G(0.33,0.006,-0.08),_G(0.53,0.035, 0.28)],
// };
// const Map<String, double> kST = {'II': 0.02, 'aVF': 0.01, 'V1': -0.02};
//
// double _mv(String lead, double normT) {
//   double v = kST[lead] ?? 0.0;
//   for (final g in kMorphs[lead]!) v += g.v(normT);
//   return v;
// }
//
// // ─── VITALS MODEL ────────────────────────────────────────────────────────────
// class VitalsModel extends ChangeNotifier {
//   final _rng = Random();
//   int hr = 72, spo2 = 98, rr = 16, etco2 = 35;
//   double temp = 37.1;
//   String nibp = '124/82';
//   Timer? _timer;
//
//   VitalsModel() {
//     _timer = Timer.periodic(const Duration(seconds: 4), (_) => _tick());
//   }
//
//   double _j(double v, double mn, double mx, double d) =>
//       (v + (_rng.nextDouble() - 0.5) * d).clamp(mn, mx);
//
//   void _tick() {
//     hr    = _j(hr.toDouble(),   55, 95,  2).round();
//     spo2  = _j(spo2.toDouble(), 95, 100, 0.5).round();
//     rr    = _j(rr.toDouble(),   12, 22,  1).round();
//     temp  = double.parse(_j(temp, 36.5, 37.8, 0.05).toStringAsFixed(1));
//     etco2 = _j(etco2.toDouble(), 30, 45, 1).round();
//     notifyListeners();
//   }
//
//   @override
//   void dispose() { _timer?.cancel(); super.dispose(); }
// }
//
// // ─── ECG SIGNAL STATE ────────────────────────────────────────────────────────
// // CPU optimisations vs previous version:
// //  • Sample rate 200 Hz (was 500) — imperceptible on screen
// //  • Float64List ring buffers — no object allocation per sample
// //  • advance() returns # of samples written; painter only called when > 0
// //  • All 12 leads share one beatPhase — computed once per sample, not 12×
// //  • No sqrt() / division inside inner loop
// class ECGSignalState {
//   static const int    sampleRate     = 200;
//   static const double displaySeconds = 5.0;
//   static const int    bufSize        = sampleRate * 5; // 1000 samples
//
//   final Map<String, Float64List> buf = {
//     for (final l in kLeads) l: Float64List(bufSize)
//   };
//
//   int    _writeIdx  = 0;
//   double _beatPhase = 0.0; // seconds within current beat
//   final  _rng       = Random();
//
//   int get writeIdx => _writeIdx;
//
//   int advance(double dt, int hr) {
//     if (dt <= 0.0 || dt > 0.2) return 0;
//
//     final rrSec      = 60.0 / hr.clamp(30, 220);
//     final rrInv      = 1.0  / rrSec;              // precompute reciprocal
//     final nSamples   = (dt * sampleRate).round().clamp(1, 40);
//     final dtPerSamp  = dt / nSamples;
//
//     for (var s = 0; s < nSamples; s++) {
//       _beatPhase += dtPerSamp;
//       if (_beatPhase >= rrSec) _beatPhase -= rrSec;
//
//       final normT = _beatPhase * rrInv;            // [0,1), no division in loop
//       final noise = (_rng.nextDouble() - 0.5) * 0.010;
//
//       for (final l in kLeads) {
//         buf[l]![_writeIdx] = _mv(l, normT) + noise;
//       }
//       _writeIdx = (_writeIdx + 1) % bufSize;
//     }
//     return nSamples;
//   }
// }
//
// // ─── ECG PAINTER ─────────────────────────────────────────────────────────────
// const int    _COLS       = 3;
// const int    _ROWS       = 4;
// const double _MV_TO_FRAC = 0.30;  // 1 mV → 30 % of cell height
// const double _BASELINE   = 0.50;  // vertical centre
//
// class ECGPainter extends CustomPainter {
//   final ECGSignalState state;
//   ECGPainter(this.state);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final cw = size.width  / _COLS;
//     final ch = size.height / _ROWS;
//
//     canvas.drawRect(Offset.zero & size, Paint()..color = ECGColors.bg);
//     _grid(canvas, size, cw, ch);
//
//     final wi  = state.writeIdx;
//     final buf = ECGSignalState.bufSize;
//
//     for (var i = 0; i < 12; i++) {
//       _lead(canvas, kLeads[i], (i % _COLS) * cw, (i ~/ _COLS) * ch,
//           cw, ch, wi, buf);
//     }
//   }
//
//   void _grid(Canvas canvas, Size size, double cw, double ch) {
//     final minP = Paint()..color = ECGColors.gridMinor..strokeWidth = 0.4;
//     final majP = Paint()..color = ECGColors.gridMajor..strokeWidth = 0.7;
//     // 1 mm at 25 mm/s over displaySeconds
//     final mmPx  = cw / (ECGSignalState.displaySeconds * 25.0);
//     final small = mmPx;
//     final large = mmPx * 5.0;
//
//     for (double x = 0; x <= size.width; x += small)
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), minP);
//     for (double y = 0; y <= size.height; y += small)
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), minP);
//     for (double x = 0; x <= size.width; x += large)
//       canvas.drawLine(Offset(x, 0), Offset(x, size.height), majP);
//     for (double y = 0; y <= size.height; y += large)
//       canvas.drawLine(Offset(0, y), Offset(size.width, y), majP);
//
//     final bP = Paint()..color = const Color(0xBB1E3C5A)..strokeWidth = 1.0;
//     for (var c = 0; c <= _COLS; c++)
//       canvas.drawLine(Offset(c*cw,0), Offset(c*cw,size.height), bP);
//     for (var r = 0; r <= _ROWS; r++)
//       canvas.drawLine(Offset(0,r*ch), Offset(size.width,r*ch), bP);
//   }
//
//   void _lead(Canvas canvas, String lead,
//       double ox, double oy, double cw, double ch,
//       int writeIdx, int bufSize) {
//     final data  = state.buf[lead]!;
//     final color = leadColor(lead);
//
//     // Sweep cursor
//     final sweepFrac = writeIdx / bufSize;
//     final sweepX    = ox + sweepFrac * cw;
//     const eraseW    = 22.0;
//
//     // Erase band
//     canvas.drawRect(Rect.fromLTWH(sweepX, oy, eraseW, ch),
//         Paint()..color = ECGColors.bg);
//
//     // Cursor line
//     canvas.drawLine(
//       Offset(sweepX + eraseW * 0.5, oy),
//       Offset(sweepX + eraseW * 0.5, oy + ch),
//       Paint()..color = ECGColors.sweepCursor..strokeWidth = 1.0,
//     );
//
//     // Waveform — iterate in display order (oldest→newest = left→right)
//     final paint = Paint()
//       ..color       = color
//       ..strokeWidth = 1.6
//       ..style       = PaintingStyle.stroke
//       ..strokeCap   = StrokeCap.round
//       ..strokeJoin  = StrokeJoin.round;
//
//     final path        = Path();
//     bool  needsMove   = true;
//     final eraseLeft   = sweepX - ox;          // relative to cell
//     final eraseRight  = eraseLeft + eraseW;
//
//     for (var di = 0; di < bufSize; di++) {
//       final relX = (di / bufSize) * cw;
//       // skip erase band — break path continuity
//       if (relX >= eraseLeft && relX < eraseRight) {
//         needsMove = true;
//         continue;
//       }
//       final mv      = data[(writeIdx + di) % bufSize];
//       final screenX = ox + relX;
//       final screenY = (oy + (_BASELINE - mv * _MV_TO_FRAC) * ch)
//           .clamp(oy + 1.0, oy + ch - 1.0);
//       if (needsMove) { path.moveTo(screenX, screenY); needsMove = false; }
//       else           { path.lineTo(screenX, screenY); }
//     }
//     canvas.drawPath(path, paint);
//
//     // Lead label
//     final tp = TextPainter(
//       text: TextSpan(text: lead,
//           style: TextStyle(color: color, fontSize: 11,
//               fontWeight: FontWeight.bold, letterSpacing: 0.8)),
//       textDirection: TextDirection.ltr,
//     )..layout();
//     tp.paint(canvas, Offset(ox + 6, oy + 5));
//
//     // 1 mV calibration bar
//     final base = oy + _BASELINE * ch;
//     canvas.drawLine(Offset(ox + 2, base),
//         Offset(ox + 2, base - _MV_TO_FRAC * ch),
//         Paint()..color = color.withOpacity(0.22)..strokeWidth = 1.5);
//   }
//
//   @override
//   bool shouldRepaint(covariant ECGPainter _) => true;
// }
//
// // ─── APP ─────────────────────────────────────────────────────────────────────
// class ECGMonitorApp extends StatelessWidget {
//   const ECGMonitorApp({super.key});
//   @override
//   Widget build(BuildContext context) => MaterialApp(
//     title: '12-Lead ECG Monitor',
//     debugShowCheckedModeBanner: false,
//     theme: ThemeData.dark().copyWith(
//       scaffoldBackgroundColor: ECGColors.bg,
//       colorScheme: const ColorScheme.dark(
//           primary: ECGColors.accentBlue, surface: ECGColors.surface),
//     ),
//     home: const _Screen(),
//   );
// }
//
// // ─── SCREEN ──────────────────────────────────────────────────────────────────
// // Root never calls setState.
// // Only _ECGCanvas (isolated by RepaintBoundary) repaints every frame.
// // VitalsStrip rebuilds only when VitalsModel fires (~every 4 s).
// class _Screen extends StatefulWidget {
//   const _Screen();
//   @override State<_Screen> createState() => _ScreenState();
// }
//
// class _ScreenState extends State<_Screen> {
//   final _vitals = VitalsModel();
//   final _signal = ECGSignalState();
//
//   @override
//   void dispose() { _vitals.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: ECGColors.bg,
//     body: Column(children: [
//       _TopBar(vitals: _vitals),
//       ListenableBuilder(
//         listenable: _vitals,
//         builder: (_, __) => _VitalsStrip(vitals: _vitals),
//       ),
//       Expanded(child: RepaintBoundary(
//         child: _ECGCanvas(signal: _signal, vitals: _vitals),
//       )),
//       const _BottomBar(),
//     ]),
//   );
// }
//
// // Isolated canvas — the ONLY widget that repaints every frame.
// class _ECGCanvas extends StatefulWidget {
//   final ECGSignalState signal;
//   final VitalsModel    vitals;
//   const _ECGCanvas({required this.signal, required this.vitals});
//   @override State<_ECGCanvas> createState() => _ECGCanvasState();
// }
//
// class _ECGCanvasState extends State<_ECGCanvas>
//     with SingleTickerProviderStateMixin {
//   late final Ticker _ticker;
//   Duration _last = Duration.zero;
//
//   @override
//   void initState() {
//     super.initState();
//     _ticker = createTicker(_tick)..start();
//   }
//
//   void _tick(Duration elapsed) {
//     final dt = (elapsed - _last).inMicroseconds / 1e6;
//     _last = elapsed;
//     final wrote = widget.signal.advance(dt, widget.vitals.hr);
//     if (wrote > 0 && mounted) setState(() {});
//   }
//
//   @override
//   void dispose() { _ticker.dispose(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext context) =>
//       CustomPaint(painter: ECGPainter(widget.signal), size: Size.infinite);
// }
//
// // ─── TOP BAR ─────────────────────────────────────────────────────────────────
// class _TopBar extends StatefulWidget {
//   final VitalsModel vitals;
//   const _TopBar({required this.vitals});
//   @override State<_TopBar> createState() => _TopBarState();
// }
//
// class _TopBarState extends State<_TopBar> {
//   late final Timer _timer;
//   String _time = '', _date = '';
//   bool   _muted = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _update();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       _update(); if (mounted) setState(() {});
//     });
//   }
//
//   void _update() {
//     final n = DateTime.now();
//     _time = '${_p(n.hour)}:${_p(n.minute)}:${_p(n.second)}';
//     _date = '${n.day}/${n.month}/${n.year}';
//   }
//
//   String _p(int v) => v.toString().padLeft(2, '0');
//
//   @override
//   void dispose() { _timer.cancel(); super.dispose(); }
//
//   @override
//   Widget build(BuildContext ctx) => Container(
//     height: 38,
//     color: ECGColors.surface,
//     padding: const EdgeInsets.symmetric(horizontal: 12),
//     child: Row(children: [
//       _LiveDot(),
//       const SizedBox(width: 6),
//       const Text('LIVE MONITOR', style: TextStyle(
//           color: ECGColors.accentBlue, fontSize: 10,
//           fontWeight: FontWeight.bold, letterSpacing: 1.5)),
//       const SizedBox(width: 16),
//       const Text(
//         'Patient: ICU-04-B  |  Age: 58 · M · 74 kg  |  Dr. Arora · Cardiology',
//         style: TextStyle(color: ECGColors.textMuted, fontSize: 11),
//       ),
//       const Spacer(),
//       _btn('ALARMS', _muted ? ECGColors.textMuted : ECGColors.nibpOrange,
//               () => setState(() => _muted = !_muted)),
//       const SizedBox(width: 6),
//       _btn('TRENDS', ECGColors.accentBlue, () {}),
//       const SizedBox(width: 6),
//       _btn('FREEZE', ECGColors.accentBlue, () {}),
//       const SizedBox(width: 16),
//       Column(crossAxisAlignment: CrossAxisAlignment.end,
//           mainAxisAlignment: MainAxisAlignment.center, children: [
//             Text(_time, style: const TextStyle(fontFamily: 'monospace',
//                 color: ECGColors.textPrimary, fontSize: 14)),
//             Text(_date, style: const TextStyle(
//                 color: ECGColors.textMuted, fontSize: 10)),
//           ]),
//     ]),
//   );
//
//   Widget _btn(String label, Color c, VoidCallback fn) => GestureDetector(
//     onTap: fn,
//     child: Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//       decoration: BoxDecoration(
//         color: ECGColors.border,
//         border: Border.all(color: c.withOpacity(0.4)),
//         borderRadius: BorderRadius.circular(3),
//       ),
//       child: Text(label,
//           style: TextStyle(color: c, fontSize: 10, letterSpacing: 1)),
//     ),
//   );
// }
//
// // Pulsing live indicator — self-contained, no external setState
// class _LiveDot extends StatefulWidget {
//   @override State<_LiveDot> createState() => _LiveDotState();
// }
// class _LiveDotState extends State<_LiveDot>
//     with SingleTickerProviderStateMixin {
//   late final AnimationController _ac;
//   @override
//   void initState() {
//     super.initState();
//     _ac = AnimationController(
//         vsync: this, duration: const Duration(milliseconds: 800))
//       ..repeat(reverse: true);
//   }
//   @override void dispose() { _ac.dispose(); super.dispose(); }
//   @override
//   Widget build(BuildContext context) => FadeTransition(
//     opacity: _ac,
//     child: Container(width: 8, height: 8,
//         decoration: const BoxDecoration(
//             color: ECGColors.hrGreen, shape: BoxShape.circle)),
//   );
// }
//
// // ─── VITALS STRIP ─────────────────────────────────────────────────────────────
// class _VitalsStrip extends StatelessWidget {
//   final VitalsModel vitals;
//   const _VitalsStrip({required this.vitals});
//   @override
//   Widget build(BuildContext context) => Container(
//     height: 66,
//     color: ECGColors.surface,
//     child: Row(children: [
//       _VB('♥ HR',  '${vitals.hr}',    'bpm',    ECGColors.hrGreen),
//       _VB('SpO₂',  '${vitals.spo2}',  '%',      ECGColors.spo2Blue),
//       _VB('NIBP',  vitals.nibp,        'mmHg',   ECGColors.nibpOrange),
//       _VB('RR',    '${vitals.rr}',     'br/min', ECGColors.rrPurple),
//       _VB('TEMP',  '${vitals.temp}',   '°C',     ECGColors.tempYellow),
//       _VB('EtCO₂', '${vitals.etco2}',  'mmHg',   ECGColors.etco2Cyan),
//       Expanded(child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 14),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             Text('RHYTHM', style: TextStyle(
//                 color: ECGColors.textMuted, fontSize: 9, letterSpacing: 1.5)),
//             SizedBox(height: 2),
//             Text('Normal Sinus Rhythm', style: TextStyle(
//                 color: ECGColors.hrGreen, fontSize: 13,
//                 fontWeight: FontWeight.w600)),
//             SizedBox(height: 2),
//             Text('QTc: 420 ms  ·  PR: 162 ms  ·  QRS: 88 ms',
//                 style: TextStyle(color: ECGColors.textMuted, fontSize: 10)),
//           ],
//         ),
//       )),
//     ]),
//   );
// }
//
// class _VB extends StatelessWidget
// {
//   final String label, value, unit;
//   final Color  color;
//   const _VB(this.label, this.value, this.unit, this.color);
//   @override
//   Widget build(BuildContext context) => Container(
//     width: 110,
//     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//     decoration: const BoxDecoration(
//         border: Border(right: BorderSide(color: ECGColors.border))),
//     child: Column(crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center, children: [
//           Text(label, style: TextStyle(color: color, fontSize: 9,
//               fontWeight: FontWeight.bold, letterSpacing: 1.5)),
//           const SizedBox(height: 1),
//           Text(value, style: TextStyle(color: color, fontSize: 22,
//               fontFamily: 'monospace', height: 1.1)),
//           Text(unit, style: const TextStyle(
//               color: ECGColors.textMuted, fontSize: 9)),
//         ]),
//   );
// }
//
// // ─── BOTTOM BAR ──────────────────────────────────────────────────────────────
// class _BottomBar extends StatefulWidget {
//   const _BottomBar();
//   @override State<_BottomBar> createState() => _BottomBarState();
// }
// class _BottomBarState extends State<_BottomBar> {
//   double _speed = 25;
//   @override
//   Widget build(BuildContext context) => Container(
//     height: 28,
//     color: ECGColors.surface,
//     padding: const EdgeInsets.symmetric(horizontal: 12),
//     child: Row(children: [
//       _bb('GAIN',   '10 mm/mV'),
//       const SizedBox(width: 14),
//       _bb('FILTER', '0.5–40 Hz'),
//       const SizedBox(width: 14),
//       ...[12.5, 25.0, 50.0].map((s) => Padding(
//         padding: const EdgeInsets.only(right: 4),
//         child: GestureDetector(
//           onTap: () => setState(() => _speed = s),
//           child: Container(
//             padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
//             decoration: BoxDecoration(
//               color: _speed == s
//                   ? const Color(0xFF1D3A5C) : ECGColors.border,
//               border: Border.all(color: _speed == s
//                   ? ECGColors.accentBlue : ECGColors.border),
//               borderRadius: BorderRadius.circular(2),
//             ),
//             child: Text('${s % 1 == 0 ? s.toInt() : s}',
//                 style: TextStyle(
//                     color: _speed == s
//                         ? ECGColors.accentBlue : ECGColors.textMuted,
//                     fontSize: 9, letterSpacing: 0.5)),
//           ),
//         ),
//       )),
//       _bb('', 'mm/s'),
//       const Spacer(),
//       _bb('LEAD',           'Standard 12'),
//       const SizedBox(width: 14),
//       _bb('IEC 60601-2-51', 'Compliant'),
//     ]),
//   );
//
//   Widget _bb(String k, String v) => RichText(text: TextSpan(children: [
//     if (k.isNotEmpty) TextSpan(text: '$k ',
//         style: const TextStyle(color: ECGColors.textMuted, fontSize: 10)),
//     TextSpan(text: v,
//         style: const TextStyle(color: ECGColors.accentBlue, fontSize: 10)),
//   ]));
