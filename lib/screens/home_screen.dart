import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import '../theme/colors.dart';
import '../providers/chat_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/file_tree_provider.dart';
import '../services/llm_service.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'file_explorer_screen.dart';
import '../widgets/editor/code_editor.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showFileTree = false;
  bool _showSettings = false;
  bool _showEditor = false;
  String? _editorFilePath;
  String? _editorCode;
  String? _editorLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    await settings.load();

    if (!mounted) return;
    final llmService = LLMService(settings.llmConfig);
    final chatProvider = context.read<ChatProvider>();
    chatProvider.init(llmService);

    if (chatProvider.activeConversation == null) {
      chatProvider.createConversation();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(
                    child: _buildContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_showSettings) {
      return const SettingsScreen();
    }
    if (_showEditor) {
      return _buildEditorPanel();
    }
    return Row(
      children: [
        if (_showFileTree)
          SizedBox(
            width: 280,
            child: FileExplorerScreen(
              onFileOpened: (path, code, lang) {
                setState(() {
                  _editorFilePath = path;
                  _editorCode = code;
                  _editorLanguage = lang;
                  _showEditor = true;
                  _showFileTree = false;
                });
              },
            ),
          ),
        const Expanded(child: ChatScreen()),
      ],
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 48,
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          _buildSidebarButton(
            icon: Icons.chat_bubble_outline,
            tooltip: 'Chat',
            selected: !_showFileTree && !_showSettings && !_showEditor,
            onTap: () => setState(() {
              _showFileTree = false;
              _showSettings = false;
              _showEditor = false;
            }),
          ),
          _buildSidebarButton(
            icon: Icons.folder_outlined,
            tooltip: 'Files',
            selected: _showFileTree,
            onTap: () => setState(() {
              _showFileTree = !_showFileTree;
              _showSettings = false;
              _showEditor = false;
            }),
          ),
          _buildSidebarButton(
            icon: Icons.code,
            tooltip: 'Editor',
            selected: _showEditor,
            onTap: () => setState(() {
              _showEditor = !_showEditor;
              _showFileTree = false;
              _showSettings = false;
            }),
          ),
          _buildSidebarButton(
            icon: Icons.terminal_outlined,
            tooltip: 'Terminal',
            onTap: () {
              // Terminal placeholder
            },
          ),
          const Spacer(),
          _buildSidebarButton(
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            selected: _showSettings,
            onTap: () => setState(() {
              _showSettings = !_showSettings;
              _showFileTree = false;
              _showEditor = false;
            }),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String tooltip,
    bool selected = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.accentBlue.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.accentBlue : AppColors.textMuted,
                size: 22,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Consumer<ChatProvider>(
      builder: (context, chat, _) {
        return Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: AppColors.backgroundSurface,
            border: Border(
              bottom: BorderSide(color: AppColors.border, width: 1),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: chat.activeConversation?.id,
                    isExpanded: true,
                    dropdownColor: AppColors.backgroundCard,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    icon: const Icon(
                      Icons.keyboard_arrow_down,
                      color: AppColors.textMuted,
                      size: 18,
                    ),
                    items: chat.conversations
                        .where((c) => !c.isArchived)
                        .map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(
                        c.title,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                        .toList(),
                    onChanged: (id) {
                      if (id != null) chat.switchConversation(id);
                    },
                  ),
                ),
              ),
              const Spacer(),
              _buildIconButton(Icons.add, 'New conversation', () {
                chat.createConversation();
              }),
              const SizedBox(width: 8),
              _buildIconButton(Icons.delete_outline, 'Clear', () {
                _showDeleteConfirm(chat);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.textMuted, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _buildEditorPanel() {
    return Column(
      children: [
        Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          color: const Color(0xFF1A1B2E),
          child: Row(
            children: [
              if (_editorFilePath != null)
                _buildEditorTab(
                  _editorFilePath!.split('/').last,
                  () {
                    setState(() {
                      _showEditor = false;
                      _editorFilePath = null;
                      _editorCode = null;
                    });
                  },
                ),
              const Spacer(),
              if (_editorFilePath != null && _editorCode != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildEditorAction(
                      Icons.save_outlined,
                      'Save',
                      () => _saveCurrentFile(),
                    ),
                    const SizedBox(width: 4),
                    _buildEditorAction(
                      Icons.open_in_new,
                      'Open in explorer',
                      () {
                        setState(() {
                          _showEditor = false;
                          _showFileTree = true;
                        });
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: _editorCode != null
              ? CodeEditor(
                  code: _editorCode!,
                  language: _editorLanguage ?? 'plaintext',
                  filePath: _editorFilePath,
                  readOnly: false,
                  onChanged: (code) {
                    _editorCode = code;
                  },
                )
              : const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.code, color: AppColors.textMuted, size: 64),
                      SizedBox(height: 16),
                      Text(
                        'Open a file to start editing',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Use the file explorer or type a file path',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEditorTab(String name, VoidCallback onClose) {
    return Container(
      height: 32,
      margin: const EdgeInsets.only(right: 4, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCode,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
        border: const Border(
          top: BorderSide(color: AppColors.accentBlue, width: 2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file, color: AppColors.fileIcon, size: 12),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onClose,
            child: const Icon(Icons.close, color: AppColors.textMuted, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEditorAction(IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onTap,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            child: Icon(icon, color: AppColors.textSecondary, size: 18),
          ),
        ),
      ),
    );
  }

  Future<void> _saveCurrentFile() async {
    if (_editorFilePath == null || _editorCode == null) return;

    try {
      final file = await _toFile(_editorFilePath!);
      await file.writeAsString(_editorCode!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File saved'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<io.File> _toFile(String path) async {
    final file = io.File(path);
    if (await file.exists()) return file;
    // Try relative to current working directory
    final home = await _getHomePath();
    return io.File('$home/$path');
  }

  Future<String> _getHomePath() async {
    // Mobile: use app documents directory
    return '/storage/emulated/0/Download';
  }

  void _showDeleteConfirm(ChatProvider chat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Clear conversations?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              chat.clearAllConversations();
              chat.createConversation();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
