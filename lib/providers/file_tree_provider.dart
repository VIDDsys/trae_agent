import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';

class FileTreeProvider extends ChangeNotifier {
  String? _rootPath;
  List<FileItem> _files = [];
  FileItem? _selectedFile;
  String? _fileContent;
  bool _isLoading = false;
  final Set<String> _expandedPaths = {};

  String? get rootPath => _rootPath;
  List<FileItem> get files => _files;
  FileItem? get selectedFile => _selectedFile;
  String? get fileContent => _fileContent;
  bool get isLoading => _isLoading;
  bool get hasProject => _rootPath != null;

  void openProject(String path) {
    _rootPath = path;
    _loadDirectory(path);
    notifyListeners();
  }

  void closeProject() {
    _rootPath = null;
    _files.clear();
    _selectedFile = null;
    _fileContent = null;
    _expandedPaths.clear();
    notifyListeners();
  }

  void loadDirectory(String path) {
    _loadDirectory(path);
    notifyListeners();
  }

  Future<void> _loadDirectory(String path) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        _files = [];
        _isLoading = false;
        return;
      }

      _files = await _listDirectory(dir);
    } catch (_) {
      _files = [];
    }

    _isLoading = false;
  }

  Future<List<FileItem>> _listDirectory(Directory dir) async {
    final items = <FileItem>[];
    try {
      final entities = await dir.list(followLinks: false).toList();
      entities.sort((a, b) {
        final aIsDir = a is Directory;
        final bIsDir = b is Directory;
        if (aIsDir && !bIsDir) return -1;
        if (!aIsDir && bIsDir) return 1;
        return a.path.split('/').last.compareTo(b.path.split('/').last);
      });

      for (final entity in entities) {
        final name = entity.path.split('/').last;
        if (name.startsWith('.') && name != '.gitignore') continue;

        if (entity is Directory) {
          items.add(FileItem(
            name: name,
            path: entity.path,
            isDirectory: true,
            modifiedAt: await entity.stat().then((s) => s.modified),
          ));
        } else if (entity is File) {
          final stat = await entity.stat();
          items.add(FileItem(
            name: name,
            path: entity.path,
            isDirectory: false,
            size: stat.size,
            modifiedAt: stat.modified,
          ));
        }
      }
    } catch (_) {}
    return items;
  }

  Future<void> loadChildren(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) return;

    final children = await _listDirectory(dir);
    final item = _findItemByPath(_files, path);
    if (item != null) {
      _expandedPaths.add(path);
    }
    notifyListeners();
  }

  Future<void> toggleExpand(String path) async {
    if (_expandedPaths.contains(path)) {
      _expandedPaths.remove(path);
      notifyListeners();
    } else {
      _expandedPaths.add(path);
      notifyListeners();
    }
  }

  bool isExpanded(String path) => _expandedPaths.contains(path);

  Future<void> openFile(FileItem file) async {
    if (file.isDirectory) return;

    _selectedFile = file;
    _isLoading = true;
    notifyListeners();

    try {
      final f = File(file.path);
      if (await f.exists()) {
        _fileContent = await f.readAsString();
      } else {
        _fileContent = null;
      }
    } catch (_) {
      _fileContent = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  void closeFile() {
    _selectedFile = null;
    _fileContent = null;
    notifyListeners();
  }

  Future<bool> saveFile(String content) async {
    if (_selectedFile == null) return false;
    try {
      final f = File(_selectedFile!.path);
      await f.writeAsString(content);
      _fileContent = content;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void refresh() {
    if (_rootPath != null) {
      _loadDirectory(_rootPath!);
    }
  }

  FileItem? _findItemByPath(List<FileItem> items, String path) {
    for (final item in items) {
      if (item.path == path) return item;
      if (item.children != null) {
        final found = _findItemByPath(item.children!, path);
        if (found != null) return found;
      }
    }
    return null;
  }
}
