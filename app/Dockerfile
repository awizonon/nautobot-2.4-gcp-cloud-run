# Nautobot Custom Image
# Base: Official Nautobot 2.4.x image
# Docs: https://docs.nautobot.com/projects/core/en/stable/user-guide/administration/guides/docker/

ARG NAUTOBOT_VERSION=2.4-py3.12
FROM networktocode/nautobot:${NAUTOBOT_VERSION}

# Switch to root to install dependencies and copy files
USER root

# Install postgresql-client and redis-tools for connection testing
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    postgresql-client \
    redis-tools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt && \
    rm /tmp/requirements.txt

# Copy custom Nautobot configuration
COPY nautobot_config.py /opt/nautobot/nautobot_config.py

# Copy custom jobs directory
# Jobs should be in ./jobs/ relative to Dockerfile
COPY jobs/ /opt/nautobot/jobs/

# Set proper ownership for Nautobot files
RUN chown -R nautobot:nautobot /opt/nautobot/nautobot_config.py \
    && chown -R nautobot:nautobot /opt/nautobot/jobs/ \
    && chmod -R 755 /opt/nautobot/jobs/

# Copy custom entrypoint script
COPY entrypoint.sh entrypoint-worker.sh entrypoint-beat.sh /app/
RUN chmod +x /app/entrypoint*.sh

# Switch back to nautobot user for security
USER nautobot