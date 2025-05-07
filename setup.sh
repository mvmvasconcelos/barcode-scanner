#!/bin/bash

# Script para inicializar o projeto Flutter para leitor de código de barras

# Criar novo projeto Flutter se não existir
if [ ! -d "lib" ]; then
  echo "Criando novo projeto Flutter..."
  flutter create --org br.edu.ifsul.venancioaires --project-name barcode_scanner .
  
  # Limpar conteúdo inicial do main.dart
  > lib/main.dart
fi

# Instalar dependências necessárias no pubspec.yaml
if ! grep -q "flutter_barcode_scanner" pubspec.yaml; then
  echo "Adicionando dependências necessárias..."
  flutter pub add flutter_barcode_scanner
  flutter pub add provider
  flutter pub add shared_preferences
fi

echo "Configuração concluída!"
echo "Para iniciar o desenvolvimento, execute: flutter run"