const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = 3000;
const MOCK_DATA_PATH = path.join(__dirname, 'mock-data.json');
const PREVIEW_HTML_PATH = path.join(__dirname, 'preview', 'index.html');

let orders = [];

function loadData() {
    try {
        if (fs.existsSync(MOCK_DATA_PATH)) {
            const raw = fs.readFileSync(MOCK_DATA_PATH, 'utf-8');
            orders = JSON.parse(raw);
        }
    } catch (e) {
        console.error('Failed to load initial mock data:', e);
    }
}

function saveData() {
    try {
        fs.writeFileSync(MOCK_DATA_PATH, JSON.stringify(orders, null, 2), 'utf-8');
    } catch (e) {
        console.error('Failed to persist mock data:', e);
    }
}

loadData();

// Centralized Approval Rules (mirroring ZSO_APPR_RULE & ZSO_C_APPR_RULE)
const APPROVAL_RULES = [
    {
        RuleId: 'R001',
        AmountFrom: 0.00,
        AmountTo: 50000.00,
        ApprovalRole: 'Sales Manager',
        RoleTitle: 'Sales Manager',
        AssignedUser: 'Sandeep Rao',
        Level: '1',
        SlaDays: 2,
        SlaHours: 48,
        IsActive: true,
        ValidFrom: '2024-01-01',
        ValidTo: '9999-12-31'
    },
    {
        RuleId: 'R002',
        AmountFrom: 50001.00,
        AmountTo: 200000.00,
        ApprovalRole: 'Senior Manager',
        RoleTitle: 'Senior Manager',
        AssignedUser: 'Vikram Joshi',
        Level: '2',
        SlaDays: 3,
        SlaHours: 72,
        IsActive: true,
        ValidFrom: '2024-01-01',
        ValidTo: '9999-12-31'
    },
    {
        RuleId: 'R003',
        AmountFrom: 200001.00,
        AmountTo: 500000.00,
        ApprovalRole: 'Director',
        RoleTitle: 'Director',
        AssignedUser: 'Rajesh Kumar',
        Level: '3',
        SlaDays: 5,
        SlaHours: 120,
        IsActive: true,
        ValidFrom: '2024-01-01',
        ValidTo: '9999-12-31'
    },
    {
        RuleId: 'R004',
        AmountFrom: 500001.00,
        AmountTo: 999999.00,
        ApprovalRole: 'VP Sales',
        RoleTitle: 'VP Sales',
        AssignedUser: 'Meenakshi Iyer',
        Level: '4',
        SlaDays: 7,
        SlaHours: 168,
        IsActive: true,
        ValidFrom: '2024-01-01',
        ValidTo: '9999-12-31'
    }
];

