import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../services/intelligent_voice_service.dart';
import '../widgets/exquisite_ui_helpers.dart';

class SmartVoiceChatPage extends StatefulWidget {
  final String userName;
  final String weatherInfo;

  const SmartVoiceChatPage({
    super.key,
    required this.userName,
    required this.weatherInfo,
  });

  @override
  State<SmartVoiceChatPage> createState() => _SmartVoiceChatPageState();
}

class _SmartVoiceChatPageState extends State<SmartVoiceChatPage>
    with TickerProviderStateMixin {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isFactMode = false;
  String _speechText = '';
  String _responseText = '';
  late AnimationController _pulseController;
  late AnimationController _waveController;
    // Voice functionality
  late FlutterTts _flutterTts;
  late stt.SpeechToText _speech;
  late IntelligentVoiceService _intelligentVoice;
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
  }
  Future<void> _initializeServices() async {
    _flutterTts = FlutterTts();
    _speech = stt.SpeechToText();
    _intelligentVoice = IntelligentVoiceService();
    
    await _initializeSpeech();
    await _initializeFlutterTts();
  }

  Future<void> _initializeSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (val) => {},
      onStatus: (val) => {},
    );
    setState(() {});
  }
  Future<void> _initializeFlutterTts() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
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
    _lastWords = '';    await _speech.listen(
      onResult: (val) => setState(() {
        _lastWords = val.recognizedWords;
        if (val.hasConfidenceRating && val.confidence > 0) {
          _speechText = 'You said: "$_lastWords"';
        }
      }),
      listenFor: const Duration(seconds: 30), // Max listening time
      pauseFor: const Duration(seconds: 5),   // Auto-stop after pause
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
      ),
      onSoundLevelChange: (level) => {}, // Handle sound level changes
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

    try {
      String response;
      
      // Enhanced fact detection logic
      if (_isFactMode || _shouldProcessAsFact(input)) {
        setState(() {
          _speechText = 'Processing fact: "$input"';
        });
        
        // Add timeout for fact processing
        final result = await _intelligentVoice.processVoiceToFact(input).timeout(
          const Duration(seconds: 15),
          onTimeout: () => {
            'success': false,
            'message': 'Processing timeout. Please try again with a shorter phrase.',
          },
        );
        
        response = result['message'];
        
        if (result['isNewFact'] == true) {
          setState(() {
            _responseText = '✅ Fact Added: $response';
            _isFactMode = false; // Auto-exit fact mode after adding
          });
          // Give user feedback for successful fact addition
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('New fact added to your knowledge base!'),
                    ),
                  ],
                ),
                backgroundColor: Colors.green.withValues(alpha: 0.8),
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          setState(() {
            _responseText = response;
          });
        }
      } else {
        setState(() {
          _speechText = 'Searching your knowledge: "$input"';
        });
        
        // Enhanced fact-based conversation with timeout
        response = await _intelligentVoice.generateFactBasedResponse(input).timeout(
          const Duration(seconds: 10),
          onTimeout: () => 'Sorry, that took too long to process. Please try again.',
        );
        
        setState(() {
          _responseText = response;
        });
      }
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Speak the response with appropriate voice
        await _speak(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _responseText = 'I had trouble processing that. Please try again.';
          _speechText = 'Error occurred while processing your request.';
        });
      }
    }
  }

  // Enhanced fact detection logic
  bool _shouldProcessAsFact(String input) {
    final lowerInput = input.toLowerCase();
    final factTriggers = [
      'remember that',
      'remember this',
      'add fact',
      'save this',
      'store this',
      'i learned',
      'keep in mind',
      'note that',
      'my name is',
      'i am',
      'i live',
      'i work',
      'i like',
      'i prefer',
      'i want to remember',
      'fact:',
      'please remember',
      'don\'t forget',
      'write down that',
    ];
    
    return factTriggers.any((trigger) => lowerInput.contains(trigger));
  }

  void _toggleFactMode() {
    setState(() {
      _isFactMode = !_isFactMode;
      _responseText = _isFactMode 
          ? 'Fact mode ON: Say "Remember that..." or "Add fact..." to store new information'
          : 'Fact mode OFF: Ask me about your stored knowledge';
    });
    
    _speak(_responseText);
  }

  void _changeVoicePreset(String preset) {
    setState(() {
      _currentVoicePreset = preset;
    });
    _speak('Voice changed to $_currentVoicePreset preset.');
  }

  void _showVoiceCommands() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Voice Commands',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...(_intelligentVoice.getSuggestedCommands().map((command) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  command,
                  style: TextStyle(color: Colors.grey[300], fontSize: 14),
                ),
              )
            )),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it!'),
            ),
          ],
        ),
      ),
    );
  }
  void _cancelProcessing() {
    setState(() {
      _isListening = false;
      _isProcessing = false;
      _isSpeaking = false;
      _speechText = 'Operation cancelled.';
      _responseText = '';
    });
    
    // Stop any ongoing speech recognition
    _speech.stop();
    
    // Stop any ongoing TTS
    _flutterTts.stop();
    
    // Show feedback to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.cancel, color: Colors.orange),
            const SizedBox(width: 8),
            const Text('Operation cancelled. You can try again.'),
          ],
        ),
        backgroundColor: Colors.orange.withValues(alpha: 0.8),
        duration: const Duration(seconds: 2),
      ),
    );
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
          'Smart Voice Assistant',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _isFactMode ? Icons.save : Icons.search,
              color: _isFactMode ? Colors.green : Colors.white,
            ),
            onPressed: _toggleFactMode,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: _showVoiceCommands,
          ),          PopupMenuButton<String>(
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF1A1A2E).withValues(alpha: 0.8),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Enhanced Mode indicator with glassmorphism
                FadeInDown(
                  duration: const Duration(milliseconds: 600),
                  child: ExquisiteUIHelpers.buildGlassmorphicCard(
                    borderRadius: 20,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _isFactMode 
                                    ? [const Color(0xFF34A853), const Color(0xFF137333)]
                                    : [const Color(0xFF4285F4), const Color(0xFF1967D2)],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(                                  color: (_isFactMode 
                                      ? const Color(0xFF34A853) 
                                      : const Color(0xFF4285F4)).withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isFactMode ? Icons.bookmark_add : Icons.psychology,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isFactMode ? 'Fact Learning Mode' : 'Smart Assistant Mode',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _isFactMode 
                                      ? 'Say "Remember that..." to add facts'
                                      : 'Ask about your stored knowledge',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isFactMode,
                            onChanged: (_) => _toggleFactMode(),
                            activeColor: const Color(0xFF34A853),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // Enhanced Voice Visualization
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Multi-layered Animated Voice Circle with Particle Effect
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              // Outer glow ring
                              AnimatedBuilder(
                                animation: _waveController,
                                builder: (context, child) {
                                  return Container(
                                    width: 220 + (_waveController.value * 20),
                                    height: 220 + (_waveController.value * 20),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: (_isSpeaking
                                            ? const Color(0xFF34A853)
                                            : _isListening
                                                ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                                : const Color(0xFF39A7FF)).withValues(alpha: 0.3 - (_waveController.value * 0.3)),
                                        width: 2,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              // Middle ring
                              AnimatedBuilder(
                                animation: _pulseController,
                                builder: (context, child) {
                                  return Container(
                                    width: 180 + (_pulseController.value * 10),
                                    height: 180 + (_pulseController.value * 10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: RadialGradient(
                                        colors: [
                                          (_isSpeaking
                                              ? const Color(0xFF34A853)
                                              : _isListening
                                                  ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                                  : const Color(0xFF39A7FF)).withValues(alpha: 0.2),
                                          Colors.transparent,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_isSpeaking
                                              ? const Color(0xFF34A853)
                                              : _isListening
                                                  ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                                  : const Color(0xFF39A7FF)).withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              // Main interactive circle
                              GestureDetector(
                                onTap: _toggleListening,
                                child: AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return ExquisiteUIHelpers.buildGlassmorphicCard(
                                      borderRadius: 75,
                                      opacity: 0.2,
                                      child: Container(
                                        width: 150,
                                        height: 150,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: RadialGradient(
                                            colors: [
                                              _isSpeaking
                                                  ? const Color(0xFF34A853)
                                                  : _isListening
                                                      ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                                      : const Color(0xFF39A7FF),
                                              (_isSpeaking
                                                  ? const Color(0xFF34A853)
                                                  : _isListening
                                                      ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                                      : const Color(0xFF39A7FF)).withValues(alpha: 0.7),
                                            ],
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (_isSpeaking
                                                  ? const Color(0xFF34A853)
                                                  : _isListening
                                                      ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                                      : const Color(0xFF39A7FF)).withValues(alpha: 0.4),
                                              blurRadius: 15,
                                              spreadRadius: 3,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _isSpeaking
                                              ? Icons.volume_up
                                              : _isListening
                                                  ? Icons.mic
                                                  : _isProcessing
                                                      ? Icons.auto_awesome
                                                      : Icons.mic_none,
                                          color: Colors.white,
                                          size: 60,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 30),                          // Enhanced Status Text with Cancel Option
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: (_isSpeaking 
                                    ? const Color(0xFF34A853)
                                    : _isListening 
                                        ? const Color(0xFF4285F4)
                                        : const Color(0xFF39A7FF)).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    _isSpeaking
                                        ? '🔊 Speaking with Smart AI...'
                                        : _isListening
                                            ? (_isFactMode ? '📝 Recording fact...' : '🎤 Listening...')
                                            : _isProcessing
                                                ? (_isFactMode ? '🤖 Processing fact...' : '🔍 Searching knowledge...')
                                                : _speechEnabled 
                                                    ? '👆 Tap to speak'
                                                    : '❌ Speech not available',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                // Cancel button when processing
                                if (_isProcessing || _isListening)
                                  GestureDetector(
                                    onTap: _cancelProcessing,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Enhanced Speech Text Display
                          if (_speechText.isNotEmpty)
                            FadeInUp(
                              duration: const Duration(milliseconds: 500),
                              child: ExquisiteUIHelpers.buildGlassmorphicCard(
                                borderRadius: 16,
                                opacity: 0.15,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.record_voice_over,
                                            color: const Color(0xFF39A7FF),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'You said:',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _speechText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          if (_speechText.isNotEmpty && _responseText.isNotEmpty)
                            const SizedBox(height: 16),

                          // Enhanced Response Text Display
                          if (_responseText.isNotEmpty)
                            FadeInUp(
                              duration: const Duration(milliseconds: 600),
                              delay: const Duration(milliseconds: 200),
                              child: ExquisiteUIHelpers.buildGlassmorphicCard(
                                borderRadius: 16,
                                opacity: 0.2,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: _responseText.startsWith('✅')                                          ? [
                                              const Color(0xFF34A853).withValues(alpha: 0.2),
                                              const Color(0xFF137333).withValues(alpha: 0.1),
                                            ]
                                          : [
                                              const Color(0xFF4285F4).withValues(alpha: 0.2),
                                              const Color(0xFF1967D2).withValues(alpha: 0.1),
                                            ],
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _responseText.startsWith('✅') 
                                                ? Icons.check_circle
                                                : Icons.psychology,
                                            color: _responseText.startsWith('✅') 
                                                ? const Color(0xFF34A853)
                                                : const Color(0xFF4285F4),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            _responseText.startsWith('✅') 
                                                ? 'Fact saved!'
                                                : 'Assistant response:',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _responseText,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          height: 1.4,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
