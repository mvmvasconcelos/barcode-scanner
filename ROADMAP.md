# ROADMAP - Leitor de Código de Barras IFSUL

## Visão Geral

Este documento apresenta o planejamento de desenvolvimento futuro para o aplicativo Leitor de Código de Barras, incluindo melhorias e novas funcionalidades planejadas para as próximas versões.

## Versão Atual (1.0.0)

O aplicativo atualmente oferece:
- Escaneamento de códigos de barras
- Lista simples de itens escaneados
- Cópia de códigos para a área de transferência
- Verificação de atualizações

## Roadmap de Desenvolvimento

### Versão 1.1.0 - Integração Básica com Google Sheets
- [ ] Autenticação com Google (OAuth 2.0)
- [ ] Configuração de acesso à API Google Sheets
- [ ] Interface para selecionar planilha de destino
- [ ] Envio básico de códigos escaneados para uma planilha

### Versão 1.2.0 - Área Avançada: Módulo de Inventário Patrimonial
- [ ] Novo menu "Modo Avançado" na tela principal
- [ ] Interface para seleção de salas/localizações
- [ ] Sistema de busca de informações de itens na planilha
- [ ] Exibição de detalhes do item a partir do código lido
- [ ] Registro de localização atual de cada item

### Versão 1.3.0 - Integração Completa e Sincronização
- [ ] Sincronização bidirecional com Google Sheets
- [ ] Suporte a modo offline com sincronização posterior
- [ ] Busca avançada de itens no banco de dados local
- [ ] Sistema de categorização de itens
- [ ] Filtros por sala, tipo de item, data de cadastro, etc.

### Versão 1.4.0 - Relatórios e Exportação Avançada
- [ ] Geração de relatórios de inventário
- [ ] Exportação em múltiplos formatos (PDF, CSV)
- [ ] Histórico de alterações e movimentações
- [ ] Dashboard com estatísticas de itens por sala/setor

## Detalhamento Técnico: Área Avançada de Integração com Google Sheets

### Objetivo
Desenvolver um sistema completo para gestão de patrimônio utilizando o Google Sheets como banco de dados, permitindo escaneamento, registro e consulta de itens patrimoniais de forma simples e eficiente.

### Componentes Principais

#### 1. Autenticação e Configuração
- Implementação de OAuth 2.0 para autenticação com Google
- Tela de configuração para:
  - Selecionar/inserir ID da planilha
  - Definir abas e colunas principais
  - Configurar parâmetros de sincronização
- Armazenamento seguro de credenciais no dispositivo

#### 2. Módulo de Escaneamento para Google Sheets
- Nova opção no menu principal: "Enviar para Planilha"
- Fluxo de trabalho:
  1. Usuário escaneia um código
  2. O código é enviado para a planilha configurada
  3. Confirmação visual do envio bem-sucedido
  4. Opção para escanear o próximo item ou finalizar

#### 3. Módulo de Inventário por Sala
- Interface para seleção de sala/localização
- Fluxo de trabalho:
  1. Usuário seleciona uma sala
  2. Inicia processo de escaneamento de itens
  3. Para cada item escaneado:
     - Sistema busca informações na planilha mestra
     - Exibe dados do item (descrição, valor, responsável, etc.)
     - Confirma presença do item na localização
  4. Ao finalizar, dados são enviados para uma aba específica da sala na planilha

#### 4. Consulta de Informações
- Campo de busca para consultar itens por:
  - Código de patrimônio
  - Descrição
  - Localização
- Visualização completa do item com todos os dados disponíveis na planilha
- Histórico de localizações anteriores

### Diagrama de Fluxo de Dados

```
┌────────────┐         ┌────────────────┐         ┌───────────────┐
│            │         │                │         │               │
│  Scanner   │───────▶│ Aplicativo     │◀────────│  Google       │
│            │         │ Flutter        │         │  Sheets API   │
└────────────┘         └────────────────┘         └───────────────┘
                              │                          ▲
                              │                          │
                              ▼                          │
                      ┌────────────────┐                 │
                      │                │                 │
                      │  Cache Local   │─────────────────┘
                      │                │
                      └────────────────┘
```

### Estrutura da Planilha Google Sheets

1. **Aba: Inventário Geral**
   - Colunas: Código, Descrição, Valor, Data Aquisição, Responsável, Localização Atual, Última Verificação

2. **Aba: Salas**
   - Lista de todas as salas/localizações disponíveis

3. **Abas Dinâmicas**
   - Uma aba para cada sala/localização (criadas automaticamente)
   - Colunas: Código, Descrição, Confirmado Em (data), Status

### Requisitos Técnicos

1. **Pacotes Flutter Necessários:**
   - `googleapis`: Para comunicação com a API Google
   - `googleapis_auth`: Para autenticação OAuth 2.0
   - `google_sign_in`: Para integração com login Google
   - `sqflite`: Para armazenamento local e cache

2. **API Google Necessárias:**
   - Google Sheets API v4
   - Google Drive API (para permissões)
   - Google Identity Platform

3. **Melhorias de Infraestrutura:**
   - Sistema robusto de tratamento de erros de conexão
   - Cache eficiente para operação offline
   - Sincronização inteligente para minimizar uso de dados

## Cronograma de Implementação

| Etapa | Descrição | Tempo Estimado |
|-------|-----------|----------------|
| 1 | Configuração do ambiente e APIs Google | 1 semana |
| 2 | Implementação da autenticação OAuth | 1 semana |
| 3 | Desenvolvimento do módulo básico de envio para planilha | 2 semanas |
| 4 | Desenvolvimento do módulo de inventário por sala | 3 semanas |
| 5 | Sistema de consulta e visualização de dados | 1 semana |
| 6 | Testes e otimizações | 2 semanas |
| 7 | Implantação e documentação | 1 semana |

## Conclusão

A implementação da área avançada com integração ao Google Sheets transformará o aplicativo de um simples leitor de códigos de barras para uma solução completa de gestão patrimonial, mantendo a simplicidade de uso e adicionando recursos poderosos para gerenciamento de inventário.