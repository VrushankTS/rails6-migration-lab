#!/usr/bin/env bash
set -e

# Rails 6 Docker workflow for this project.
# Usage:
#   chmod +x scripts/rails6-docker-workflow.sh
#   ./scripts/rails6-docker-workflow.sh start
#   ./scripts/rails6-docker-workflow.sh stop
#   ./scripts/rails6-docker-workflow.sh reset
#   ./scripts/rails6-docker-workflow.sh db-create
#   ./scripts/rails6-docker-workflow.sh migrate
#   ./scripts/rails6-docker-workflow.sh console
#   ./scripts/rails6-docker-workflow.sh test

case "$1" in
  start)
    echo "Starting PostgreSQL and Rails app..."
    docker compose up -d db
    docker compose up
    ;;
  stop)
    echo "Stopping containers..."
    docker compose down
    ;;
  reset)
    echo "Resetting Docker volumes and rebuilding..."
    docker compose down -v
    docker compose build --no-cache
    docker compose up -d db
    docker compose run --rm web bin/rails db:create
    docker compose run --rm web bin/rails db:migrate
    docker compose up
    ;;
  db-create)
    echo "Creating the database..."
    docker compose run --rm web bin/rails db:create
    ;;
  migrate)
    echo "Running database migrations..."
    docker compose run --rm web bin/rails db:migrate
    ;;
  console)
    echo "Opening Rails console..."
    docker compose run --rm web bin/rails console
    ;;
  test)
    echo "Running test suite..."
    docker compose run --rm web bin/rails test
    ;;
  shell)
    echo "Opening a shell in the web container..."
    docker compose run --rm web bash
    ;;
  version)
    echo "Checking Rails version..."
    docker compose run --rm web bin/rails --version
    ;;
  *)
    cat <<'EOF'
Usage:
  ./scripts/rails6-docker-workflow.sh start
  ./scripts/rails6-docker-workflow.sh stop
  ./scripts/rails6-docker-workflow.sh reset
  ./scripts/rails6-docker-workflow.sh db-create
  ./scripts/rails6-docker-workflow.sh migrate
  ./scripts/rails6-docker-workflow.sh console
  ./scripts/rails6-docker-workflow.sh test
  ./scripts/rails6-docker-workflow.sh shell
  ./scripts/rails6-docker-workflow.sh version
EOF
    ;;
esac
