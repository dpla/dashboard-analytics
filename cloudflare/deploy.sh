#!/usr/bin/env bash
# Deploy (or update) the analytics-dashboard error-interceptor Worker.
#
# Requires a Cloudflare API token with:
#   - Account / Workers Scripts : Edit
#   - Zone / Workers Routes     : Edit
#
# Usage:
#   CF_DEPLOY_TOKEN=<token> CF_ACCOUNT_ID=<account_id> ./cloudflare/deploy.sh
#
# Or set the variables in your shell before running.

set -euo pipefail

WORKER_NAME="analytics-dashboard-error-page"
WORKER_ROUTE="analytics-dashboard.dp.la/*"
ZONE_ID="e2f608520065d1e85ac39d6f254ed95b"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

: "${CF_DEPLOY_TOKEN:?CF_DEPLOY_TOKEN must be set}"
: "${CF_ACCOUNT_ID:?CF_ACCOUNT_ID must be set}"

AUTH_HEADER="Authorization: Bearer $CF_DEPLOY_TOKEN"

echo "==> Uploading Worker script..."
curl -s -X PUT \
  "https://api.cloudflare.com/client/v4/accounts/$CF_ACCOUNT_ID/workers/scripts/$WORKER_NAME" \
  -H "$AUTH_HEADER" \
  -H "Content-Type: application/javascript" \
  --data-binary @"$SCRIPT_DIR/worker.js" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if d['success']:
    print('  Worker uploaded successfully.')
else:
    print('  ERROR:', d['errors'])
    sys.exit(1)
"

echo "==> Checking for existing route..."
EXISTING=$(curl -s \
  "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/workers/routes" \
  -H "$AUTH_HEADER")

ROUTE_ID=$(echo "$EXISTING" | python3 -c "
import json, sys
routes = json.load(sys.stdin).get('result', [])
for r in routes:
    if r.get('pattern') == '$WORKER_ROUTE':
        print(r['id'])
        break
" 2>/dev/null || true)

if [ -n "$ROUTE_ID" ]; then
  echo "==> Updating existing route $ROUTE_ID..."
  curl -s -X PUT \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/workers/routes/$ROUTE_ID" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    --data "{\"pattern\":\"$WORKER_ROUTE\",\"script\":\"$WORKER_NAME\"}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if d['success']:
    print('  Route updated.')
else:
    print('  ERROR:', d['errors'])
    sys.exit(1)
"
else
  echo "==> Creating new route..."
  curl -s -X POST \
    "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/workers/routes" \
    -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    --data "{\"pattern\":\"$WORKER_ROUTE\",\"script\":\"$WORKER_NAME\"}" | python3 -c "
import json, sys
d = json.load(sys.stdin)
if d['success']:
    print('  Route created.')
else:
    print('  ERROR:', d['errors'])
    sys.exit(1)
"
fi

echo "==> Done. Worker active at: $WORKER_ROUTE"
