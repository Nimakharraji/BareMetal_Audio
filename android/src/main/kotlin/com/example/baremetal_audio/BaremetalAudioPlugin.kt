package com.example.baremetal_audio

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin

/** * This is a dummy plugin class required to satisfy Flutter's build system.
 * The actual logic is handled via Dart FFI and C++.
 */
class BaremetalAudioPlugin: FlutterPlugin {
  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    // FFI plugin - No MethodChannels needed here.
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    // Cleanup handled in C++ destructor.
  }
}