import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class SettingsProvider extends ChangeNotifier {
  AppSettings _settings = AppSettings();
  bool _isLoaded = false;

  AppSettings get settings => _settings;
  LLMConfig get llmConfig => _settings.llmConfig;
  bool get isLoaded => _isLoaded;
  bool get hasApiKey => _settings.llmConfig.apiKey.isNotEmpty;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('app_settings');
    if (stored != null) {
      try {
        _settings = AppSettings.fromJson(jsonDecode(stored));
      } catch (_) {
        _settings = AppSettings();
      }
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_settings', jsonEncode(_settings.toJson()));
  }

  Future<void> updateLLMConfig(LLMConfig config) async {
    _settings.llmConfig = config;
    await save();
    notifyListeners();
  }

  Future<void> updateApiKey(String key) async {
    _settings.llmConfig.apiKey = key;
    await save();
    notifyListeners();
  }

  Future<void> updateBaseUrl(String url) async {
    _settings.llmConfig.baseUrl = url;
    await save();
    notifyListeners();
  }

  Future<void> updateModel(String model) async {
    _settings.llmConfig.model = model;
    await save();
    notifyListeners();
  }

  Future<void> updateTemperature(double temp) async {
    _settings.llmConfig.temperature = temp;
    await save();
    notifyListeners();
  }

  Future<void> updateMaxTokens(int tokens) async {
    _settings.llmConfig.maxTokens = tokens;
    await save();
    notifyListeners();
  }

  Future<void> setDefaultProjectPath(String? path) async {
    _settings.defaultProjectPath = path;
    await save();
    notifyListeners();
  }

  Future<void> updateFontSize(int size) async {
    _settings.fontSize = size;
    await save();
    notifyListeners();
  }

  Future<void> toggleCodeWrap() async {
    _settings.codeWrap = !_settings.codeWrap;
    await save();
    notifyListeners();
  }

  List<String> get quickActions => _settings.quickActions;
}
