# Fiori Elements App — BAS Generator & Local Preview Guide (Day 5)

## Option A: Generate in SAP Business Application Studio (Recommended)

### Prerequisites
- BAS dev space is running (Full Stack Cloud Application or SAP Fiori type)
- BTP ABAP system is connected as a destination in BTP cockpit
- Service `ZSO_SB_REQ_H` is published (Day 4 complete)

### Step-by-Step in BAS

1. **Open BAS** → Open your dev space

2. **New Project from Template**
   - View → Find Command → "Fiori: Open Application Generator"
   - OR: Welcome tab → "New Project from Template" → "SAP Fiori Application"

3. **Choose template**: Select **"List Report Page"** → Next

4. **Data source and service**
   - Data source: **"Connect to a System"**
   - System: Select your BTP ABAP trial destination
   - Service: `ZSO_SB_REQ_H` (should appear in the dropdown)
   - If not listed: choose "Enter manually" and paste:
     ```
     /sap/opu/odata4/sap/zso_sb_req_h/srvd/sap/zso_sd_req_h/0001/
     ```
   - Click → **Next**

5. **Entity selection**
   - Main entity: `SalesOrderRequest`
   - Navigation entity: `SalesOrderItem` (for the items table on Object Page)
   - → **Next**

6. **Project attributes**

   | Field | Value |
   |---|---|
   | Module name | `salesorderapproval` |
   | Application title | `Sales Order Approval` |
   | Application namespace | `com.company` |
   | Description | `Manage and approve sales order requests` |
   | Project folder path | `/home/user/projects/` or your chosen folder |
   | Add deployment config | Yes (BTP Cloud Foundry) |
   | Add FLP config | Yes |

   → **Finish**

7. **BAS generates** the project with:
   - `webapp/manifest.json` — **replace with the file from this repo**
   - `webapp/Component.js` — keep or replace with repo version
   - `webapp/i18n/i18n.properties` — **replace with the file from this repo**
   - `package.json` — keep generated version, or replace with repo version
   - `ui5.yaml` — **update proxy URL** with your system host

8. **Run locally**
   ```bash
   npm install
   npm start
   ```
   Browser opens at `http://localhost:8080/test/flpSandbox.html`

---

## Option B: Use This Repo's Files Directly (Skip Generator)

If you want to use the pre-built files from this repo:

1. Copy the `fiori/salesorderapproval/` folder to your BAS workspace
2. Update `ui5.yaml` → replace `<your-btp-abap-host>`:
   ```yaml
   url: "https://your-abap-system.abap-trial.us10.hana.ondemand.com"
   ```
3. Run:
   ```bash
   cd fiori/salesorderapproval
   npm install
   npm start
   ```

---

## Verify the Fiori App

### Checklist: List Report
- [ ] Page loads without errors
- [ ] Filter bar shows: Status, Customer ID, Request Date
- [ ] Table columns: Request ID, Customer, Request Date, Total Amount, Status
- [ ] Status column shows traffic-light colours (green=Approved, yellow=Pending, red=Rejected)
- [ ] "Create" button is present in toolbar
- [ ] Draft indicator appears on unsaved rows (pencil icon)

### Checklist: Object Page
- [ ] Clicking a row opens the Object Page
- [ ] Header shows Request ID as title, Status as subtitle
- [ ] Three sections visible: General Information | Items | Approval Details
- [ ] Items table shows: Item No, Material, Qty, Unit, Unit Price, Net Amount
- [ ] "Submit" button visible only when Status = Draft
- [ ] "Approve" and "Reject" buttons visible only when Status = Pending
- [ ] "Resubmit" button visible only when Status = Rejected

### Checklist: Draft Flow
1. Click **Create** → Object Page opens in edit mode (no key yet)
2. Fill in Customer ID, Request Date
3. Add items via Items table
4. **Save** → draft saved (pencil icon in list)
5. Click **Submit** → status changes to Pending
6. Log in as approver → **Approve** → status changes to Approved ✅

---

## Deploy to BTP Launchpad

After testing locally:

```bash
# Add deploy config (if not done during generation)
npx fiori add deploy-config

# Build production bundle
npm run build

# Deploy to BTP HTML5 Application Repository
npm run deploy
```

Then in BTP cockpit:
1. HTML5 Applications → find `salesorderapproval`
2. SAP Build Work Zone → Site Manager → add tile pointing to `SalesOrderApproval-display`

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Blank page, no error | Wrong `routerClass` | Must be `sap.fe.core.AppComponent` |
| "Service not reachable" | Proxy not configured | Update `ui5.yaml` with correct backend URL |
| "Draft" not shown | Service binding is "Web API" type | Recreate binding as "OData V4 - UI" |
| Actions missing in toolbar | BDEF not activated | Activate BDEF, republish service binding |
| Status filter empty | `ZSO_VH_STATUS` not in SRVD | Add to service definition and republish |
| 403 on all requests | No business role assigned to user | Day 7 — assign `ZSO_BC_REQUESTER` role |
| Items table empty on Object Page | Wrong `contextPath` in routing target | Must be `/SalesOrderRequest/SalesOrderItem` |
