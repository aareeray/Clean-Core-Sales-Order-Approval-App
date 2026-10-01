# ADR-005: Two-Tier Authorization Architecture with Instance-Based Control

## Status
Accepted

## Context
A sales order approval app handles contractual and financial commitments. Requesters must not approve their own orders, and approvers must only access requests within their authorized scope.

## Problem
Relying on frontend UI button hiding or simple broad PFCG roles allows malicious users to bypass controls by calling OData V4 actions directly.

## Decision
We implemented a strict two-tier authorization model:
- **Tier 1 (Kernel SQL Filter)**: CDS Data Control Language (DCL) `ZSO_R_REQ_H.dcl` injects instance-level restrictions directly into generated SQL queries (`CreatedBy = $user` for Requesters, `Approver = $user` for Approvers).
- **Tier 2 (Application Layer Guard)**: RAP `get_instance_authorizations` and action method guards validate user credentials against instance state and return explicit `%msg` errors on unauthorized attempts.

## Alternatives Considered
1. **Simple Broad Role Authorization (Only checking SU21 Authorization Objects)**: Fails instance segregation (any approver could approve any order across the enterprise).
2. **Pure Application-Level Checks (No DCL)**: Allows unauthorized records to be selected from the database into memory before being filtered out, hurting performance and risking data leakage in mass queries.
3. **Combined DCL + RAP Runtime Guards**: Chosen approach. Provides ironclad security at both database query and transactional update layers.

## Consequences
- **Positive**: Complete defense against direct API bypass and horizontal privilege escalation.
- **Positive**: Transparent database filtering improves query performance for individual user inboxes.
- **Negative / Trade-off**: Administrators must assign corresponding IAM business catalogs and maintain test users across roles.
