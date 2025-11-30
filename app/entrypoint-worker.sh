#!/usr/bin/env bash
set -euo pipefail

# # ---- Wait on background processes ----
# wait -n

: "${PORT:=8080}"

# Start health check server in background
python - <<'PY' &
import http.server, socketserver, os
port = int(os.environ.get("PORT", "8080"))
class Handler(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header('Content-Type', 'text/plain')
        self.end_headers()
        self.wfile.write(b"healthy")
    def log_message(self, *args): pass
with socketserver.TCPServer(("", port), Handler) as httpd:
    print(f"Health server on port {port}", flush=True)
    httpd.serve_forever()
PY

export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-nautobot_config}"
export NAUTOBOT_CONFIG="${NAUTOBOT_CONFIG:-/app/nautobot_config.py}"

sleep 2

echo "[worker] Starting Celery (solo pool, events enabled)…" >&2
# IMPORTANT CHANGES:
# - use solo pool (no child processes)
# - enable events (-E) so UI sees transitions
# - single concurrency
# - fair prefetch so tasks ack/update in order

# Use default pool, higher concurrency for performance, enable events
exec nautobot-server celery worker \
  --loglevel=DEBUG \
  -E \
  --concurrency=${CELERY_WORKER_CONCURRENCY:-2} \
  --max-tasks-per-child=10 \
  -Q default