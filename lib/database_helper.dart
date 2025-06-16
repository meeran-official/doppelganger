import 'package:doppelganger_flutter/fact_model.dart';
import 'package:doppelganger_flutter/models/conversation_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  // This is the Singleton pattern. It ensures that only one instance
  // of DatabaseHelper exists throughout the app's lifecycle.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // This will be our single database connection.
  static Database? _database;

  // This is the getter for our database. If it doesn't exist yet,
  // it will be initialized.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // This method sets up the connection to the database file.
  _initDatabase() async {
    String path = join(await getDatabasesPath(), 'doppelganger_database.db');
    return await openDatabase(
      path,
      version: 2, // Increased version for schema changes
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // This method creates our tables.
  Future _onCreate(Database db, int version) async {
    // Enhanced facts table
    await db.execute('''
      CREATE TABLE facts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question TEXT NOT NULL,
        answer TEXT NOT NULL,
        category TEXT DEFAULT 'General',
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER,
        tags TEXT,
        importance INTEGER DEFAULT 3
      )
      ''');

    // Conversation sessions table
    await db.execute('''
      CREATE TABLE conversation_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        startTime INTEGER NOT NULL,
        endTime INTEGER
      )
      ''');

    // Conversation messages table
    await db.execute('''
      CREATE TABLE conversation_messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId INTEGER NOT NULL,
        message TEXT NOT NULL,
        isUser INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        category TEXT,
        context TEXT,
        FOREIGN KEY (sessionId) REFERENCES conversation_sessions (id)
      )
      ''');

    // User preferences table
    await db.execute('''
      CREATE TABLE user_preferences (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updatedAt INTEGER NOT NULL
      )
      ''');
  }

  // Handle database upgrades
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns to existing facts table
      await db.execute('ALTER TABLE facts ADD COLUMN category TEXT DEFAULT "General"');
      await db.execute('ALTER TABLE facts ADD COLUMN createdAt INTEGER DEFAULT ${DateTime.now().millisecondsSinceEpoch}');
      await db.execute('ALTER TABLE facts ADD COLUMN updatedAt INTEGER');
      await db.execute('ALTER TABLE facts ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE facts ADD COLUMN importance INTEGER DEFAULT 3');
      
      // Create new tables
      await db.execute('''
        CREATE TABLE conversation_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          startTime INTEGER NOT NULL,
          endTime INTEGER
        )
        ''');

      await db.execute('''
        CREATE TABLE conversation_messages (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sessionId INTEGER NOT NULL,
          message TEXT NOT NULL,
          isUser INTEGER NOT NULL,
          timestamp INTEGER NOT NULL,
          category TEXT,
          context TEXT,
          FOREIGN KEY (sessionId) REFERENCES conversation_sessions (id)
        )
        ''');

      await db.execute('''
        CREATE TABLE user_preferences (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updatedAt INTEGER NOT NULL
        )
        ''');
    }
  }
  // --- CRUD Methods ---

  // FACTS METHODS
  Future<void> insertFact(Fact fact) async {
    final db = await instance.database;
    await db.insert(
      'facts',
      fact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Fact>> getAllFacts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'facts',
      orderBy: 'importance DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => Fact.fromMap(maps[i]));
  }

  Future<List<Fact>> getFactsByCategory(String category) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'facts',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'importance DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => Fact.fromMap(maps[i]));
  }

  Future<List<String>> getAllCategories() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT DISTINCT category FROM facts ORDER BY category',
    );
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<void> updateFact(Fact fact) async {
    final db = await instance.database;
    await db.update(
      'facts',
      fact.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [fact.id],
    );
  }

  Future<void> deleteFact(int id) async {
    final db = await instance.database;
    await db.delete(
      'facts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Fact>> searchFacts(String query) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'facts',
      where: 'question LIKE ? OR answer LIKE ? OR tags LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'importance DESC, createdAt DESC',
    );
    return List.generate(maps.length, (i) => Fact.fromMap(maps[i]));
  }

  // CONVERSATION METHODS
  Future<int> createConversationSession(String title) async {
    final db = await instance.database;
    return await db.insert('conversation_sessions', {
      'title': title,
      'startTime': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addConversationMessage(int sessionId, String message, bool isUser, {String? category, String? context}) async {
    final db = await instance.database;
    await db.insert('conversation_messages', {
      'sessionId': sessionId,
      'message': message,
      'isUser': isUser ? 1 : 0,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'category': category,
      'context': context,
    });
  }

  Future<List<ConversationMessage>> getConversationMessages(int sessionId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversation_messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );
    return List.generate(maps.length, (i) => ConversationMessage.fromMap(maps[i]));
  }

  Future<List<ConversationSession>> getConversationSessions() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'conversation_sessions',
      orderBy: 'startTime DESC',
    );
    return List.generate(maps.length, (i) => ConversationSession.fromMap(maps[i]));
  }

  Future<void> endConversationSession(int sessionId) async {
    final db = await instance.database;
    await db.update(
      'conversation_sessions',
      {'endTime': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  // USER PREFERENCES METHODS
  Future<void> setPreference(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'user_preferences',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreference(String key) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'user_preferences',
      where: 'key = ?',
      whereArgs: [key],
    );
    return maps.isNotEmpty ? maps.first['value'] : null;
  }

  // ANALYTICS METHODS
  Future<Map<String, dynamic>> getAnalytics() async {
    final db = await instance.database;
    
    final factCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM facts')) ?? 0;
    final conversationCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM conversation_sessions')) ?? 0;
    final messageCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM conversation_messages')) ?? 0;
    
    final categoryStats = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM facts 
      GROUP BY category 
      ORDER BY count DESC
    ''');
    
    return {
      'totalFacts': factCount,
      'totalConversations': conversationCount,
      'totalMessages': messageCount,
      'categoryBreakdown': categoryStats,
    };
  }
}