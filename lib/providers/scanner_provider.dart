/// Provider responsável por gerenciar o estado relacionado aos códigos escaneados.
/// 
/// Gerencia a lista de escaneamentos, estado de seleção e operações como adicionar,
/// remover e limpar códigos. Também controla as configurações de feedback.

import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ScannerProvider extends ChangeNotifier {
  List<String> _scans = [];
  Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  bool _hapticFeedbackEnabled = true;
  bool _soundFeedbackEnabled = true;
  
  final StorageService _storageService = StorageService();
  
  ScannerProvider() {
    _loadScans();
    _loadFeedbackPreferences();
  }
  
  // Getters para as configurações de feedback
  bool get hapticFeedbackEnabled => _hapticFeedbackEnabled;
  bool get soundFeedbackEnabled => _soundFeedbackEnabled;
  
  List<String> get scans => _scans;
  bool get isSelectionMode => _isSelectionMode;
  int get selectedCount => _selectedIndices.length;
  
  bool isSelected(int index) => _selectedIndices.contains(index);
  
  bool areAllSelected() => 
      _scans.isNotEmpty && _selectedIndices.length == _scans.length;
  
  /// Alterna o modo de seleção
  void toggleSelectionMode(bool mode) {
    _isSelectionMode = mode;
    if (!mode) {
      _selectedIndices.clear();
    }
    notifyListeners();
  }
  
  /// Alterna a seleção de um item específico
  void toggleSelection(int index) {
    if (_selectedIndices.contains(index)) {
      _selectedIndices.remove(index);
      if (_selectedIndices.isEmpty) {
        _isSelectionMode = false;
      }
    } else {
      _selectedIndices.add(index);
    }
    notifyListeners();
  }
  
  /// Seleciona ou desseleciona todos os itens
  void selectAll(bool select) {
    if (select) {
      for (var i = 0; i < _scans.length; i++) {
        _selectedIndices.add(i);
      }
    } else {
      _selectedIndices.clear();
    }
    notifyListeners();
  }
  
  /// Retorna uma lista com os scans selecionados
  List<String> getSelectedScans() {
    final List<String> selected = [];
    final List<int> sortedIndices = _selectedIndices.toList()..sort();
    
    for (var i in sortedIndices) {
      selected.add(_scans[i]);
    }
    return selected;
  }
  
  /// Remove os itens selecionados e retorna a quantidade removida
  int removeSelected() {
    if (_selectedIndices.isEmpty) return 0;
    
    final count = _selectedIndices.length;
    final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
    
    for (var i in sortedIndices) {
      _scans.removeAt(i);
    }
    
    _selectedIndices.clear();
    _isSelectionMode = false;
    _saveScans();
    notifyListeners();
    return count;
  }
  
  /// Carrega os scans salvos no armazenamento
  Future<void> _loadScans() async {
    _scans = await _storageService.loadScans();
    notifyListeners();
  }
  
  /// Salva os scans no armazenamento
  Future<void> _saveScans() async {
    await _storageService.saveScans(_scans);
  }
  
  /// Adiciona um novo código escaneado
  void addScan(String code) {
    _scans.add(code);
    _saveScans();
    notifyListeners();
  }
  
  /// Remove um código pelo índice
  void removeScan(int index) {
    _scans.removeAt(index);
    _saveScans();
    notifyListeners();
  }
  
  /// Remove todos os códigos
  void clearScans() {
    _scans.clear();
    _selectedIndices.clear();
    _isSelectionMode = false;
    _saveScans();
    notifyListeners();
  }
  
  /// Carrega as preferências de feedback
  Future<void> _loadFeedbackPreferences() async {
    _hapticFeedbackEnabled = await _storageService.loadHapticFeedback();
    _soundFeedbackEnabled = await _storageService.loadSoundFeedback();
    notifyListeners();
  }
  
  /// Configura o feedback háptico
  Future<void> setHapticFeedback(bool enabled) async {
    _hapticFeedbackEnabled = enabled;
    await _storageService.saveHapticFeedback(enabled);
    notifyListeners();
  }
  
  /// Configura o feedback sonoro
  Future<void> setSoundFeedback(bool enabled) async {
    _soundFeedbackEnabled = enabled;
    await _storageService.saveSoundFeedback(enabled);
    notifyListeners();
  }
}