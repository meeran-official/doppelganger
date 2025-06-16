class Fact {
  final int? id; // Can be null if the fact is not yet saved to the DB
  final String question;
  final String answer;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> tags;
  final int importance; // 1-5 scale

  Fact({
    this.id, 
    required this.question, 
    required this.answer,
    this.category = 'General',
    DateTime? createdAt,
    this.updatedAt,
    this.tags = const [],
    this.importance = 3,
  }) : createdAt = createdAt ?? DateTime.now();

  // Helper method to convert a Fact object into a Map.
  // This is used when inserting/updating data in the database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'tags': tags.join(','),
      'importance': importance,
    };
  }

  // Helper method to create a Fact object from a Map.
  // This is used when reading data from the database.
  factory Fact.fromMap(Map<String, dynamic> map) {
    return Fact(
      id: map['id'],
      question: map['question'],
      answer: map['answer'],
      category: map['category'] ?? 'General',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
      updatedAt: map['updatedAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['updatedAt'])
          : null,
      tags: map['tags'] != null && map['tags'].isNotEmpty 
          ? map['tags'].split(',')
          : [],
      importance: map['importance'] ?? 3,
    );
  }

  Fact copyWith({
    int? id,
    String? question,
    String? answer,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tags,
    int? importance,
  }) {
    return Fact(
      id: id ?? this.id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tags: tags ?? this.tags,
      importance: importance ?? this.importance,
    );
  }
}