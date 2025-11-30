#!/usr/bin/env bash
# set -euo pipefail
# echo "[web] Starting Nautobot (uWSGI via nautobot-server start)..."
# #exec nautobot-server startapp --http :8080 --workers ${UWSGI_WORKERS:-4} --threads ${UWSGI_THREADS:-2}
# # Gunicorn alternative:
# exec gunicorn nautobot.wsgi:application --bind :8080 --workers ${GUNI_WORKERS:-4} --threads ${GUNI_THREADS:-2} --timeout ${GUNI_TIMEOUT:-60}

#!/usr/bin/env bash
set -euo pipefail

# Writable dirs (Cloud Run: use /tmp)
: "${DATA_DIR:=/tmp/nautobot}"
: "${STATIC_ROOT:=${DATA_DIR}/static}"
: "${MEDIA_ROOT:=${DATA_DIR}/media}"   # In prod, use GCS STORAGE_BACKEND; this is just a fallback
: "${GIT_ROOT:=${DATA_DIR}/git}"
: "${JOBS_ROOT:=${DATA_DIR}/jobs}"
mkdir -p "${STATIC_ROOT}" "${MEDIA_ROOT}" "${GIT_ROOT}" "${JOBS_ROOT}"
umask 0022

# Settings / import path
export PYTHONPATH="/app:${PYTHONPATH:-}"
export DJANGO_SETTINGS_MODULE="${DJANGO_SETTINGS_MODULE:-nautobot_config}"
export NAUTOBOT_CONFIG="${NAUTOBOT_CONFIG:-/opt/nautobot/nautobot_config.py}"

# Gunicorn tuning + Cloud Run port
: "${GUNI_WORKERS:=4}"
: "${GUNI_THREADS:=1}"
: "${GUNI_TIMEOUT:=90}"
: "${PORT:=8080}"

echo "[web] Starting Nautobot via Gunicorn on :${PORT}"
exec gunicorn nautobot.core.wsgi:application \
  --bind ":${PORT}" \
  --workers "${GUNI_WORKERS}" \
  --threads "${GUNI_THREADS}" \
  --timeout "${GUNI_TIMEOUT}"

