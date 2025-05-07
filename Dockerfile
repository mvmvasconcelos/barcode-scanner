FROM ubuntu:20.04

# Evitar interações com prompts durante a instalação de pacotes
ENV DEBIAN_FRONTEND=noninteractive

# Instalar dependências necessárias (mínimas)
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    openjdk-11-jdk \
    wget \
    apt-transport-https

# Definir variáveis de ambiente para Android SDK
ENV ANDROID_SDK_ROOT /opt/android-sdk
ENV PATH $PATH:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools

# Criar diretório para Android SDK
RUN mkdir -p ${ANDROID_SDK_ROOT}

# Baixar e instalar Android SDK
RUN wget -q https://dl.google.com/android/repository/commandlinetools-linux-7583922_latest.zip -O /tmp/cmdline-tools.zip && \
    mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    unzip -q /tmp/cmdline-tools.zip -d /tmp && \
    mv /tmp/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Aceitar licenças Android SDK
RUN yes | sdkmanager --licenses

# Instalar build-tools e platform-tools mínimos necessários
RUN sdkmanager "build-tools;30.0.3" "platforms;android-30" "platform-tools"

# Definir variáveis de ambiente para Flutter
ENV FLUTTER_HOME /opt/flutter
ENV PATH $PATH:$FLUTTER_HOME/bin

# Baixar Flutter diretamente como arquivo ZIP (estável e mais confiável que git clone)
RUN mkdir -p ${FLUTTER_HOME} && \
    cd /opt && \
    wget -q https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.13.9-stable.tar.xz -O flutter.tar.xz && \
    tar xf flutter.tar.xz && \
    rm flutter.tar.xz

# Configurar Flutter para ambiente headless (sem GUI)
RUN flutter config --no-analytics && \
    flutter config --no-enable-web && \
    flutter config --no-enable-ios && \
    flutter precache --android && \
    flutter doctor

# Configurar diretório de trabalho
WORKDIR /app

# Expor porta para hot reload
EXPOSE 8080

# Comando padrão ao iniciar o container
CMD ["bash"]