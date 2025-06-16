import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'gemini_tts_service.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();
  late SpeechToText _speechToText;
  late GeminiTtsService _geminiTts;
  bool _speechEnabled = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  // Callbacks
  Function(String)? onSpeechResult;
  Function(String)? onSpeechError;
  Function()? onListeningStart;
  Function()? onListeningStop;
  Future<void> initialize() async {
    try {
      _speechToText = SpeechToText();
      _geminiTts = GeminiTtsService();
      
      // Initialize speech to text
      _speechEnabled = await _speechToText.initialize(
        onError: (error) => onSpeechError?.call(error.errorMsg),
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
            onListeningStart?.call();
          } else if (status == 'done' || status == 'notListening') {
            _isListening = false;
            onListeningStop?.call();
          }
        },
      );

      // Initialize Gemini TTS
      await _geminiTts.initialize();
      
      // Set up TTS callbacks
      _geminiTts.onSpeakingStart = () {
        _isSpeaking = true;
      };

      _geminiTts.onSpeakingComplete = () {
        _isSpeaking = false;
      };

      _geminiTts.onError = (error) {
        _isSpeaking = false;
        if (kDebugMode) print("TTS Error: $error");
      };
    } catch (e) {
      if (kDebugMode) print("Voice service initialization error: $e");
      _speechEnabled = false;
    }
  }

  Future<bool> requestPermissions() async {
    try {
      final microphoneStatus = await Permission.microphone.request();
      return microphoneStatus == PermissionStatus.granted;
    } catch (e) {
      if (kDebugMode) print("Permission request error: $e");
      return false;
    }
  }

  Future<void> startListening() async {
    if (!_speechEnabled) {
      onSpeechError?.call("Speech recognition not available");
      return;
    }

    if (!await requestPermissions()) {
      onSpeechError?.call("Microphone permission denied");
      return;
    }

    if (_isListening) return;

    try {      await _speechToText.listen(
        onResult: (result) {
          onSpeechResult?.call(result.recognizedWords);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        onSoundLevelChange: (level) {},
      );
    } catch (e) {
      if (kDebugMode) print("Start listening error: $e");
      onSpeechError?.call("Failed to start listening");
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      try {
        await _speechToText.stop();
      } catch (e) {
        if (kDebugMode) print("Stop listening error: $e");
      }
    }
  }
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      try {
        await _geminiTts.speak(text);
      } catch (e) {
        if (kDebugMode) print("TTS speak error: $e");
      }
    }
  }

  Future<void> stop() async {
    try {
      await _geminiTts.stop();
      await _speechToText.stop();
    } catch (e) {
      if (kDebugMode) print("Voice service stop error: $e");
    }
  }

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get speechEnabled => _speechEnabled;

  void dispose() {
    try {
      _speechToText.cancel();
      _geminiTts.stop();
    } catch (e) {
      if (kDebugMode) print("Voice service dispose error: $e");
    }
  }
}
