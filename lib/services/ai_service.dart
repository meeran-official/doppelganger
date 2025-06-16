import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../database_helper.dart';
import '../fact_model.dart';
import '../models/conversation_model.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  late GenerativeModel _model;
  int? _currentSessionId;
  List<ConversationMessage> _conversationHistory = [];  void initialize() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null) {
      throw Exception("Gemini API Key not found in .env file");
    }
    _model = GenerativeModel(model: 'gemini-2.5-flash-preview-05-20', apiKey: apiKey);
  }

  Future<int> startNewConversation({String? title}) async {
    final sessionTitle = title ?? 'Chat ${DateTime.now().toString().substring(0, 16)}';
    _currentSessionId = await DatabaseHelper.instance.createConversationSession(sessionTitle);
    _conversationHistory.clear();
    return _currentSessionId!;
  }

  Future<String> generateResponse(String userMessage, {
    String? userName,
    String? weatherInfo,
    bool includePersonality = true,
  }) async {
    try {
      // Start a new conversation if none exists
      if (_currentSessionId == null) {
        await startNewConversation();
      }

      // Save user message to database
      await DatabaseHelper.instance.addConversationMessage(
        _currentSessionId!,
        userMessage,
        true,
      );

      // Add to local history
      _conversationHistory.add(ConversationMessage(
        message: userMessage,
        isUser: true,
        timestamp: DateTime.now(),
      ));

      // Build enhanced context
      final context = await _buildEnhancedContext(userName, weatherInfo);
      
      // Build conversation history for context
      final conversationContext = _buildConversationContext();
      
      // Create the full prompt
      final fullPrompt = '''
$context

$conversationContext

Current User Message: $userMessage

Remember to be helpful, personable, and draw from the facts and conversation history to provide the most relevant response.
''';

      // Generate AI response
      final response = await _model.generateContent([Content.text(fullPrompt)]);
      final aiResponse = response.text ?? "I couldn't generate a response right now.";

      // Save AI response to database
      await DatabaseHelper.instance.addConversationMessage(
        _currentSessionId!,
        aiResponse,
        false,
      );

      // Add to local history
      _conversationHistory.add(ConversationMessage(
        message: aiResponse,
        isUser: false,
        timestamp: DateTime.now(),
      ));

      return aiResponse;
    } catch (e) {
      return "I encountered an error: ${e.toString()}";
    }
  }

  Future<String> _buildEnhancedContext(String? userName, String? weatherInfo) async {
    final facts = await DatabaseHelper.instance.getAllFacts();
    final preferences = await _getUserPreferences();
    
    final contextBuilder = StringBuffer();
    
    // Personality and role definition
    contextBuilder.writeln("""
You are an advanced AI assistant and digital companion for ${userName ?? 'the user'}. You have access to their personal facts and preferences, and you remember conversation history. Your personality is:
- Intelligent and knowledgeable
- Friendly and personable
- Proactive and helpful
- Respectful of privacy
- Good at making connections between different pieces of information

IMPORTANT: Use ONLY the facts provided below to answer questions. If you don't have information, say so honestly. Be conversational and remember context from our chat history.
""");

    // Weather context
    if (weatherInfo != null) {
      contextBuilder.writeln("Current Weather Context: $weatherInfo\n");
    }

    // User preferences
    if (preferences.isNotEmpty) {
      contextBuilder.writeln("--- USER PREFERENCES ---");
      preferences.forEach((key, value) {
        contextBuilder.writeln("$key: $value");
      });
      contextBuilder.writeln("");
    }

    // Facts organized by category
    contextBuilder.writeln("--- PERSONAL KNOWLEDGE BASE ---");
    final categorizedFacts = <String, List<Fact>>{};
    
    for (var fact in facts) {
      categorizedFacts.putIfAbsent(fact.category, () => []).add(fact);
    }

    categorizedFacts.forEach((category, categoryFacts) {
      contextBuilder.writeln("Category: $category");
      for (var fact in categoryFacts) {
        contextBuilder.writeln("Q: ${fact.question}");
        contextBuilder.writeln("A: ${fact.answer}");
        if (fact.tags.isNotEmpty) {
          contextBuilder.writeln("Tags: ${fact.tags.join(', ')}");
        }
        contextBuilder.writeln("");
      }
    });

    contextBuilder.writeln("--- END OF KNOWLEDGE BASE ---\n");
    
    return contextBuilder.toString();
  }

  String _buildConversationContext() {
    if (_conversationHistory.isEmpty) return "";
    
    final contextBuilder = StringBuffer();
    contextBuilder.writeln("--- RECENT CONVERSATION ---");
    
    // Include last 10 messages for context
    final recentMessages = _conversationHistory.length > 10 
        ? _conversationHistory.sublist(_conversationHistory.length - 10)
        : _conversationHistory;
    
    for (var message in recentMessages) {
      final speaker = message.isUser ? "User" : "Assistant";
      contextBuilder.writeln("$speaker: ${message.message}");
    }
    
    contextBuilder.writeln("--- END OF CONVERSATION ---\n");
    return contextBuilder.toString();
  }

  Future<Map<String, String>> _getUserPreferences() async {
    // You can expand this to get various user preferences
    final prefs = <String, String>{};
    
    // Example preferences
    final theme = await DatabaseHelper.instance.getPreference('preferred_theme');
    if (theme != null) prefs['Theme'] = theme;
    
    final responseStyle = await DatabaseHelper.instance.getPreference('response_style');
    if (responseStyle != null) prefs['Response Style'] = responseStyle;
    
    return prefs;
  }

  Future<void> loadConversationHistory(int sessionId) async {
    _currentSessionId = sessionId;
    _conversationHistory = await DatabaseHelper.instance.getConversationMessages(sessionId);
  }

  Future<String> suggestFactsToAdd() async {
    final facts = await DatabaseHelper.instance.getAllFacts();
    final categories = await DatabaseHelper.instance.getAllCategories();
    
    final prompt = '''
Based on the following categories and facts, suggest 3-5 useful new facts that the user might want to add to their knowledge base. Make suggestions that would complement what they already have:

Categories: ${categories.join(', ')}

Current Facts:
${facts.map((f) => "- ${f.question}: ${f.answer}").take(10).join('\n')}

Suggest new facts in this format:
1. Category | Question | Suggested Answer
2. Category | Question | Suggested Answer
etc.

Keep suggestions practical and relevant.
''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "I couldn't generate suggestions right now.";
    } catch (e) {
      return "Error generating suggestions: $e";
    }
  }

  void endCurrentConversation() async {
    if (_currentSessionId != null) {
      await DatabaseHelper.instance.endConversationSession(_currentSessionId!);
      _currentSessionId = null;
      _conversationHistory.clear();
    }
  }

  List<ConversationMessage> get conversationHistory => _conversationHistory;
  int? get currentSessionId => _currentSessionId;
}
