# Enterprise Production Deployment Guide: SAP BTP

This guide provides the complete, step-by-step instructions for deploying the **Clean-Core Sales Order Approval App** to **SAP Business Technology Platform (SAP BTP)**.

---

## 🏗️ Architecture Overview

The production architecture consists of four coordinated components:

```
┌────────────────────────────────────────────────────────────────────────┐
│                        SAP BTP Launchpad                               │
│              (SAP Build Work Zone, Standard Edition)                   │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Opens App via Intent
┌───────────────────────────────────▼────────────────────────────────────┐
│                    HTML5 Application Repository                        │
│             Frontend UI: com.company.salesorderapproval                │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ Proxied via BTP Destination
                                    │ (ZSO_ABAP_BACKEND)
┌───────────────────────────────────▼────────────────────────────────────┐
│                  SAP BTP ABAP Environment (Steampunk)                  │
│  - OData V4 Service: ZSO_SB_REQ_H                                      │
│  - RAP Business Object: ZSO_R_REQ_H (Managed with Draft & Strict 2)    │
│  - Core Data Services: ZSO_C_REQ_H, ZSO_R_REQ_H                        │
│  - SAP HANA Cloud Database Tables: ZSO_REQ_H, ZSO_REQ_I                │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 📋 Prerequisites & Tools Checklist

Ensure you have the following ready before starting:

1. **SAP BTP Subaccount**:
   - Cloud Foundry Environment enabled (with at least 1 Space created, e.g., `dev` or `prod`).
   - SAP BTP ABAP Environment instance provisioned (or SAP S/4HANA Cloud system).
   - Subscription to **SAP Build Work Zone, standard edition**.
2. **Local Development Tools**:
   - **Eclipse IDE** (Latest) with **ABAP Development Tools (ADT)** plugin ([tools.hana.ondemand.com](https://tools.hana.ondemand.com)).
   - **Node.js** (v18, v20, or v24 installed) & **npm**.
   - **Cloud Foundry CLI (`cf`)**: Verify in terminal with `cf -v`. ([Download CF CLI](https://github.com/cloudfoundry/cli/releases)).
   - **Cloud MTA Build Tool (`mbt`)** *(recommended)*: `npm install -g mbt`.

---

## 🚀 PHASE 1: Deploy ABAP Cloud Backend (ADT)

All ABAP code files are already located in your local project under the `abap/` directory.

### Step 1.1: Connect Eclipse ADT to your SAP BTP ABAP System
1. Open Eclipse with ADT installed.
2. Go to **File → New → ABAP Cloud Project**.
3. Choose **SAP BTP ABAP Environment**.
4. Log in using your SAP Universal ID or BTP credentials.
5. Finish the wizard. Your system will appear in the Project Explorer.

### Step 1.2: Create the Package & Transport Request
1. Right-click on your Project → **New → ABAP Package**.
   - **Name**: `Z_SALES_APPROVAL`
   - **Description**: `Clean-Core Sales Order Approval App`
   - **Package Type**: `Development`
   - **Application Component**: `CA-GTF` (or leave default)
   - **Software Component**: `ZLOCAL` (or your company's custom software component)
2. Create a new Transport Request:
   - **Description**: `Sales Order Approval Initial Implementation`

### Step 1.3: Create and Activate ABAP Objects in Strict Order
Create each object in Eclipse ADT by copying the exact code from your local project repository, then activate (**Ctrl+F3**):

| # | Object Type in ADT | Name in ADT | Local Source File Path |
|---|---|---|---|
| 1 | Domain | `ZSO_D_STATUS` | [abap/tables/src/ZSO_D_STATUS.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_D_STATUS.ddls.asddls) |
| 2 | Data Element | `ZSO_E_REQUEST_ID` | [abap/tables/src/ZSO_E_REQUEST_ID.dtel.asdtel](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_E_REQUEST_ID.dtel.asdtel) |
| 3 | Data Element | `ZSO_E_STATUS` | [abap/tables/src/ZSO_E_STATUS.dtel.asdtel](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_E_STATUS.dtel.asdtel) |
| 4 | Data Element | `ZSO_E_TOTAL_AMT` | [abap/tables/src/ZSO_E_TOTAL_AMT.dtel.asdtel](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_E_TOTAL_AMT.dtel.asdtel) |
| 5 | Database Table | `ZSO_REQ_H` | [abap/tables/src/ZSO_REQ_H.tabl.asdbtab](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_REQ_H.tabl.asdbtab) |
| 6 | Database Table | `ZSO_REQ_I` | [abap/tables/src/ZSO_REQ_I.tabl.asdbtab](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_REQ_I.tabl.asdbtab) |
| 7 | Draft Database Table | `ZSO_DREQ_H` | [abap/tables/src/ZSO_DREQ_H.tabl.asdbtab](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_DREQ_H.tabl.asdbtab) |
| 8 | Draft Database Table | `ZSO_DREQ_I` | [abap/tables/src/ZSO_DREQ_I.tabl.asdbtab](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/tables/src/ZSO_DREQ_I.tabl.asdbtab) |
| 9 | CDS View Entity (Item Interface) | `ZSO_R_REQ_I` | [abap/cds/src/ZSO_R_REQ_I.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_R_REQ_I.ddls.asddls) |
| 10 | CDS View Entity (Header Interface) | `ZSO_R_REQ_H` | [abap/cds/src/ZSO_R_REQ_H.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_R_REQ_H.ddls.asddls) |
| 11 | CDS View Entity (Value Help) | `ZSO_VH_STATUS` | [abap/cds/src/ZSO_VH_STATUS.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_VH_STATUS.ddls.asddls) |
| 12 | CDS View Entity (Value Help) | `ZSO_VH_CUSTOMER` | [abap/cds/src/ZSO_VH_CUSTOMER.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_VH_CUSTOMER.ddls.asddls) |
| 13 | CDS View Entity (Item Projection) | `ZSO_C_REQ_I` | [abap/cds/src/ZSO_C_REQ_I.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_C_REQ_I.ddls.asddls) |
| 14 | CDS View Entity (Header Projection) | `ZSO_C_REQ_H` | [abap/cds/src/ZSO_C_REQ_H.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/cds/src/ZSO_C_REQ_H.ddls.asddls) |
| 15 | Abstract Entity (Action Parameter) | `ZSO_P_REJECT` | [abap/rap/src/ZSO_P_REJECT.ddls.asddls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/rap/src/ZSO_P_REJECT.ddls.asddls) |
| 16 | Behavior Definition (RAP BDEF) | `ZSO_R_REQ_H` | [abap/rap/src/ZSO_R_REQ_H.bdef.asbdef](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/rap/src/ZSO_R_REQ_H.bdef.asbdef) |
| 17 | Behavior Implementation Class | `ZSO_BP_REQ_H` | Global stub: [ZSO_BP_REQ_H.clas.abap](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/rap/src/ZSO_BP_REQ_H.clas.abap)<br>Local types tab: [ZSO_BP_REQ_H.clas.locals_imp.abap](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/rap/src/ZSO_BP_REQ_H.clas.locals_imp.abap) |
| 18 | Service Definition | `ZSO_SD_REQ_H` | [abap/rap/src/service/ZSO_SD_REQ_H.srvd.asdsrvd](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/rap/src/service/ZSO_SD_REQ_H.srvd.asdsrvd) |
| 19 | Access Control (Header DCL) | `ZSO_R_REQ_H` | [abap/dcl/src/ZSO_R_REQ_H.dcl.asdcls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/dcl/src/ZSO_R_REQ_H.dcl.asdcls) |
| 20 | Access Control (Item DCL) | `ZSO_R_REQ_I` | [abap/dcl/src/ZSO_R_REQ_I.dcl.asdcls](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/dcl/src/ZSO_R_REQ_I.dcl.asdcls) |

### Step 1.4: Create and Publish Service Binding
1. Right-click `ZSO_SD_REQ_H` → **New Service Binding**.
   - **Name**: `ZSO_SB_REQ_H`
   - **Binding Type**: `OData V4 - UI`
2. Open `ZSO_SB_REQ_H` in the editor.
3. Click the **Publish** button on the toolbar.
4. Verify the status shows **Published ✅**.
5. Select `SalesOrderRequest` and click **Preview** to verify the service works.

---

## 🌐 PHASE 2: Configure SAP BTP Destination

The frontend HTML5 application connects to the ABAP backend via a secure BTP Destination.

1. Open **SAP BTP Cockpit** → Navigate to your **Subaccount**.
2. In the left navigation menu, go to **Connectivity → Destinations**.
3. Click **New Destination** and configure:

| Destination Property | Value |
|---|---|
| **Name** | `ZSO_ABAP_BACKEND` |
| **Type** | `HTTP` |
| **Description** | `Connection to BTP ABAP Sales Order OData V4 Service` |
| **URL** | `https://<your-btp-abap-tenant-host>` *(from your service key or ADT)* |
| **Proxy Type** | `Internet` |
| **Authentication** | `OAuth2UserTokenExchange` *(or `BasicAuthentication` for trial)* |
| **Client** | `100` |

