import 'dart:async';
import 'dart:ffi' as ffi;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'ffi_bridge.dart';

// --- State Definition ---

/// Represents the current state of the DSP Engine across the UI.
class DspState {
  /// Whether the native engine is currently actively processing audio.
  final bool isRunning;
  /// The current volume magnitude (Root Mean Square).
  final double rmsLevel;
  /// Array containing the current magnitude of 512 frequency bins.
  final List<double> fftData;
  /// High-precision timeline clock driven by audio sample rate.
  final double mediaTime;
  /// The text string of the subtitle meant to be displayed at this exact frame.
  final String subtitleText;
  /// The current global audio multiplier.
  final double masterGain;

  /// Creates a complete snapshot of the DSP parameters.
  const DspState({
    required this.isRunning,
    required this.rmsLevel,
    required this.fftData,
    required this.mediaTime,
    required this.subtitleText,
    required this.masterGain,
  });

  /// Factory constructor providing the default baseline state.
  factory DspState.initial() {
    return DspState(
      isRunning: false,
      rmsLevel: 0.0,
      fftData: List.filled(512, 0.0),
      mediaTime: 0.0,
      subtitleText: "",
      masterGain: 1.0,
    );
  }

  /// Creates a copy of the state with specific overridden parameters.
  DspState copyWith({
    bool? isRunning,
    double? rmsLevel,
    List<double>? fftData,
    double? mediaTime,
    String? subtitleText,
    double? masterGain,
  }) {
    return DspState(
      isRunning: isRunning ?? this.isRunning,
      rmsLevel: rmsLevel ?? this.rmsLevel,
      fftData: fftData ?? this.fftData,
      mediaTime: mediaTime ?? this.mediaTime,
      subtitleText: subtitleText ?? this.subtitleText,
      masterGain: masterGain ?? this.masterGain,
    );
  }
}

// --- Events ---

/// Base abstract event class for the DSP BLoC architecture.
abstract class DspEvent {}

/// Toggles the engine processing state (Starts/Stops the native C++ thread).
class ToggleEngine extends DspEvent {}

/// Updates the master gain configuration inside the native engine.
class SetGain extends DspEvent {
  /// Gain multiplier to apply.
  final double gain;
  
  /// Dispatches a new gain calculation to the engine.
  SetGain(this.gain);
}

// Internal telemetry trigger
class _UpdateTelemetry extends DspEvent {}

// --- BLoC Implementation ---

/// Business Logic Component bridging the native C++ FFI state to Flutter UI.
/// 
/// Runs a high-performance 60FPS loop querying telemetry directly from memory.
class DspBloc extends Bloc<DspEvent, DspState> {
  final DspBridge _bridge;
  Timer? _telemetryTimer;

  /// Initializes the BLoC and binds the event handlers.
  DspBloc(this._bridge) : super(DspState.initial()) {
    on<ToggleEngine>(_onToggleEngine);
    on<_UpdateTelemetry>(_onUpdateTelemetry);
    on<SetGain>(_onSetGain);
  }

  void _onToggleEngine(ToggleEngine event, Emitter<DspState> emit) {
    if (state.isRunning) {
      // Stop logic
      _bridge.stopEngine();
      _telemetryTimer?.cancel();
      emit(DspState.initial());
    } else {
      // --- STARTUP LOGIC: MODE 1 (PLAYBACK) ---

      // Windows Example: "C:\\Music\\track.mp3"
      const String testFilePath =
          "C:\\Users\\RSKALA\\Downloads\\example222.mp3";

      // Initialize Engine in Mode 1 (Playback)
      // This will decode the file, play it to speakers, and analyze it.
      _bridge.initEngine(mode: 1, filePath: testFilePath);

      // --- INJECT SYNC TEST SUBTITLES ---
      // These timestamps will match the audio file's playback time
      const mockSrt = """
1
00:00:01,000 --> 00:00:04,000
MODE 1: PLAYBACK ACTIVE
DECODING AUDIO FILE...

2
00:00:04,500 --> 00:00:08,000
SYNCING SUBTITLES TO MUSIC
SAMPLE-ACCURATE TIMING

3
00:00:08,500 --> 00:00:12,000
BARE-METAL DSP ENGINE
READY FOR IOS DEPLOYMENT
""";
      _bridge.loadSubtitles(mockSrt);
      // -----------------------------

      // Start Telemetry Loop (60 FPS / ~16ms)
      _telemetryTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        add(_UpdateTelemetry());
      });

      emit(state.copyWith(isRunning: true));
    }
  }

  void _onSetGain(SetGain event, Emitter<DspState> emit) {
    _bridge.setGain(event.gain);
    emit(state.copyWith(masterGain: event.gain));
  }

  void _onUpdateTelemetry(_UpdateTelemetry event, Emitter<DspState> emit) {
    if (!state.isRunning) return;

    // 1. Fetch RMS Level
    final double level = _bridge.getRmsLevel();

    // 2. Fetch Media Time (Driven by Audio Samples)
    final double time = _bridge.getMediaTime();

    // 3. Fetch FFT Data (Direct Pointer Access)
    final ffi.Pointer<ffi.Float> ptr = _bridge.getFftArray();
    List<double> currentFft = state.fftData;

    if (ptr != ffi.nullptr) {
      // Fast copy from C heap to Dart heap for rendering
      currentFft = List<double>.from(ptr.asTypedList(512));
    }

    // 4. Fetch Subtitles (Synced to Media Time)
    final int subIdx = _bridge.getSubtitleIndex();
    String currentSub = "";
    if (subIdx != -1) {
      currentSub = _bridge.getSubtitleText(subIdx);
    }

    emit(state.copyWith(
      rmsLevel: level,
      fftData: currentFft,
      mediaTime: time,
      subtitleText: currentSub,
    ));
  }

  @override
  Future<void> close() {
    _telemetryTimer?.cancel();
    _bridge.stopEngine();
    return super.close();
  }
}