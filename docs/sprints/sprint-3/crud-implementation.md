# CRUD da lista de compras

## Arquitetura

```text
ShoppingListPage / ProductPage
  → ShoppingListNotifier (AsyncNotifier, Riverpod)
  → ShoppingListRepository
  → ShoppingListDatabase
  → SQLite mercadex.db
```

A interface não executa SQL. O provider só atualiza o estado depois que o repositório devolve a lista já gravada.

| Arquivo | Responsabilidade |
| --- | --- |
| `data/shopping_list_database.dart` | Abre `mercadex.db` uma vez, cria a tabela na versão 1 e mantém a conexão. |
| `data/shopping_list_repository.dart` | CRUD, transações e conversão entre linhas SQLite e `ShoppingListItem`. |
| `domain/shopping_list_item.dart` | Produto, embalagem, quantidade e datas. |
| `presentation/providers/shopping_list_provider.dart` | Carga inicial, estado assíncrono e operações da interface. |
| `presentation/pages/shopping_list_page.dart` | Lista, quantidades, remoção, loading e erro. |

`shoppingListRepositoryProvider` entrega a implementação SQLite. Os testes substituem esse provider por um fake ou por um banco temporário.

## Operações

### CREATE

`add` procura `product_id` dentro de uma transação.

- Se não existe, insere quantidade 1 e preenche `created_at` e `updated_at`.
- Se existe, soma 1 em `quantity` e atualiza `updated_at`.

A chave primária impede uma segunda linha do mesmo produto.

### READ

Na criação do provider, `readAll` lê a tabela ordenada por `created_at` e `product_id`. A tela permanece em loading até essa leitura terminar. Ela não mostra “lista vazia” antes disso.

### UPDATE

Aumentar a quantidade usa `add` no item já existente.

Diminuir usa `decrement`:

- quantidade maior que 1: grava a nova quantidade;
- quantidade igual a 1: exclui a linha, porque a constraint não aceita zero.

### DELETE

`Remover` chama `remove`, apaga a linha e a interface só muda depois que a exclusão termina.

## Concorrência

Escritas do repositório entram numa fila. Cada inclusão, decremento ou exclusão também roda numa transação que relê a quantidade atual antes de gravar. Dois toques rápidos no mesmo produto não perdem incremento.

O notifier espera a carga inicial e serializa as próprias chamadas. A tela desliga os botões daquele item enquanto a gravação está em andamento. Na página do produto, o botão de adicionar fica desabilitado até a operação acabar.

## Erros

Exceções não são descartadas. Se a gravação falha, o estado anterior da lista permanece e a interface mostra uma mensagem de erro. A notificação de sucesso só aparece depois da gravação. Uma falha não apaga o banco. Se a carga inicial falhar, a tela oferece “Tentar novamente”.

## SQLite local e PostgreSQL remoto

| | SQLite | PostgreSQL |
| --- | --- | --- |
| Onde fica | Arquivo no dispositivo | Banco do backend |
| O que guarda nesta sprint | Lista de compras | Usuários, produtos, mercados e preços |
| Acesso | `sqflite`, direto no app | NestJS e Prisma |
| Conta | Não separa por usuário | Dados do servidor |
| Sincronização | Nenhuma | Não recebe a lista local |

A demonstração com mocks não precisa do Docker. A lista continua sendo gravada no SQLite do aparelho.
