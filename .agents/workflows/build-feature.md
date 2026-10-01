---
name: build-feature
description: >
  Workflow slash command (/build-feature) that orchestrates the AI team
  through a full feature implementation pipeline: design → implement →
  test → secure → document → review.
slash_command: build-feature
---

# /build-feature Workflow

## Purpose

Orchestrates the full lifecycle of a feature from design to documentation.
Chains SAP_ABAP_ARCHITECT → specialist agent → SAP_TEST_ENGINEER →
SAP_SECURITY_ENGINEER → SAP_DOCUMENTATION_WRITER.

---

## Invocation

`
/build-feature <feature-name> [optional: description]
`

Examples:
- `/build-feature create-database-tables`
- `/build-feature create-cds-views`
- `/build-feature create-rap-bo`
- `/build-feature create-service`
- `/build-feature create-fiori-app`
- `/build-feature create-approval-workflow`
- `/build-feature create-authorization-and-tests`
- `/build-feature generate-readme`

---

## Pipeline

### Step 1 — Architect Review (SAP_ABAP_ARCHITECT)

Agent: **SAP_ABAP_ARCHITECT**
Input: Feature name + any additional description from the user
Output: Approved design specification with:
  - Object list (tables, CDS views, classes, etc.)
  - Naming conventions confirmed (`ZSO_` prefix)
  - Clean-core compliance pre-check
  - Handover to appropriate specialist agent

Pause condition: Architect must confirm design is ABAP Cloud compliant before proceeding.

---

### Step 2 — Implementation (Specialist Agent)

Route to specialist based on feature name:

| Feature Keyword       | Specialist Agent         |
|-----------------------|--------------------------|
| `database-tables`   | SAP_DATABASE_ENGINEER    |
| `cds-views`         | SAP_ABAP_ARCHITECT + SAP_DATABASE_ENGINEER |
| `rap-bo`            | SAP_RAP_DEVELOPER        |
| `service`           | SAP_RAP_DEVELOPER        |
| `fiori-app`         | SAP_FIORI_DEVELOPER      |
| `approval-workflow` | SAP_WORKFLOW_ARCHITECT   |
| `authorization`     | SAP_SECURITY_ENGINEER    |
| `readme`            | SAP_DOCUMENTATION_WRITER |

Agent: Specialist (from table above)
Input: Architect's design specification + relevant skill file
Output: Implemented artifact(s) with:
  - Complete, syntactically correct ABAP/CDS/DCL code
  - All objects assigned to package `Z_SALES_APPROVAL`
  - Transport request number documented

Skill to load: Read the appropriate SKILL.md from `.agents/skills/` before implementing.

---

### Step 3 — Clean-Core Validation (SAP_ABAP_ARCHITECT)

Agent: **SAP_ABAP_ARCHITECT**
Input: All artifacts from Step 2
Output: Clean-core compliance report:
  - List any non-released API usage
  - ATC check results (via MCP bridge if available)
  - GO / REWORK decision

If REWORK: Return to Step 2 with specific findings.
If GO: Proceed to Step 4.

---

### Step 4 — Unit Testing (SAP_TEST_ENGINEER)

Agent: **SAP_TEST_ENGINEER**
Input: Implemented artifacts from Step 2/3
Output:
  - ABAP Unit test class for all validations, determinations, and actions
  - Test execution results (via MCP bridge if available)
  - Coverage report (target: ≥ 80%)

If tests FAIL: Return to SAP_RAP_DEVELOPER with failure details.
If tests PASS: Proceed to Step 5.

Skip this step for: `create-fiori-app`, `create-service`, `generate-readme`.

---

### Step 5 — Authorization Review (SAP_SECURITY_ENGINEER)

Agent: **SAP_SECURITY_ENGINEER**
Input: Implemented artifacts
Output:
  - Confirm DCL is applied to all new CDS entities
  - Confirm IAM app includes new service endpoints
  - Flag any missing authorization checks in BDEF
  - Authorization review: GO / REWORK

If REWORK: Return to specialist with specific authorization gaps.
If GO: Proceed to Step 6.

Skip this step for: `generate-readme`.

---

### Step 6 — Documentation (SAP_DOCUMENTATION_WRITER)

Agent: **SAP_DOCUMENTATION_WRITER**
Input: All artifacts, test results, authorization decisions
Output:
  - Update `README.md` with the new feature description
  - Add the feature to the architecture Mermaid diagram
  - Generate resume bullet point for this feature

---

### Step 7 — User Review (PAUSE)

**PAUSE — Human review required.**

Present to user:
1. Summary of all created/modified objects
2. Clean-core validation report
3. Test results and coverage
4. Authorization review findings
5. Updated documentation

User decisions:
- **Approve** → Commit all changes to transport request
- **Request Changes** → Specify what to revise; workflow loops back to appropriate step
- **Discard** → Abandon all changes for this feature

---

## Artifact Handover Rules

- Each agent outputs a structured handover document containing:
  - **Objects Created/Modified**: Full list with technical names
  - **Transport Request**: TR number all objects are assigned to
  - **Dependencies**: Any prerequisite objects that must exist first
  - **Test Results**: Pass/Fail with details
  - **Open Issues**: Any items needing manual action

- Agents MUST NOT proceed to the next step without a clean handover document.
- If an agent cannot complete its task, it must STOP and report blockers clearly.

---

## Iterative Rework Loop

If any step produces REWORK:
1. The blocking agent documents exact findings (line numbers, object names, error messages).
2. The workflow returns to the failing step's specialist.
3. The specialist fixes ONLY the reported issues.
4. Re-run from the failed step forward.
5. Maximum 3 rework iterations before escalating to human review.

---

## Clean-Core Checklist

Every feature MUST pass:
- [ ] No `CALL FUNCTION` to non-released FMs
- [ ] No direct table access to SAP standard tables (use CDS abstractions)
- [ ] No `MODIFY`/`INSERT`/`DELETE` on standard SAP tables
- [ ] No `ENHANCEMENT`/`EXIT` to standard objects
- [ ] All APIs checked against `Released for ABAP Cloud` state
- [ ] ATC ruleset: `ABAP Cloud` (includes SLIN, ABAP_CLOUD checks)
- [ ] All objects in custom package (`Z_SALES_APPROVAL`)
