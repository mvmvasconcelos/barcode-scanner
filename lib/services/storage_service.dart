/// Serviço para gerenciar o armazenamento persistente do aplicativo.
///
/// Centraliza as operações de salvamento e carregamento de dados usando SharedPreferences.
/// Isso permite um ponto único para alterar a implementação de persistência no futuro.

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Chaves para as preferências
  static const String _scansKey = 'scans';
  static const String _hapticFeedbackKey = 'haptic_feedback_enabled';
  static const String _soundFeedbackKey = 'sound_feedback_enabled';
  
  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();
  
  /// Salva a lista de códigos escaneados
  Future<void> saveScans(List<String> scans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scansKey, scans);
  }
  
  /// Carrega a lista de códigos escaneados
  Future<List<String>> loadScans() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_scansKey) ?? [];
  }
  
  /// Salva as configurações de feedback háptico
  Future<void> saveHapticFeedback(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hapticFeedbackKey, enabled);
  }
  
  /// Carrega as configurações de feedback háptico
  Future<bool> loadHapticFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hapticFeedbackKey) ?? true;
  }
  
  /// Salva as configurações de feedback sonoro
  Future<void> saveSoundFeedback(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundFeedbackKey, enabled);
  }
  
  /// Carrega as configurações de feedback sonoro
  Future<bool> loadSoundFeedback() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundFeedbackKey) ?? true;
  }
  
  /// Limpa todos os dados armazenados
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}