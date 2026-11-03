# ecommerce_b2b

Um projeto Flutter para E-commerce B2B (Atacado).

Documentação do Projeto:

- Arquivo: [Documentação Trabalho Final - PDF](./documentacao_trabalho_final_flutter.pdf).

-
Overleaf: [Documentação Trabalho Final - Overleaf](https://www.overleaf.com/project/6a39c5295711b4fb2b9409be).

---

## Como Executar o Projeto

O app é um **cliente fino da API C#** (`../EcommerceB2b`). Toda a regra de negócio, persistência e
autorização ficam na API; o Flutter apenas apresenta dados e valida formulários.

### Pré-requisitos

- Flutter compatível com Dart `^3.12.2`.
- API rodando (por padrão em `http://localhost:5143`).

### 1. Subir a API

```bash
cd ../EcommerceB2b
dotnet run --project src/EcommerceB2b.Api --launch-profile http
```

A API cria o SQLite e roda o seed demo no startup.

### 2. Obter dependências do Flutter

```bash
flutter pub get
```

### 3. Executar os testes

```bash
flutter analyze
flutter test
```

> **Cobertura atual:** o foco está em cubits, repositórios HTTP, formatação e widgets
> reutilizáveis. Páginas completas (`order_list_page`, `order_detail_page`) ainda não têm widget
> test: elas dependem do `B2BAppBar`, que lê o `AuthCubit` pelo `UserProfileDropdown`. Os pedaços
> testáveis já foram extraídos (`OrderSearchField`, `OrderSummaryTile`, `OpenOrdersBadge`).

### 4. Executar o aplicativo

```bash
# Web/desktop (API local)
flutter run

# Emulador Android (a URL padrão já é 10.0.2.2)
flutter run

# Dispositivo físico ou API remota
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:5143
```

> O app não abre mais um banco local. Sem a API no ar ele mostra a tela de login e as chamadas
> falham com a mensagem de conectividade.

---

## Credenciais de Acesso (Testes):

| E-mail              | Perfil (Role)                            |
|---------------------|------------------------------------------|
| buyer@test.com      | Buyer (Comprador)                        |
| pepper@stark.com    | Buyer (Comprador)                        |
| rep@test.com        | Representative (Representante Comercial) |
| supervisor@test.com | Supervisor                               |
| finance@test.com    | Finance (Financeiro)                     |
| admin@test.com      | Admin (gestão de usuários)               |

> A senha para todos é: `password123`.

---

## Arquitetura do cliente

O app é um **cliente fino**: não tem banco local nem regra de negócio própria. A API C# é a
autoridade sobre validação, autorização, crédito, estoque e transições de estado; o Flutter
mantém apenas um **modelo de leitura** e a apresentação.

```Plaintext
lib/
│
├── app/                             # Infraestrutura transversal do app
│   ├── core/
│   │   ├── errors/                  # AppError + AppErrorCodes (mesmo vocabulário da API)
│   │   ├── events/                  # Canais de evento (invalidação de sessão e de pedidos)
│   │   ├── format/                  # Formatação de exibição (datas)
│   │   ├── network/                 # ApiClient, JWT/refresh, envelope { data, meta }
│   │   ├── result/                  # Result/Success/Failure
│   │   ├── routes/                  # go_router (AppPage, OrderRoutes)
│   │   └── di/                      # get_it
│   └── presentation/                # Layout, tema, widgets globais e inputs formz
│
└── modules/                         # Um diretório por contexto de negócio
    └── catalog/                     # Exemplo: Produtos e Tabelas de Preço
        ├── model/                   # Modelo de leitura do cliente
        │   ├── product.dart         # Entidades e VOs (Money, Quantity, ...)
        │   ├── enums/               # Enums do contrato (status, UF, papel)
        │   ├── repositories/        # Contratos que a infraestrutura implementa
        │   └── ...                  # IDs tipados e objetos comuns
        │
        ├── application/             # Use cases: orquestram repositórios
        │
        ├── infrastructure/          # Implementações HTTP
        │   └── repositories/        # api_*: traduzem JSON da API -> model
        │
        └── presentation/            # Cubits, páginas e widgets do contexto
```

### Quem é dono de cada regra

| Responsabilidade | Onde mora |
|---|---|
| CNPJ, crédito, hierarquia comercial, preço, transição de pedido, estoque | **API C#** |
| Busca, filtros e paginação de listagem (`?query`, `page`, `pageSize`) | **API C#** |
| Validação de formulário, máscara e formatação para o usuário | Cliente (espelho de UX) |
| Tradução dos enums PascalCase da API (`Representative`, `SaoPaulo`, ...) | `infrastructure/repositories/api_*` |
| Envelope `{ data, meta }` / `{ errors, meta }` e refresh de token | `app/core/network` |

Os VOs do cliente (`Cnpj`, `EmailAddress`, `Money`, ...) continuam validando para dar feedback
imediato no formulário, mas **não são a fonte da verdade**: os códigos de erro são os mesmos da
API e qualquer regra que divirja é considerada bug do cliente.

---

## Divisão dos módulos

```Plaintext
lib/modules/
├── customer_management/      # Gestão de Empresas (Clientes B2B), Compradores Autorizados e Limite de Crédito
├── sales_team/               # Representantes de Venda, Hierarquia de Supervisão, Carteira e Comissões
├── catalog/                  # Produtos, Grades de Itens e Tabelas de Preço
├── inventory/                # Controle de Estoque, Alocação, Reservas de Itens e Gestão de Armazém (Warehouse)
├── order_flow/               # Fluxo de Orçamentos (Quotes), Pedidos de Venda (Sales Orders) e Liberação Financeira
├── logistics/                # Fluxo de Expedição (Picking, Packing), Etiquetas, Rastreamento e Frete
├── customer_portal/          # Portal do Cliente, Histórico de Compras, Download de Boletos e Devoluções (RMA)
├── identity_access/          # Controle de Autenticação, Login, Gerenciamento de Sessão e Perfis de Acesso (Roles)
└── shared_kernel/            # Modelo comum: Entity, EntityId, IDs tipados (Cnpj, Money, Address, ...)
```

---

## Persistência e sessão

- **Dados de negócio:** vivem exclusivamente na API C# (EF Core + SQLite/PostgreSQL).
- **Sessão:** access/refresh tokens são persistidos com `flutter_secure_storage` (fallback
  `shared_preferences` no Web). O `ApiClient` renova o access token uma vez em caso de 401 e, se o
  refresh falhar, derruba a sessão para o login.
- **Enums da API:** a camada `infrastructure/repositories/api_*` traduz os nomes PascalCase da API
  (`Representative`, `Invoicing`, `Converted`, `SaoPaulo`, etc.) para os enums do modelo Flutter.

---

## Estado, invalidação e notificações

O cliente **não mantém store global**: cada tela carrega seus dados ao montar (e por
pull-to-refresh). Para o pouco estado que precisa sobreviver à tela, existe um canal de eventos em
`app/core/events/`.

```text
mutação confirmada → evento (sem payload) → consumidor relê da API → rebuild
```

| Canal | Emissor | Consumidor | Efeito |
|---|---|---|---|
| `SessionEvents.onExpired` | `ApiClient` (refresh falhou) | `AuthCubit` | derruba a sessão e volta ao login |
| `OrderEvents.onChanged` | `FinanceReviewCubit` (aprovar/reprovar/faturar), `BillingPage` (faturar) | `OpenOrdersCubit` | recalcula o selo de pedidos em aberto |

**O evento não transporta dados.** Quem escuta relê a fonte
(`SalesOrderRepository.getAll()`, já escopada por papel no backend), então o selo e a lista nunca
divergem. Uma falha na releitura mantém o último valor conhecido em vez de derrubar a tela.

**Regras**

1. Emita **só depois** do sucesso da API — nunca de forma otimista.
2. Emita de quem executou a mutação, não de quem apenas navegou.
3. O evento é global do app, não da tela: o consumidor precisa tolerar falha sem propagar.
4. Listas de tela (`/orders`, "Atividades Recentes") **não** assinam o evento — recarregam ao
   montar e por pull-to-refresh.
5. `OpenOrdersCubit` vive no `MyApp` (acima do router), carrega quando a sessão autentica e zera
   no logout ou para o comprador, que não usa a navegação.

## Rotas de pedidos

`/orders` (abertos x encerrados, com busca por id, empresa ou nome fantasia; `?group=closed` abre
direto no grupo) e `/orders/:id` (detalhe). Ficam fora de `AppPage`-como-módulo apenas no
cadastro de rotas: a entrada `AppPage.orders` existe para a sidebar e leva o mesmo caminho.
Comprador é redirecionado para o portal por um `redirect` na própria rota.

## Datas

A API expõe `createdAt` em **UTC**. O cliente converte para o fuso local e formata com
`formatDate`/`formatDateTime` (`app/core/format/`) — helper próprio, no mesmo espírito de
`Money.formatted`, para não adicionar o pacote `intl` por um único formato. Ordenação de
"recentes" usa `mostRecentSalesOrders` (`sales_order_sort.dart`).
