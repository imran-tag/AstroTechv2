#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/back_end"

echo "==> Stopping and removing backend Docker containers..."
docker compose -f "$BACKEND_DIR/docker-compose.yml" down

echo "==> Done."
