// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:baremetal_audio/baremetal_audio.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Baremetal Audio Demo',
    themeMode: ThemeMode.dark,
    home: BaremetalHome(),
  ));
}

class BaremetalHome extends StatelessWidget {
  const BaremetalHome({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 1.5,
              colors: [Color(0xFF1A1A2E), Color(0xFF000000)],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                const Expanded(
                  child: TabBarView(
                    children: [
                      CaptureTab(),
                      PlaybackTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: const Border(bottom: BorderSide(color: Colors.white10)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BAREMETAL",
                      style: TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                          fontSize: 18)),
                  Text("AUDIO ENGINE",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          letterSpacing: 4)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.cyanAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent.withOpacity(0.3))),
                child: const Text("v1.0.0",
                    style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 15),
          Container(
            height: 45,
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(25.0),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(25.0),
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
                ),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white54,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "LIVE CAPTURE"),
                Tab(text: "SYNC PLAYER"),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- TAB 1: Microphone Visualizer ---
class CaptureTab extends StatefulWidget {
  const CaptureTab({super.key});
  @override
  State<CaptureTab> createState() => _CaptureTabState();
}

class _CaptureTabState extends State<CaptureTab> {
  bool _isRunning = false;
  List<double> _fftData = [];
  double _rms = 0.0;
  Timer? _timer;

  void _toggle() async {
    if (_isRunning) {
      // 1. Kill Timer FIRST to stop FFI calls
      _timer?.cancel();
      _timer = null;

      // 2. Then stop engine
      BaremetalAudio.stop();
      
      setState(() => _isRunning = false);
    } else {
      if (await Permission.microphone.request().isGranted) {
        BaremetalAudio.init(mode: EngineMode.capture);
        _startTicker();
        setState(() => _isRunning = true);
      }
    }
  }

  void _startTicker() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      final ptr = BaremetalAudio.getFftArray();
      if (ptr == ffi.nullptr) return;

      setState(() {
        _rms = BaremetalAudio.getRmsLevel();
        _fftData = ptr.asTypedList(512).sublist(0, 128);
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: _isRunning
                      ? Colors.cyanAccent.withOpacity(0.1)
                      : Colors.transparent,
                  blurRadius: 20,
                  spreadRadius: 2,
                )
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  CustomPaint(painter: GridPainter(), size: Size.infinite),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: CustomPaint(
                      painter: ProGradientSpectrumPainter(_fftData),
                      size: Size.infinite,
                    ),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isRunning ? Colors.redAccent : Colors.grey,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _isRunning ? "REC ●" : "IDLE",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    const Icon(Icons.volume_up, color: Colors.white54, size: 20),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          minHeight: 8,
                          value: _rms * 1.5,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _rms > 0.8 ? Colors.redAccent : Colors.greenAccent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _toggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isRunning
                          ? Colors.redAccent.withOpacity(0.2)
                          : Colors.cyanAccent.withOpacity(0.2),
                      foregroundColor: _isRunning ? Colors.redAccent : Colors.cyanAccent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: _isRunning ? Colors.redAccent : Colors.cyanAccent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      _isRunning ? "STOP ENGINE" : "START CAPTURE",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// --- TAB 2: File Playback & Sync ---
class PlaybackTab extends StatefulWidget {
  const PlaybackTab({super.key});
  @override
  State<PlaybackTab> createState() => _PlaybackTabState();
}

class _PlaybackTabState extends State<PlaybackTab> {
  bool _isRunning = false;
  String _subtitle = "Ready to Play";
  double _time = 0.0;
  List<double> _fftData = [];
  Timer? _timer;

  final String _demoSrt = """
1
00:00:00,500 --> 00:00:02,500
[Baremetal Audio Engine]

2
00:00:02,600 --> 00:00:05,000
Testing Sample-Accurate Sync...

3
00:00:05,100 --> 00:00:08,000
C++ Backend: Miniaudio
Frontend: Dart FFI

4
00:00:08,100 --> 00:00:11,000
No MethodChannels.
Zero Latency.
""";

  Future<void> _play() async {
    if (_isRunning) {
      // 1. Kill Timer FIRST
      _timer?.cancel();
      _timer = null;

      // 2. Stop Engine
      BaremetalAudio.stop();
      
      setState(() => _isRunning = false);
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/test_audio.mp3');

    // Always clean up old file
    if (await file.exists()) {
      await file.delete();
    }

    try {
      final data = await rootBundle.load('assets/test_audio.mp3');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Asset 'test_audio.mp3' not found!")));
      return;
    }

    if (!await file.exists()) return;

    BaremetalAudio.init(mode: EngineMode.playback, filePath: file.path);
    BaremetalAudio.loadSubtitles(_demoSrt);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      
      final ptr = BaremetalAudio.getFftArray();
      List<double> currentFft = [];
      if (ptr != ffi.nullptr) {
        currentFft = ptr.asTypedList(512).sublist(0, 64);
      }

      setState(() {
        _time = BaremetalAudio.getMediaTime();
        _subtitle = BaremetalAudio.getCurrentSubtitle();
        _fftData = currentFft;
      });
    });

    setState(() => _isRunning = true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: 200,
          child: Opacity(
            opacity: 0.5,
            child: CustomPaint(
              painter: ProGradientSpectrumPainter(_fftData, isMirror: true),
              size: Size.infinite,
            ),
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _time.toStringAsFixed(3),
              style: const TextStyle(
                fontSize: 70,
                fontFamily: "Monospace",
                color: Colors.white12,
                fontWeight: FontWeight.bold,
                letterSpacing: -2,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(30),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                children: [
                   Text(
                    "SUBTITLE TRACK",
                    style: TextStyle(
                      color: Colors.cyanAccent.withOpacity(0.5),
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _subtitle.isEmpty ? "..." : _subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      height: 1.3,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4)
                      ]
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 50),
            IconButton(
              onPressed: _play,
              iconSize: 80,
              icon: Icon(
                _isRunning ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: Colors.white,
              ),
              padding: EdgeInsets.zero,
              tooltip: "Play Demo",
            ),
          ],
        ),
      ],
    );
  }
}

// --- PAINTERS ---
class ProGradientSpectrumPainter extends CustomPainter {
  final List<double> data;
  final bool isMirror;

  ProGradientSpectrumPainter(this.data, {this.isMirror = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final barWidth = size.width / data.length;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < data.length; i++) {
      final magnitude = data[i] * 120.0;
      final barHeight = (magnitude * size.height * 0.8).clamp(2.0, size.height);
      
      final rect = Rect.fromLTWH(
        i * barWidth, 
        size.height - barHeight, 
        barWidth * 0.6,
        barHeight
      );

      paint.shader = const LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.purpleAccent, Colors.cyanAccent],
      ).createShader(rect);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ProGradientSpectrumPainter oldDelegate) => true;
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}