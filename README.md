# Leitor de Código de Barras

[![Status](https://img.shields.io/badge/Status-Em%20Desenvolvimento-yellow)](https://github.com/mvmvasconcelos/)[![Versão](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/ifsul/barcode-scanner) [![Flutter](https://img.shields.io/badge/Flutter-v3.1.5+-02569B?logo=flutter)](https://flutter.dev/) [![Licença](https://img.shields.io/badge/licença-MIT-green.svg)](https://opensource.org/licenses/MIT) [![Platform](https://img.shields.io/badge/platform-Android-brightgreen.svg)](https://www.android.com/) [![Docker](https://img.shields.io/badge/Docker-Suportado-2496ED?logo=docker)](https://www.docker.com/) [![IFSul](https://img.shields.io/badge/IFSul-Venâncio%20Aires-195128)](https://vairao.ifsul.edu.br/)


Projeto simplificado para criação de um aplicativo android para leitura de código de barras em etiquetas de patrimônio e jogá-las em uma lista simples.

### Pré-requisitos

- Docker e Docker Compose instalados no servidor

### Como Usar

1. **Construir o container Docker**:
   ```bash
   docker-compose build
   ```

2. **Iniciar o container Docker**:
   ```bash
   docker-compose up -d
   ```

3. **Acessar o container**:
   ```bash
   docker-compose exec flutter bash
   ```
   Dentro do container, execute os scripts abaixo:

   1. **Executar o script de build**:
      Para compilar o projeto, execute o script abaixo:
      
      ```bash
      ./build-apk.sh
      ```
      Este script irá:
      - Atualizar versão build do aplicativo
      - Compilar o projeto Flutter
      - Gerar o APK do aplicativo

      ### Parâmetros do Script
      `major` -- versão principal
      `minor` -- versão secundária
      `patch` -- versão de correção
      Exemplo: `./build-apk.sh minor`

   2. **Compartilhar o APK**
      Após compilar o projeto, execute o script abaixo para compartilhar o APK:
      ```bash
      ./share-apk.sh
      ```
      Este script irá:
      - Copiar o APK para o diretório compartilhado
      - Gerar um servidor web para compartilhar o APK
      - Gerar QRCode para acesso ao servidor web
      - Permitir que seja possível a atualização do aplicativo pelo menu "Sobre"

## Instalação

Para instalar, siga os passos pelo terminal.

1. **Clonar repositório**:
   ```bash
   git clone https://github.com/mvmvasconcelos/barcode-scanner ./barcode-scanner
   ```

2. **Criar e iniciar o container**:
   ```bash
   cd barcode-scanner
   docker-compose up -d --build
   ```

3. **Acessar o container Flutter**:
   ```bash
   docker-compose exec flutter bash
   ```

4. **Executar o script de configuração**:
   Estando dentro do container, execute o script de setup:
   ```bash
   ./setup.sh
   ```
   > Pode demorar alguns minutos

5. **Compilar o aplicativo pela primeira vez**:
   Ainda dentro do container, execute o script abaixo:
   ```bash
   ./build-apk.sh
   ```
   > **Nota**: Esta etapa demorará alguns minutos e ocorrerá alguns erros, já que os pacotes necessários serão baixados e instalados no container.

---

## 🔒 Licença

Este projeto é licenciado sob a [licença MIT](https://opensource.org/licenses/MIT).
