# Mercadex

**Compare preços. Compre melhor.**

Aplicativo colaborativo de comparação de preços em supermercados. Quem compra pesquisa produtos, vê o preço em cada rede, monta a lista de compras e descobre em qual supermercado a compra inteira sai mais barata. Quem vê um preço diferente na prateleira pode informá-lo, e o valor passa a valer para todos.

Projeto Integrado I — Desenvolvimento Móvel. Equipe: Jorge Inácio e Fernando Vieira.

## Funcionalidades

| Funcionalidade | Como funciona |
| --- | --- |
| Busca | Por nome, marca, categoria ou código de barras, sem diferenciar acentos ("cafe" encontra "Café"). Sem termo, lista todos os produtos com filtro por categoria. |
| Produto | Preço em cada supermercado, do mais barato ao mais caro, com destaque para o menor preço e quanto se economiza. Mostra se o preço é de referência ou informado por um usuário, e há quanto tempo. |
| Supermercados | Unidades, endereço e preço de cada produto naquela rede. |
| Lista de compras | CRUD em SQLite no aparelho (`mercadex.db`): adicionar, alterar quantidade e remover. A ordenação (adição ou nome A–Z) fica em SharedPreferences. |
| Comparação da cesta | Soma a lista em cada rede, considerando as quantidades. Só cestas completas entram no ranking; mercados sem algum produto aparecem à parte, com o que falta. |
| Informar preço | Exige login. O preço é enviado à API, que registra o autor a partir do token e substitui o preço anterior daquela unidade. |
| Scanner | Lê EAN-13/EAN-8/UPC/Code 128 com a câmera e abre o produto. Também aceita digitar o código, o que permite usar o simulador. |
| Conta | Login com JWT; a sessão fica no armazenamento seguro do aparelho até o token expirar (1 dia). |
| Preferências | Tema claro/escuro e produtos vistos recentemente, em SharedPreferences. |

Os preços e endereços do catálogo são **fictícios**, criados para demonstração. Os nomes das redes são usados apenas como exemplo.

## Stack

- **Mobile:** Flutter, Dart, Riverpod 3, GoRouter, `http`, `sqflite`, `shared_preferences`, `flutter_secure_storage`, `mobile_scanner`
- **Backend:** NestJS, Prisma 7, PostgreSQL 16, JWT, `class-validator`
- **Infra:** Docker Compose

```text
backend/     API NestJS e Prisma (schema, migrations e seed)
mobile/      aplicativo Flutter, organizado por feature em lib/features/
docs/        arquitetura, sprints e material de demonstração
```

O catálogo de demonstração é um único arquivo, `backend/prisma/seed/catalog.json`, usado pelo seed do banco. O app traz uma cópia em `mobile/assets/demo/catalog.json` para o modo offline; um teste garante que as duas cópias são iguais.

## Executando

### 1. Backend (API + banco)

```bash
cp .env.example .env          # defina um JWT_SECRET próprio
docker compose up --build
```

O Compose sobe o PostgreSQL, aplica as migrations, roda o seed e inicia a API em `http://127.0.0.1:3001` (porta `BACKEND_PORT`).

Para recomeçar com o banco limpo (por exemplo, antes de uma apresentação):

```bash
docker compose down -v && docker compose up --build
```

Contas criadas pelo seed (somente desenvolvimento):

| Usuário | Senha |
| --- | --- |
| `jorge` | `mercadex` |
| `fernando` | `mercadex` |
| `admin` | `admin` |

Verificação rápida de todos os endpoints usados pelo app (publica um preço de teste):

```bash
cd backend && ./scripts/smoke-test.sh
```

### 2. App conectado à API

```bash
cd mobile
flutter pub get

# iOS Simulator
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_URL=http://127.0.0.1:3001

# Android Emulator
flutter run --dart-define=USE_MOCK_DATA=false --dart-define=API_URL=http://10.0.2.2:3001
```

Num celular físico, use o IP do computador na rede local (por exemplo `http://192.168.0.10:3001`) e mantenha os dois na mesma rede.

### 3. App em modo demonstração (sem backend)

```bash
cd mobile
flutter run
```

Sem `API_URL`, o app usa o catálogo empacotado e mostra o selo "Modo demo". Busca, produtos, lista, comparação e scanner funcionam; publicar preços exige a API e o app avisa isso em vez de simular sucesso. As contas da tabela acima também funcionam no modo demo.

## Testes

```bash
cd mobile
flutter analyze
flutter test

# Fluxo completo no simulador, com a API rodando:
flutter test integration_test -d <id-do-simulador> \
  --dart-define=USE_MOCK_DATA=false --dart-define=API_URL=http://127.0.0.1:3001
```

```bash
cd backend
npm run lint
npm run build
./scripts/smoke-test.sh
```

O teste de integração busca "cafe", entra como `jorge`, publica um preço e confere que ele aparece como o melhor preço. Ele grava dados reais no banco.

## Demonstração do scanner

O simulador não tem câmera: use "Digitar o código" na tela do scanner. Para ler com a câmera de um celular, abra [docs/demo/etiquetas-codigo-de-barras.html](docs/demo/etiquetas-codigo-de-barras.html) no computador ou imprima a página. Para usar um produto real, troque o campo `barcode` desse produto no `catalog.json` pelo código da embalagem, copie o arquivo para `mobile/assets/demo/` e rode o seed de novo.

## Documentação

- [Arquitetura atual](docs/architecture/current-architecture.md)
- [Sprints](docs/sprints/)

Os arquivos do ícone e da tela de abertura ficam em `mobile/assets/branding/`; depois de alterá-los, rode `dart run flutter_launcher_icons` e `dart run flutter_native_splash:create` em `mobile/`. Os logotipos dos supermercados ficam em `mobile/assets/markets/` (fontes em `SOURCES.md`).
