# Leitor de Código de Barras

[![Status](https://img.shields.io/badge/Status-Concluído-1dfd5c)](https://github.com/mvmvasconcelos/)[![Versão](https://img.shields.io/badge/version-1.0.2-blue.svg)](https://github.com/ifsul/barcode-scanner) [![Flutter](https://img.shields.io/badge/Flutter-v3.1.5+-02569B?logo=flutter)](https://flutter.dev/) [![Licença](https://img.shields.io/badge/licença-MIT-green.svg)](https://opensource.org/licenses/MIT) [![Platform](https://img.shields.io/badge/platform-Android-brightgreen.svg)](https://www.android.com/) [![Docker](https://img.shields.io/badge/Docker-Suportado-2496ED?logo=docker)](https://www.docker.com/) [![IFSul](https://img.shields.io/badge/IFSul-Venâncio%20Aires-195128)](https://vairao.ifsul.edu.br/)


Projeto para criação de um aplicativo Android para leitura de código de barras. O app lê um código de barras e armazena numa lista. Depois o usuário selecionar um ou vários códigos e mandá-los para a área de transferência do celular, colando a lista em um bloco de notas ou mensageiro. Em breve será incorporado em um app para controle patrimonial no IFSul.

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
      ./compilaApk.sh
      ```
      Este script irá:
      - Atualizar versão build do aplicativo
      - Compilar o projeto Flutter
      - Gerar o APK do aplicativo

      ### Parâmetros do Script
      `major` -- versão principal
      `minor` -- versão secundária
      `patch` -- versão de correção
      Exemplo: `./compilaApk.sh minor`

   2. **Compartilhar o APK**
      Após compilar o projeto, execute o script abaixo para compartilhar o APK:
      ```bash
      ./compartilhaApk.sh
      ```
      Esse script gera um servidor http python que permite que o APK seja baixado de duas formas: diretamente pelo link ou pelo QRCode gerado no terminal.
      Além disso, com o servidor rodando, é possível clicar no botão "Verificar Atualizações" no aplicativo para baixar a nova versão do APK compilado. Está configurado para aceitar atualizações desde que a versão do APK seja diferente da versão instalada, independente da versão ser maior ou menor.
      Na prática, a primeira vez você precisará baixar o APK diretamente, e as próximas vezes você poderá usar o botão "Verificar Atualizações" para baixar a versão disponível.

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
   ./compilaApk.sh
   ```
   > **Nota**: Esta etapa demorará alguns minutos e ocorrerá alguns erros, já que os pacotes necessários serão baixados e instalados no container.

---

## 🔒 Licença

Este projeto é licenciado sob a [licença MIT](https://opensource.org/licenses/MIT).
