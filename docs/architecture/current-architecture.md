# Arquitetura atual

O Mercadex é um protótipo de comparação colaborativa de preços em supermercados. Este documento descreve o código da versão entregue no TI4.

## Visão geral

```text
Flutter (iOS / Android)
 ├─ SQLite (mercadex.db) ............ lista de compras
 ├─ SharedPreferences ............... ordenação da lista, tema, vistos recentemente
 ├─ Armazenamento seguro ............ sessão (token JWT)
 └─ HTTP + JSON ──► NestJS ──► Prisma ──► PostgreSQL
                     (Docker Compose)
```

O PostgreSQL é a única fonte de verdade para produtos, supermercados e preços. A lista de compras é pessoal e fica só no aparelho.

## Mobile

Organização por feature em `mobile/lib/features/` (`auth`, `home`, `markets`, `prices`, `products`, `profile`, `scanner`, `shopping_list`), cada uma com `data`, `domain` e `presentation` quando necessário. Código compartilhado fica em `mobile/lib/core/` (configuração, rede, tema, formatação, widgets).

- **Estado:** Riverpod 3. Os repositórios são expostos por providers (`productsRepositoryProvider`, `marketsRepositoryProvider`, `pricesRepositoryProvider`, `authRepositoryProvider`, `shoppingListRepositoryProvider`), o que permite trocá-los nos testes.
- **Dados remotos em cache:** `productDealsProvider(id)` guarda os preços de um produto e é compartilhado pela página do produto, pela lista e pela comparação. Ao publicar um preço, o provider é invalidado e as três telas se atualizam.
- **Navegação:** GoRouter, com `StatefulShellRoute` para as abas Início, Lista e Perfil.
- **Rede:** `ApiClient` aplica timeout de 10 s e converte falhas em `ApiException` (sem conexão, 401, 404, 5xx), exibidas com mensagens em português e opção de tentar de novo.
- **Dinheiro:** valores em centavos inteiros (`core/format/money.dart`), formatados como `R$ 1.234,56`.

### Modo API e modo demonstração

`AppConfig` decide a fonte dos dados:

| Configuração | Fonte |
| --- | --- |
| `USE_MOCK_DATA=false` + `API_URL` | API NestJS |
| sem `API_URL` (padrão) | catálogo empacotado `assets/demo/catalog.json` |

O catálogo empacotado é uma cópia de `backend/prisma/seed/catalog.json`, o mesmo arquivo que o seed grava no banco. No modo demonstração, publicar preço fica desabilitado com uma explicação, porque o valor não seria visto por outras pessoas.

### Persistência local

| Dado | Tecnologia | Chave / arquivo |
| --- | --- | --- |
| Lista de compras | SQLite (`sqflite`) | `mercadex.db`, tabela `shopping_list_items` |
| Ordenação da lista | SharedPreferences | `shopping_list_sort_order` |
| Tema escuro | SharedPreferences | `dark_mode` |
| Vistos recentemente | SharedPreferences | `recent_products` (JSON, até 8 itens) |
| Sessão | `flutter_secure_storage` (Keychain/Keystore) | `auth_session` |

A lista não é separada por conta e não é enviada ao servidor. Ela funciona sem login.

## Backend

NestJS organizado por domínio, no fluxo Controller → Service → Prisma → PostgreSQL:

| Módulo | Responsabilidade |
| --- | --- |
| `auth` | Login com usuário e senha (bcrypt) e emissão de JWT; `JwtAuthGuard` |
| `products` | Catálogo com menor e maior preço, busca por código de barras e preços por produto |
| `search` | Busca por nome, marca, categoria e código, sem diferenciar acentos |
| `markets` | Redes, unidades e preço de cada produto na rede |
| `prices` | Publicação de preços por usuários autenticados |
| `prisma` | Conexão com o PostgreSQL |

A entrada é validada por `ValidationPipe` global com DTOs (`class-validator`); campos não previstos são rejeitados.

### Endpoints

| Método | Rota | Autenticação | Uso no app |
| --- | --- | --- | --- |
| GET | `/health` | — | verificação |
| POST | `/auth/login` | — | login |
| GET | `/products` | — | início, catálogo |
| GET | `/search?query=` | — | busca |
| GET | `/products/barcode/:barcode` | — | scanner |
| GET | `/products/:id/deals` | — | produto, lista, comparação |
| GET | `/markets` | — | início, informar preço |
| GET | `/markets/:id` | — | supermercado, informar preço |
| POST | `/prices` | JWT | informar preço |

### Publicação de preços

`POST /prices` recebe `productId`, `branchId` e `price`. O autor vem do token (`sub`), nunca do corpo da requisição. Em uma transação, o preço ativo anterior daquele produto naquela unidade passa para `EXPIRED` e o novo é criado como `ACTIVE`. Assim, cada prateleira tem um único preço vigente e a comparação nunca mistura valores antigos e novos.

Os preços publicados entram ativos imediatamente. Não há moderação nesta versão.

### Banco de dados

Modelos Prisma: `User`, `Product` (com `barcode` único), `Market`, `MarketBranch` e `PriceObservation` (status `PENDING`, `ACTIVE`, `REJECTED` ou `EXPIRED`). As mudanças de schema são feitas por migrations em `backend/prisma/migrations/`.

O seed lê `catalog.json` (4 redes, 54 produtos, preços por unidade) e cria as contas de demonstração. Ele pode ser executado de novo sem reativar preços que usuários substituíram.

## Fluxo da comparação

```text
Lista (SQLite)
  → productDealsProvider para cada item
  → menor preço de cada produto em cada rede × quantidade
  → ranking só com cestas completas
  → mercados incompletos listados à parte, com os produtos que faltam
```

## Limitações conhecidas

- Preços, endereços e códigos de barras do catálogo são fictícios (EAN-13 de uso interno, prefixo 200).
- Não há cadastro de usuários pelo app; as contas vêm do seed.
- Localização e distância até as lojas não são usadas, apesar de o banco guardar latitude e longitude.
- A busca filtra o catálogo em memória no backend, adequado ao tamanho atual do catálogo.
