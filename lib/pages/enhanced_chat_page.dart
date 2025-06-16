import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:animate_do/animate_do.dart';
import '../models/conversation_model.dart';
import '../services/ai_service.dart';
import '../services/voice_service.dart';
import '../database_helper.dart';
import 'package:intl/intl.dart';

class EnhancedChatPage extends StatefulWidget {
  final String userName;
  final String weatherInfo;
  
  const EnhancedChatPage({
    super.key,
    required this.userName,
    required this.weatherInfo,
  });

  @override
  State<EnhancedChatPage> createState() => _EnhancedChatPageState();
}

class _EnhancedChatPageState extends State<EnhancedChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  final VoiceService _voiceService = VoiceService();
  
  List<ConversationMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;
  late AnimationController _pulseController;
  late AnimationController _typingController;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupAnimations();
    _startNewConversation();
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  Future<void> _initializeServices() async {
    try {
      _aiService.initialize();
      await _voiceService.initialize();
      
      // Set up voice service callbacks
      _voiceService.onSpeechResult = (result) {
        setState(() {
          _messageController.text = result;
        });
      };
      
      _voiceService.onSpeechError = (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: $error')),
        );
      };
      
      _voiceService.onListeningStart = () {
        setState(() {
          _isListening = true;
        });
        _pulseController.repeat();
      };
      
      _voiceService.onListeningStop = () {
        setState(() {
          _isListening = false;
        });
        _pulseController.stop();
      };    } catch (e) {
      if (kDebugMode) print('Error initializing services: $e');
    }
  }

  Future<void> _startNewConversation() async {
    final sessionId = await _aiService.startNewConversation();
    setState(() {
      _messages = [];
    });
      // Add welcome message
    final welcomeMessage = ConversationMessage(
      sessionId: sessionId,
      message: "Hi ${widget.userName}! 👋 I'm your enhanced digital assistant. I now remember our conversations, can listen to your voice, and have access to all your personal facts. How can I help you today?",
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(welcomeMessage);
    });
    
    await DatabaseHelper.instance.addConversationMessage(
      sessionId,
      welcomeMessage.message,
      false,
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;    // Clear input and add user message
    _messageController.clear();
    final userMessage = ConversationMessage(
      sessionId: _aiService.currentSessionId,
      message: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    _typingController.repeat();
    _scrollToBottom();

    try {
      final aiResponse = await _aiService.generateResponse(
        message,
        userName: widget.userName,
        weatherInfo: widget.weatherInfo,
      );      final aiMessage = ConversationMessage(
        sessionId: _aiService.currentSessionId,
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      
      _typingController.stop();
      _scrollToBottom();

      // Optional: Read response aloud
      // await _voiceService.speak(aiResponse);
      
    } catch (e) {
      setState(() {
        _isLoading = false;        _messages.add(ConversationMessage(
          sessionId: _aiService.currentSessionId,
          message: "Sorry, I encountered an error: $e",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
      _typingController.stop();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
    }
  }

  Widget _buildMessage(ConversationMessage message, int index) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final color = isUser 
        ? Theme.of(context).colorScheme.primary 
        : Theme.of(context).colorScheme.surface;
    final textColor = isUser 
        ? Theme.of(context).colorScheme.onPrimary 
        : Theme.of(context).colorScheme.onSurface;

    return FadeInUp(
      duration: Duration(milliseconds: 300 + (index * 100)),
      child: Container(
        alignment: alignment,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: const Icon(Icons.smart_toy, size: 18),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.message,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('HH:mm').format(message.timestamp),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  widget.userName.isNotEmpty ? widget.userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return FadeInUp(
      child: Container(
        alignment: Alignment.centerLeft,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              child: const Icon(Icons.smart_toy, size: 18),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thinking',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _typingController,
                    builder: (context, child) {
                      final dots = ((_typingController.value * 3).floor() % 4);
                      return Text(
                        '.' * dots,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.userName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show conversation history
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // TODO: Show chat settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Weather info banner
          if (widget.weatherInfo.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
              child: Text(
                widget.weatherInfo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ),
          
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index], index);
              },
            ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Voice input button
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isListening ? 1.0 + (_pulseController.value * 0.2) : 1.0,
                      child: IconButton(
                        icon: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: _isListening 
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: _voiceService.speechEnabled ? _toggleVoiceInput : null,
                      ),
                    );
                  },
                ),
                
                // Text input
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Send button
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: IconButton.filled(
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: _isLoading 
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _typingController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _voiceService.dispose();
    super.dispose();
  }
}
