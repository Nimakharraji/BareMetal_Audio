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
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          title: const Text("Baremetal Engine",
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1F1F1F),
          bottom: const TabBar(
            indicatorColor: Colors.cyanAccent,
            labelColor: Colors.cyanAccent,
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.mic), text: "Live Capture"),
              Tab(icon: Icon(Icons.movie), text: "Sync Player"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CaptureTab(),
            PlaybackTab(),
          ],
        ),
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
      BaremetalAudio.stop();
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      if (await Permission.microphone.request().isGranted) {
        BaremetalAudio.init(mode: EngineMode.capture);
        _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
          if (!mounted) return;
          final ptr = BaremetalAudio.getFftArray();

          setState(() {
            _rms = BaremetalAudio.getRmsLevel();
            // Take first 128 bins for cleaner UI
            _fftData = ptr.asTypedList(512).sublist(0, 128);
          });
        });
        setState(() => _isRunning = true);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    // Note: We don't stop engine here to allow tab switching,
    // but in a real app you might want to.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              border: Border.all(color: Colors.white12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter:
                    ModernSpectrumPainter(_fftData, color: Colors.cyanAccent),
                size: Size.infinite,
              ),
            ),
          ),
        ),

        // Meters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Row(
            children: [
              const Text("RMS Level: ",
                  style: TextStyle(color: Colors.white54)),
              Expanded(
                child: LinearProgressIndicator(
                  value: _rms * 1.5, // Boost for visibility
                  backgroundColor: Colors.white10,
                  color: _rms > 0.8 ? Colors.redAccent : Colors.greenAccent,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),
        FloatingActionButton.extended(
          onPressed: _toggle,
          backgroundColor: _isRunning ? Colors.redAccent : Colors.cyan,
          icon: Icon(_isRunning ? Icons.stop : Icons.mic),
          label: Text(_isRunning ? "STOP ENGINE" : "START MIC"),
        ),
        const SizedBox(height: 30),
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
  String _subtitle = "";
  double _time = 0.0;
  Timer? _timer;

  // Embedded SRT for demo simplicity
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
      BaremetalAudio.stop();
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    // Copy asset to temp (Standard way for examples to access files)
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/test_audio.mp3');
    try {
      final data = await rootBundle.load('assets/test_audio.mp3');
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    } catch (e) {
      _showError("Asset 'test_audio.mp3' not found in example/assets/");
      return;
    }

    BaremetalAudio.init(mode: EngineMode.playback, filePath: file.path);
    BaremetalAudio.loadSubtitles(_demoSrt);

    _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        _time = BaremetalAudio.getMediaTime();
        _subtitle = BaremetalAudio.getCurrentSubtitle();
      });
    });

    setState(() => _isRunning = true);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _time.toStringAsFixed(3),
            style: const TextStyle(
                fontSize: 60,
                fontFamily: "Monospace",
                color: Colors.white10,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 10)
                ]),
            child: Text(
              _subtitle.isEmpty ? "..." : _subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 60),
          ElevatedButton.icon(
            onPressed: _play,
            icon: Icon(_isRunning ? Icons.stop : Icons.play_arrow),
            label: Text(_isRunning ? "STOP PLAYBACK" : "PLAY DEMO ASSET"),
            style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.white,
                foregroundColor: Colors.black),
          ),
        ],
      ),
    );
  }
}

// --- Visualizer Painter ---
class ModernSpectrumPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  ModernSpectrumPainter(this.data, {required this.color});

  @override
  void paint(Canvas canvas, size) {
    if (data.isEmpty) return;

    final paint = Paint()
      // ignore: deprecated_member_use
      ..color = color.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final barWidth = size.width / data.length;
    final path = Path();

    path.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      // Logarithmic scaling roughly approximates human hearing
      final magnitude = data[i] * 100.0;
      final barHeight = (magnitude * size.height).clamp(0.0, size.height);
      final x = i * barWidth;
      final y = size.height - barHeight;

      // Draw smooth curve or blocks
      canvas.drawRect(
          RRect.fromRectAndRadius(
                  Rect.fromLTWH(x, y, barWidth * 0.8, barHeight),
                  const Radius.circular(2))
              .outerRect,
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant ModernSpectrumPainter oldDelegate) => true;
}