4. Under **Additional Properties**, click **New Property** and add:

| Key | Value |
|---|---|
| `HTML5.DynamicDestination` | `true` |
| `WebIDEEnabled` | `true` |
| `WebIDEUsage` | `odata_abap,bsp_execute_abap,dev_abap` |
| `sap-client` | `100` |

5. Click **Save**, then click **Check Connection**. Verify you receive a `200 OK` or `302 Found` response.

---

## 📦 PHASE 3: Build & Deploy Fiori UI (Cloud Foundry)

Deploy the UI into the SAP BTP **HTML5 Application Repository**.

### Step 3.1: Verify Destination in `xs-app.json`
Verify [fiori/salesorderapproval/webapp/xs-app.json](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/fiori/salesorderapproval/webapp/xs-app.json):
```json
{
  "welcomeFile": "/index.html",
  "routes": [
    {
      "source": "^/sap/(.*)$",
      "target": "/sap/$1",
      "destination": "ZSO_ABAP_BACKEND",
      "authenticationType": "none",
      "csrfProtection": false
    },
    {
      "source": "^(.*)$",
      "target": "$1",
      "service": "html5-apps-repo-rt",
      "authenticationType": "xsuaa"
    }
  ]
}
```

### Step 3.2: Log in to Cloud Foundry
Open your terminal on your computer:
```powershell
cf login -a https://api.cf.<region>.hana.ondemand.com
```
- Enter your BTP email and password.
- Select your target Organization and Space (e.g., `dev`).

