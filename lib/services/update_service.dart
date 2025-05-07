import 'dart:io';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:install_plugin/install_plugin.dart';
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yaml/yaml.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

class UpdateService {
  // Chaves para preferências
  static const String _prefServerIpKey = "update_server_ip";
  static const String _prefServerPortKey = "update_server_port";
  
  // Dados padrão do servidor de atualização
  static const String _defaultServerIp = "128.1.1.49"; // IP correto do seu servidor
  static const int _defaultServerPort = 8085;
  static const String _apkPath = "apk/barcode.apk";
  static const String _versionEndpoint = "version.json";
  
  // Dados do servidor atual
  String _serverIp = _defaultServerIp;
  int _serverPort = _defaultServerPort;
  
  // URLs completas
  String get _serverUrl => "http://$_serverIp:$_serverPort";
  String get _apkUrl => "$_serverUrl/$_apkPath";
  String get _versionUrl => "$_serverUrl/$_versionEndpoint";
  
  // Configurações avançadas
  final Duration _connectionTimeout = const Duration(seconds: 8);
  final int _connectionRetries = 3;

  // Status da atualização
  bool _isChecking = false;
  bool _isDownloading = false;
  double _downloadProgress = 0;
  
  // Getters para status
  bool get isChecking => _isChecking;
  bool get isDownloading => _isDownloading;
  double get downloadProgress => _downloadProgress;
  
  // Getters e setters para configurações
  String get serverIp => _serverIp;
  int get serverPort => _serverPort;
  
