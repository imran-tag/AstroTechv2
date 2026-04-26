#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$ROOT_DIR/back_end"
FRONTEND_DIR="$ROOT_DIR/front_end"

echo "==> Starting backend services (MySQL + APIs) via Docker Compose..."
docker compose -f "$BACKEND_DIR/docker-compose.yml" up --build -d

echo ""
echo "==> Waiting for services to be healthy..."
sleep 5

echo ""
echo "==> Backend services:"
echo "    MySQL        → localhost:3307"
echo "    phpMyAdmin   → http://localhost:8080"
echo "    client_api   → http://localhost:3001/api/v1/clients"
echo "    fichier_api  → http://localhost:3002/api/v1/fichiers"
echo "    referent_api → http://localhost:3003/api/v1/referents"
echo "    technicien_api → http://localhost:3004/api/v1/techniciens"
echo "    affaires_api → http://localhost:3005/api/v1/affaires"
echo ""

echo "==> Installing frontend dependencies (if needed)..."
cd "$FRONTEND_DIR"
npm install --silent

echo ""
echo "==> Starting Angular dev server on http://localhost:4200"
echo "    (Press Ctrl+C to stop the frontend; run ./stop.sh to shut down Docker services)"
echo ""
npm start
