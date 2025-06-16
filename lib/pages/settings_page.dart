import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../database_helper.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _responseStyle = 'friendly';
  bool _voiceEnabled = true;
  bool _autoSpeak = false;
  bool _darkMode = true;
  String _userName = '';
  final TextEditingController _userNameController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  Future<void> _loadSettings() async {
    final responseStyle = await DatabaseHelper.instance.getPreference('response_style') ?? 'friendly';
    final voiceEnabled = await DatabaseHelper.instance.getPreference('voice_enabled') ?? 'true';
    final autoSpeak = await DatabaseHelper.instance.getPreference('auto_speak') ?? 'false';
    final darkMode = await DatabaseHelper.instance.getPreference('dark_mode') ?? 'true';
    final userName = await DatabaseHelper.instance.getPreference('user_name') ?? '';
    
    setState(() {
      _responseStyle = responseStyle;
      _voiceEnabled = voiceEnabled == 'true';
      _autoSpeak = autoSpeak == 'true';
      _darkMode = darkMode == 'true';
      _userName = userName;
      _userNameController.text = userName;
    });
  }  Future<void> _saveSettings() async {
    final messenger = ScaffoldMessenger.of(context);
    await DatabaseHelper.instance.setPreference('response_style', _responseStyle);
    await DatabaseHelper.instance.setPreference('voice_enabled', _voiceEnabled.toString());
    await DatabaseHelper.instance.setPreference('auto_speak', _autoSpeak.toString());
    await DatabaseHelper.instance.setPreference('dark_mode', _darkMode.toString());
    await DatabaseHelper.instance.setPreference('user_name', _userName);
    
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Settings saved successfully'),
        backgroundColor: Color(0xFF39A7FF),
      ),
    );
  }

  @override
  void dispose() {
    _userNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: FadeInDown(
          child: const Text(
            'Settings',
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
            child: TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Color(0xFF39A7FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personal Settings
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: _buildSection(
                'Personal Settings',
                [
                  _buildUserNameSetting(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // AI Settings
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 200),
              child: _buildSection(
                'AI Personality',
                [
                  _buildResponseStyleSetting(),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
              // Voice Settings
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                'Voice Settings',
                [
                  _buildSwitchSetting(
                    'Voice Input Enabled',
                    'Allow speech-to-text input',
                    _voiceEnabled,
                    (value) => setState(() => _voiceEnabled = value),
                  ),
                  _buildSwitchSetting(
                    'Auto-speak Responses',
                    'Automatically read AI responses aloud',
                    _autoSpeak,
                    (value) => setState(() => _autoSpeak = value),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Appearance Settings
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 600),
              child: _buildSection(
                'Appearance',
                [
                  _buildSwitchSetting(
                    'Dark Mode',
                    'Use dark theme (recommended)',
                    _darkMode,
                    (value) => setState(() => _darkMode = value),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Data Management
            FadeInUp(
              duration: const Duration(milliseconds: 600),
              delay: const Duration(milliseconds: 600),
              child: _buildSection(
                'Data Management',
                [
                  _buildActionSetting(
                    'Export Data',
                    'Export your facts and conversations',
                    Icons.download,
                    () => _showExportDialog(),
                  ),
                  _buildActionSetting(
                    'Clear All Data',
                    'Reset the app to factory settings',
                    Icons.warning,
                    () => _showClearDataDialog(),
                    isDestructive: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildResponseStyleSetting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Response Style',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _responseStyle,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: const Color(0xFF2C2C2E),
            style: const TextStyle(color: Colors.white),            items: const [
              DropdownMenuItem(value: 'friendly', child: Text('Friendly & Casual')),
              DropdownMenuItem(value: 'professional', child: Text('Professional')),
              DropdownMenuItem(value: 'concise', child: Text('Concise & Direct')),
              DropdownMenuItem(value: 'creative', child: Text('Creative & Playful')),
            ],
            onChanged: (value) => setState(() => _responseStyle = value!),
          ),
          const SizedBox(height: 4),
          Text(
            'How the AI should respond to your queries',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserNameSetting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Name',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _userNameController,
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: Colors.grey[500]),
              filled: true,
              fillColor: const Color(0xFF0A0A0A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Icon(
                Icons.person_outline,
                color: Colors.grey[400],
              ),
              suffixIcon: _userName.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Colors.grey[400],
                      ),
                      onPressed: () {
                        _userNameController.clear();
                        setState(() => _userName = '');
                      },
                    )
                  : null,
            ),
            style: const TextStyle(color: Colors.white),
            onChanged: (value) {
              setState(() => _userName = value.trim());
            },
          ),
          const SizedBox(height: 4),
          Text(
            'How the AI should address you in conversations',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF39A7FF),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(String title, String subtitle, IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0A0A0A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDestructive ? Colors.red : const Color(0xFF39A7FF),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: isDestructive ? Colors.red : Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Export Data', style: TextStyle(color: Colors.white)),
        content: Text(
          'This feature will be available in a future update. It will allow you to export your facts and conversation history.',
          style: TextStyle(color: Colors.grey[300]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF39A7FF))),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text('Clear All Data', style: TextStyle(color: Colors.red)),
        content: Text(
          'This will permanently delete all your facts, conversations, and settings. This action cannot be undone.',
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
              // TODO: Implement clear data functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Clear data functionality will be implemented soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
