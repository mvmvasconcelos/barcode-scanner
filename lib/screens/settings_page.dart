/// Tela de configurações do aplicativo.
/// 
/// Permite ao usuário configurar preferências como feedback háptico e sonoro.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scanner_provider.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ScannerProvider>(context);
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: ListView(
        children: [
          // Seção de feedback
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
            child: Text(
              'Feedback',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
          ),
          
          // Opção de feedback háptico (vibração)
          ListTile(
            leading: Icon(
              Icons.vibration,
              color: provider.hapticFeedbackEnabled ? colorScheme.primary : colorScheme.outline,
            ),
            title: const Text('Feedback háptico (vibração)'),
            subtitle: const Text('Vibração ao escanear um código'),
            trailing: Switch(
              value: provider.hapticFeedbackEnabled,
              onChanged: (value) => provider.setHapticFeedback(value),
              activeColor: colorScheme.primary,
            ),
          ),
          
          // Opção de feedback sonoro
          ListTile(
            leading: Icon(
              Icons.volume_up,
              color: provider.soundFeedbackEnabled ? colorScheme.primary : colorScheme.outline,
            ),
            title: const Text('Feedback sonoro'),
            subtitle: const Text('Som ao escanear um código'),
            trailing: Switch(
              value: provider.soundFeedbackEnabled,
              onChanged: (value) => provider.setSoundFeedback(value),
              activeColor: colorScheme.primary,
            ),
          ),
          
          const Divider(),
          
          // Nota informativa
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'As configurações são aplicadas imediatamente e salvas automaticamente.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: colorScheme.outline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}