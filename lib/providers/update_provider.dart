/// Provider opcional para gerenciar o estado de atualização do aplicativo.
/// 
/// Centraliza a lógica de gerenciamento do processo de atualização que antes estava
/// diretamente na tela About. Comunica-se com o UpdateService.

import 'package:flutter/material.dart';
import '../services/update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateProvider extends ChangeNotifier {
  final UpdateService _updateService = UpdateService();
  
  bool _isLoading = false;
  bool _isCheckingForUpdates = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _updateMessage = '';
  bool _showUpdateMessage = false;
  String? _lastInstalledVersion;
  
  // Getters
  bool get isLoading => _isLoading;
  bool get isCheckingForUpdates => _isCheckingForUpdates;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  String get updateMessage => _updateMessage;
  bool get showUpdateMessage => _showUpdateMessage;
  String get serverIp => _updateService.serverIp;
  int get serverPort => _updateService.serverPort;
  
  UpdateProvider() {
    _checkCurrentVersion();
  }
  
  // Verifica a versão atual para rastrear mudanças
  Future<void> _checkCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _lastInstalledVersion = packageInfo.version;
    } catch (e) {
      // Falha ao obter a versão não é crítico
    }
  }
  
  /// Verifica se o app foi atualizado desde o último uso
  Future<void> checkIfUpdated() async {
    try {
      if (_lastInstalledVersion != null) {
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;
        
        // Se a versão mudou, a atualização foi concluída
        if (currentVersion != _lastInstalledVersion) {
          _showUpdateMessage = false;
          _isDownloading = false;
          _lastInstalledVersion = currentVersion;
          notifyListeners();
        }
      }
    } catch (e) {
      // Falha ao obter a versão não é crítico
    }
  }

  /// Define o estado de carregamento
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  /// Verifica por atualizações disponíveis
  Future<UpdateCheckResult> checkForUpdates() async {
    // Verificar se o app foi atualizado após retornar da tela de instalação
    await checkIfUpdated();
    
    if (_isCheckingForUpdates || _isDownloading) {
      return UpdateCheckResult(
        status: UpdateStatus.inProgress,
        message: 'Operação em andamento',
      );
    }

    _isCheckingForUpdates = true;
    _showUpdateMessage = false;
    notifyListeners();
    
    final result = await _updateService.checkForUpdates();
    
    _isCheckingForUpdates = false;
    _showUpdateMessage = true;
    _updateMessage = result.message;
    notifyListeners();
    
    if (result.status != UpdateStatus.updateAvailable) {
      Future.delayed(const Duration(seconds: 3), () {
        _showUpdateMessage = false;
        notifyListeners();
      });
    }
    
    return result;
  }
  
  /// Baixa e instala a atualização disponível
  Future<UpdateResult> downloadAndInstallUpdate() async {
    _isDownloading = true;
    _downloadProgress = 0;
    _updateMessage = 'Iniciando download...';
    _showUpdateMessage = true;
    notifyListeners();
    
    final result = await _updateService.downloadAndInstallUpdate(
      onProgress: (progress) {
        _downloadProgress = progress;
        _updateMessage = 'Download em andamento: ${(progress * 100).toStringAsFixed(0)}%';
        notifyListeners();
      },
    );
    
    _isDownloading = false;
    _updateMessage = result.message;
    
    if (!result.success) {
      Future.delayed(const Duration(seconds: 8), () {
        _showUpdateMessage = false;
        notifyListeners();
      });
    } else {
      _updateMessage = 'Instalação iniciada. Por favor, siga as instruções na tela.';
      // Salvar a versão atual para comparação após a instalação
      _checkCurrentVersion();
    }
    
    notifyListeners();
    return result;
  }
  
  /// Salva as configurações do servidor de atualização
  Future<void> saveServerSettings(String ip, int port) async {
    if (ip.isNotEmpty) {
      await _updateService.setServerIp(ip);
      await _updateService.setServerPort(port);
      notifyListeners();
    }
  }
}