#!/bin/sh
set -e

alembic upgrade head
celery -A worker worker --loglevel=info --pool=solo &
exec uvicorn main:app --host 0.0.0.0 --port "${PORT:-8000}"
