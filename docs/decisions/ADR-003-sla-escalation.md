# ADR-003: SLA Monitoring and Decoupled Escalation Mechanism

## Status
Accepted

## Context
Sales orders pending approval must be resolved within contracted SLA timeframes to avoid operational disruption and revenue recognition delays.

## Problem
A static status field without due date calculation or breach awareness allows orders to stall silently in approver queues without executive visibility or automated escalation.

## Decision
We added `ApprovalDueDate`, `SlaStatus`, `EscalationLevel`, `EscalatedTo`, and `EscalatedAt` to the header entity.
Upon submission, `zcl_so_routing_engine` calculates target due dates based on configured `sla_hours`.
Escalation is executed via RAP action `escalate`, which can be triggered directly by authorized administrators or asynchronously by SAP Build Process Automation timer boundary events.

## Alternatives Considered
1. **Background Job Polling in ABAP Cloud (`cl_apj_rt_exec_subobject`)**: Running continuous database scans for overdue records creates database contention and background job scheduling overhead.
2. **Synchronous Client-Side Checking in UI**: Cannot escalate orders if no user opens the application.
3. **Decoupled Workflow Timer Boundary Event with OData Action Hook**: Chosen approach. Respects Clean Core principles by delegating temporal wait states and alarms to the SAP Build Process Automation engine while maintaining transactional integrity in RAP.

## Consequences
- **Positive**: Proactive identification of approval bottlenecks with semantic visual badges on Fiori screens.
- **Positive**: Automated hierarchical escalation without custom background daemon scripts.
- **Negative / Trade-off**: Requires synchronizing SLA status across workflow process triggers and RAP data layers.
