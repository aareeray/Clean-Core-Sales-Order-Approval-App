# ADR-004: Zero-Persistence Approval Simulation Engine

## Status
Accepted

## Context
Sales representatives constructing large, complex draft orders need visibility into required approval ladders (e.g. will this order require Director sign-off?) prior to committing the request into the official approval workflow.

## Problem
Allowing draft submissions merely to "test" who will approve creates clutter in approver inboxes, triggers false workflow notifications, and corrupts audit trails if the draft is subsequently cancelled.

## Decision
We implemented a stateless, zero-persistence approval simulation service (`zcl_so_routing_engine=>simulate_route( )`) exposed via RAP static action `simulateApproval` with abstract entities `ZSO_P_SIM_IN` and `ZSO_P_SIM_OUT`.
The simulation executes identical business logic to live submission without writing records to `ZSO_REQ_H` or `ZSO_APPR_HIST`.

## Alternatives Considered
1. **Submit-and-Rollback / Temporary Draft Records**: Creating temporary database records and rolling back the transaction risks locking issues and pollutes UUID keyspaces.
2. **Duplicate Client-Side JavaScript Logic**: Re-implementing routing rules in UI5 JavaScript duplicates business logic and inevitably leads to discrepancies between frontend preview and backend routing.
3. **Stateless Domain Method Re-use**: Chosen approach. Evaluates live configuration tables in memory with 100% fidelity and zero database footprint.

## Consequences
- **Positive**: Accurate, instant pre-submission visibility for sales representatives.
- **Positive**: Guaranteed zero persistence and zero workflow noise.
- **Negative / Trade-off**: Requires separate abstract entity parameters in service metadata.
