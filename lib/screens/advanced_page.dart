/// Tela de modo avançado para funcionalidades futuras.
/// 
/// Esta tela será expandida nas próximas versões para incluir integrações
/// com Google Sheets e recursos avançados de inventário.

import 'package:flutter/material.dart';

class AdvancedPage extends StatelessWidget {
  const AdvancedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Avançado'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 80,
              color: colorScheme.primary.withOpacity(0.7),
            ),
            const SizedBox(height: 24),
            Text(
              'Em Breve',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Recursos avançados de integração com Google Sheets e gestão de inventário estarão disponíveis nas próximas atualizações.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}