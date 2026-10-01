# Master Data Integration & Released SAP APIs

## 1. Overview & Clean Core Master Data Principles

A common anti-pattern in legacy ABAP development is querying standard ERP tables directly (e.g. `SELECT * FROM kna1` for customers or `SELECT * FROM mara/makt` for materials). In ABAP Cloud and SAP S/4HANA Cloud:
1. **Direct table reads are blocked** by the compiler syntax check.
2. Applications must consume **SAP Released CDS View Entities** under contract **C1** (System-Internal API).
3. Free-text input on transactional entities must be replaced with robust, searchable value helps.

---

## 2. Released Master Data Views Utilized

| Entity / Dimension | Legacy SAP Table | Clean Core Released CDS View | Contract | Implemented Value Help View |
|---|---|---|---|---|
| **Customer Master** | `KNA1` | `I_Customer` | C1 (Released) | [`ZSO_VH_CUSTOMER`](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_VH_CUSTOMER.ddls.asddls) |
| **Material / Product Master** | `MARA` / `MAKT` | `I_Product` & `I_ProductDescription` | C1 (Released) | [`ZSO_VH_MATERIAL`](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_VH_MATERIAL.ddls.asddls) |
| **Currency Codes** | `TCURC` | `I_Currency` | C1 (Released) | System standard `@Semantics.currencyCode: true` |
| **Unit of Measure** | `T006` | `I_UnitOfMeasure` | C1 (Released) | System standard `@Semantics.unitOfMeasure: true` |

---

## 3. Value Help Field Binding & Derivation

In [`ZSO_C_REQ_I`](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_C_REQ_I.ddls.asddls), the `Material` field uses `@Consumption.valueHelpDefinition` with `additionalBinding`:

```abap
@Consumption.valueHelpDefinition: [{
  entity: { name: 'ZSO_VH_MATERIAL', element: 'MaterialId' },
  additionalBinding: [
    { localElement: 'Material', element: 'MaterialId', usage: #RESULT },
    { localElement: 'Unit',     element: 'BaseUnit',   usage: #RESULT }
  ]
}]
Material,
```

### Business Benefits:
1. **Automatic Unit Derivation**: When a user selects a material (e.g. `MAT-PUMP-HD`), the base unit of measure (`PCE`) is automatically populated in the item line without requiring manual user input.
2. **Fuzzy Search & Typeahead**: Enabled via `@Search.searchable: true` and `@Search.fuzzinessThreshold: 0.8` on material descriptions and customer names.
3. **Master Data Integrity**: Prevents typo errors or invalid product codes from entering order fulfillment.

---

## 4. Environmental Fallback Strategy (Trial / Sandbox Environments)

In certain SAP BTP ABAP Environment trial tenants, standard master data tables (`I_Customer`, `I_Product`) may have empty seed data:
- *Fallback Mechanism*: The application architecture supports local stub/shadow data tables without requiring architectural redesign.
- *Production Environment*: When deployed to a full S/4HANA Cloud system, `I_Customer` and `I_Product` automatically bind to the enterprise master data repository without code changes.
