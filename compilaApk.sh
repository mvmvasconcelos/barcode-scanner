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
VERSION_JSON_FILE="public/version.json"
LOCAL_PROPERTIES_FILE="android/local.properties"
README_FILE="README.md"

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

# Atualizar também o arquivo local.properties com a nova versão para o Android
if [ -f "$LOCAL_PROPERTIES_FILE" ]; then
  # Remover as propriedades de versão anteriores se existirem
  sed -i '/flutter.versionName=/d' "$LOCAL_PROPERTIES_FILE"
  sed -i '/flutter.versionCode=/d' "$LOCAL_PROPERTIES_FILE"
  
  # Adicionar as novas propriedades de versão
  echo "flutter.versionName=$NEW_VERSION_NAME" >> "$LOCAL_PROPERTIES_FILE"
  echo "flutter.versionCode=$NEW_VERSION_CODE" >> "$LOCAL_PROPERTIES_FILE"
  
  echo "Arquivo local.properties atualizado com a nova versão"
else
  # Se o arquivo não existir, criar um novo com as propriedades de versão
  echo "flutter.versionName=$NEW_VERSION_NAME" > "$LOCAL_PROPERTIES_FILE"
  echo "flutter.versionCode=$NEW_VERSION_CODE" >> "$LOCAL_PROPERTIES_FILE"
  echo "Arquivo local.properties criado com a nova versão"
fi

# Atualizar a versão no README.md (badge de versão)
if [ -f "$README_FILE" ]; then
  # Atualizar o badge de versão no README.md
  sed -i "s/version-[0-9]*\.[0-9]*\.[0-9]*-blue/version-$NEW_VERSION_NAME-blue/" "$README_FILE"
  echo "Badge de versão no README.md atualizado para $NEW_VERSION_NAME"
else
  echo "Arquivo README.md não encontrado"
fi

# Atualizar também o arquivo version.json com a nova versão
if [ -f "$VERSION_JSON_FILE" ]; then
  # Obter a data atual no formato YYYY-MM-DD
  CURRENT_DATE=$(date +"%Y-%m-%d")
  
  # Atualizar o arquivo version.json com a nova versão e data atual
  cat > "$VERSION_JSON_FILE" <<EOL
{
    "version": "$NEW_VERSION_NAME",
    "buildNumber": "$NEW_VERSION_CODE",
    "releaseDate": "$CURRENT_DATE",
    "downloadUrl": "http://128.1.1.49:8085/apk/barcode.apk"
}
EOL
  echo "Arquivo version.json atualizado com a nova versão: $NEW_VERSION_NAME (build $NEW_VERSION_CODE)"
else
  echo "Arquivo version.json não encontrado. Verifique o diretório public/"
fi

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
  echo "./compartilhaApk.sh"
    
  # Copiar o APK para o diretório público
  mkdir -p public/apk
  cp "$APK_PATH" "public/apk/barcode.apk"
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

    # Copiar o APK de debug para o diretório público
    mkdir -p public/apk
    cp "$DEBUG_APK_PATH" "public/apk/barcode.apk"
    echo "Para compartilhar o APK com seu celular, execute:"
    echo "./compartilhaApk.sh"
    echo ""
    echo "APK também disponível em: public/apk/barcode.apk"
    echo ""
  else
    echo "❌ Todos os métodos de compilação falharam."
  fi
fi