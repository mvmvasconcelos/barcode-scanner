#!/bin/bash

# Script para compilar APK
echo "Iniciando compilação do APK ..."

# Configurar Git como seguro
git config --global --add safe.directory /opt/flutter

# Verificar se o diretório lib existe
if [ ! -d "lib" ]; then
  echo "Erro: Diretório 'lib' não encontrado. Execute o setup.sh primeiro."
  exit 1
fi

# Verificar se o arquivo main.dart existe
if [ ! -f "lib/main.dart" ]; then
  echo "Erro: Arquivo main.dart não encontrado."
  exit 1
fi

# Incrementar automaticamente o versionCode e verificar parâmetros para versão semântica
echo "Atualizando versão do aplicativo..."
PUBSPEC_FILE="pubspec.yaml"

# Extrair a versão atual
CURRENT_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //')
echo "Versão atual: $CURRENT_VERSION"

# Separar o versionName (X.Y.Z) do versionCode (N)
VERSION_NAME=$(echo "$CURRENT_VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$CURRENT_VERSION" | cut -d'+' -f2)

# Extrair os componentes da versão semântica (X.Y.Z)
IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NAME"

# Incrementar o versionCode sempre
NEW_VERSION_CODE=$((VERSION_CODE + 1))

# Verificar os parâmetros de entrada para ajustar a versão semântica
if [ "$1" = "major" ]; then
  # Incrementar a versão major (X.0.0)
  MAJOR=$((MAJOR + 1))
  MINOR=0
  PATCH=0
  echo "Incrementando versão major para $MAJOR.0.0"
elif [ "$1" = "minor" ]; then
  # Incrementar a versão minor (X.Y+1.0)
  MINOR=$((MINOR + 1))
  PATCH=0
  echo "Incrementando versão minor para $MAJOR.$MINOR.0"
elif [ "$1" = "patch" ]; then
  # Incrementar a versão patch (X.Y.Z+1)
  PATCH=$((PATCH + 1))
  echo "Incrementando versão patch para $MAJOR.$MINOR.$PATCH"
else
  # Se não houver parâmetro específico, apenas incrementar o versionCode
  if [ -n "$1" ]; then
    echo "Parâmetro '$1' não reconhecido. Use 'major', 'minor' ou 'patch'."
    echo "Mantendo a versão semântica atual e incrementando apenas o versionCode."
  else
    echo "Mantendo a versão semântica atual e incrementando apenas o versionCode."
  fi
fi

# Montar a nova versão completa
NEW_VERSION_NAME="$MAJOR.$MINOR.$PATCH"
NEW_VERSION="${NEW_VERSION_NAME}+${NEW_VERSION_CODE}"

echo "Nova versão: $NEW_VERSION"

# Atualizar o arquivo pubspec.yaml com a nova versão
sed -i "s/^version: .*/version: $NEW_VERSION/" "$PUBSPEC_FILE"

echo "Gerando arquivos Flutter necessários..."
flutter pub get --offline || flutter pub get

# Resto do script para compilar o APK...
echo "Compilando APK diretamente com Gradle (modo offline)..."
cd android
./gradlew assembleRelease --offline || ./gradlew assembleRelease
cd ..

# Verificar se o APK foi gerado
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ -f "$APK_PATH" ]; then
  echo ""
  echo "✅ APK gerado com sucesso!"
  echo ""
  echo "O APK está disponível em: $APK_PATH"
  echo "Versão: $NEW_VERSION"
  echo ""
  echo "Para compartilhar o APK com seu celular, execute:"
  echo "./share-apk.sh"
    
  echo ""
  echo "APK também disponível em: public/apk/barcode.apk"
  echo ""
else
  echo ""
  echo "❌ Erro durante a compilação. O APK não foi gerado."
  echo ""
  echo "Tentando método alternativo de compilação..."
  echo ""
  
  # Método alternativo - tentar gerar um APK de debug que geralmente requer menos dependências
  flutter build apk --debug
  
  # Verificar se o APK de debug foi gerado
  DEBUG_APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
  if [ -f "$DEBUG_APK_PATH" ]; then
    echo ""
    echo "✅ APK de debug gerado com sucesso!"
    echo ""
    echo "O APK está disponível em: $DEBUG_APK_PATH"
    echo "Versão: $NEW_VERSION"
    echo ""

    echo "Para compartilhar o APK com seu celular, execute:"
    echo "./share-apk.sh"
    echo ""
    echo "APK também disponível em: public/apk/barcode.apk"
    echo ""
  else
    echo "❌ Todos os métodos de compilação falharam."
  fi
fi