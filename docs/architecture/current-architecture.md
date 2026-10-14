# Arquitetura atual

O Mercadex é um protótipo de comparação colaborativa de preços em supermercados. A organização abaixo descreve o código desta branch, sem antecipar tecnologias que ainda não entram no fluxo.

## Mobile

- Flutter e Dart
- Riverpod para estado
- GoRouter, com `StatefulShellRoute` na navegação inferior
- Repositórios por feature (`auth`, `products`, `markets`, `shopping_list`)
- Dados de produtos, mercados e login vindos de mocks locais ou da API HTTP, escolhidos por `AppConfig`
- Lista de compras persistida em SQLite local (`sqflite`), no arquivo `mercadex.db`

`USE_MOCK_DATA` vale `true` por padrão. Com `USE_MOCK_DATA=false`, os repositórios HTTP usam `API_URL`.

O scanner de código de barras usa o pacote `mobile_scanner` e o widget `MobileScanner` na página do scanner. O formulário de informar preço ainda não envia nem persiste o valor. A sessão de login continua apenas em memória.

A lista de compras é local ao dispositivo. Ela não é sincronizada com o PostgreSQL e, nesta versão, não é separada por conta.

## Backend

- NestJS, organizado por domínio: `auth`, `favorites`, `markets`, `products`, `search` e `prisma`
- Prisma como acesso ao banco
- PostgreSQL

## Fluxo dos dados remotos

```text
Flutter
  → Repository
  → Mock ou HTTP API
  → NestJS
  → Prisma
  → PostgreSQL
```

## Fluxo da lista de compras

```text
Flutter
  → ShoppingListNotifier
  → ShoppingListRepository
  → SQLite (mercadex.db no dispositivo)
```

Novas tecnologias entram somente quando uma entrega precisar delas.
