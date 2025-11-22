FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive \
    SRVPORT=4499

# Install runtime dependencies and clean up apt cache to keep the image small.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        fortune-mod \
        cowsay \
        netcat-openbsd \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy application script.
COPY wisecow.sh .

# Drop privileges.
RUN useradd -r -u 10001 wisecow \
    && chmod +x /app/wisecow.sh \
    && chown -R wisecow:wisecow /app

USER wisecow

EXPOSE 4499

ENTRYPOINT ["./wisecow.sh"]
