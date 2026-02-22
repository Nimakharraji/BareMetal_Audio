import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// --- C++ Signatures (Updated) ---
// الان init_engine دو ورودی دارد: Mode (int) و Path (char*)
typedef InitEngineNative = ffi.Void Function(ffi.Int32 mode, ffi.Pointer<Utf8> path);
typedef InitEngineDart = void Function(int mode, ffi.Pointer<Utf8> path);

typedef StopEngineNative = ffi.Void Function();
typedef StopEngineDart = void Function();

typedef GetRmsNative = ffi.Float Function();
typedef GetRmsDart = double Function();

typedef GetFftNative = ffi.Pointer<ffi.Float> Function();
typedef GetFftDart = ffi.Pointer<ffi.Float> Function();

typedef SetGainNative = ffi.Void Function(ffi.Float gain);
typedef SetGainDart = void Function(double gain);

typedef LoadSubtitlesNative = ffi.Void Function(ffi.Pointer<Utf8> data);
typedef LoadSubtitlesDart = void Function(ffi.Pointer<Utf8> data);

typedef GetSubIdxNative = ffi.Int32 Function();
typedef GetSubIdxDart = int Function();

typedef GetSubTextNative = ffi.Pointer<Utf8> Function(ffi.Int32 index);
typedef GetSubTextDart = ffi.Pointer<Utf8> Function(int index);

typedef GetTimeNative = ffi.Double Function();
typedef GetTimeDart = double Function();

class DspBridge {
  static final DspBridge _instance = DspBridge._internal();
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
      print("CRITICAL ERROR LOADING DLL: $e");
      rethrow;
    }
  }

  void _bindSignatures() {
    _initEngineNative = _nativeLib.lookupFunction<InitEngineNative, InitEngineDart>('init_engine');
    _stopEngineNative = _nativeLib.lookupFunction<StopEngineNative, StopEngineDart>('stop_engine');
    _getRmsLevelNative = _nativeLib.lookupFunction<GetRmsNative, GetRmsDart>('get_rms_level');
    _getFftArrayNative = _nativeLib.lookupFunction<GetFftNative, GetFftDart>('get_fft_array');
    _setGainNative = _nativeLib.lookupFunction<SetGainNative, SetGainDart>('set_gain');
    _loadSubtitlesNative = _nativeLib.lookupFunction<LoadSubtitlesNative, LoadSubtitlesDart>('load_subtitles');
    _getSubtitleIndexNative = _nativeLib.lookupFunction<GetSubIdxNative, GetSubIdxDart>('get_subtitle_index');
    _getSubtitleTextNative = _nativeLib.lookupFunction<GetSubTextNative, GetSubTextDart>('get_subtitle_text');
    _getMediaTimeNative = _nativeLib.lookupFunction<GetTimeNative, GetTimeDart>('get_media_time');
  }

  // --- PUBLIC API ---

  // Updated Init: Accepts mode and optional file path
  void initEngine({int mode = 0, String? filePath}) {
    final ptr = (filePath != null) ? filePath.toNativeUtf8() : ffi.nullptr;
    _initEngineNative(mode, ptr);
    if (ptr != ffi.nullptr) {
      calloc.free(ptr);
    }
  }
  
  void stopEngine() => _stopEngineNative();
  double getRmsLevel() => _getRmsLevelNative();
  ffi.Pointer<ffi.Float> getFftArray() => _getFftArrayNative();
  void setGain(double gain) => _setGainNative(gain);
  double getMediaTime() => _getMediaTimeNative();
  int getSubtitleIndex() => _getSubtitleIndexNative();

  void loadSubtitles(String srtContent) {
    final ptr = srtContent.toNativeUtf8();
    _loadSubtitlesNative(ptr);
    calloc.free(ptr);
  }

  String getSubtitleText(int index) {
    final ptr = _getSubtitleTextNative(index);
    if (ptr == ffi.nullptr) return "";
    return ptr.toDartString();
  }
}