sap.ui.define(
    ["sap/fe/core/AppComponent"],
    function (AppComponent) {
        "use strict";

        /**
         * Sales Order Approval Application Component
         *
         * Extends sap.fe.core.AppComponent — the standard Fiori Elements
         * app component. All routing, draft handling, and action execution
         * is managed by the Fiori Elements framework.
         *
         * Do NOT add custom controller logic here unless strictly required.
         * All business logic lives in the ABAP RAP backend (ZSO_BP_REQ_H).
         */
        return AppComponent.extend("com.company.salesorderapproval.Component", {
            metadata: {
                manifest: "json"
            }
        });
    }
);
