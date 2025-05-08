/// Ponto de entrada do aplicativo.
/// 
/// Inicializa a aplicação, configura os providers e define as rotas principais.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'config/app_info.dart';
import 'providers/scanner_provider.dart';
import 'providers/update_provider.dart';
import 'screens/home_page.dart';
import 'screens/settings_page.dart';
import 'screens/about_page.dart';
import 'screens/advanced_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ScannerProvider()),
        ChangeNotifierProvider(create: (context) => UpdateProvider()),
      ],
      child: const BarcodeApp(),
    ),
  );
}

class BarcodeApp extends StatelessWidget {
  const BarcodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Inicializa as informações do app
    AppInfo.initialize();
    
    return MaterialApp(
      title: 'Leitor de Código IFSUL',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFD1B5E20), // Verde do IFSUL
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/about': (context) => const AboutPage(),
        // Temporariamente redirecionando o modo avançado para uma tela de "Em breve"
        '/advanced': (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Modo Avançado'),
          ),
          body: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.construction, size: 80, color: Colors.amber),
                SizedBox(height: 16),
                Text(
                  'Funcionalidade em desenvolvimento',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'O Modo Avançado estará disponível em breve.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      },
    );
  }
}