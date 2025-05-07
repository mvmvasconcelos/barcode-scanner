# Leitor de Código de Barras

Projeto simplificado para criação de um aplicativo android para leitura de código de barras em etiquetas de patrimônio e jogá-las em uma lista simples.

## Ambiente de Desenvolvimento com Docker

Este projeto está configurado para desenvolvimento utilizando Docker, o que permite um ambiente consistente e isolado para desenvolvimento Flutter.

### Pré-requisitos

- Docker instalado no servidor
- Docker Compose instalado no servidor

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
      ./build-offline-apk.sh
      ```
      Este script irá:
      - Atualizar versão build do aplicativo
      - Compilar o projeto Flutter
      - Gerar o APK do aplicativo

      ### Parâmetros do Script
      `major` -- versão principal
      `minor` -- versão secundária
      `patch` -- versão de correção
      Exemplo: `./build-offline-apk.sh minor`

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
