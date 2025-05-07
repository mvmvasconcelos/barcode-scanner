#!/bin/bash

# Definir o IP do servidor manualmente (pode ser alterado conforme necessário)
IP_ADDRESS="128.1.1.49"
PORT=8085

# Verifica se o APK existe
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
    echo "Erro: APK não encontrado em $APK_PATH"
    echo "Execute 'docker-compose exec flutter bash -c \"./build-apk.sh\"' primeiro."
    exit 1
fi

# Criar diretório para APK com caminho mais amigável
mkdir -p public/apk
cp "$APK_PATH" public/apk/barcode.apk
FRIENDLY_PATH="apk/barcode.apk"

# Extrair informações de versão do APK para criar o arquivo version.json
PUBSPEC_FILE="pubspec.yaml"
if [ -f "$PUBSPEC_FILE" ]; then
    VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | cut -d'+' -f1)
    BUILD_NUMBER=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version: //' | cut -d'+' -f2)
    CURRENT_DATE=$(date +"%Y-%m-%d")
    
    # Criar arquivo version.json na pasta public
    cat > public/version.json << EOF
{
    "version": "$VERSION",
    "buildNumber": "$BUILD_NUMBER",
    "releaseDate": "$CURRENT_DATE",
    "downloadUrl": "http://$IP_ADDRESS:$PORT/$FRIENDLY_PATH"
}
EOF
    echo "Arquivo version.json criado com sucesso."
else
    echo "Arquivo pubspec.yaml não encontrado. Não foi possível criar version.json."
fi


# Instalar python3 silenciosamente se não estiver disponível
if ! command -v python3 &> /dev/null; then
    echo "Instalando Python3 (primeira execução)..."
    apt-get update -qq > /dev/null && apt-get install -y -qq python3 python3-pip > /dev/null
    echo "Python3 instalado."
fi

# Tenta gerar um QR code silenciosamente
if ! command -v qrencode &> /dev/null; then
    echo "Instalando QR Code generator (primeira execução)..."
    apt-get update -qq > /dev/null && apt-get install -y -qq qrencode > /dev/null
    echo "QR Code generator instalado."
fi

echo "Iniciando servidor na porta $PORT..."
echo ""
echo "✅ Para baixar o APK no seu celular:"
echo "   1. Conecte seu celular na mesma rede Wi-Fi deste servidor"
echo "   2. Acesse no navegador do seu celular:"
echo "   http://$IP_ADDRESS:$PORT/$FRIENDLY_PATH"
echo ""
echo "📱 Link direto para compartilhar:"
echo "   http://$IP_ADDRESS:$PORT/$FRIENDLY_PATH"
echo ""
echo "📱 Após o download, você precisará:"
echo "   - Permitir a instalação de fontes desconhecidas nas configurações"
echo "   - Abrir o APK baixado para instalar o aplicativo"
echo ""
echo "⚠️  Este servidor será acessível apenas dentro da rede local"
echo "⚠️  Pressione Ctrl+C para parar o servidor quando terminar"
echo ""

if command -v qrencode &> /dev/null; then
    echo "QR Code para download direto:"
    echo ""
    # Usar formato UTF8 em vez de ANSI para melhor compatibilidade
    qrencode -t UTF8 "http://$IP_ADDRESS:$PORT/$FRIENDLY_PATH"
    echo ""
fi

# Cria um arquivo HTML com QR code para facilitar acesso
mkdir -p public
cat > public/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Download do APK - Leitor de Código de Barras IFSUL</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
            text-align: center;
        }
        h1 {
            color: #1B5E20;
        }
        .download-btn {
            background-color: #1B5E20;
            color: white;
            padding: 15px 25px;
            text-decoration: none;
            font-size: 18px;
            border-radius: 8px;
            display: inline-block;
            margin: 20px 0;
        }
        .instructions {
            text-align: left;
            border: 1px solid #ddd;
            padding: 15px;
            border-radius: 8px;
            margin-top: 20px;
        }
        .qr-section {
            margin: 30px 0;
        }
        img {
            max-width: 100%;
        }
        .version-info {
            background-color: #f5f5f5;
            padding: 10px;
            border-radius: 5px;
            margin: 10px 0;
            font-size: 16px;
        }
    </style>
</head>
<body>
    <h1>Leitor de Código de Barras IFSUL</h1>
    <p>Aplicativo para leitura de códigos de barras em etiquetas de patrimônio</p>
    
    <div class="version-info">
        <p><strong>Versão:</strong> $VERSION (build $BUILD_NUMBER)</p>
        <p><strong>Data:</strong> $CURRENT_DATE</p>
    </div>
    
    <a href="/$FRIENDLY_PATH" class="download-btn">Baixar APK</a>
    
    <div class="instructions">
        <h3>Instruções de instalação:</h3>
        <ol>
            <li>Clique no botão acima para baixar o APK</li>
            <li>Nas configurações do seu celular, habilite a instalação de fontes desconhecidas</li>
            <li>Abra o arquivo APK baixado para instalar o aplicativo</li>
            <li>Conceda as permissões necessárias para a câmera quando solicitado</li>
        </ol>
    </div>
    
    <div class="qr-section">
        <h3>Ou escaneie o QR code abaixo:</h3>
        <img src="https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=http://$IP_ADDRESS:$PORT/$FRIENDLY_PATH" alt="QR Code para download">
    </div>
</body>
</html>
EOF

echo "Página web de download criada. Acesse http://$IP_ADDRESS:$PORT/ no navegador."
echo ""

# Inicia um servidor Python simples na pasta public
cd public || exit
python3 -m http.server $PORT