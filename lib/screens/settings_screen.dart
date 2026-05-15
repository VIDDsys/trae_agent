import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../models/models.dart';
import '../providers/chat_provider.dart';
import '../services/llm_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _baseUrlController;
  late TextEditingController _apiKeyController;
  late TextEditingController _modelController;
  bool _isTesting = false;
  bool? _testResult;
  String? _testMessage;
  bool _obscureApiKey = true;

  @override
  void initState() {
    super.initState();
    final chatProvider = context.read<ChatProvider>();
    final config = chatProvider.isInitialized
        ? chatProvider.llmService?.config ?? LLMConfig()
        : LLMConfig();

    _baseUrlController = TextEditingController(text: config.baseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _saveConfig() async {
    final config = LLMConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );

    await config.save();

    final chatProvider = context.read<ChatProvider>();
    final service = LLMService(config);
    chatProvider.setLlmService(service);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuration saved'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testMessage = null;
    });

    final config = LLMConfig(
      baseUrl: _baseUrlController.text.trim(),
      apiKey: _apiKeyController.text.trim(),
      model: _modelController.text.trim(),
    );

    final service = LLMService(config);
    final result = await service.validateConnection();

    setState(() {
      _isTesting = false;
      _testResult = result;
      _testMessage = result
          ? '✅ Connection successful! Model "${config.effectiveModel}" is available.'
          : '❌ Connection failed. Check your API URL and key.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveConfig,
            child: const Text(
              'Save',
              style: TextStyle(color: AppColors.accentBlue, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // API Configuration section
          const _SectionTitle(title: 'API Configuration'),
          const SizedBox(height: 12),

          // Base URL
          _buildTextField(
            controller: _baseUrlController,
            label: 'API Base URL',
            hint: 'https://api.deepseek.com',
            icon: Icons.link,
          ),
          const SizedBox(height: 12),

          // API Key
          _buildTextField(
            controller: _apiKeyController,
            label: 'API Key',
            hint: 'sk-xxxxxxxxxxxxxxxx',
            icon: Icons.key,
            obscure: _obscureApiKey,
            suffix: GestureDetector(
              onTap: () => setState(() => _obscureApiKey = !_obscureApiKey),
              child: Icon(
                _obscureApiKey ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textMuted,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Model
          _buildTextField(
            controller: _modelController,
            label: 'Model',
            hint: 'deepseek-chat',
            icon: Icons.memory,
          ),
          const SizedBox(height: 12),

          // API Info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Supports OpenAI-compatible APIs: DeepSeek, OpenAI, Groq, Together, and more.',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Test & Save buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue),
                          )
                        : const Icon(Icons.wifi_tethering, size: 18),
                    label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentBlue,
                      side: const BorderSide(color: AppColors.accentBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _saveConfig,
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save & Apply'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Test result
          if (_testMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (_testResult ?? false)
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: (_testResult ?? false)
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    (_testResult ?? false) ? Icons.check_circle : Icons.error,
                    color: (_testResult ?? false) ? AppColors.success : AppColors.error,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testMessage!,
                      style: TextStyle(
                        color: (_testResult ?? false) ? AppColors.success : AppColors.error,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 32),

          // About section
          const _SectionTitle(title: 'About'),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppColors.accentBlue, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Vias',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'AI Coding Agent v0.1.0',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  'Built with Flutter on Android',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
          suffixIcon: suffix,
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }
}
