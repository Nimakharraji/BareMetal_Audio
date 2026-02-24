import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- C++ Signatures (Updated) ---

/// Defines the native C layout for initializing the engine.
typedef InitEngineNative = ffi.Void Function(
    ffi.Int32 mode, ffi.Pointer<Utf8> path);
/// Defines the Dart layout for initializing the engine.
typedef InitEngineDart = void Function(int mode, ffi.Pointer<Utf8> path);

/// Defines the native C layout for halting the DSP thread.
typedef StopEngineNative = ffi.Void Function();
/// Defines the Dart layout for halting the DSP thread.
typedef StopEngineDart = void Function();

/// Defines the native C layout for RMS volume retrieval.
typedef GetRmsNative = ffi.Float Function();
/// Defines the Dart layout for RMS volume retrieval.
typedef GetRmsDart = double Function();

/// Defines the native C layout for fetching the FFT pointer.
typedef GetFftNative = ffi.Pointer<ffi.Float> Function();
/// Defines the Dart layout for fetching the FFT pointer.
typedef GetFftDart = ffi.Pointer<ffi.Float> Function();

/// Defines the native C layout for adjusting signal gain.
typedef SetGainNative = ffi.Void Function(ffi.Float gain);
/// Defines the Dart layout for adjusting signal gain.
typedef SetGainDart = void Function(double gain);

/// Defines the native C layout for loading raw subtitle data.
typedef LoadSubtitlesNative = ffi.Void Function(ffi.Pointer<Utf8> data);
/// Defines the Dart layout for loading raw subtitle data.
typedef LoadSubtitlesDart = void Function(ffi.Pointer<Utf8> data);

/// Defines the native C layout for querying subtitle index.
typedef GetSubIdxNative = ffi.Int32 Function();
/// Defines the Dart layout for querying subtitle index.
typedef GetSubIdxDart = int Function();

/// Defines the native C layout for reading subtitle strings.
typedef GetSubTextNative = ffi.Pointer<Utf8> Function(ffi.Int32 index);
/// Defines the Dart layout for reading subtitle strings.
typedef GetSubTextDart = ffi.Pointer<Utf8> Function(int index);

/// Defines the native C layout for the media clock time.
typedef GetTimeNative = ffi.Double Function();
/// Defines the Dart layout for the media clock time.
typedef GetTimeDart = double Function();

/// Direct FFI communication bridge specifically mapped to `libbaremetal_dsp.so` 
/// or `baremetal_dsp.dll`. Used internally by state managers like BLoC.
class DspBridge {
  static final DspBridge _instance = DspBridge._internal();
  
  /// Exposes the persistent singleton bridge instance.
  factory DspBridge() => _instance;

  late final ffi.DynamicLibrary _nativeLib;

  late final InitEngineDart _initEngineNative;
  late final StopEngineDart _stopEngineNative;
  late final GetRmsDart _getRmsLevelNative;
  late final GetFftDart _getFftArrayNative;
  late final SetGainDart _setGainNative;
  late final LoadSubtitlesDart _loadSubtitlesNative;
  late final GetSubIdxDart _getSubtitleIndexNative;
  late final GetSubTextDart _getSubtitleTextNative;
  late final GetTimeDart _getMediaTimeNative;

  DspBridge._internal() {
    _loadLibrary();
    _bindSignatures();
  }

  void _loadLibrary() {
    try {
      if (Platform.isWindows) {
        _nativeLib = ffi.DynamicLibrary.open('baremetal_dsp.dll');
      } else if (Platform.isAndroid || Platform.isLinux) {
        _nativeLib = ffi.DynamicLibrary.open('libbaremetal_dsp.so');
      } else if (Platform.isIOS || Platform.isMacOS) {
        _nativeLib = ffi.DynamicLibrary.process();
      } else {
        throw UnsupportedError('OS not supported.');
      }
    } catch (e) {
      rethrow;
    }
  }

  void _bindSignatures() {
    _initEngineNative = _nativeLib
        .lookupFunction<InitEngineNative, InitEngineDart>('init_engine');
    _stopEngineNative = _nativeLib
        .lookupFunction<StopEngineNative, StopEngineDart>('stop_engine');
    _getRmsLevelNative =
        _nativeLib.lookupFunction<GetRmsNative, GetRmsDart>('get_rms_level');
    _getFftArrayNative =
        _nativeLib.lookupFunction<GetFftNative, GetFftDart>('get_fft_array');
    _setGainNative =
        _nativeLib.lookupFunction<SetGainNative, SetGainDart>('set_gain');
    _loadSubtitlesNative =
        _nativeLib.lookupFunction<LoadSubtitlesNative, LoadSubtitlesDart>(
            'load_subtitles');
    _getSubtitleIndexNative = _nativeLib
        .lookupFunction<GetSubIdxNative, GetSubIdxDart>('get_subtitle_index');
    _getSubtitleTextNative = _nativeLib
        .lookupFunction<GetSubTextNative, GetSubTextDart>('get_subtitle_text');
    _getMediaTimeNative =
        _nativeLib.lookupFunction<GetTimeNative, GetTimeDart>('get_media_time');
  }

  // --- PUBLIC API ---

  /// Triggers engine initialisation mapped to C++ backend.
  /// 
  /// Utilizes [mode] to switch context (e.g. 0 for capture, 1 for playback).
  void initEngine({int mode = 0, String? filePath}) {
    final ptr = (filePath != null) ? filePath.toNativeUtf8() : ffi.nullptr;
    _initEngineNative(mode, ptr);
    if (ptr != ffi.nullptr) {
      calloc.free(ptr);
    }
  }

  /// Commands the C++ environment to halt operation safely.
  void stopEngine() => _stopEngineNative();
  
  /// Fetches volume magnitude directly from active memory.
  double getRmsLevel() => _getRmsLevelNative();
  
  /// Requests the hardware memory pointer for spectral rendering.
  ffi.Pointer<ffi.Float> getFftArray() => _getFftArrayNative();
  
  /// Forces a master volume modification at the native signal stage.
  void setGain(double gain) => _setGainNative(gain);
  
  /// Queries the synchronized hardware clock.
  double getMediaTime() => _getMediaTimeNative();
  
  /// Queries the internal C++ struct index for active subtitles.
  int getSubtitleIndex() => _getSubtitleIndexNative();

  /// Converts Dart Strings to UTF-8 buffers and executes load on C++.
  void loadSubtitles(String srtContent) {
    final ptr = srtContent.toNativeUtf8();
    _loadSubtitlesNative(ptr);
    calloc.free(ptr);
  }

  /// Pulls the resolved string back from C++ allocated memory to Dart.
  String getSubtitleText(int index) {
    final ptr = _getSubtitleTextNative(index);
    if (ptr == ffi.nullptr) return "";
    return ptr.toDartString();
  }
}