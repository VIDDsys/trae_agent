import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../models/models.dart';
import '../providers/settings_provider.dart';
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
  late TextEditingController _customHeadersController;
  double _temperature = 0.7;
  int _maxTokens = 4096;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;
  List<String> _availableModels = [];

  @override
  void initState() {
    super.initState();
    final config = context.read<SettingsProvider>().llmConfig;
    _baseUrlController = TextEditingController(text: config.baseUrl);
    _apiKeyController = TextEditingController(text: config.apiKey);
    _modelController = TextEditingController(text: config.model);
    _customHeadersController = TextEditingController(text: config.customHeaders ?? '');
    _temperature = config.temperature;
    _maxTokens = config.maxTokens;
  }

  @override
  void dispose() {
    _baseUrlController.dispose();
    _apiKeyController.dispose();
    _modelController.dispose();
    _customHeadersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundDark,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          const Text(
            'Settings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // API Configuration Section
          _sectionHeader('LLM API Configuration'),
          const SizedBox(height: 16),

          // Preset providers
          _buildPresetRow(),
          const SizedBox(height: 16),

          // Base URL
          _buildTextField(
            label: 'API Base URL',
            hint: 'https://api.deepseek.com',
            controller: _baseUrlController,
            onChanged: (_) => _saveField('baseUrl'),
          ),
          const SizedBox(height: 12),

          // API Key
          _buildTextField(
            label: 'API Key',
            hint: 'sk-xxxxxxxxxxxxxxxx',
            controller: _apiKeyController,
            obscureText: true,
            onChanged: (_) => _saveField('apiKey'),
          ),
          const SizedBox(height: 12),

          // Model
          _buildModelField(),
          const SizedBox(height: 16),

          // Temperature slider
          _buildSlider(
            label: 'Temperature',
            value: _temperature,
            min: 0.0,
            max: 2.0,
            divisions: 40,
            displayValue: _temperature.toStringAsFixed(1),
            onChanged: (v) {
              setState(() => _temperature = v);
              context.read<SettingsProvider>().updateTemperature(v);
            },
          ),
          const SizedBox(height: 12),

          // Max tokens
          _buildSlider(
            label: 'Max Tokens',
            value: _maxTokens.toDouble(),
            min: 256,
            max: 32768,
            divisions: 63,
            displayValue: _maxTokens.toString(),
            onChanged: (v) {
              setState(() => _maxTokens = v.toInt());
              context.read<SettingsProvider>().updateMaxTokens(v.toInt());
            },
          ),
          const SizedBox(height: 12),

          // Custom headers
          _buildTextField(
            label: 'Custom Headers (JSON)',
            hint: '{"X-Custom-Header": "value"}',
            controller: _customHeadersController,
            maxLines: 3,
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),

          // Test connection button
          _buildTestButton(),
          if (_testResult != null) _buildTestResult(),

          const SizedBox(height: 32),
          const Divider(color: AppColors.divider),

          // App Settings Section
          _sectionHeader('App Settings'),
          const SizedBox(height: 16),

          // Project path
          _buildProjectPathField(),
          const SizedBox(height: 12),

          // Font size
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => _buildSlider(
              label: 'Font Size',
              value: settings.settings.fontSize.toDouble(),
              min: 10,
              max: 24,
              divisions: 14,
              displayValue: settings.settings.fontSize.toString(),
              onChanged: (v) => settings.updateFontSize(v.toInt()),
            ),
          ),
          const SizedBox(height: 12),

          // Code wrap toggle
          Consumer<SettingsProvider>(
            builder: (context, settings, _) => SwitchListTile(
              title: const Text('Wrap Code', style: TextStyle(color: AppColors.textPrimary)),
              subtitle: const Text('Enable line wrapping in code blocks', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              value: settings.settings.codeWrap,
              activeColor: AppColors.accentBlue,
              onChanged: (_) => settings.toggleCodeWrap(),
            ),
          ),

          const SizedBox(height: 16),
          Text(
            'Powered by ${context.read<SettingsProvider>().llmConfig.model}',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Trae Agent v0.1.0',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.accentBlue,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildPresetRow() {
    final presets = [
      ('DeepSeek', 'https://api.deepseek.com', 'deepseek-chat'),
      ('OpenAI', 'https://api.openai.com/v1', 'gpt-4o'),
      ('Groq', 'https://api.groq.com/openai/v1', 'llama-3.1-70b'),
      ('Together', 'https://api.together.xyz/v1', 'mistralai/Mixtral-8x7B-Instruct-v0.1'),
      ('Local', 'http://localhost:11434/v1', 'qwen2.5-coder'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: presets.map((p) {
        final selected = _baseUrlController.text == p.$1;
        return ActionChip(
          label: Text(p.$1, style: TextStyle(
            color: selected ? AppColors.accentBlue : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          )),
          backgroundColor: selected ? AppColors.accentBlue.withOpacity(0.15) : AppColors.backgroundHover,
          side: BorderSide(
            color: selected ? AppColors.accentBlue : AppColors.border,
          ),
          onPressed: () {
            _baseUrlController.text = p.$2;
            _modelController.text = p.$3;
            setState(() {});
            _saveField('baseUrl');
            _saveField('model');
          },
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
    int maxLines = 1,
    required void Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          maxLines: maxLines,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildModelField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Model', style: TextStyle(
          color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _modelController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'deepseek-chat',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
                onChanged: (_) => _saveField('model'),
              ),
            ),
            if (_availableModels.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.refresh, color: AppColors.textMuted, size: 20),
                color: AppColors.backgroundCard,
                onSelected: (model) {
                  _modelController.text = model;
                  _saveField('model');
                  setState(() {});
                },
                itemBuilder: (ctx) => _availableModels.map((m) =>
                  PopupMenuItem(value: m, child: Text(m, style: const TextStyle(fontSize: 13)))
                ).toList(),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
            )),
            const Spacer(),
            Text(displayValue, style: const TextStyle(
              color: AppColors.accentBlue, fontSize: 13, fontWeight: FontWeight.w600,
            )),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.accentBlue,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.accentBlue,
            overlayColor: AppColors.accentBlue.withOpacity(0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isTesting ? null : _testConnection,
        icon: _isTesting
            ? const SizedBox(
          width: 16, height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
        )
            : const Icon(Icons.wifi_find),
        label: Text(_isTesting ? 'Testing...' : 'Test Connection'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildTestResult() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (_testSuccess == true ? AppColors.success : AppColors.error).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (_testSuccess == true ? AppColors.success : AppColors.error).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _testSuccess == true ? Icons.check_circle : Icons.error,
            color: _testSuccess == true ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _testResult!,
              style: TextStyle(
                color: _testSuccess == true ? AppColors.success : AppColors.error,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectPathField() {
    final settings = context.read<SettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Default Project Path', style: TextStyle(
          color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500,
        )),
        const SizedBox(height: 6),
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            // TODO: Open file picker for directory selection
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder, color: AppColors.textMuted, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    settings.settings.defaultProjectPath ?? 'Tap to select project folder',
                    style: TextStyle(
                      color: settings.settings.defaultProjectPath != null
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _saveField(String field) {
    final settings = context.read<SettingsProvider>();
    switch (field) {
      case 'baseUrl':
        settings.updateBaseUrl(_baseUrlController.text);
      case 'apiKey':
        settings.updateApiKey(_apiKeyController.text);
      case 'model':
        settings.updateModel(_modelController.text);
    }
    // Update LLM service — dispose old, create new
    final chatProvider = context.read<ChatProvider>();
    final newService = LLMService(settings.llmConfig);
    chatProvider.init(newService);
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final config = LLMConfig(
      baseUrl: _baseUrlController.text,
      apiKey: _apiKeyController.text,
      model: _modelController.text,
    );

    final service = LLMService(config);
    final success = await service.validateConnection();
    service.dispose();

    setState(() {
      _isTesting = false;
      if (success) {
        _testResult = 'Connection successful! Model: ${config.effectiveModel}';
        _testSuccess = true;
      } else {
        _testResult = 'Connection failed. Check URL and API key.';
        _testSuccess = false;
      }
    });
  }
}
