FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends dante-server net-tools iproute2 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

COPY danted.conf /etc/danted.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1080

ENTRYPOINT ["/entrypoint.sh"]
