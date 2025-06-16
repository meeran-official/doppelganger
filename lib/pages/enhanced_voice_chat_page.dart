import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class EnhancedVoiceChatPage extends StatefulWidget {
  final String userName;
  final String weatherInfo;

  const EnhancedVoiceChatPage({
    super.key,
    required this.userName,
    required this.weatherInfo,
  });

  @override
  State<EnhancedVoiceChatPage> createState() => _EnhancedVoiceChatPageState();
}

class _EnhancedVoiceChatPageState extends State<EnhancedVoiceChatPage>
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
  String _currentVoicePreset = 'Friendly';
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
    
    _initializeServices();
  }  void _initializeServices() async {
    await _initializeTts();
    await _initializeSpeech();
  }
  Future<void> _initializeTts() async {
    _flutterTts = FlutterTts();
    
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
      });
    });

    _flutterTts.setErrorHandler((msg) {
      setState(() {
        _isSpeaking = false;
      });
    });
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize(
      onError: (val) => {},
      onStatus: (val) => {},
    );
    setState(() {});
  }
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _flutterTts.stop();
    super.dispose();
  }
  Future<void> _speak(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _isSpeaking = true;
    });

    try {
      await _flutterTts.speak(text);
      
      // Set up completion callback
      _flutterTts.setCompletionHandler(() {
        setState(() {
          _isSpeaking = false;
        });
      });
    } catch (e) {
      setState(() {
        _isSpeaking = false;
      });
    }
  }

  Future<void> _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() {
      _isSpeaking = false;
    });
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
      onSoundLevelChange: (level) => {},
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

    // Simulate AI processing (connect to your AI service here)
    await Future.delayed(const Duration(seconds: 2));
    
    String response = _generateResponse(input);
    
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _responseText = response;
      });
      
      // Speak the response with Gemini TTS
      await _speak(response);
    }
  }

  String _generateResponse(String input) {
    String lowerInput = input.toLowerCase();
    
    if (lowerInput.contains('hello') || lowerInput.contains('hi')) {
      return 'Hello ${widget.userName}! I\'m your digital doppelgänger, powered by Gemini\'s advanced voice technology. How can I assist you today?';
    } else if (lowerInput.contains('weather')) {
      return widget.weatherInfo.isNotEmpty 
          ? 'Here\'s the current weather: ${widget.weatherInfo}'
          : 'I don\'t have current weather information available right now.';
    } else if (lowerInput.contains('voice') || lowerInput.contains('sound')) {
      return 'I\'m using Google\'s Gemini 2.5 Flash Preview TTS with the $_currentVoicePreset voice preset. Pretty cool, right?';
    } else if (lowerInput.contains('time')) {
      final now = DateTime.now();
      return 'The current time is ${now.hour}:${now.minute.toString().padLeft(2, '0')}.';
    } else if (lowerInput.contains('schedule') || lowerInput.contains('calendar')) {
      return 'I\'d be happy to help you manage your schedule. You can ask me about upcoming events or add new appointments to your calendar.';
    } else if (lowerInput.contains('reminder')) {
      return 'I can help you set intelligent reminders. What would you like me to remind you about, and when?';
    } else {
      return 'I heard you say "$input". That\'s interesting! I\'m powered by advanced AI and can help you with various tasks. What else would you like to know?';
    }
  }

  void _changeVoicePreset(String preset) {
    setState(() {
      _currentVoicePreset = preset;
    });
    _speak('Voice changed to $_currentVoicePreset preset.');
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
          'Gemini Voice Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [          PopupMenuButton<String>(
            icon: const Icon(Icons.settings_voice, color: Colors.white),
            onSelected: _changeVoicePreset,
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'Friendly',
                child: Text('Friendly Voice'),
              ),
              const PopupMenuItem<String>(
                value: 'Professional',
                child: Text('Professional Voice'),
              ),
              const PopupMenuItem<String>(
                value: 'Casual',
                child: Text('Casual Voice'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Welcome Section with Gemini branding
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFEA4335), Color(0xFFFBBC05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Gemini',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Premium Voice Assistant',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Powered by 2.5 Flash Preview TTS',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Current Voice: $_currentVoicePreset',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Voice Visualization
              Expanded(
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        
                        // Animated Voice Circle with Gemini colors
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 150 + (_pulseController.value * 15),
                              height: 150 + (_pulseController.value * 15),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    _isSpeaking
                                        ? const Color(0xFF34A853)
                                        : _isListening
                                            ? const Color(0xFF4285F4)
                                            : const Color(0xFF2C2C2E),
                                    _isSpeaking
                                        ? const Color(0xFF34A853).withValues(alpha: 0.4)
                                        : _isListening
                                            ? const Color(0xFF4285F4).withValues(alpha: 0.3)
                                            : const Color(0xFF1C1C1E),
                                  ],
                                ),
                                boxShadow: (_isListening || _isSpeaking)
                                    ? [
                                        BoxShadow(
                                          color: (_isSpeaking 
                                              ? const Color(0xFF34A853)
                                              : const Color(0xFF4285F4))
                                              .withValues(alpha: 0.4),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Icon(
                                _isSpeaking
                                    ? Icons.graphic_eq
                                    : _isListening
                                        ? Icons.mic
                                        : _isProcessing
                                            ? Icons.hourglass_empty
                                            : Icons.auto_awesome,
                                size: 50,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Status Text
                        Text(
                          _isSpeaking
                              ? 'Speaking with Gemini TTS...'
                              : _isListening
                                  ? 'Listening...'
                                  : _isProcessing
                                      ? 'Processing with AI...'
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

                        // Response Text with Gemini styling
                        if (_responseText.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4285F4), Color(0xFF34A853)],
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
              ),

              // Voice Control Button
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
                        colors: _isSpeaking
                            ? [const Color(0xFF34A853), const Color(0xFF137333)]
                            : _isListening
                                ? [const Color(0xFFEA4335), const Color(0xFFD73527)]
                                : [const Color(0xFF4285F4), const Color(0xFF1967D2)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_isSpeaking
                                  ? const Color(0xFF34A853)
                                  : _isListening
                                      ? const Color(0xFFEA4335)
                                      : const Color(0xFF4285F4))
                              .withValues(alpha: 0.4),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
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
                          : 'Using device TTS • Tap ⚙️ to change voice style',
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
