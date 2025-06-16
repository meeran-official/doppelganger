import '../database_helper.dart';
import '../fact_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class IntelligentVoiceService {
  late DatabaseHelper _databaseHelper;
  GenerativeModel? _model;

  IntelligentVoiceService() {
    _databaseHelper = DatabaseHelper.instance;
    _initializeAI();
  }  void _initializeAI() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash-preview-05-20',
        apiKey: apiKey,
      );
    }
  }
  // Add fact through voice input
  Future<Map<String, dynamic>> processVoiceToFact(String voiceInput) async {
    try {
      if (_model == null) {
        return {
          'success': false,
          'message': 'AI service not available. Please add facts manually.',
        };
      }

      // Add timeout for AI processing
      final Future<GenerateContentResponse> aiCall = _model!.generateContent([
        Content.text("""
Analyze this voice input and extract fact information:

Voice input: "$voiceInput"

If this sounds like a fact to store, respond with:
FACT: [question] | [answer] | [category from: Personal,Professional,Health,Learning,Goals,Ideas]

If this is not a fact to store, respond with:
CHAT: [conversational response]

Examples:
- "Remember that I work at Google" → FACT: Where do I work? | I work at Google | Professional
- "Hello how are you" → CHAT: Hello! I'm doing well, thank you for asking.
""")
      ]);

      final response = await aiCall.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('AI processing timeout'),
      );
      
      final responseText = response.text ?? '';
      
      if (responseText.startsWith('FACT:')) {
        final parts = responseText.substring(5).split('|').map((s) => s.trim()).toList();
        if (parts.length >= 3) {          final fact = Fact(
            question: parts[0],
            answer: parts[1],
            category: parts[2],
            importance: 3, // Default medium importance
            tags: ['voice-input'],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          await _databaseHelper.insertFact(fact);
          return {
            'success': true,
            'message': 'Great! I\'ve added this to your ${parts[2].toLowerCase()} facts.',
            'fact': fact,
            'isNewFact': true,
          };
        }
      }
      
      // If it's a chat response or parsing failed
      final chatResponse = responseText.startsWith('CHAT:') 
          ? responseText.substring(5).trim()
          : 'I understand, but this doesn\'t seem like something to store as a fact.';
          
      return {
        'success': true,
        'message': chatResponse,
        'isNewFact': false,
      };
      
    } catch (e) {
      return {
        'success': false,
        'message': 'I had trouble processing that. Could you try rephrasing or add it manually?',
      };
    }
  }

  // Generate intelligent response based on facts
  Future<String> generateFactBasedResponse(String query) async {
    try {
      // Search relevant facts
      final relevantFacts = await _searchRelevantFacts(query);
        if (relevantFacts.isEmpty) {
        return await _generateGeneralResponse(query);
      }

      // Generate response using facts
      if (_model == null) {
        return _generateSimpleFactResponse(relevantFacts, query);
      }

      final factsContext = relevantFacts.map((fact) =>
        "Q: ${fact.question}\nA: ${fact.answer}\nCategory: ${fact.category}\nTags: ${fact.tags.join(', ')}"
      ).join('\n\n');
      
      // Get user name from settings for personalization
      final userName = await _databaseHelper.getPreference('user_name') ?? '';
      final userGreeting = userName.isNotEmpty ? ' $userName' : '';

      final prompt = """
You are the user's personal AI assistant with access to their stored knowledge. Answer their question using ONLY the provided facts. Be conversational, helpful, and personal.

User's question: "$query"

Available facts:
$factsContext

Instructions:
- Use only information from the provided facts
- Be conversational and personal${userGreeting.isNotEmpty ? ', addressing them as$userGreeting when appropriate' : ''}
- If the facts don't contain the answer, say "I don't have that information in your stored facts"
- Reference specific facts when helpful
- Keep responses concise but informative

Response:
""";

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
        return response.text ?? _generateSimpleFactResponse(relevantFacts, query);
    } catch (e) {
      return await _generateGeneralResponse(query);
    }
  }

  // Search for relevant facts based on query
  Future<List<Fact>> _searchRelevantFacts(String query) async {
    final queryLower = query.toLowerCase();
    final allFacts = await _databaseHelper.getAllFacts();
    
    // Score and filter facts based on relevance
    final scoredFacts = allFacts.map((fact) {
      int score = 0;
      
      // Check question relevance
      if (fact.question.toLowerCase().contains(queryLower)) score += 10;
      
      // Check answer relevance
      if (fact.answer.toLowerCase().contains(queryLower)) score += 8;
      
      // Check tag relevance
      for (String tag in fact.tags) {
        if (tag.toLowerCase().contains(queryLower) || queryLower.contains(tag.toLowerCase())) {
          score += 5;
        }
      }
      
      // Check category relevance
      if (fact.category.toLowerCase().contains(queryLower)) score += 3;
      
      // Keyword matching
      final queryWords = queryLower.split(' ');
      for (String word in queryWords) {
        if (word.length > 3) {
          if (fact.question.toLowerCase().contains(word)) score += 2;
          if (fact.answer.toLowerCase().contains(word)) score += 2;
        }
      }
      
      return {'fact': fact, 'score': score};
    }).where((item) => item['score'] as int > 0).toList();
    
    // Sort by score and return top facts
    scoredFacts.sort((a, b) => (b['score'] as int).compareTo(a['score'] as int));
    
    return scoredFacts.take(3).map((item) => item['fact'] as Fact).toList();
  }
  Future<String> _generateGeneralResponse(String query) async {
    final queryLower = query.toLowerCase();
    
    // Get user name for personalized greeting
    final userName = await _databaseHelper.getPreference('user_name') ?? '';
    final greeting = userName.isNotEmpty ? ' $userName' : '';
    
    if (queryLower.contains('hello') || queryLower.contains('hi')) {
      return 'Hello$greeting! I can help you search your stored facts or add new ones through voice. What would you like to know?';
    } else if (queryLower.contains('help')) {
      return 'I can search your stored facts, add new facts from voice input, or answer questions about your knowledge base. Try asking about something you\'ve stored!';
    } else {
      return 'I don\'t have any stored facts that match your query. Would you like to add this as a new fact?';
    }
  }

  String _generateSimpleFactResponse(List<Fact> facts, String query) {
    if (facts.length == 1) {
      return "Based on your stored facts: ${facts.first.answer}";
    } else {
      return "I found ${facts.length} relevant facts about that. ${facts.first.answer}";
    }
  }

  // Voice command detection
  bool isAddFactCommand(String voiceInput) {
    final lowerInput = voiceInput.toLowerCase();
    return lowerInput.contains('remember') ||
           lowerInput.contains('add fact') ||
           lowerInput.contains('store this') ||
           lowerInput.contains('note that') ||
           lowerInput.contains('save this') ||
           lowerInput.startsWith('i learned') ||
           lowerInput.startsWith('today i') ||
           lowerInput.contains('important:');
  }

  // Enhanced suggested voice commands
  List<String> getSuggestedCommands() {
    return [
      "💬 Conversation Examples:",
      "  • What do you know about my work?",
      "  • Tell me about my health goals",
      "  • What are my learning priorities?",
      "",
      "📝 Fact Addition Examples:",
      "  • Remember that I work at Google",
      "  • Add fact: My favorite food is pizza",
      "  • I live in New York (auto-detected)",
      "  • Note that I prefer morning workouts",
      "  • My birthday is March 15th",
      "  • Store this: I want to learn Python",
      "",
      "🎯 Pro Tips:",
      "  • Use natural language - I'll detect facts automatically",
      "  • Toggle Fact Mode for dedicated fact recording",
      "  • Ask specific questions about stored knowledge",
    ];
  }
}