### Step 3.3: Deploy using SAP Fiori Tools Deployment
Navigate to the Fiori app directory:
```powershell
cd "c:\Users\letsm\Downloads\SAP PROJECT\fiori\salesorderapproval"
```

Install deployment dependencies (if not already installed):
```powershell
npm install
```

Run the build and deploy command:
```powershell
npm run deploy
```
*(The wizard will prompt you to select your target: choose **Cloud Foundry** and confirm the destination `ZSO_ABAP_BACKEND`)*.

---

### Alternative: Automated MTA (Multi-Target Application) Deployment
If your organization standardizes on MTA deployments:
1. Generate the MTA archive:
   ```powershell
   mbt build -t ./
   ```
2. Deploy the generated `.mtar` package directly into Cloud Foundry:
   ```powershell
   cf deploy salesorderapproval_1.0.0.mtar
   ```

3. In BTP Cockpit → Subaccount → **HTML5 Applications**, you will see:
   - **App Name**: `comcompanysalesorderapproval`
   - **Version**: `1.0.0`
   - **Status**: `Active ✅`

---

## 🖥️ PHASE 4: Publish Tile to SAP Build Work Zone

Make the application accessible to business users via the Fiori Launchpad:

### Step 4.1: Open SAP Build Work Zone Site Manager
1. In BTP Cockpit → Subaccount → **Instances and Subscriptions**.
2. Click on **SAP Build Work Zone, standard edition** → Click **Go to Application**.
3. In the Work Zone administration menu, click **Channel Manager**.
4. Click the **Refresh / Fetch** icon on the **HTML5 Apps** content channel to synchronize your newly deployed app.

