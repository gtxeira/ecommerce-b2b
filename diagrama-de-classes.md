

# Visão Geral dos Contextos

> **Documento histórico.** Este diagrama descreve o modelo original do app Flutter, antes da
> migração para a API C#. A referência atual do domínio é
> [`../EcommerceB2b/docs/diagrama-de-classes.md`](../EcommerceB2b/docs/diagrama-de-classes.md);
> no cliente, o código correspondente vive em `lib/modules/*/model/`.

```text
┌──────────────────────┐
│ Customer Management  │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│     Sales Team       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│       Catalog        │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      Inventory       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      Order Flow      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│      Logistics       │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│   Customer Portal    │
└──────────────────────┘
```

---

# Customer Management

```plantuml
@startuml

class Company {
    +CompanyId id
    +String legalName
    +String tradeName
    +Cnpj cnpj
    +InscricaoEstadual inscricaoEstadual
    +EmailAddress email
    +PhoneNumber phone
    +Address billingAddress
    +Address shippingAddress
    +StateCode stateCode
    +Money creditLimit
}

class CustomerCreditAccount {
    +Money preApprovedLimit
    +Money openBalance
    +Money availableLimit()
}

note right of Company
  Compradores autorizados são usuários
  (IdentityAccess) com role Buyer e companyId.
end note

Company "1" *-- "1" CustomerCreditAccount

@enduml
```

---

# Sales Team

```plantuml
@startuml

class SalesRepresentative {
    +RepresentativeId id
    +String fullName
    +EmailAddress email
    +Percentage commissionRate
}

class SalesHierarchyLink {
    +RepresentativeId supervisorId
    +RepresentativeId subordinateId
}

class CustomerAssignment {
    +CompanyId companyId
}

class Commission {
    +Money baseAmount
    +Percentage rate
    +Money amount
    +CommissionStatus status
}

SalesRepresentative "1" --> "*" CustomerAssignment
SalesRepresentative "1" --> "*" Commission

SalesRepresentative "1" <-- "0..1" SalesHierarchyLink : supervisor
SalesRepresentative "1" --> "*" SalesHierarchyLink : subordinate

@enduml
```

---

# Catalog

Aqui eu faria de Product um Aggregate Root.

```plantuml
@startuml

class Product {
    +ProductId id
    +String sku
    +String name
    +String description
    +Boolean active
}

class ProductVariant {
    +ProductVariantId id
    +String color
    +String size
    +String voltage
    +String variantSku
}

class PriceTable {
    +PriceTableId id
    +String name
    +PriceScopeType scopeType
}

class PriceRule {
    +Integer minQuantity
    +Integer maxQuantity
    +StateCode stateCode
    +Money unitPrice
}

Product "1" *-- "*" ProductVariant
PriceTable "1" *-- "*" PriceRule

@enduml
```

---

# Inventory

```plantuml
@startuml

class Warehouse {
    +WarehouseId id
    +String code
    +String name
}

class StockItem {
    +Quantity physicalQuantity
    +Quantity reservedQuantity
    +Quantity availableQuantity()
}

class StockReservation {
    +OrderId orderId
    +Quantity quantity
}

Warehouse "1" *-- "*" StockItem
StockItem "1" --> "*" StockReservation

@enduml
```

---

# Order Flow

Esse é o coração do sistema.

```plantuml
@startuml

class Quote {
    +QuoteId id
    +QuoteStatus status
    +Money total
    +DateTime? createdAt
}

class QuoteItem {
    +Quantity quantity
    +Money unitPrice
}

class SalesOrder {
    +OrderId id
    +OrderStatus status
    +Money total
    +CreditStatus creditStatus
    +DateTime? createdAt
    +DateTime? lastActivityAt
    +DateTime? activityAt
}

class OrderTimelineEntry {
    +String id
    +DateTime? occurredAt
    +OrderTimelineEventType type
    +OrderStatus? fromStatus
    +OrderStatus? toStatus
    +CreditStatus? toCreditStatus
    +FinanceDecision? decision
    +String? actorId
    +String? actorRole
    +String? note
}

class OrderItem {
    +Quantity quantity
    +Money unitPriceSnapshot
}

class FinanceReview {
    +FinanceDecision decision
    +String reason
}

Quote "1" *-- "*" QuoteItem

SalesOrder "1" *-- "*" OrderItem
SalesOrder "1" --> "0..1" FinanceReview
SalesOrder "1" o-- "*" OrderTimelineEntry : lê do endpoint

@enduml
```

---

# Logistics

```plantuml
@startuml

class PickingList {
}

class PackingSession {
}

class Shipment {
    +TrackingCode trackingCode
    +ShipmentStatus status
}

class ShippingLabel {
    +String labelNumber
}

class TrackingEvent {
    +TrackingStatus status
    +DateTime occurredAt
}

Shipment "1" *-- "*" TrackingEvent
Shipment "1" *-- "1" ShippingLabel

@enduml
```

---

# Customer Portal

```plantuml
@startuml

class BoletoCopy {
    +String barcode
    +String url
}

class ReturnRequest {
    +RmaId id
    +RmaStatus status
    +String reason
}

class ReturnRequestItem {
    +Quantity quantity
    +String problemDescription
}

ReturnRequest "1" *-- "*" ReturnRequestItem

@enduml
```

---

# Diagrama mais importante: Aggregate Roots

Eu definiria os Aggregates assim:

```text
Company
└── CustomerCreditAccount

SalesRepresentative
├── CustomerAssignment
├── Commission
└── SalesHierarchyLink

Product
└── ProductVariant

PriceTable
└── PriceRule

Warehouse
├── StockItem
└── StockReservation

Quote
└── QuoteItem

SalesOrder
├── OrderItem
└── FinanceReview

Shipment
├── ShippingLabel
└── TrackingEvent

ReturnRequest
└── ReturnRequestItem
```

---

# Serviços de domínio

```text
CreditPolicy
CommissionCalculator
InventoryAllocator
OrderPricingService
OrderStateMachine
FreightQuoteService
TrackingService
```

---

# Máquina de estados do pedido

Eu modelaria isso explicitamente:

```plantuml
@startuml

[*] --> Quote

Quote --> PendingFinanceApproval

PendingFinanceApproval --> BlockedByFinance
PendingFinanceApproval --> PickingPacking

BlockedByFinance --> PickingPacking

PickingPacking --> InTransit

InTransit --> Delivered

Delivered --> RMA

@enduml
```

---

# Melhoria aos requisitos

```text
shared_kernel
```

```text
shared_kernel
│
├── ids/
├── enums/
├── value_objects/
├── events/
├── specifications/
├── domain_services/
└── failures/
```

com:

```text
Money
Percentage
Quantity
Weight
Address
PhoneNumber
EmailAddress
ZipCode
StateCode
TrackingCode

OrderStatus
RmaStatus
ShipmentStatus
CreditStatus
FinanceDecision

DomainEvent
AggregateRoot
Entity
ValueObject
```
