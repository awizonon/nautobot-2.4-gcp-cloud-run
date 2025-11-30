#!/usr/bin/env bash
set -euo pipefail

: "${PORT:=8080}"

# --- start Celery Beat in background ---
# Nautobot 2.x uses Celery. This writes the schedule db to /tmp by default.
#nautobot-server celery beat -l INFO &

# --- minimal HTTP server for Cloud Run health ---
python - <<'PY' &
import http.server, socketserver, os
port = int(os.environ.get("PORT","8080"))
class H(http.server.SimpleHTTPRequestHandler):
    def do_GET(self):
        # simple 200 OK for / and /healthz
        self.send_response(200); self.end_headers(); self.wfile.write(b"ok")
    def log_message(self, *a, **k): pass
socketserver.TCPServer(("", port), H).serve_forever()
PY

export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-nautobot_config}"
export NAUTOBOT_CONFIG="${NAUTOBOT_CONFIG:-/app/nautobot_config.py}"

# Give health server time to start
sleep 2

# Start Celery Beat in foreground (main process)
echo "Starting Celery Beat scheduler..." >&2
exec nautobot-server celery beat --loglevel=INFO
