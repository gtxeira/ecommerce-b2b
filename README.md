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
| rep@test.com        | Representative (Representante Comercial) |
| supervisor@test.com | Supervisor                               |
| finance@test.com    | Finance (Financeiro)                     |
| admin@test.com      | Admin (gestão de usuários)               |

> A senha para todos é: `password123`.

---

## Arquitetura Modelo:

```Plaintext
lib/
│
├── app/                             # Configurações globais do app
│   ├── config/                      # Rotas, temas, cores, injeção de dependência global
│   └── core/                        # Componentes compartilhados por todo o sistema
│       ├── errors/                  # Falhas e exceções (Failure, Exception)
│       ├── usecases/                # Classe base abstrata para UseCases
│       └── utils/                   # Extensões, formatadores, constantes
│
└── modules/                         # O coração do DDD orientado a Features (Módulos)
    └── auth/                        # Exemplo de Feature: Autenticação
        │
        ├── domain/                  # CAMADA DE DOMÍNIO (Regras de Negócio Puras)
        │   ├── entities/            # Entidades de Negócio (ex: User)
        │   ├── value_objects/       # Objetos de Valor (ex: Email, Password com validações)
        │   ├── repositories/        # Interfaces/Contratos dos Repositórios
        │   └── usecases/            # Casos de Uso (ex: LoginWithEmail, Logout)
        │
        ├── data/                    # CAMADA DE DADOS (Infraestrutura)
        │   ├── datasources/         # Fontes de dados (AuthRemoteDataSource, AuthLocalDataSource)
        │   ├── models/              # Modelos de dados (ex: UserModel que herda de User + toJson/fromJson)
        │   └── repositories/        # Implementações dos repositórios do domínio
        │
        └── presentation/            # CAMADA DE APRESENTAÇÃO (Interface e Estado)
            ├── controllers/         # Gerenciamento de estado (Bloc, Cubit, Controller, Notifier)
            ├── pages/               # Telas completas (LoginPage, RegisterPage)
            └── widgets/             # Componentes visuais exclusivos dessa feature
```

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
└── shared_kernel/            # Núcleo Compartilhado: Classes base de DDD (Entity, ValueObject) e Objetos comuns (Cnpj, Money, Address)
```

---

## Persistência e sessão

- **Dados de negócio:** vivem exclusivamente na API C# (EF Core + SQLite/PostgreSQL).
- **Sessão:** access/refresh tokens são persistidos com `flutter_secure_storage` (fallback
  `shared_preferences` no Web). O `ApiClient` renova o access token uma vez em caso de 401 e, se o
  refresh falhar, derruba a sessão para o login.
- **Enums da API:** a camada `infrastructure/repositories/api_*` traduz os nomes PascalCase da API
  (`Representative`, `Invoicing`, `Converted`, `SaoPaulo`, etc.) para os enums do domínio Flutter.

