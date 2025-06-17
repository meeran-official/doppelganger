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
    await _initializeSpeech();
    await _initializeFlutterTts();
    _intelligentVoice = IntelligentVoiceService();
  }

  Future<void> _initializeSpeech() async {
    _speech = stt.SpeechToText();
    _speechEnabled = await _speech.initialize();
    setState(() {});
  }

  Future<void> _initializeFlutterTts() async {
    _flutterTts = FlutterTts();
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _speak(String text) async {
    if (text.isNotEmpty) {
      setState(() {
        _isSpeaking = true;
      });
      
      try {
        await _flutterTts.speak(text);
        
        // Wait for TTS to complete
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
        
        // Add safety timeout
        Future.delayed(const Duration(seconds: 30), () {
          if (_isListening && mounted) {
            _stopListening();
          }
        });
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
        if (val.hasConfidenceRating && val.confidence > 0) {
          _speechText = 'You said: "$_lastWords"';
        }
        
        // Auto-stop when final result is detected
        if (val.finalResult) {
          _stopListening();
        }
      }),
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        onDevice: false,
      ),
    );
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _isProcessing = true;
      });
      
      if (_lastWords.isNotEmpty) {
        _processVoiceInput(_lastWords);
      } else {
        setState(() {
          _isProcessing = false;
          _speechText = 'No speech detected. Please try again.';
        });
      }
    }
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
        
        final result = await _intelligentVoice.processVoiceToFact(input).timeout(
          const Duration(seconds: 15),
          onTimeout: () => {
            'success': false,
            'message': 'Processing timeout. Please try again with a shorter phrase.',
          },
        );
        
        response = result['message'] ?? 'Unknown error occurred';
        
        if (result['success'] == true && result['isNewFact'] == true) {
          setState(() {
            _responseText = '✅ Fact Added: $response';
            _isFactMode = false;
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Fact added successfully!')),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
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

  bool _shouldProcessAsFact(String input) {
    final factKeywords = [
      'remember', 'note', 'save', 'store', 'add fact', 'my',
      'i am', 'i work', 'i live', 'i like', 'i have', 'i study'
    ];
    
    final lowercaseInput = input.toLowerCase();
    return factKeywords.any((keyword) => lowercaseInput.contains(keyword));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: Text(
          'Smart Voice Ass...',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(
              _isFactMode ? Icons.lightbulb : Icons.lightbulb_outline,
              color: _isFactMode ? const Color(0xFF34A853) : Colors.white70,
            ),
            onPressed: () {
              setState(() {
                _isFactMode = !_isFactMode;
              });
            },
            tooltip: _isFactMode ? 'Exit Fact Mode' : 'Enter Fact Mode',
          ),
          IconButton(
            icon: Icon(Icons.mic),
            onPressed: () {},
            tooltip: 'Voice Settings',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Mode Indicator
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4)).withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFactMode ? Icons.lightbulb : Icons.chat_bubble_outline,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFactMode ? 'Fact Learning Mode' : 'Smart Assistant Mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isFactMode,
                      onChanged: (value) {
                        setState(() {
                          _isFactMode = value;
                        });
                      },
                      activeColor: Colors.white,
                      activeTrackColor: Colors.white24,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.white24,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                _isFactMode ? 'Say "Remember that..." to add facts' : 'Ask about your stored knowledge',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Voice Visualization
              Expanded(
                flex: 2,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer pulsing ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 200 + (_pulseController.value * 50),
                            height: 200 + (_pulseController.value * 50),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: (_isSpeaking
                                    ? const Color(0xFF34A853)
                                    : _isListening
                                        ? (_isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4))
                                        : const Color(0xFF39A7FF)).withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                      // Middle wave ring
                      AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Container(
                            width: 175 + (_waveController.value * 25),
                            height: 175 + (_waveController.value * 25),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
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
                                          : Icons.mic_none,
                                  color: Colors.white,
                                  size: 50,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
                // Status and Results
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // Current status
                        if (_isListening)
                          SlideInUp(
                            child: ExquisiteUIHelpers.buildGlassmorphicCard(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.mic,
                                      color: _isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isFactMode ? 'Recording fact...' : 'Listening...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: _stopListening,
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.red[400],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        if (_isProcessing)
                          SlideInUp(
                            child: ExquisiteUIHelpers.buildGlassmorphicCard(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          _isFactMode ? const Color(0xFF34A853) : const Color(0xFF4285F4),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _isFactMode ? 'Processing fact...' : 'Thinking...',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Speech Text
                        if (_speechText.isNotEmpty)
                          FadeInUp(
                            child: ExquisiteUIHelpers.buildGlassmorphicCard(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.hearing,
                                          color: Colors.blue[300],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'You said:',
                                          style: TextStyle(
                                            color: Colors.blue[300],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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
                                      ),
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 16),
                        
                        // Response Text
                        if (_responseText.isNotEmpty)
                          FadeInUp(
                            child: ExquisiteUIHelpers.buildGlassmorphicCard(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _responseText.startsWith('✅') ? Icons.check_circle : Icons.smart_toy,
                                          color: _responseText.startsWith('✅') ? Colors.green[300] : Colors.purple[300],
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _responseText.startsWith('✅') ? 'Success:' : 'Assistant:',
                                          style: TextStyle(
                                            color: _responseText.startsWith('✅') ? Colors.green[300] : Colors.purple[300],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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
                                      ),
                                      maxLines: 5,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        
                        // Add some bottom padding for scroll space
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
    );
  }
}
