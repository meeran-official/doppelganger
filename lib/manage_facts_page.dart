import 'package:doppelganger_flutter/database_helper.dart';
import 'package:doppelganger_flutter/fact_model.dart';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';

class ManageFactsPage extends StatefulWidget {
  const ManageFactsPage({super.key});

  @override
  State<ManageFactsPage> createState() => _ManageFactsPageState();
}

class _ManageFactsPageState extends State<ManageFactsPage> with TickerProviderStateMixin {
  List<Fact> _factsList = [];
  List<String> _categories = ['General'];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshFactsList();
    _loadCategories();
  }

  Future<void> _refreshFactsList() async {
    setState(() => _isLoading = true);
    
    List<Fact> facts;
    if (_selectedCategory == 'All') {
      facts = await DatabaseHelper.instance.getAllFacts();
    } else {
      facts = await DatabaseHelper.instance.getFactsByCategory(_selectedCategory);
    }
    
    if (mounted) {
      setState(() {
        _factsList = facts;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCategories() async {
    final categories = await DatabaseHelper.instance.getAllCategories();
    setState(() {
      _categories = ['All', 'General', ...categories];
    });
  }

  Future<void> _searchFacts(String query) async {
    if (query.isEmpty) {
      _refreshFactsList();
      return;
    }
    
    setState(() => _isLoading = true);
    final facts = await DatabaseHelper.instance.searchFacts(query);
    setState(() {
      _factsList = facts;
      _isLoading = false;
    });
  }
  Future<void> _deleteFact(int id) async {
    final messenger = ScaffoldMessenger.of(context);
    await DatabaseHelper.instance.deleteFact(id);
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Fact deleted successfully'),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
      ),
    );
    _refreshFactsList();
    _loadCategories();
  }

  Future<void> _showAddFactDialog({Fact? editingFact}) async {
    final questionController = TextEditingController(text: editingFact?.question ?? '');
    final answerController = TextEditingController(text: editingFact?.answer ?? '');
    final tagsController = TextEditingController(text: editingFact?.tags.join(', ') ?? '');
    String selectedCategory = editingFact?.category ?? 'General';
    int importance = editingFact?.importance ?? 3;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1C1C1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    editingFact == null ? Icons.add_circle_outline : Icons.edit,
                    color: const Color(0xFF39A7FF),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    editingFact == null ? 'Add New Fact' : 'Edit Fact',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Question field
                    TextField(
                      controller: questionController,
                      decoration: InputDecoration(
                        labelText: "Question / Key",
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Answer field
                    TextField(
                      controller: answerController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: "Answer / Value",
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category dropdown
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: "Category",
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      dropdownColor: const Color(0xFF2C2C2E),
                      style: const TextStyle(color: Colors.white),
                      items: _categories.where((cat) => cat != 'All').map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Tags field
                    TextField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: "Tags (comma separated)",
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        labelStyle: TextStyle(color: Colors.grey[400]),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    
                    // Importance slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [                        Text(
                          'Importance: $importance/5',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        Slider(
                          value: importance.toDouble(),
                          min: 1,
                          max: 5,
                          divisions: 4,
                          activeColor: const Color(0xFF39A7FF),
                          onChanged: (value) {
                            setDialogState(() {
                              importance = value.round();
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF39A7FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(editingFact == null ? 'Add' : 'Update'),                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final question = questionController.text.trim();
                    final answer = answerController.text.trim();
                    
                    if (question.isNotEmpty && answer.isNotEmpty) {
                      final tags = tagsController.text
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList();
                      
                      final fact = Fact(
                        id: editingFact?.id,
                        question: question,
                        answer: answer,
                        category: selectedCategory,
                        tags: tags,
                        importance: importance,
                        createdAt: editingFact?.createdAt ?? DateTime.now(),
                      );
                      
                      if (editingFact == null) {
                        await DatabaseHelper.instance.insertFact(fact);
                      } else {
                        await DatabaseHelper.instance.updateFact(fact);
                      }
                      
                      navigator.pop();
                      _refreshFactsList();
                      _loadCategories();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: FadeInDown(
          child: const Text(
            'Knowledge Base',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        actions: [
          FadeInDown(
            delay: const Duration(milliseconds: 200),
            child: IconButton(
              icon: const Icon(Icons.analytics_outlined, color: Color(0xFF39A7FF)),
              onPressed: _showAnalytics,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search facts...',
                      hintStyle: TextStyle(color: Colors.grey[500]),
                      prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                      filled: true,
                      fillColor: const Color(0xFF2C2C2E),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                    onChanged: _searchFacts,
                  ),
                  const SizedBox(height: 16),
                  
                  // Category filter
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        final isSelected = category == _selectedCategory;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                              _refreshFactsList();
                            },
                            backgroundColor: const Color(0xFF2C2C2E),
                            selectedColor: const Color(0xFF39A7FF),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[400],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
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
          
          // Facts list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF39A7FF),
                    ),
                  )
                : _factsList.isEmpty
                    ? FadeInUp(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lightbulb_outline,
                                size: 80,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No facts yet!',
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the + button to add your first fact',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _factsList.length,
                        itemBuilder: (context, index) {
                          final fact = _factsList[index];
                          return FadeInUp(
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            child: _buildFactCard(fact, index),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FadeInUp(
        delay: const Duration(milliseconds: 800),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF39A7FF), Color(0xFF00D4FF)],
            ),
            shape: BoxShape.circle,
          ),
          child: FloatingActionButton(
            onPressed: () => _showAddFactDialog(),
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildFactCard(Fact fact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          color: const Color(0xFF39A7FF).withValues(alpha: 0.2),
        ),
      ),      child: ExpansionTile(
        title: Text(
          fact.question,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _buildCategoryChip(fact.category),
                const SizedBox(width: 8),
                _buildImportanceIndicator(fact.importance),
              ],
            ),
            if (fact.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: fact.tags.take(3).map((tag) => _buildTag(tag)).toList(),
              ),
            ],
          ],        ),
        iconColor: const Color(0xFF39A7FF),
        collapsedIconColor: Colors.grey[400],
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    fact.answer,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Created: ${_formatDate(fact.createdAt)}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Color(0xFF39A7FF)),
                          onPressed: () => _showAddFactDialog(editingFact: fact),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _showDeleteConfirmation(fact),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF39A7FF).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        category,
        style: const TextStyle(
          color: Color(0xFF39A7FF),
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildImportanceIndicator(int importance) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < importance ? Icons.star : Icons.star_border,
          color: const Color(0xFFFFD700),
          size: 16,
        );
      }),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: Colors.grey[300],
          fontSize: 10,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation(Fact fact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Delete Fact?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "${fact.question}"?',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[400])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFact(fact.id!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
  void _showAnalytics() async {
    final analytics = await DatabaseHelper.instance.getAnalytics();
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: Row(
          children: [
            Icon(Icons.analytics, color: const Color(0xFF39A7FF)),
            const SizedBox(width: 8),
            const Text('Analytics', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalyticRow('Total Facts', '${analytics['totalFacts']}'),
            _buildAnalyticRow('Conversations', '${analytics['totalConversations']}'),
            _buildAnalyticRow('Messages', '${analytics['totalMessages']}'),
            const SizedBox(height: 16),
            const Text(
              'Categories:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...((analytics['categoryBreakdown'] as List).map((cat) =>
              _buildAnalyticRow(cat['category'], '${cat['count']}'))),
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

  Widget _buildAnalyticRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[300])),
          Text(value, style: const TextStyle(color: Color(0xFF39A7FF))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}