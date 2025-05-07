/// Classe auxiliar para obter e gerenciar informações globais do aplicativo.
/// 
/// Fornece acesso a informações como versão, nome e data de lançamento do app.
/// Estas informações são carregadas dinamicamente e podem ser acessadas de qualquer lugar do app.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:yaml/yaml.dart';

class AppInfo {
  static String appName = 'Leitor de Código de Barras';
  static String version = '1.0.0';
  static String releaseDate = '';
  static bool _initialized = false;
  
  /// Inicializa as informações do app, carregando dados do sistema ou do pubspec.yaml
  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Método 1: Usar package_info_plus para obter informações diretas do pacote instalado
      final packageInfo = await PackageInfo.fromPlatform();
      appName = packageInfo.appName.isEmpty ? 'Leitor de Código de Barras' : packageInfo.appName;
      version = packageInfo.version;
      
      // Método 2 (fallback): Ler do asset pubspec.yaml
      if (version == '1.0.0' || version.isEmpty) {
        try {
          final yamlString = await rootBundle.loadString('pubspec.yaml');
          final yaml = loadYaml(yamlString);
          
          if (yaml['version'] != null) {
            // Remove o versionCode (parte após o +)
            version = yaml['version'].toString().split('+')[0];
          }
        } catch (e) {
          debugPrint('Erro ao carregar pubspec.yaml: $e');
        }
      }
      
      // Configurar a data como a data atual
      final dateFormat = DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR');
      releaseDate = dateFormat.format(DateTime.now());
      _initialized = true;
    } catch (e) {
      debugPrint('Erro ao carregar informações do app: $e');
      // Usar os valores padrão em caso de erro
      releaseDate = '29 de abril de 2025';
    }
  }
}