#ifndef BAREMETAL_DSP_ENGINE_H
#define BAREMETAL_DSP_ENGINE_H

#include <atomic>
#include <vector>
#include <string>
#include <cstdint>

// Forward Declarations
struct ma_device;
struct ma_decoder;

#if defined(_WIN32)
    #define EXPORT extern "C" __declspec(dllexport)
#else
    #define EXPORT extern "C" __attribute__((visibility("default"))) __attribute__((used))
#endif

#define FFT_SIZE 1024
#define FFT_BINS (FFT_SIZE / 2)
#define SAMPLE_RATE 48000

enum class EngineMode {
    IDLE = -1,
    CAPTURE = 0, // Visualizer (Microphone)
    PLAYBACK = 1 // Media Player (File)
};

struct SubtitleEvent {
    double startTime;
    double endTime;
    std::string text;
};

class DSPEngine {
public:
    DSPEngine();
    ~DSPEngine();

    void start(int mode, const char* filePath = nullptr);
    void stop();

    float getRms();
    float* getFftData();
    double getCurrentTime() const;

    void setMasterGain(float gain);
    void loadSubtitles(const char* srtContent);
    int32_t getActiveSubtitleIndex() const;
    const char* getSubtitleText(int32_t index) const;

    // Internal callback
    void onAudioData(void* pOutput, const void* pInput, uint32_t frameCount);

private:
    std::atomic<bool> isRunning;
    EngineMode currentMode;

    ma_device* device;
    ma_decoder* decoder;

    std::atomic<uint64_t> totalFramesProcessed;
    std::atomic<float> masterGain;
    std::atomic<float> currentRms;

    // Subtitle Logic
    std::vector<SubtitleEvent> subtitles;
    std::atomic<int32_t> currentSubtitleIdx;

    // DSP State
    float prevInput;
    float prevOutput;
    const float R = 0.995f;

    // FFT State
    float sampleBuffer[FFT_SIZE];
    int bufferIndex;
    float fftMagnitudes[FFT_BINS];

    void computeFFT();
    void syncSubtitles(double timestamp);
    void processSignal(const float* buffer, uint32_t frames);
};

// --- FFI Exports ---
EXPORT void init_engine(int mode, const char* file_path);
EXPORT void stop_engine();
EXPORT float get_rms_level();
EXPORT float* get_fft_array();
EXPORT void set_gain(float gain);
EXPORT void load_subtitles(const char* srt_data);
EXPORT int32_t get_subtitle_index();
EXPORT const char* get_subtitle_text(int32_t index);
EXPORT double get_media_time();

#endif // BAREMETAL_DSP_ENGINE_H