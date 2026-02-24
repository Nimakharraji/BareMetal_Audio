import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- Type Definitions (C++ Signatures) ---

/// Native C signature for initializing the engine.
typedef InitEngineNative = ffi.Void Function(ffi.Int32, ffi.Pointer<Utf8>);
/// Dart signature for initializing the engine.
typedef InitEngineDart = void Function(int, ffi.Pointer<Utf8>);

/// Native C signature for stopping the engine.
typedef StopEngineNative = ffi.Void Function();
/// Dart signature for stopping the engine.
typedef StopEngineDart = void Function();

/// Native C signature for retrieving the RMS level.
typedef GetRmsNative = ffi.Float Function();
/// Dart signature for retrieving the RMS level.
typedef GetRmsDart = double Function();

/// Native C signature for retrieving the FFT array pointer.
typedef GetFftNative = ffi.Pointer<ffi.Float> Function();
/// Dart signature for retrieving the FFT array pointer.
typedef GetFftDart = ffi.Pointer<ffi.Float> Function();

/// Native C signature for setting the master gain.
typedef SetGainNative = ffi.Void Function(ffi.Float);
/// Dart signature for setting the master gain.
typedef SetGainDart = void Function(double);

/// Native C signature for loading subtitles into memory.
typedef LoadSubsNative = ffi.Void Function(ffi.Pointer<Utf8>);
/// Dart signature for loading subtitles into memory.
typedef LoadSubsDart = void Function(ffi.Pointer<Utf8>);

/// Native C signature for getting the active subtitle index.
typedef GetSubIdxNative = ffi.Int32 Function();
/// Dart signature for getting the active subtitle index.
typedef GetSubIdxDart = int Function();

/// Native C signature for getting the subtitle text by index.
typedef GetSubTextNative = ffi.Pointer<Utf8> Function(ffi.Int32);
/// Dart signature for getting the subtitle text by index.
typedef GetSubTextDart = ffi.Pointer<Utf8> Function(int);

/// Native C signature for getting the current media time.
typedef GetTimeNative = ffi.Double Function();
/// Dart signature for getting the current media time.
typedef GetTimeDart = double Function();

/// Defines the operational mode of the Baremetal Audio Engine.
enum EngineMode {
  /// Captures audio from the device's microphone for real-time analysis.
  capture,
  /// Decodes and plays a specified audio file from the disk.
  playback
}

/// The core entry point for the Baremetal Audio Engine.
/// 
/// This class handles direct FFI communication with the underlying C++ audio engine.
/// It uses a singleton pattern to ensure only one instance manages the shared memory bridge.
class BaremetalAudio {
  static final BaremetalAudio _instance = BaremetalAudio._internal();
  
  /// Factory constructor to return the singleton instance.
  factory BaremetalAudio() => _instance;

  late ffi.DynamicLibrary _lib;

  // Function Pointers
  late InitEngineDart _initEngine;
  late StopEngineDart _stopEngine;
  late GetRmsDart _getRms;
  late GetFftDart _getFft;
  late SetGainDart _setGain;
  late LoadSubsDart _loadSubs;
  late GetSubIdxDart _getSubIdx;
  late GetSubTextDart _getSubText;
  late GetTimeDart _getTime;

  BaremetalAudio._internal() {
    // 1. Load the Native Library
    if (Platform.isAndroid) {
      try {
        _lib = ffi.DynamicLibrary.open("libbaremetal_audio.so");
      } catch (e) {
        rethrow;
      }
    } else if (Platform.isIOS) {
      _lib = ffi.DynamicLibrary.process();
    } else if (Platform.isWindows) {
      _lib = ffi.DynamicLibrary.open("baremetal_audio.dll");
    } else {
      throw UnsupportedError("Platform not supported");
    }

    // 2. Lookup Symbols (Link Dart functions to C++ functions)
    try {
      _initEngine =
          _lib.lookupFunction<InitEngineNative, InitEngineDart>("init_engine");
      _stopEngine =
          _lib.lookupFunction<StopEngineNative, StopEngineDart>("stop_engine");
      _getRms = _lib.lookupFunction<GetRmsNative, GetRmsDart>("get_rms_level");
      _getFft = _lib.lookupFunction<GetFftNative, GetFftDart>("get_fft_array");
      _setGain = _lib.lookupFunction<SetGainNative, SetGainDart>("set_gain");
      _loadSubs =
          _lib.lookupFunction<LoadSubsNative, LoadSubsDart>("load_subtitles");
      _getSubIdx = _lib
          .lookupFunction<GetSubIdxNative, GetSubIdxDart>("get_subtitle_index");
      _getSubText = _lib.lookupFunction<GetSubTextNative, GetSubTextDart>(
          "get_subtitle_text");
      _getTime =
          _lib.lookupFunction<GetTimeNative, GetTimeDart>("get_media_time");
    } catch (e) {
      rethrow;
    }
  }

  // --- Public API ---

  /// Initializes the audio engine.
  /// 
  /// The [mode] parameter defines whether the engine should run in capture or playback mode.
  /// If playback mode is selected, a valid [filePath] must be provided.
  static void init({required EngineMode mode, String? filePath}) {
    final pathPtr = (filePath ?? "").toNativeUtf8();
    _instance._initEngine(mode == EngineMode.playback ? 1 : 0, pathPtr);
    malloc.free(pathPtr);
  }

  /// Stops the audio engine and halts processing gracefully.
  static void stop() => _instance._stopEngine();

  /// Returns the current RMS (Root Mean Square) volume level.
  /// 
  /// The value is typically normalized between 0.0 and 1.0.
  static double getRmsLevel() => _instance._getRms();

  /// Returns a pointer to the raw Fast Fourier Transform (FFT) array in native C memory.
  /// 
  /// Extremely fast operation as it involves zero memory copying between Dart and C++.
  static ffi.Pointer<ffi.Float> getFftArray() => _instance._getFft();

  /// Sets the master gain (volume) for the audio output.
  /// 
  /// The [gain] value is a multiplier (e.g., 1.0 is default, 0.5 is half volume).
  static void setGain(double gain) => _instance._setGain(gain);

  /// Loads SubRip Text (SRT) formatted content into the C++ engine for synchronization.
  /// 
  /// Pass the raw SRT file content as a string in [srtContent].
  static void loadSubtitles(String srtContent) {
    final ptr = srtContent.toNativeUtf8();
    _instance._loadSubs(ptr);
    malloc.free(ptr);
  }

  /// Retrieves the sample-accurate media time directly from the audio thread.
  /// 
  /// Returns the elapsed time in seconds as a high-precision double.
  static double getMediaTime() => _instance._getTime();

  /// Retrieves the text of the currently active subtitle based on the engine's internal clock.
  /// 
  /// Returns an empty string if no subtitle is currently active.
  static String getCurrentSubtitle() {
    int idx = _instance._getSubIdx();
    if (idx == -1) return "";
    final ptr = _instance._getSubText(idx);
    return ptr.toDartString();
  }
}