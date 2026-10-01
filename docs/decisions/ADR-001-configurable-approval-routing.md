# ADR-001: Configurable Approval Routing Matrix

## Status
Accepted

## Context
In sales order management, delegation of authority policies and financial approval limits change regularly due to organizational shifts, risk policies, and inflation. The initial prototype embedded approval thresholds directly in ABAP conditional branches (`IF TotalAmount >= 10000`).

## Problem
Hard-coded rules violate Clean Core maintainability principles. Updating thresholds required code changes, developer allocation, testing cycles, and transports across development, quality, and production environments.

## Decision
We implemented a dedicated configuration table `ZSO_APPR_RULE`, CDS interface view `ZSO_I_APPR_RULE`, and a centralized domain routing engine `ZCL_SO_ROUTING_ENGINE`.
All routing decisions (in RAP BO actions, SAP Build Process Automation workflow step resolution, and approval simulation) invoke `zcl_so_routing_engine=>determine_route( )` as the single source of truth.

## Alternatives Considered
1. **SAP Business Rules Service / Decision Service**: Excellent for ultra-complex rule graphs, but introduces additional service subscription costs and runtime latency for standard hierarchical approvals.
2. **Hard-coded ABAP constants / BRFplus**: BRFplus is not supported in ABAP Cloud.
3. **Configuration table + Centralized Domain Engine**: Chosen approach. Complies 100% with ABAP Cloud, incurs zero external service latency, and allows dynamic multi-level expansion.

## Consequences
- **Positive**: Business administrators can adjust tiers, add multi-level approval stages, and update SLA hours without modifying ABAP code.
- **Positive**: Single source of truth guarantees consistent routing across UI, simulation, and workflow.
- **Negative / Trade-off**: Requires administrative maintenance of rule records and validation against overlapping amount ranges.
