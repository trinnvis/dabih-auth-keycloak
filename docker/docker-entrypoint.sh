#!/bin/bash
set -eou pipefail

# Function to wait for database
wait_for_db() {
    echo "Waiting for database to be ready..."
    until /opt/keycloak/bin/kc.sh show-config | grep -q "kc.db-url-host"; do
        echo "Database is not ready. Waiting..."
        sleep 5
    done
    echo "Database is ready!"
}

# Parse database URL from environment variable or secret
if [ -n "${DB_SECRET_JSON:-}" ]; then
    echo "Loading database credentials from secret..."
    export KC_DB_URL_HOST=$(echo "$DB_SECRET_JSON" | jq -r '.host')
    export KC_DB_URL_PORT=$(echo "$DB_SECRET_JSON" | jq -r '.port')
    export KC_DB_URL_DATABASE=$(echo "$DB_SECRET_JSON" | jq -r '.dbname')
    export KC_DB_USERNAME=$(echo "$DB_SECRET_JSON" | jq -r '.username')
    export KC_DB_PASSWORD=$(echo "$DB_SECRET_JSON" | jq -r '.password')
fi

# Set database schema for Keycloak
export KC_DB_SCHEMA=${KC_DB_SCHEMA:-keycloak}

# Construct the full database URL with schema
export KC_DB_URL="jdbc:postgresql://${KC_DB_URL_HOST}:${KC_DB_URL_PORT}/${KC_DB_URL_DATABASE}?currentSchema=${KC_DB_SCHEMA}"

echo "Starting Keycloak with database URL: jdbc:postgresql://${KC_DB_URL_HOST}:${KC_DB_URL_PORT}/${KC_DB_URL_DATABASE}"
echo "Using schema: ${KC_DB_SCHEMA}"

# Wait for database before starting
wait_for_db

# Start Keycloak in production mode
exec /opt/keycloak/bin/kc.sh start --optimized