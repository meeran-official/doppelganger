import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:animate_do/animate_do.dart';
import 'database_helper.dart';
import 'manage_facts_page.dart';
import 'pages/enhanced_chat_page.dart';
import 'pages/smart_voice_chat_page.dart';
import 'pages/analytics_page.dart';
import 'pages/settings_page.dart';
import 'widgets/exquisite_ui_helpers.dart';

// The main function now needs to be async to load our API key before the app starts
Future<void> main() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Digital Doppelgänger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF39A7FF),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF39A7FF),
          brightness: Brightness.dark,
          surface: const Color(0xFF1C1C1E),
          secondary: const Color(0xFF00D4FF),
        ),        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 8,
          shadowColor: const Color(0xFF39A7FF).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),        appBarTheme: const AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _textController = TextEditingController();  String _response = "AI response will appear here...";
  bool _isLoading = false;
  String _userName = "User";

  String _weatherGreeting = "Welcome! Getting ready for you...";
  @override
  void initState() {
    super.initState();
    // Set a default greeting immediately to prevent blank UI
    setState(() {
      _weatherGreeting = "Welcome! Loading your personalized experience...";
    });
    _loadInitialData();
  }
  Future<void> _loadInitialData() async {
    // Load the name from database settings
    final savedName = await DatabaseHelper.instance.getPreference('user_name');

    if (savedName == null || savedName.isEmpty) {
      // If no name is saved, show the dialog to ask for it.
      // The 'await' ensures we wait for the user to enter a name.
      await _showNameInputDialog();
    } else {
      // If a name was found, update our state
      setState(() {
        _userName = savedName;
      });
    }
    // After getting the name, fetch the weather
    _fetchWeatherAndLocation();
  }

  Future<void> _showNameInputDialog() async {
    final nameController = TextEditingController();
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must enter a name
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Welcome!'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "How should I call you?"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Save'),              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  final navigator = Navigator.of(context);
                  await DatabaseHelper.instance.setPreference('user_name', nameController.text);
                  setState(() {
                    _userName = nameController.text;
                  });
                  navigator.pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // This is the final, truly cross-platform version of the function
  Future<void> _fetchWeatherAndLocation() async {

    if (kIsWeb) {
      setState(() {
        _weatherGreeting = "Use the mobile app for the live weather feature!";
      });
      return; // Exit the function immediately.
    }    String weatherUrl;
    // Get weather API key from environment variables
    final weatherApiKey = dotenv.env['WEATHER_API_KEY'];
    if (weatherApiKey == null) {
      setState(() {
        _weatherGreeting = "Welcome, $_userName! Weather API key not configured.";
      });
      return;
    }



    // We use the special 'kIsWeb' constant to check for web FIRST.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // For desktop, use a hardcoded location
      const locationQuery = "Chennai";
      weatherUrl =
      'http://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=$locationQuery';
    }    // If it's not web and not desktop, it must be a mobile device.
    else {
      try {
        // This block contains the location logic that only works on mobile
        Location location = Location();
        bool serviceEnabled;
        PermissionStatus permissionGranted;
        LocationData locationData;

        serviceEnabled = await location.serviceEnabled();
        if (!serviceEnabled) {
          serviceEnabled = await location.requestService();
          if (!serviceEnabled) {
            setState(() => _weatherGreeting = "Welcome, $_userName! Please enable location services for weather updates.");
            return;
          }
        }

        permissionGranted = await location.hasPermission();
        if (permissionGranted == PermissionStatus.denied) {
          permissionGranted = await location.requestPermission();
          if (permissionGranted != PermissionStatus.granted) {
            setState(() => _weatherGreeting = "Welcome, $_userName! Location permission needed for weather updates.");
            return;
          }
        }

        locationData = await location.getLocation();
        final lat = locationData.latitude;
        final lon = locationData.longitude;

        if (lat == null || lon == null) {
          setState(() => _weatherGreeting = "Welcome, $_userName! Could not get your location.");
          return;
        }
        weatherUrl =
            'http://api.weatherapi.com/v1/current.json?key=$weatherApiKey&q=$lat,$lon';
      } catch (e) {
        // If location service fails, fallback to a default greeting
        setState(() => _weatherGreeting = "Welcome, $_userName! Have a great day!");
        if (kDebugMode) print("Location error: $e");
        return;
      }
    }

    // The rest of the function (making the API call) is the same for all platforms
    try {
      final response = await http.get(Uri.parse(weatherUrl));
      if (response.statusCode == 200) {
        final weatherData = jsonDecode(response.body);
        final cityName = weatherData['location']['name'];
        final temp = weatherData['current']['temp_c'].round();
        final description = weatherData['current']['condition']['text'];
        setState(() {
          _weatherGreeting = "Good morning, $_userName. It's $temp°C and $description in $cityName.";
        });
      } else {
        throw Exception('Failed to load weather data');
      }    } catch (e) {
      setState(() => _weatherGreeting = "Could not fetch weather.");
      if (kDebugMode) print("Weather error: $e");
    }
  }

  // Refresh user name when returning from settings
  Future<void> _refreshUserName() async {
    final savedName = await DatabaseHelper.instance.getPreference('user_name');
    if (savedName != null && savedName != _userName) {
      setState(() {
        _userName = savedName;
      });
      // Also refresh the weather greeting to use the new name
      _fetchWeatherAndLocation();
    }
  }

  // This is where all the magic happens!
  // This is the updated, final version of our logic function
  Future<void> _generateResponse() async {
    // First, check if the user actually typed something
    if (_textController.text.trim().isEmpty) {
      // Show a small popup message if the text field is empty
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a query.')));
      return;
    }

    // Tell the UI to start loading
    setState(() {
      _isLoading = true;
      _response = ""; // Clear the previous response
    });    try {
      // 1. GET USER NAME FROM SETTINGS
      final userName = await DatabaseHelper.instance.getPreference('user_name') ?? 'there';
      
      // 2. FETCH FACTS FROM DATABASE (The New Part!)
      // This gets all the facts you saved on the other screen.
      final facts = await DatabaseHelper.instance.getAllFacts();

      // 3. BUILD THE CONTEXT STRING
      // We create a detailed prompt that "trains" the AI for this one conversation.
      final contextBuilder = StringBuffer();
      contextBuilder.writeln(
          "IMPORTANT: You are a helpful AI assistant for a person${userName.isNotEmpty ? ' named $userName' : ''}. Your ONLY source of knowledge is the following set of facts. Answer the user's question based *only* on these facts. If the answer is not contained in the facts, you MUST say 'I do not have that information.'. Do not use any external knowledge.\n");
      contextBuilder.writeln("--- FACTS ---");
      for (var fact in facts) {
        contextBuilder.writeln("Question: ${fact.question}");
        contextBuilder.writeln("Answer: ${fact.answer}");
      }
      contextBuilder.writeln("--- END OF FACTS ---\n");

      // 3. COMBINE CONTEXT WITH THE USER'S QUERY
      final finalPrompt =
          '${contextBuilder.toString()}User\'s Question: ${_textController.text}';      // --- THE REST OF THE CODE IS THE SAME AS BEFORE ---
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null) {
        throw Exception("Gemini API Key not found in .env file");
      }

      final model =
      GenerativeModel(model: 'gemini-2.5-flash-preview-05-20', apiKey: apiKey);

      // Send the big, context-rich prompt to the AI
      final response = await model.generateContent([Content.text(finalPrompt)]);

      // Update the UI with the final response
      setState(() {
        _response = response.text ?? "Could not get a response.";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _response = "Error: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF1C1C1E),
              const Color(0xFF0A0A0A),
            ],
          ),
        ),        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [// Header Section
                FadeInDown(
                  duration: const Duration(milliseconds: 800),
                  child: Column(
                    children: [
                      // App bar with menu
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(
                                Icons.menu,
                                color: Color(0xFF39A7FF),
                                size: 28,
                              ),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.refresh,
                              color: Color(0xFF39A7FF),
                              size: 28,
                            ),
                            onPressed: _fetchWeatherAndLocation,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Welcome greeting
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF39A7FF).withValues(alpha: 0.2),
                              const Color(0xFF00D4FF).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF39A7FF).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.psychology,
                              size: 40,
                              color: Color(0xFF39A7FF),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Digital Doppelgänger',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _weatherGreeting,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16, 
                                color: Colors.grey[300],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),                // Quick Actions
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 200),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              'Enhanced Chat',
                              Icons.chat_bubble_outline,
                              'Voice & memory enabled',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EnhancedChatPage(
                                    userName: _userName,
                                    weatherInfo: _weatherGreeting,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildQuickActionCard(
                              'Manage Facts',
                              Icons.library_books,
                              'Organize knowledge',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ManageFactsPage(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickActionCard(
                              'Analytics',
                              Icons.analytics,
                              'Insights & stats',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AnalyticsPage(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(                            child: _buildQuickActionCard(
                              'Voice Chat',
                              Icons.mic,
                              'AI + Facts powered',
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SmartVoiceChatPage(
                                    userName: _userName,
                                    weatherInfo: _weatherGreeting,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),                // Quick Chat Section
                Expanded(
                  child: FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,                          colors: [
                            const Color(0xFF1C1C1E).withValues(alpha: 0.9),
                            const Color(0xFF2C2C2E).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF39A7FF).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF39A7FF).withValues(alpha: 0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF39A7FF).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.chat_bubble_outline,
                                  color: const Color(0xFF39A7FF),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Quick Chat',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const Spacer(),
                              if (_response.isNotEmpty)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _response = '';
                                      _textController.clear();
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear,
                                    color: Colors.grey[400],
                                    size: 18,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 30,
                                    minHeight: 30,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2C2C2E),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                ),
                              ),
                              child: _isLoading
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: const Color(0xFF39A7FF),
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Thinking...',
                                            style: TextStyle(
                                              color: Colors.grey[400],
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )                                  : SingleChildScrollView(
                                      child: Text(
                                        _response.isEmpty 
                                            ? '💬 Ask me anything! I can help with quick questions, provide information, or assist with various topics.'
                                            : _response,
                                        style: TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                          color: _response.isEmpty ? Colors.grey[500] : Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),const SizedBox(height: 16),

                // Enhanced Input Section
                FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(                        colors: [
                          const Color(0xFF39A7FF).withValues(alpha: 0.2),
                          const Color(0xFF00D4FF).withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(26),
                            ),
                            child: TextField(
                              controller: _textController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.transparent,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(26),
                                  borderSide: BorderSide.none,
                                ),
                                hintText: '💭 Ask me anything...',
                                hintStyle: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 16,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 16,
                                ),
                                prefixIcon: Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.grey[500],
                                  size: 20,
                                ),
                              ),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              onSubmitted: (_) => _isLoading ? null : _generateResponse(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF39A7FF),
                                const Color(0xFF00D4FF),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF39A7FF).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            onPressed: _isLoading ? null : _generateResponse,
                            icon: Icon(
                              _isLoading ? Icons.hourglass_empty : Icons.send_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                  ),                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Stack(
        children: [
          // Voice Chat FAB
          Positioned(
            bottom: 80,
            right: 0,            child: ExquisiteUIHelpers.buildFloatingActionButton(
              heroTag: "voice_chat_fab", // Unique hero tag
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SmartVoiceChatPage(
                    userName: _userName,
                    weatherInfo: _weatherGreeting,
                  ),
                ),
              ),
              icon: Icons.mic,
              tooltip: 'Voice Chat',
              backgroundColor: const Color(0xFF4285F4),
            ),
          ),
          // Main FAB for quick input
          Positioned(
            bottom: 0,
            right: 0,
            child: ExquisiteUIHelpers.buildFloatingActionButton(
              heroTag: "quick_send_fab", // Unique hero tag
              onPressed: () {
                if (_textController.text.isNotEmpty && !_isLoading) {
                  _generateResponse();
                }
              },
              icon: _isLoading ? Icons.hourglass_empty : Icons.send,
              tooltip: 'Send Quick Message',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF39A7FF),
                  const Color(0xFF00D4FF),
                ],
              ),
            ),            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // User Avatar with Initials
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getUserInitials(_userName),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Text Column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.psychology,
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Digital Doppelgänger',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _userName.isNotEmpty ? 'Welcome back, $_userName!' : 'Welcome!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildDrawerItem(
                  icon: Icons.home,
                  title: 'Home',
                  onTap: () => Navigator.pop(context),
                ),
                _buildDrawerItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'Enhanced Chat',
                  subtitle: 'Voice & memory enabled',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EnhancedChatPage(
                          userName: _userName,
                          weatherInfo: _weatherGreeting,
                        ),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.library_books,
                  title: 'Manage Facts',
                  subtitle: 'Organize your knowledge',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ManageFactsPage(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Insights & statistics',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AnalyticsPage(),
                      ),
                    );
                  },
                ),
                const Divider(color: Colors.grey),                  _buildDrawerItem(
                  icon: Icons.settings,
                  title: 'Settings',
                  subtitle: 'App preferences',
                  onTap: () async {
                    Navigator.pop(context);
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsPage(),
                      ),
                    );
                    // Refresh user name after returning from settings
                    await _refreshUserName();
                  },
                ),
                _buildDrawerItem(
                  icon: Icons.info_outline,
                  title: 'About',
                  onTap: () {
                    Navigator.pop(context);
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Version 2.0.0 - Enhanced',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF39A7FF)),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            )
          : null,
      onTap: onTap,
      hoverColor: const Color(0xFF39A7FF).withValues(alpha: 0.1),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Row(
          children: [
            const Icon(Icons.psychology, color: Color(0xFF39A7FF)),
            const SizedBox(width: 8),
            const Text('About', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Digital Doppelgänger v2.0',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your enhanced AI companion with memory, voice interaction, and intelligent fact management.',
              style: TextStyle(color: Colors.grey[300]),
            ),
            const SizedBox(height: 16),
            const Text(
              'Features:',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...([
              '• Conversation memory',
              '• Voice input/output',
              '• Enhanced fact management',
              '• Analytics & insights',
              '• Beautiful dark theme',
            ].map((feature) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                feature,
                style: TextStyle(color: Colors.grey[300]),
              ),
            ))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF39A7FF))),
          ),
        ],
      ),
    );
  }

  String _getUserInitials(String name) {
    if (name.isEmpty) return 'U';
    
    List<String> words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }
  Widget _buildQuickActionCard(String title, IconData icon, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF2C2C2E),
              const Color(0xFF1C1C1E),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF39A7FF).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39A7FF).withValues(alpha: 0.1),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF39A7FF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: const Color(0xFF39A7FF),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}