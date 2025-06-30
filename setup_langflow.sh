#!/usr/bin/env bash
set -e

install_if_missing() {
    local cmd=$1
    local pkg=$2
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing $pkg..."
        sudo apt-get update
        sudo apt-get install -y "$pkg"
    fi
}

install_if_missing git git
install_if_missing docker docker.io

if ! docker compose version >/dev/null 2>&1 && ! command -v docker-compose >/dev/null 2>&1; then
    echo "Installing docker-compose..."
    sudo apt-get update
    sudo apt-get install -y docker-compose
fi

if [ ! -d "$HOME/langflow" ]; then
    git clone https://github.com/langflow-ai/langflow.git "$HOME/langflow"
fi

cd "$HOME/langflow"

cat <<'COMPOSE' > docker-compose.yml
version: '3.9'
services:
  langflow:
    image: langflowai/langflow:latest
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "7860:7860"
    environment:
      LANGFLOW_DATABASE_URL: postgresql://langflow:langflow@postgres:5432/langflow
      LANGFLOW_CACHE_TYPE: redis
      LANGFLOW_REDIS_HOST: redis
      LANGFLOW_REDIS_PORT: 6379
      LANGFLOW_SUPERUSER: admin
      LANGFLOW_SUPERUSER_PASSWORD: adminpass
      LANGFLOW_AUTO_LOGIN: "false"
    volumes:
      - langflow-data:/app/langflow
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7860/"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 40s

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: langflow
      POSTGRES_PASSWORD: langflow
      POSTGRES_DB: langflow
    volumes:
      - pg-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U langflow"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    command: redis-server --save 60 1 --loglevel warning
    volumes:
      - redis-data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  langflow-data:
  pg-data:
  redis-data:
COMPOSE

sudo docker compose up -d

printf "Waiting for services to become healthy...\n"
while true; do
  unhealthy=$(sudo docker compose ps --format '{{.Service}} {{.State}}' | grep -v 'running (healthy)' | wc -l)
  if [ "$unhealthy" -eq 0 ]; then
    break
  fi
  sleep 5
done

echo ""
echo "Langflow is up and running!"
echo "Frontend URL: http://localhost:7860"
echo "Swagger docs: http://localhost:7860/docs"
echo "Langflow API run endpoint: POST /api/v1/run/{flow_id}"
echo "Redis address: redis:6379"
echo "PostgreSQL DSN: postgresql://langflow:langflow@postgres:5432/langflow"
echo "Default superuser: admin"
echo "Default password: adminpass"
echo ""
echo "Tail logs: docker compose logs -f"
echo "Stop stack: docker compose down"
echo "Remove data volumes: docker compose down -v"
