# Mercadex

Aplicativo colaborativo de comparação de preços em supermercados.

## Objetivo

Ajudar quem compra a encontrar o mesmo produto em mercados próximos, comparar a cesta e registrar preços observados pela comunidade.

## Funcionalidades atuais

- Busca de produtos
- Visualização de preços por supermercado
- Scanner de código de barras com a câmera (`mobile_scanner`)
- Informar preço: formulário de protótipo, sem persistir o valor
- Lista de compras em memória
- Comparação de cesta
- Login
- Login salvo no armazenamento seguro do dispositivo até o token expirar (1 dia); senha não é salva
- Suporte a mocks e à API HTTP

## Stack

Mobile:

- Flutter
- Dart
- Riverpod
- GoRouter
- HTTP
- mobile_scanner

Backend:

- NestJS
- Prisma
- PostgreSQL

Infra:

- Docker Compose

## Estrutura do repositório

```text
backend/     API NestJS e Prisma
mobile/      aplicativo Flutter
docs/        arquitetura atual e sprints
docker-compose.yml
```

O mobile segue organização por feature em `mobile/lib/features/`. Componentes compartilhados ficam em `mobile/lib/core/`.

## Executando o Mobile com Mocks

Mocks são o padrão.

```bash
cd mobile
flutter pub get
flutter run --dart-define=USE_MOCK_DATA=true
```

`USE_MOCK_DATA=true` já é o valor padrão, então `flutter run` também usa dados mockados.

## Executando com API

O endereço vem de `API_URL` em `AppConfig`. Desligue os mocks na mesma execução.

iOS Simulator:

```bash
flutter run \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_URL=http://127.0.0.1:3001
```

Android Emulator:

```bash
flutter run \
  --dart-define=USE_MOCK_DATA=false \
  --dart-define=API_URL=http://10.0.2.2:3001
```

A porta `3001` corresponde a `BACKEND_PORT` do `.env.example`.

## Backend

Copie `.env.example` para `.env` e suba os serviços:

```bash
docker compose up --build
```

O Compose sobe PostgreSQL 16, aplica as migrations, executa o seed e inicia a API. Credenciais de desenvolvimento do exemplo:

```text
POSTGRES_DB=mercadex
POSTGRES_USER=mercadex
POSTGRES_PASSWORD=change_me
BACKEND_PORT=3001
```

O seed cria a conta administrativa de desenvolvimento:

```text
Username: admin
Password: admin
```

`JWT_SECRET` é exigido pelo serviço `backend` e precisa estar definido no ambiente do Compose.

## Equipe

- Jorge Inácio
- Fernando Vieira

## Organização acadêmica

As entregas ficam documentadas em [docs/sprints/](docs/sprints/).
