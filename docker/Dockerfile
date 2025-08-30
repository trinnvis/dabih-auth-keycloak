FROM quay.io/keycloak/keycloak:26.0 AS builder

# Health check configuration
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true

# Build Keycloak with custom configuration
WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:26.0

# Copy built configuration
COPY --from=builder /opt/keycloak/ /opt/keycloak/

# Environment variables for runtime configuration
ENV KC_DB=postgres
ENV KC_HOSTNAME_STRICT=false
ENV KC_HOSTNAME_STRICT_HTTPS=false
ENV KC_HTTP_ENABLED=true
ENV KC_HEALTH_ENABLED=true
ENV KC_METRICS_ENABLED=true
ENV KC_PROXY=edge
ENV KC_TRANSACTION_XA_ENABLED=false
ENV PROXY_ADDRESS_FORWARDING=true

# Create custom entrypoint script
COPY docker-entrypoint.sh /opt/keycloak/
RUN chmod +x /opt/keycloak/docker-entrypoint.sh

ENTRYPOINT ["/opt/keycloak/docker-entrypoint.sh"]