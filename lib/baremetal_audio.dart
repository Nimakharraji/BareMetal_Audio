import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- Type Definitions (C++ Signatures) ---
typedef InitEngineNative = ffi.Void Function(ffi.Int32, ffi.Pointer<Utf8>);
typedef InitEngineDart = void Function(int, ffi.Pointer<Utf8>);

typedef StopEngineNative = ffi.Void Function();
typedef StopEngineDart = void Function();

typedef GetRmsNative = ffi.Float Function();
typedef GetRmsDart = double Function();

typedef GetFftNative = ffi.Pointer<ffi.Float> Function();
typedef GetFftDart = ffi.Pointer<ffi.Float> Function();

typedef SetGainNative = ffi.Void Function(ffi.Float);
typedef SetGainDart = void Function(double);

typedef LoadSubsNative = ffi.Void Function(ffi.Pointer<Utf8>);
typedef LoadSubsDart = void Function(ffi.Pointer<Utf8>);

typedef GetSubIdxNative = ffi.Int32 Function();
typedef GetSubIdxDart = int Function();

typedef GetSubTextNative = ffi.Pointer<Utf8> Function(ffi.Int32);
typedef GetSubTextDart = ffi.Pointer<Utf8> Function(int);

typedef GetTimeNative = ffi.Double Function();
typedef GetTimeDart = double Function();

enum EngineMode { capture, playback }

class BaremetalAudio {
  static final BaremetalAudio _instance = BaremetalAudio._internal();
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
      // Android links against the shared object defined in CMakeLists.txt
      try {
        _lib = ffi.DynamicLibrary.open("libbaremetal_audio.so");
      } catch (e) {
        print("ERROR LOADING SO: $e");
        rethrow;
      }
    } else if (Platform.isIOS) {
      // iOS statically links via CocoaPods/Xcode
      _lib = ffi.DynamicLibrary.process(); 
    } else if (Platform.isWindows) {
       _lib = ffi.DynamicLibrary.open("baremetal_audio.dll");
    } else {
       throw UnsupportedError("Platform not supported");
    }

    // 2. Lookup Symbols (Link Dart functions to C++ functions)
    try {
      _initEngine = _lib.lookupFunction<InitEngineNative, InitEngineDart>("init_engine");
      _stopEngine = _lib.lookupFunction<StopEngineNative, StopEngineDart>("stop_engine");
      _getRms = _lib.lookupFunction<GetRmsNative, GetRmsDart>("get_rms_level");
      _getFft = _lib.lookupFunction<GetFftNative, GetFftDart>("get_fft_array");
      _setGain = _lib.lookupFunction<SetGainNative, SetGainDart>("set_gain");
      _loadSubs = _lib.lookupFunction<LoadSubsNative, LoadSubsDart>("load_subtitles");
      _getSubIdx = _lib.lookupFunction<GetSubIdxNative, GetSubIdxDart>("get_subtitle_index");
      _getSubText = _lib.lookupFunction<GetSubTextNative, GetSubTextDart>("get_subtitle_text");
      _getTime = _lib.lookupFunction<GetTimeNative, GetTimeDart>("get_media_time");
    } catch (e) {
      print("ERROR LINKING SYMBOLS: $e");
      rethrow;
    }
  }

  // --- Public API ---

  /// Initializes the audio engine.
  /// [mode] defines if we capture Mic or play a File.
  static void init({required EngineMode mode, String? filePath}) {
    final pathPtr = (filePath ?? "").toNativeUtf8();
    _instance._initEngine(mode == EngineMode.playback ? 1 : 0, pathPtr);
    malloc.free(pathPtr);
  }

  static void stop() => _instance._stopEngine();

  /// Returns the current RMS (Volume) level (0.0 - 1.0)
  static double getRmsLevel() => _instance._getRms();

  /// Returns a pointer to the raw FFT array in C memory.
  /// FAST: No copying involved.
  static ffi.Pointer<ffi.Float> getFftArray() => _instance._getFft();

  static void setGain(double gain) => _instance._setGain(gain);

  static void loadSubtitles(String srtContent) {
    final ptr = srtContent.toNativeUtf8();
    _instance._loadSubs(ptr);
    malloc.free(ptr);
  }

  /// Sample-accurate media time from the audio thread.
  static double getMediaTime() => _instance._getTime();

  static String getCurrentSubtitle() {
    int idx = _instance._getSubIdx();
    if (idx == -1) return "";
    final ptr = _instance._getSubText(idx);
    return ptr.toDartString();
  }
}