  // Atualiza o IP do servidor
  Future<void> setServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefServerIpKey, ip);
    _serverIp = ip;
  }
  
  // Atualiza a porta do servidor
  Future<void> setServerPort(int port) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefServerPortKey, port);
    _serverPort = port;
  }

  // Singleton
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal() {
    _loadSettings();
  }
  
  // Carrega configurações salvas
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _serverIp = prefs.getString(_prefServerIpKey) ?? _defaultServerIp;
      _serverPort = prefs.getInt(_prefServerPortKey) ?? _defaultServerPort;
      developer.log('UpdateService: Configurações carregadas - IP: $_serverIp, Porta: $_serverPort');
    } catch (e) {
      developer.log('UpdateService: Erro ao carregar configurações: $e');
    }
  }

  // Método para verificar se há atualizações disponíveis
  Future<UpdateCheckResult> checkForUpdates() async {
    if (_isChecking || _isDownloading) {
      return UpdateCheckResult(
        status: UpdateStatus.inProgress,
        message: 'Operação em andamento',
      );
    }

    _isChecking = true;
    developer.log('UpdateService: Iniciando verificação de atualizações');
    developer.log('UpdateService: Servidor: $_serverUrl');
    
    try {
      // Verificar conexão com a internet primeiro
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _isChecking = false;
        return UpdateCheckResult(
          status: UpdateStatus.serverUnavailable,
          message: 'Sem conexão com a internet',
          error: 'Dispositivo sem conexão à rede',
        );
      }
      
      // Obter a versão atual do aplicativo instalado
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      final String currentVersion = packageInfo.version;
      developer.log('UpdateService: Versão atual: $currentVersion');
      
      // Verificar se o servidor está online
      bool isServerOnline = false;
      String errorMessage = '';
      
      // Cliente HTTP com configuração específica
      final client = http.Client();
      
      for (int i = 0; i < _connectionRetries; i++) {
        try {
          developer.log('UpdateService: Tentando conectar ao servidor (tentativa ${i+1})');
          
          // Usar reqwest que é mais robusto para ambientes móveis
          final response = await client.get(
            Uri.parse(_serverUrl),
            headers: {'Connection': 'close'}, // Impede problemas de keep-alive
          ).timeout(_connectionTimeout);
          
          if (response.statusCode < 400) {
            isServerOnline = true;
            developer.log('UpdateService: Servidor online! Status: ${response.statusCode}');
            break;
          } else {
            errorMessage = 'Erro de servidor: ${response.statusCode}';
            developer.log('UpdateService: $errorMessage');
          }
        } catch (e) {
          errorMessage = e.toString();
          developer.log('UpdateService: Erro de conexão: $errorMessage');
          
          // Mostrar mensagem mais amigável para o erro específico
          if (e is SocketException || e.toString().contains('SocketException')) {
            errorMessage = 'Não foi possível conectar ao servidor. Verifique se o dispositivo está na mesma rede do servidor.';
          }
        }
        
        // Pequena pausa entre tentativas
        await Future.delayed(const Duration(milliseconds: 800));
      }
      
      // Fechar o cliente HTTP
      client.close();
      
      if (!isServerOnline) {
        _isChecking = false;
        return UpdateCheckResult(
          status: UpdateStatus.serverUnavailable,
          message: 'Servidor de atualizações não está disponível\nVerifique sua conexão e tente novamente',
          error: errorMessage,
        );
      }
      
      // Tentar buscar informações sobre a versão mais recente
      try {
        developer.log('UpdateService: Buscando informações de versão em $_versionUrl');
        
        // Criar um novo cliente para esta solicitação
        final versionClient = http.Client();
        try {
          final response = await versionClient.get(
            Uri.parse(_versionUrl),
            headers: {'Connection': 'close'},
          ).timeout(_connectionTimeout);
          
          if (response.statusCode == 200) {
            developer.log('UpdateService: Dados de versão recebidos: ${response.body}');
            final Map<String, dynamic> versionData = 
                Map<String, dynamic>.from(await _parseJsonOrYaml(response.body));
            
            final String latestVersion = versionData['version'] ?? '0.0.0';
            developer.log('UpdateService: Versão mais recente: $latestVersion');
            
            // Comparar versões
            final bool updateAvailable = _isNewerVersion(latestVersion, currentVersion);
            
            _isChecking = false;
            
            if (updateAvailable) {
              developer.log('UpdateService: Atualização disponível');
              return UpdateCheckResult(
                status: UpdateStatus.updateAvailable,
                message: 'Nova versão disponível: $latestVersion',
                latestVersion: latestVersion,
              );
            } else {
              developer.log('UpdateService: Aplicativo atualizado');
              return UpdateCheckResult(
                status: UpdateStatus.upToDate,
                message: 'Seu aplicativo está atualizado (versão $currentVersion)',
              );
            }
          } else {
            // Se não conseguir obter o arquivo de versão, tenta obter direto do APK
            developer.log('UpdateService: Erro ao obter arquivo version.json, verificando APK');
            final bool apkExists = await _doesApkExist();
            
            if (apkExists) {
              developer.log('UpdateService: APK encontrado, assumindo atualização disponível');
              _isChecking = false;
              return UpdateCheckResult(
                status: UpdateStatus.updateAvailable,
                message: 'Nova versão disponível',
              );
            } else {
              developer.log('UpdateService: APK não encontrado');
              _isChecking = false;
              return UpdateCheckResult(
                status: UpdateStatus.upToDate,
                message: 'Nenhuma atualização encontrada',
              );
            }
          }
        } finally {
          versionClient.close();
        }
      } catch (e) {
        developer.log('UpdateService: Erro ao verificar atualizações: $e');
        _isChecking = false;
        return UpdateCheckResult(
          status: UpdateStatus.error,
          message: 'Erro ao verificar atualizações',
          error: e.toString(),
        );
      }
    } catch (e) {
      developer.log('UpdateService: Erro inesperado: $e');
      _isChecking = false;
      return UpdateCheckResult(
        status: UpdateStatus.error,
        message: 'Erro inesperado',
        error: e.toString(),
      );
    }
  }

  // Método para baixar e instalar a atualização
  Future<UpdateResult> downloadAndInstallUpdate({
    required Function(double) onProgress,
  }) async {
    if (_isDownloading) {
      return UpdateResult(
        success: false,
        message: 'Download já está em andamento',
      );
    }

    _isDownloading = true;
    _downloadProgress = 0;
    developer.log('UpdateService: Iniciando download de $_apkUrl');
    
    try {
      // Verificar conexão com a internet primeiro
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        _isDownloading = false;
        return UpdateResult(
          success: false,
          message: 'Sem conexão com a internet',
        );
      }
      
      // Verificar e solicitar permissões necessárias
      final bool hasPermission = await _checkAndRequestPermissions();
      if (!hasPermission) {
        _isDownloading = false;
        return UpdateResult(
          success: false,
          message: 'Permissões necessárias não foram concedidas',
        );
      }
      
      // Obter diretório temporário para salvar o APK
      final Directory tempDir = await getTemporaryDirectory();
      final String savePath = '${tempDir.path}/update.apk';
      developer.log('UpdateService: Salvando APK em $savePath');
      
      // Criar instância do Dio para download com progresso
      final Dio dio = Dio();
      dio.options.connectTimeout = _connectionTimeout;
      dio.options.receiveTimeout = const Duration(minutes: 5);
      dio.options.headers = {'Connection': 'close'};
      
      try {
        await dio.download(
          _apkUrl,
          savePath,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              _downloadProgress = received / total;
              onProgress(_downloadProgress);
            }
          },
          options: Options(
            // Impede problemas de cache
            responseType: ResponseType.bytes,
            followRedirects: true,
            validateStatus: (status) {
              return status != null && status < 500;
            },
          ),
        );
        
        developer.log('UpdateService: Download concluído');
      } catch (e) {
        developer.log('UpdateService: Erro no download: $e');
        _isDownloading = false;
        
        String errorMsg = 'Erro ao baixar atualização';
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionTimeout) {
            errorMsg = 'Tempo esgotado ao tentar conectar com o servidor';
          } else if (e.type == DioExceptionType.receiveTimeout) {
            errorMsg = 'Tempo esgotado ao receber dados do servidor';
          }
        }
        
        return UpdateResult(
          success: false,
          message: errorMsg,
          error: e.toString(),
        );
      }
      
      // Após o download, instalar o APK
      developer.log('UpdateService: Instalando APK');
      final result = await _installApk(savePath);
      _isDownloading = false;
      
      return result;
    } catch (e) {
      developer.log('UpdateService: Erro no processo de download/instalação: $e');
      _isDownloading = false;
      return UpdateResult(
        success: false,
        message: 'Erro ao baixar ou instalar atualização',
        error: e.toString(),
      );
    }
  }
  
  // Verifica se o servidor está disponível
  Future<bool> _isServerAvailable() async {
    try {
      developer.log('UpdateService: Verificando disponibilidade do servidor: $_serverUrl');
      
      final client = http.Client();
      try {
        final response = await client.get(
          Uri.parse(_serverUrl),
          headers: {'Connection': 'close'},
        ).timeout(_connectionTimeout);
        
        final bool isAvailable = response.statusCode < 400;
        developer.log('UpdateService: Servidor ${isAvailable ? "disponível" : "indisponível"}');
        return isAvailable;
      } finally {
        client.close();
      }
    } catch (e) {
      developer.log('UpdateService: Erro ao verificar servidor: $e');
      return false;
    }
  }
  
  // Verifica se o APK existe no servidor
  Future<bool> _doesApkExist() async {
    try {
      developer.log('UpdateService: Verificando existência do APK: $_apkUrl');
      
      final client = http.Client();
      try {
        final response = await client.head(
          Uri.parse(_apkUrl),
          headers: {'Connection': 'close'},
        ).timeout(_connectionTimeout);
        
        final bool exists = response.statusCode < 400;
        developer.log('UpdateService: APK ${exists ? "encontrado" : "não encontrado"}');
        return exists;
      } finally {
        client.close();
      }
    } catch (e) {
      developer.log('UpdateService: Erro ao verificar APK: $e');
      return false;
    }
  }
  
  // Verifica se uma versão é mais recente que outra
  bool _isNewerVersion(String newVersion, String currentVersion) {
    if (newVersion == currentVersion) return false;
    
    // Separar a versão semântica (X.Y.Z) do número de build (N)
    final String cleanNewVersion = newVersion.split('+').first;
    final int? newBuild = int.tryParse(newVersion.contains('+') ? newVersion.split('+').last : '0');
    
    final String cleanCurrentVersion = currentVersion.split('+').first;
    final int? currentBuild = int.tryParse(currentVersion.contains('+') ? currentVersion.split('+').last : '0');
    
    // Primeiro comparar as versões semânticas (X.Y.Z)
    final List<int> newParts = cleanNewVersion.split('.')
        .map((part) => int.tryParse(part) ?? 0).toList();
    final List<int> currentParts = cleanCurrentVersion.split('.')
        .map((part) => int.tryParse(part) ?? 0).toList();
    
    // Garantir que ambas as listas têm pelo menos 3 elementos (major, minor, patch)
    while (newParts.length < 3) newParts.add(0);
    while (currentParts.length < 3) currentParts.add(0);
    
    // Comparar versão por componente
    for (int i = 0; i < 3; i++) {
      if (newParts[i] > currentParts[i]) {
        return true;
      } else if (newParts[i] < currentParts[i]) {
        return false;
      }
    }
    
    // Se a versão semântica for idêntica, comparar o número de build
    // Considerar uma atualização se o build for maior
    return (newBuild ?? 0) > (currentBuild ?? 0);
  }
  
  // Verifica e solicita permissões necessárias
  Future<bool> _checkAndRequestPermissions() async {
    if (Platform.isAndroid) {
      // No Android 13+, precisamos de permissão para instalar pacotes
      if (await Permission.requestInstallPackages.request().isGranted) {
        return true;
      }
      
      // No Android mais antigo, verificamos permissão de armazenamento
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      
      return false;
    }
    
    // Em outras plataformas, assumimos que temos permissão
    return true;
  }
  
  // Instala o APK baixado
  Future<UpdateResult> _installApk(String filePath) async {
    try {
      if (Platform.isAndroid) {
        // Verificar se o arquivo existe
        final file = File(filePath);
        if (!await file.exists()) {
          developer.log('UpdateService: Arquivo APK não encontrado: $filePath');
          return UpdateResult(
            success: false,
            message: 'Arquivo de instalação não encontrado',
            error: 'APK não existe no caminho especificado',
          );
        }
        
        // Verificar tamanho do arquivo (deve ser maior que 1MB para ser um APK válido)
        final fileSize = await file.length();
        if (fileSize < 1024 * 1024) {
          developer.log('UpdateService: Arquivo APK muito pequeno: $fileSize bytes');
          return UpdateResult(
            success: false,
            message: 'Arquivo de instalação inválido',
            error: 'Tamanho do APK muito pequeno',
          );
        }

        developer.log('UpdateService: Iniciando instalação do APK: $filePath (${fileSize ~/ 1024} KB)');
        
        // Primeiro, tentar com InstallPlugin
        try {
          await InstallPlugin.installApk(filePath);
          developer.log('UpdateService: Instalação iniciada via InstallPlugin');
          return UpdateResult(
            success: true,
            message: 'Instalação iniciada',
          );
        } catch (e) {
          // Se falhar, tentar com OpenFilex como fallback
          developer.log('UpdateService: Erro ao instalar com InstallPlugin: $e. Tentando com OpenFilex...');
          
          final result = await OpenFilex.open(
            filePath,
            type: 'application/vnd.android.package-archive',
            uti: 'public.android-package-archive',
          );
          
          if (result.type == ResultType.done) {
            developer.log('UpdateService: Instalação iniciada via OpenFilex');
            return UpdateResult(
              success: true,
              message: 'Instalação iniciada',
            );
          } else {
            developer.log('UpdateService: Falha ao abrir APK: ${result.message}');
            return UpdateResult(
              success: false,
              message: 'Não foi possível iniciar a instalação',
              error: result.message,
            );
          }
        }
      } else {
        // Em outras plataformas, tentamos abrir o arquivo
        final result = await OpenFilex.open(filePath);
        developer.log('UpdateService: Tentativa de abrir arquivo para instalação: ${result.message}');
        
        return UpdateResult(
          success: result.type == ResultType.done,
          message: result.type == ResultType.done 
              ? 'Instalação iniciada' 
              : 'Não foi possível iniciar a instalação',
          error: result.type != ResultType.done ? result.message : null,
        );
      }
    } catch (e) {
      developer.log('UpdateService: Erro ao instalar: $e');
      return UpdateResult(
        success: false,
        message: 'Erro ao instalar o APK',
        error: e.toString(),
      );
    }
  }
  
  // Tenta analisar JSON ou YAML
  Future<dynamic> _parseJsonOrYaml(String content) async {
    try {
      // Tentar parse como JSON
      return json.decode(content);
    } catch (e) {
      developer.log('UpdateService: Erro ao analisar JSON: $e');
      try {
        // Se falhar, tentar como YAML
        return loadYaml(content);
      } catch (e) {
        developer.log('UpdateService: Erro ao analisar YAML: $e');
        // Se ambos falharem, retornar um mapa vazio
        return {};
      }
    }
  }
}

// Classes para representar resultados
class UpdateCheckResult {
  final UpdateStatus status;
  final String message;
  final String? latestVersion;
  final String? error;
  
  UpdateCheckResult({
    required this.status,
    required this.message,
    this.latestVersion,
    this.error,
  });
}

class UpdateResult {
  final bool success;
  final String message;
  final String? error;
  
  UpdateResult({
    required this.success,
    required this.message,
    this.error,
  });
}

// Enum para status da atualização
enum UpdateStatus {
  updateAvailable,
  upToDate,
  serverUnavailable,
  error,
  inProgress
}