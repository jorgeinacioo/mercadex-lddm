# Roteiro de demonstração — Sprint 3

Este roteiro descreve o que mostrar em aula. Ele não registra uma execução já realizada e não inclui capturas.

Use o aplicativo em modo mock, sem subir o backend:

```bash
cd mobile
flutter pub get
flutter run --dart-define=USE_MOCK_DATA=true
```

`USE_MOCK_DATA=true` é o padrão. No mock, qualquer e-mail e senha não vazios entram. A sessão fica só em memória: depois de fechar o app, entre de novo para a aba Lista aparecer. Os itens devem continuar no SQLite local, sem separação por conta.

1. Abrir o Mercadex.
2. Entrar com um e-mail e uma senha quaisquer.
3. Abrir um produto.
4. Tocar em “Adicionar à lista de compras”. A mensagem de sucesso só deve aparecer depois da gravação. Isso demonstra o CREATE.
5. Abrir a aba Lista de compras e conferir nome, embalagem e quantidade. Isso demonstra o READ.
6. Aumentar a quantidade com “+”. Isso demonstra o UPDATE.
7. Fechar o aplicativo por completo.
8. Abrir o Mercadex de novo.
9. Entrar outra vez, se a aba Lista não estiver visível.
10. Abrir a lista e confirmar que o produto e a quantidade continuam lá.
11. Tocar em “Comparar supermercados” e confirmar que o total usa a quantidade restaurada.
12. Tocar em “Remover” e ver o item sair da lista. Isso demonstra o DELETE.
13. Fechar e abrir de novo, entrar se precisar, e confirmar que o item removido não voltou.

Também vale mostrar, se der tempo:

- “−” com quantidade 1 remove o item;
- adicionar o mesmo produto outra vez aumenta a quantidade, sem criar uma segunda linha;
- se a gravação falhar, a mensagem de sucesso não aparece.