### Step 4.2: Add App to Content Manager
1. Click **Content Manager** → **Content Explorer**.
2. Select the **HTML5 Apps** tile.
3. Locate **Sales Order Approval** (`com.company.salesorderapproval`).
4. Click **+ Add to My Content**.

### Step 4.3: Configure App Tile & Navigation Intent
1. In **Content Manager**, click on the app **Sales Order Approval** to edit:
   - **Semantic Object**: `SalesOrderApproval`
   - **Action**: `manage` (or `display`)
   - **Title**: `Sales Order Approval`
   - **Subtitle**: `Manage & Approve Requests`
   - **Icon**: `sap-icon://sales-order`
2. Save the configuration.

### Step 4.4: Assign to Group & Role
1. Create or open a **Catalog** (e.g., `Sales Management Catalog`) and assign the app.
2. Create or open a **Group** (e.g., `Sales Operations`) and add the tile.
3. In **Roles**, assign the app to the **Everyone** role (or a dedicated `Sales_Approver_Role`).

### Step 4.5: Launch the Site
1. Go to **Site Directory** in Work Zone.
2. Click **Go to site** (or open the site URL).
3. The **Sales Order Approval** tile will appear on the launchpad! Click the tile to open the live production application.

---

## 🔒 PHASE 5: User Authorizations & Roles

Assign the appropriate authorizations in BTP Subaccount → **Security → Users**:

| Role Collection | Purpose | Allowed Actions |
|---|---|---|
| `ZSO_Requester_Role` | Sales Representative | Create drafts, edit items, Submit requests |
| `ZSO_Approver_Role` | Manager / Director | Display requests, Approve, Reject (with reason) |
| `ZSO_Admin_Role` | System Administrator | Full access across all customers and statuses |

*(Detailed IAM setup and business catalogs are documented in [abap/dcl/IAM_SETUP_GUIDE.md](file:///c:/Users/letsm/Downloads/SAP%20PROJECT/abap/dcl/IAM_SETUP_GUIDE.md))*.

---

## ✅ PHASE 6: Production Verification Smoke Test

Once deployed and launched via the Fiori Launchpad:

1. **Verify Read / Query**: The List Report loads without errors, showing existing requests.
2. **Verify Create Draft**: Click **+ Create**, enter Customer `CUST001`, add an item with Material, Quantity, and Price. Save draft.
3. **Verify Submit Action**: Click **Submit** on a `DRAFT` record.
   - Status transitions from `DRAFT` → `PENDING`.
   - Approver field automatically populates based on Amount threshold (`< 10k` → Manager, `>= 10k` → Director).
4. **Verify Reject Dialog**: Log in with an Approver user, select a `PENDING` request, and click **Reject**.
   - The `ZSO_P_REJECT` popup prompts for a reason.
   - Enter reason and confirm. Status transitions to `REJECTED`.
5. **Verify Resubmit**: Click **Resubmit** on a `REJECTED` request. Status resets to `PENDING`.
6. **Verify Audit Trail**: Check `ChangedBy` and `ChangedAt` fields on the Object Page.

---

**Your Clean-Core Sales Order Approval Application is now fully deployed and running in Enterprise Production on SAP BTP!**
