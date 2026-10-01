const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = 3000;
const MOCK_DATA_PATH = path.join(__dirname, 'mock-data.json');
const PREVIEW_HTML_PATH = path.join(__dirname, 'preview', 'index.html');

// In-memory state initialized from mock-data.json
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

const server = http.createServer((req, res) => {
    // CORS headers
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
                    RejectionReason: '',
                    CreatedBy: 'JSMITH',
                    CreatedAt: new Date().toISOString(),
                    ChangedBy: 'JSMITH',
                    ChangedAt: new Date().toISOString(),
                    Items: payload.Items || []
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

    // Route: POST /api/orders/:id/:action (RAP Actions: submit, approve, reject, resubmit)
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

            if (action === 'submit') {
                // RAP Determination: Route based on TotalAmount
                item.Status = 'PENDING';
                item.StatusCriticality = 2; // Warning (Orange)
                item.Approver = (item.TotalAmount >= 10000) ? 'DIR_SCHMIDT' : 'MGR_BAUER';
                item.ChangedAt = new Date().toISOString();
            } else if (action === 'approve') {
                item.Status = 'APPROVED';
                item.StatusCriticality = 3; // Success (Green)
                item.ChangedAt = new Date().toISOString();
            } else if (action === 'reject') {
                item.Status = 'REJECTED';
                item.StatusCriticality = 1; // Error (Red)
                item.RejectionReason = payload.RejectionReason || 'No reason provided';
                item.ChangedAt = new Date().toISOString();
            } else if (action === 'resubmit') {
                item.Status = 'PENDING';
                item.StatusCriticality = 2;
                item.RejectionReason = '';
                item.ChangedAt = new Date().toISOString();
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

    // Static fallback
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
});

server.listen(PORT, () => {
    console.log(`\n======================================================`);
    console.log(`🚀 SAP Fiori Sales Order Approval Preview is RUNNING!`);
    console.log(`------------------------------------------------------`);
    console.log(`🌐 URL: http://localhost:${PORT}`);
    console.log(`------------------------------------------------------`);
    console.log(`✨ You can view, filter, create, submit, approve,`);
    console.log(`   and reject sales orders directly in your browser.`);
    console.log(`======================================================\n`);

    // Auto-open browser on Windows
    exec(`start http://localhost:${PORT}`);
});