function determineRoute(amount) {
    if (amount > 500000) {
        return {
            role: 'VP Sales',
            user: 'Meenakshi Iyer',
            roleTitle: 'VP Sales',
            slaDays: 7,
            slaHours: 168,
            level: '4',
            steps: [
                { step: 1, role: 'Sales Manager', user: 'Sandeep Rao', slaDays: 2, status: 'completed' },
                { step: 2, role: 'Senior Manager', user: 'Vikram Joshi', slaDays: 3, status: 'completed' },
                { step: 3, role: 'Director', user: 'Rajesh Kumar', slaDays: 5, status: 'active' },
                { step: 4, role: 'Final Approval', user: 'Meenakshi Iyer', slaDays: 7, status: 'pending' }
            ]
        };
    } else if (amount > 200000) {
        return {
            role: 'Director',
            user: 'Rajesh Kumar',
            roleTitle: 'Director',
            slaDays: 5,
            slaHours: 120,
            level: '3',
            steps: [
                { step: 1, role: 'Sales Manager', user: 'Sandeep Rao', slaDays: 2, status: 'completed' },
                { step: 2, role: 'Senior Manager', user: 'Vikram Joshi', slaDays: 3, status: 'completed' },
                { step: 3, role: 'Director', user: 'Rajesh Kumar', slaDays: 5, status: 'active' },
                { step: 4, role: 'Final Approval', user: 'System', slaDays: 0, status: 'pending' }
            ]
        };
    } else if (amount > 50000) {
        return {
            role: 'Senior Manager',
            user: 'Vikram Joshi',
            roleTitle: 'Senior Manager',
            slaDays: 3,
            slaHours: 72,
            level: '2',
            steps: [
                { step: 1, role: 'Sales Manager', user: 'Sandeep Rao', slaDays: 2, status: 'completed' },
                { step: 2, role: 'Senior Manager', user: 'Vikram Joshi', slaDays: 3, status: 'active' },
                { step: 3, role: 'Director', user: 'Rajesh Kumar', slaDays: 5, status: 'pending' },
                { step: 4, role: 'Final Approval', user: 'System', slaDays: 0, status: 'pending' }
            ]
        };
    } else {
        return {
            role: 'Sales Manager',
            user: 'Sandeep Rao',
            roleTitle: 'Sales Manager',
            slaDays: 2,
            slaHours: 48,
            level: '1',
            steps: [
                { step: 1, role: 'Sales Manager', user: 'Sandeep Rao', slaDays: 2, status: 'completed' },
                { step: 2, role: 'Senior Manager', user: 'Vikram Joshi', slaDays: 3, status: 'pending' },
                { step: 3, role: 'Director', user: 'Rajesh Kumar', slaDays: 5, status: 'pending' },
                { step: 4, role: 'Final Approval', user: 'System', slaDays: 0, status: 'pending' }
            ]
        };
    }
}

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.writeHead(204);
        res.end();
        return;
    }

    const parsedUrl = new URL(req.url, `http://localhost:${PORT}`);
    const pathname = parsedUrl.pathname;

    // Route: Root / Preview Page
    if (pathname === '/' || pathname === '/index.html') {
        fs.readFile(PREVIEW_HTML_PATH, (err, content) => {
            if (err) {
                res.writeHead(500, { 'Content-Type': 'text/plain' });
                res.end('Error loading preview page: ' + err.message);
                return;
            }
            res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
            res.end(content);
        });
        return;
    }

    // Route: GET /api/orders
    if (pathname === '/api/orders' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(orders));
        return;
    }

    // Route: GET /api/rules (Admin UI)
    if (pathname === '/api/rules' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(APPROVAL_RULES));
        return;
    }

    // Route: GET /api/analytics (Phase 6 Cockpit matching reference image metrics)
    if (pathname === '/api/analytics' && req.method === 'GET') {
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({
            totalCount: 128,
            pendingCount: 21,
            approvedCount: 96,
            rejectedCount: 3,
            draftCount: 8,
            breachedCount: 7,
            totalAmount: 4850000.00
        }));
        return;
    }

    // Route: POST /api/simulate (Phase 7 Simulation - Zero persistence)
    if (pathname === '/api/simulate' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const payload = JSON.parse(body || '{}');
                const amt = Number(payload.TotalAmount) || 48500;
                const route = determineRoute(amt);

                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({
                    TotalAmount: amt,
                    Currency: payload.Currency || 'INR',
                    Customer: payload.Customer || 'ABC Industries',
                    CompanyCode: '1000',
                    SalesOrg: '1000',
                    DistChannel: '10',
                    Division: '00',
                    RequiredRole: route.role,
                    RoleTitle: route.roleTitle,
                    ApproverUser: route.user,
                    SlaDays: route.slaDays,
                    ApprovalLevel: route.level,
                    Steps: route.steps,
                    Message: `Amount ₹${amt.toLocaleString()} requires Level ${route.level}: ${route.roleTitle} (${route.user}) with ${route.slaDays} days SLA.`
                }));
            } catch (err) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            }
        });
        return;
    }

    // Route: POST /api/orders (Create draft)
    if (pathname === '/api/orders' && req.method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            try {
                const payload = JSON.parse(body || '{}');
                const nextNum = (orders.length + 1).toString().padStart(4, '0');
                const newOrder = {
                    RequestId: `SO-2026-${nextNum}`,
                    CustomerId: payload.CustomerId || 'CUST-1001',
                    CustomerName: payload.CustomerName || 'Acme Industrial Corp',
                    RequestDate: payload.RequestDate || new Date().toISOString().split('T')[0],
                    TotalAmount: Number(payload.TotalAmount) || 0,
                    Currency: payload.Currency || 'EUR',
                    Status: 'DRAFT',
                    StatusCriticality: 0,
                    Approver: '',
                    ApprovalDueDate: '',
                    SlaStatus: 'ON_TRACK',
                    SlaCriticality: 3,
                    DaysWaiting: 0,
                    EscalationLevel: 0,
                    EscalatedTo: '',
                    EscalatedAt: null,
                    RejectionReason: '',
                    CreatedBy: 'JSMITH',
                    CreatedAt: new Date().toISOString(),
                    ChangedBy: 'JSMITH',
                    ChangedAt: new Date().toISOString(),
                    Items: payload.Items || [],
                    History: []
                };
                orders.push(newOrder);
                saveData();
                res.writeHead(201, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify(newOrder));
            } catch (err) {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: err.message }));
            }
        });
        return;
    }

    // Route: POST /api/orders/:id/:action
    const actionMatch = pathname.match(/^\/api\/orders\/([^\/]+)\/([^\/]+)$/);
    if (actionMatch && req.method === 'POST') {
        const reqId = actionMatch[1];
        const action = actionMatch[2];

        let body = '';
        req.on('data', chunk => { body += chunk; });
        req.on('end', () => {
            const payload = body ? JSON.parse(body) : {};
            const item = orders.find(o => o.RequestId === reqId);

            if (!item) {
                res.writeHead(404, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Order not found' }));
                return;
            }

            if (!item.History) item.History = [];
            const stepNum = item.History.length + 1;
            const nowTime = new Date().toISOString().replace('T', ' ').substring(0, 19);

            if (action === 'submit') {
                const route = determineRoute(item.TotalAmount);
                const prev = item.Status;
                item.Status = 'PENDING';
                item.StatusCriticality = 2;
                item.Approver = route.user;
                item.SlaStatus = 'ON_TRACK';
                item.SlaCriticality = 3;
                const dueDate = new Date();
                dueDate.setHours(dueDate.getHours() + route.slaHours);
                item.ApprovalDueDate = dueDate.toISOString().split('T')[0];
                item.ChangedAt = new Date().toISOString();

                item.History.push({
                    StepNo: stepNum,
                    Action: 'SUBMITTED',
                    Actor: 'JSMITH',
                    ActorRole: 'REQUESTER',
                    ActionTimestamp: nowTime,
                    CommentText: `Submitted for approval. Route assigned to ${route.role} (SLA: ${route.slaHours}h).`,
                    PreviousStatus: prev,
                    NewStatus: 'PENDING'
                });
            } else if (action === 'approve') {
                const prev = item.Status;
                item.Status = 'APPROVED';
                item.StatusCriticality = 3;
                item.SlaStatus = 'COMPLETED';
                item.SlaCriticality = 0;
                item.ChangedAt = new Date().toISOString();

                item.History.push({
                    StepNo: stepNum,
                    Action: 'APPROVED',
                    Actor: item.Approver || 'DIR_SCHMIDT',
                    ActorRole: 'APPROVER',
                    ActionTimestamp: nowTime,
                    CommentText: 'Sales order request approved.',
                    PreviousStatus: prev,
                    NewStatus: 'APPROVED'
                });
            } else if (action === 'reject') {
                const prev = item.Status;
                const reason = payload.RejectionReason || 'No reason specified';
                item.Status = 'REJECTED';
                item.StatusCriticality = 1;
                item.SlaStatus = 'COMPLETED';
                item.SlaCriticality = 0;
                item.RejectionReason = reason;
                item.ChangedAt = new Date().toISOString();

                item.History.push({
                    StepNo: stepNum,
                    Action: 'REJECTED',
                    Actor: item.Approver || 'DIR_SCHMIDT',
                    ActorRole: 'APPROVER',
                    ActionTimestamp: nowTime,
                    CommentText: reason,
                    PreviousStatus: prev,
                    NewStatus: 'REJECTED'
                });
            } else if (action === 'resubmit') {
                const prev = item.Status;
                const route = determineRoute(item.TotalAmount);
                item.Status = 'PENDING';
                item.StatusCriticality = 2;
                item.Approver = route.user;
                item.RejectionReason = '';
                item.SlaStatus = 'ON_TRACK';
                item.SlaCriticality = 3;
                item.EscalationLevel = 0;
                item.ChangedAt = new Date().toISOString();

                item.History.push({
                    StepNo: stepNum,
                    Action: 'RESUBMITTED',
                    Actor: 'JSMITH',
                    ActorRole: 'REQUESTER',
                    ActionTimestamp: nowTime,
                    CommentText: `Resubmitted after modification. Re-routed to ${route.role}.`,
                    PreviousStatus: prev,
                    NewStatus: 'PENDING'
                });
            } else if (action === 'escalate') {
                const prev = item.Status;
                item.EscalationLevel = (item.EscalationLevel || 0) + 1;
                item.SlaStatus = 'ESCALATED';
                item.SlaCriticality = 1;
                item.EscalatedTo = 'DIR_SCHMIDT';
                item.EscalatedAt = new Date().toISOString();
                item.Approver = 'DIR_SCHMIDT';
                item.ChangedAt = new Date().toISOString();

                item.History.push({
                    StepNo: stepNum,
                    Action: 'ESCALATED',
                    Actor: 'SYSTEM',
                    ActorRole: 'SYSTEM',
                    ActionTimestamp: nowTime,
                    CommentText: `SLA escalation triggered. Level ${item.EscalationLevel} assigned to Executive Director.`,
                    PreviousStatus: prev,
                    NewStatus: 'PENDING'
                });
            } else {
                res.writeHead(400, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: 'Unsupported action' }));
                return;
            }

            saveData();
            res.writeHead(200, { 'Content-Type': 'application/json' });
            res.end(JSON.stringify(item));
        });
        return;
    }

    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
});

server.listen(PORT, () => {
    console.log(`\n======================================================`);
    console.log(`🚀 SAP Fiori Sales Order Approval Preview is RUNNING!`);
    console.log(`------------------------------------------------------`);
    console.log(`🌐 URL: http://localhost:${PORT}`);
    console.log(`✨ Demonstrating Configurable Routing, Audit History,`);
    console.log(`   SLA Escalation, Simulation, and Operational Cockpit!`);
    console.log(`======================================================\n`);
});
