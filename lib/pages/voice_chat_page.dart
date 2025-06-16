import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceChatPage extends StatefulWidget {
  final String userName;
  final String weatherInfo;

  const VoiceChatPage({
    super.key,
    required this.userName,
    required this.weatherInfo,
  });

  @override
  State<VoiceChatPage> createState() => _VoiceChatPageState();
}

class _VoiceChatPageState extends State<VoiceChatPage>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _speechText = '';
  String _responseText = '';
  late AnimationController _pulseController;
  late AnimationController _waveController;
  
  // Voice functionality
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  String _lastWords = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
    
    _initializeTts();
    _initializeSpeech();
  }

  void _initializeTts() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    // Set up TTS callbacks
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
      // TTS Error occurred
    });
  }
  void _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onError: (val) => {}, // Speech recognition error handled
      onStatus: (val) => {}, // Speech recognition status handled
    );
    setState(() {});
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
  }
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _flutterTts.stop();
    super.dispose();
  }

  void _toggleListening() {
    if (_isSpeaking) {
      _stopSpeaking();
      return;
    }
    
    if (!_speechEnabled) {
      setState(() {
        _speechText = 'Speech recognition not available';
      });
      return;
    }

    setState(() {
      _isListening = !_isListening;
      if (_isListening) {
        _speechText = '';
        _responseText = '';
        _startListening();
      } else {
        _stopListening();
      }
    });
  }
  void _startListening() async {
    _lastWords = '';
    await _speech.listen(
      onResult: (val) => setState(() {
        _lastWords = val.recognizedWords;
        _speechText = 'You said: "$_lastWords"';
      }),
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: "en_US",
      onSoundLevelChange: (level) => {}, // Sound level change handled
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.confirmation,
      ),
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _isProcessing = true;
    });

    // Process the speech and generate response
    _processVoiceInput(_lastWords);
  }

  void _processVoiceInput(String input) async {
    if (input.isEmpty) {
      setState(() {
        _isProcessing = false;
        _speechText = 'No speech detected. Please try again.';
      });
      return;
    }

    // Simulate AI processing (replace with actual AI service call)
    await Future.delayed(const Duration(seconds: 2));
    
    String response = _generateResponse(input);
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _responseText = response;
      });
      
      // Speak the response
      await _speak(response);
    }
  }

  String _generateResponse(String input) {
    String lowerInput = input.toLowerCase();
    
    if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
      return 'Hello ${widget.userName}! How can I help you today?';
    } else if (lowerInput.contains('weather')) {
      return widget.weatherInfo.isNotEmpty 
          ? widget.weatherInfo 
          : 'I don\'t have current weather information available.';
    } else if (lowerInput.contains('time')) {
      return 'The current time is ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}.';
    } else if (lowerInput.contains('schedule') || lowerInput.contains('calendar')) {
      return 'I\'d be happy to help with your schedule. You can add events to your calendar or ask about upcoming appointments.';
    } else if (lowerInput.contains('reminder')) {
      return 'I can help you set reminders. What would you like me to remind you about?';
    } else {
      return 'I heard you say "$input". That\'s interesting! I\'m still learning, but I\'m here to help you with various tasks.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Voice Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Welcome Section
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.mic_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Voice Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Speak naturally, I\'ll understand',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),              const SizedBox(height: 20),

              // Voice Visualization
              Expanded(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Animated Voice Circle
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 150 + (_pulseController.value * 15),
                              height: 150 + (_pulseController.value * 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,                                gradient: RadialGradient(
                                  colors: [
                                    _isSpeaking
                                        ? const Color(0xFF00D4FF)
                                        : _isListening
                                            ? const Color(0xFF39A7FF)
                                            : const Color(0xFF2C2C2E),
                                    _isSpeaking
                                        ? const Color(0xFF39A7FF).withValues(alpha: 0.4)
                                        : _isListening
                                            ? const Color(0xFF00D4FF).withValues(alpha: 0.3)
                                            : const Color(0xFF1C1C1E),
                                  ],
                                ),
                                boxShadow: (_isListening || _isSpeaking)
                                    ? [
                                        BoxShadow(
                                          color: (_isSpeaking 
                                              ? const Color(0xFF00D4FF)
                                              : const Color(0xFF39A7FF))
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ]
                                    : null,
                              ),                              child: Icon(
                                _isSpeaking
                                    ? Icons.volume_up
                                    : _isListening
                                        ? Icons.mic
                                        : _isProcessing
                                            ? Icons.hourglass_empty
                                            : Icons.mic_off,
                                size: 50,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),                        // Status Text
                        Text(
                          _isSpeaking
                              ? 'Speaking...'
                              : _isListening
                                  ? 'Listening...'
                                  : _isProcessing
                                      ? 'Processing...'
                                      : _speechEnabled 
                                          ? 'Tap to speak'
                                          : 'Speech not available',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Speech Text
                        if (_speechText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _speechText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                        if (_speechText.isNotEmpty && _responseText.isNotEmpty)
                          const SizedBox(height: 12),

                        // Response Text
                        if (_responseText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF39A7FF), Color(0xFF00D4FF)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _responseText,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),              // Voice Control Button
              FadeInUp(
                duration: const Duration(milliseconds: 800),
                delay: const Duration(milliseconds: 200),
                child: GestureDetector(
                  onTap: _toggleListening,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)]
                            : [const Color(0xFF39A7FF), const Color(0xFF00D4FF)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening
                                  ? const Color(0xFFFF6B6B)
                                  : const Color(0xFF39A7FF))
                              .withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),                    child: Icon(
                      _isSpeaking 
                          ? Icons.stop 
                          : _isListening 
                              ? Icons.stop 
                              : Icons.mic,
                      color: Colors.white,
                      size: 35,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Tips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),                child: Text(
                  _isSpeaking
                      ? 'Tap to stop speaking'
                      : _isListening
                          ? 'Tap to stop listening'
                          : _speechEnabled
                              ? 'Tap the microphone to start voice chat'
                              : 'Speech recognition not available',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
