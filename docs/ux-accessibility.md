# SAP Fiori Horizon UX & Accessibility Compliance Review

## 1. Compliance Standards & Guidelines

The Sales Order Approval application frontend is certified against:
- **SAP Fiori Design Guidelines (Horizon Morning & Evening Themes)**
- **Web Content Accessibility Guidelines (WCAG) 2.1 Level AA**
- **EN 301 549 Accessibility Requirements for ICT Products**

---

## 2. Accessibility & UX Evaluation Matrix

| Category | Design Requirement | Implementation in Application | Compliance |
|---|---|---|---|
| **Color Independence** | Status must communicate meaning through text/icons, not color alone (WCAG 1.4.1). | All status indicators (`Status`, `SlaStatus`) render explicit text labels (`APPROVED`, `PENDING`, `BREACHED`) with distinct semantic icons and contrasting pill backgrounds. Color-blind users are never forced to distinguish red vs. green alone. | COMPLIANT ✅ |
| **Color Contrast** | Minimum 4.5:1 text-to-background contrast ratio (WCAG 1.4.3). | Adheres to official SAP Horizon token palette: High-contrast text `#1d2d3e` over `#ffffff` and `#f5f6f7` card backgrounds (Contrast Ratio > 11:1). | COMPLIANT ✅ |
| **Semantic Typography** | Standard corporate type scale with clear hierarchy. | Uses SAP 72 enterprise typeface with fallbacks to Inter and system sans-serif. Distinct `H1` (22px), `H2` (18px), section titles (13px bold uppercase), and body copy (13px). | COMPLIANT ✅ |
| **Keyboard Navigation** | All interactive controls accessible via keyboard Tab, Enter, Space, Escape (WCAG 2.1.1). | Modal dialogs trap focus and respond to Escape key to dismiss; table rows navigate via standard browser keyboard arrows; checkboxes toggle with Space. | COMPLIANT ✅ |
| **Data Formatting** | Formatted currencies, units, and dates according to locale standards. | Numbers formatted via `@Semantics.amount.currencyCode` with 2 decimal precision (e.g. `14,500.00 EUR`); quantities paired with unit badges (`5 PCE`); dates in ISO/standard format. | COMPLIANT ✅ |
| **Screen Reader / ARIA** | Descriptive ARIA roles and labels for assistive devices (WCAG 4.1.2). | All input fields carry `<label for="...">` associations; modal containers declare `role="dialog"` with `aria-labelledby`; action buttons have clear contextual labels (`Confirm Reject`, `Save Draft`). | COMPLIANT ✅ |
| **Predictable Action States** | Buttons must clearly reflect enabled/disabled state without misleading clicks. | Feature control dynamically disables illegal actions (e.g. `Approve` is disabled with lowered opacity when status is `DRAFT`); tooltips communicate reason for disabled states. | COMPLIANT ✅ |
| **Responsive Layout** | Usable on desktop, tablet, and mobile displays without horizontal scrollbars (WCAG 1.4.10). | Responsive flexbox and CSS grid layouts with collapsible filters and full-width mobile cards. | COMPLIANT ✅ |
