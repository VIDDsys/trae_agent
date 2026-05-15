import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../models/models.dart';
import '../providers/file_tree_provider.dart';

import '../providers/chat_provider.dart';
import '../widgets/editor/syntax_highlighter.dart';

typedef FileOpenedCallback = void Function(String path, String content, String language);

class FileExplorerScreen extends StatelessWidget {
  final FileOpenedCallback? onFileOpened;

  const FileExplorerScreen({super.key, this.onFileOpened});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fileTreeBg,
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Divider
          const Divider(height: 1, color: AppColors.border),
          // Content
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<FileTreeProvider>(
      builder: (context, provider, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Icon(Icons.folder_outlined, color: AppColors.folderIcon, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.rootPath?.split('/').last ?? 'No project',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Open project button
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => _openProject(context),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.create_new_folder_outlined,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Refresh
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => provider.refresh(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.refresh,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    return Consumer<FileTreeProvider>(
      builder: (context, provider, _) {
        if (!provider.hasProject) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open,
                  color: AppColors.textMuted,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No project open',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _openProject(context),
                  child: const Text('Open a project folder'),
                ),
              ],
            ),
          );
        }

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.accentBlue,
              strokeWidth: 2,
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.only(top: 4),
          children: [
            for (final item in provider.files)
              _buildFileItem(context, item, provider, 0),
          ],
        );
      },
    );
  }

  Widget _buildFileItem(
    BuildContext context,
    FileItem item,
    FileTreeProvider provider,
    int depth,
  ) {
    final isSelected = provider.selectedFile?.path == item.path;
    final isExpanded = provider.isExpanded(item.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (item.isDirectory) {
              provider.toggleExpand(item.path);
            } else {
              provider.openFile(item).then((_) {
                if (onFileOpened != null && provider.fileContent != null) {
                  final lang = languageFromExtension(item.extension);
                  onFileOpened!(item.path, provider.fileContent!, lang);
                }
              });
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 8.0 + depth * 16,
              right: 8,
              top: 4,
              bottom: 4,
            ),
            color: isSelected ? AppColors.fileSelected : Colors.transparent,
            child: Row(
              children: [
                if (item.isDirectory) ...[
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                  const SizedBox(width: 2),
                ],
                Icon(
                  _getFileIcon(item),
                  color: item.isDirectory ? AppColors.folderIcon : AppColors.fileIcon,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: isSelected ? AppColors.accentBlue : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Children
        if (item.isDirectory && isExpanded && item.children != null)
          for (final child in item.children!)
            _buildFileItem(context, child, provider, depth + 1),
      ],
    );
  }

  IconData _getFileIcon(FileItem item) {
    if (item.isDirectory) return Icons.folder;
    switch (item.extension) {
      case 'dart': return Icons.code;
      case 'py': return Icons.code;
      case 'js': case 'ts': case 'jsx': case 'tsx': return Icons.javascript;
      case 'json': return Icons.data_object;
      case 'md': return Icons.description;
      case 'yaml': case 'yml': return Icons.settings;
      case 'html': return Icons.language;
      case 'css': return Icons.palette;
      case 'java': case 'kt': return Icons.code;
      case 'png': case 'jpg': case 'jpeg': case 'gif': case 'svg': return Icons.image;
      case 'pdf': return Icons.picture_as_pdf;
      case 'sh': case 'bash': return Icons.terminal;
      case 'sql': return Icons.storage;
      default: return Icons.insert_drive_file;
    }
  }

  void _openProject(BuildContext context) async {
    // TODO: Implement file picker for directory
    // For now, prompt user to enter path
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundSurface,
        title: const Text('Open Project'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '/storage/emulated/0/Download/',
            hintStyle: TextStyle(color: AppColors.textMuted),
          ),
          style: const TextStyle(color: AppColors.textPrimary),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Open'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      context.read<FileTreeProvider>().openProject(result);
      if (context.mounted) {
        final chat = context.read<ChatProvider>();
        chat.setWorkspacePath(result);
      }
    }
    controller.dispose();
  }

  static String languageFromExtension(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'dart': return 'dart';
      case 'py': return 'python';
      case 'js': return 'javascript';
      case 'ts': return 'typescript';
      case 'java': return 'java';
      case 'kt': case 'kts': return 'kotlin';
      case 'rs': return 'rust';
      case 'go': return 'go';
      case 'c': return 'c';
      case 'cpp': case 'cc': case 'cxx': return 'cpp';
      case 'h': case 'hpp': return 'cpp';
      case 'html': case 'htm': return 'html';
      case 'css': return 'css';
      case 'json': return 'json';
      case 'yaml': case 'yml': return 'yaml';
      case 'sql': return 'sql';
      case 'sh': case 'bash': case 'zsh': return 'bash';
      case 'md': case 'markdown': return 'markdown';
      case 'toml': case 'ini': case 'cfg': return 'ini';
      case 'xml': return 'xml';
      case 'svg': return 'xml';
      default: return 'plaintext';
    }
  }
}
