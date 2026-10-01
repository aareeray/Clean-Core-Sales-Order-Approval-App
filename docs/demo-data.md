# Realistic Demo & Seed Data Strategy

## 1. Overview

Enterprise software demonstrations, ABAP Unit tests, and interview walkthroughs fail when populated with arbitrary junk data (e.g. `Customer: 12345`, `Material: TEST`). 

This document defines a **realistic enterprise seed dataset** reflecting real-world industrial sales orders, diverse financial tiers, multiple global clients, and distinct operational lifecycles.

---

## 2. Seed Data Catalog

| Request ID | Customer | Amount & Currency | Status | SLA Health | Assigned Approver | Business Scenario Description |
|---|---|---|---|---|---|---|
| `SO-2026-0001` | **Acme Industrial Corp** (`CUST-1001`) | **14,500.00 EUR** | `PENDING` | `DUE_SOON` (Due in 4h) | `SRM_MUELLER` (Sr. Manager) | Mid-tier order for industrial pumps & valves. Approver needs to act immediately to avoid breach. |
| `SO-2026-0002` | **TechLogix Global BV** (`CUST-1002`) | **4,200.00 EUR** | `APPROVED` | `COMPLETED` | `MGR_BAUER` (Manager) | Standard low-tier infrastructure hardware purchase. Approved within 4 hours of submission. |
| `SO-2026-0003` | **Nordic Marine Logistics** (`CUST-1003`) | **65,000.00 EUR** | `REJECTED` | `COMPLETED` | `DIR_SCHMIDT` (Director) | High-value capital generator module. Rejected due to discretionary budget cap with detailed justification. |
| `SO-2026-0004` | **Acme Industrial Corp** (`CUST-1001`) | **8,900.00 EUR** | `DRAFT` | `ON_TRACK` | *(Unassigned)* | Newly drafted cooling turbine order. Ready for simulation and submission demo. |
| `SO-2026-0005` | **Starlight Energy Systems** (`CUST-1004`) | **120,000.00 EUR** | `PENDING` | `ESCALATED` | `DIR_SCHMIDT` (Escalated) | Multi-level high-value contract. Stalled past SLA at Level 1; escalated automatically to Executive Director. |
| `SO-2026-0006` | **TechLogix Global BV** (`CUST-1002`) | **18,750.00 EUR** | `PENDING` | `BREACHED` | `SRM_MUELLER` (Sr. Manager) | Strategic hardware batch overdue by 12 hours. Prime candidate for demonstration of the `escalate` action. |

---

## 3. Master Data Alignment

The seed transactions reference standard released master data:

### Customers:
- `CUST-1001`: Acme Industrial Corp (Industrial Manufacturing, Germany)
- `CUST-1002`: TechLogix Global BV (Cloud Infrastructure, Netherlands)
- `CUST-1003`: Nordic Marine Logistics (Shipping & Freight, Norway)
- `CUST-1004`: Starlight Energy Systems (Renewables, UK)

### Materials:
- `MAT-PUMP-HD`: Heavy Duty Industrial Pump (`PCE`, Unit Price: 1,500.00 EUR)
- `MAT-VALVE-90`: High Pressure Safety Valve (`PCE`, Unit Price: 700.00 EUR)
- `MAT-SRV-RACK`: 42U Modular Server Rack (`PCE`, Unit Price: 2,100.00 EUR)
- `MAT-ENG-MOD`: Marine Generator Module (`PCE`, Unit Price: 65,000.00 EUR)
- `MAT-TURB-FAN`: Cooling Turbine Assembly (`PCE`, Unit Price: 2,225.00 EUR)

---

## 4. Automated Seed Execution (ABAP Cloud Seed Class)

In production ABAP systems, seed data is generated deterministically via an ABAP Cloud class implementing `if_oo_adt_classrun`:
- Generates 6 consistent header records.
- Inserts associated line items with correct foreign keys.
- Inserts sequential audit history records matching the realistic timeline.
- Inserts standard routing rules into `ZSO_APPR_RULE`.
