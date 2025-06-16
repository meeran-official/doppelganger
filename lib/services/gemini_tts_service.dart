import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

class GeminiTtsService {
  static final GeminiTtsService _instance = GeminiTtsService._internal();
  factory GeminiTtsService() => _instance;
  GeminiTtsService._internal();

  late FlutterTts _fallbackTts;
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool _useGeminiTts = true;

  // Callbacks
  Function()? onSpeakingStart;
  Function()? onSpeakingComplete;
  Function(String)? onError;

  Future<void> initialize() async {
    try {
      _audioPlayer = AudioPlayer();
      _fallbackTts = FlutterTts();
      _isInitialized = true;
      
      // Configure fallback TTS
      await _fallbackTts.setLanguage("en-US");
      await _fallbackTts.setSpeechRate(0.5);
      await _fallbackTts.setVolume(1.0);
      await _fallbackTts.setPitch(1.0);
      
      // Set up completion callback for audio player
      _audioPlayer.onPlayerComplete.listen((_) {
        _isSpeaking = false;
        onSpeakingComplete?.call();
      });
      
      // Set up fallback TTS callbacks
      _fallbackTts.setStartHandler(() {
        _isSpeaking = true;
        onSpeakingStart?.call();
      });

      _fallbackTts.setCompletionHandler(() {
        _isSpeaking = false;
        onSpeakingComplete?.call();
      });

      _fallbackTts.setErrorHandler((msg) {
        _isSpeaking = false;
        onError?.call(msg);
      });
      
    } catch (e) {
      debugPrint('Error initializing Gemini TTS service: $e');
      onError?.call('Failed to initialize TTS service');
    }
  }

  Future<bool> speak(String text) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isSpeaking) {
      await stop();
    }

    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return await _speakWithFallback(text);
      }

      if (_useGeminiTts) {
        // Try Gemini TTS first
        final success = await _speakWithGemini(text, apiKey);
        if (success) {
          return true;
        } else {
          // Fall back to device TTS if Gemini fails
          _useGeminiTts = false;
          debugPrint('Gemini TTS failed, falling back to device TTS');
          return await _speakWithFallback(text);
        }
      } else {
        // Use fallback TTS
        return await _speakWithFallback(text);
      }

    } catch (e) {
      _isSpeaking = false;
      debugPrint('Error in TTS: $e');
      return await _speakWithFallback(text);
    }
  }
  Future<bool> _speakWithGemini(String text, String apiKey) async {
    try {
      _isSpeaking = true;
      onSpeakingStart?.call();

      // Use actual Gemini TTS model
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-preview-tts:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': text,
                }
              ]
            }
          ],
          'generationConfig': {
            'candidateCount': 1,
            'temperature': 0.1,
            'maxOutputTokens': 8192,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty) {
          
          final candidate = responseData['candidates'][0];
          
          // Check if response contains audio data
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            
            final part = candidate['content']['parts'][0];
            
            // Handle different possible response formats for TTS
            if (part['audioData'] != null) {
              // Direct audio data
              await _playAudioFromBase64(part['audioData']);
              return true;
            } else if (part['inlineData'] != null) {
              // Inline data format
              final inlineData = part['inlineData'];
              if (inlineData['mimeType'] != null && 
                  inlineData['mimeType'].toString().startsWith('audio/') &&
                  inlineData['data'] != null) {
                await _playAudioFromBase64(inlineData['data']);
                return true;
              }
            } else if (part['fileData'] != null) {
              // File data format
              final fileData = part['fileData'];
              if (fileData['mimeType'] != null && 
                  fileData['mimeType'].toString().startsWith('audio/') &&
                  fileData['fileUri'] != null) {
                await _playAudioFromUri(fileData['fileUri']);
                return true;
              }
            }
          }
        }
      }

      // If we get here, the TTS API call didn't return audio as expected
      debugPrint('Gemini TTS response did not contain expected audio data. Status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      _isSpeaking = false;
      return false;

    } catch (e) {
      _isSpeaking = false;
      debugPrint('Gemini TTS error: $e');
      return false;
    }  }

  Future<void> _playAudioFromBase64(String base64Audio) async {
    try {
      // Decode base64 audio data
      final audioBytes = base64Decode(base64Audio);
      
      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/gemini_tts_${DateTime.now().millisecondsSinceEpoch}.mp3');
      await tempFile.writeAsBytes(audioBytes);
      
      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(tempFile.path));
      
      // Clean up temp file after a delay
      Future.delayed(Duration(seconds: 10), () {
        if (tempFile.existsSync()) {
          tempFile.delete();
        }
      });
      
    } catch (e) {
      _isSpeaking = false;
      debugPrint('Error playing audio from base64: $e');
      onError?.call('Audio playback error: $e');
    }
  }

  Future<void> _playAudioFromUri(String audioUri) async {
    try {
      // Play audio from URI
      await _audioPlayer.play(UrlSource(audioUri));
      
    } catch (e) {
      _isSpeaking = false;
      debugPrint('Error playing audio from URI: $e');
      onError?.call('Audio playback error: $e');
    }
  }

  Future<bool> _speakWithFallback(String text) async {
    try {
      await _fallbackTts.speak(text);
      return true;
    } catch (e) {
      _isSpeaking = false;
      onError?.call('TTS error: $e');
      return false;
    }
  }

  Future<void> stop() async {
    if (_isSpeaking) {
      await _audioPlayer.stop();
      await _fallbackTts.stop();
      _isSpeaking = false;
    }
  }

  Future<void> pause() async {
    if (_isSpeaking) {
      await _audioPlayer.pause();
      await _fallbackTts.pause();
    }
  }

  Future<void> resume() async {
    if (!_isSpeaking) {
      await _audioPlayer.resume();
      _isSpeaking = true;
    }
  }

  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;

  void dispose() {
    _audioPlayer.dispose();
    _fallbackTts.stop();
    _isInitialized = false;
  }
}
