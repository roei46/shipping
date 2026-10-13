# Server Conventions

Backend for the shipping app. The big picture, decisions and the API contract are in the root `CLAUDE.md`.

## Stack
- Python, FastAPI (API), Pydantic (request / response models).
- PostgreSQL (database), Alembic (migrations).
- Redis (queue) + Celery (worker) for background jobs.
- httpx for calls to external APIs; the anthropic library for the LLM.
- Poetry for dependencies and the virtual environment (Python 3.12).
## How I want to work (I'm new to backend)
- I'm an experienced iOS developer and new to backend. Explain in simple terms, and compare to iOS / Swift when it helps.
- Before every change: explain what you are going to do and why, then wait for my OK.
- Start each new feature in Plan Mode.
- One change at a time. Don't add anything I didn't ask for; if something new is needed, say so and ask.

## Architecture rules
- The API answers fast: validate, save, enqueue, return. Anything slow (LLM, forwarders, trucking, push) runs in the Celery worker.
- Two background jobs: `prepare_options` (on submit) and `book_shipment` (on approve).
- The API contract in the root `CLAUDE.md` is the only source of truth for endpoints, fields and statuses. JSON keys are camelCase; Python names are snake_case (Pydantic alias_generator=to_camel).
- The LLM is used only for steps 1–2. Its output is validated with Pydantic. It never produces prices or dates.
- Database changes only through Alembic migrations.

## Secrets
- API keys and passwords only in `.env`, never in code. `.env` is in `.gitignore`.

## Local run
- Base URL: `http://localhost:8000`.

## First task: connectivity test
- Endpoint `GET /hello`, no authentication.
- Returns `200` with `{ "message": "hello world" }` (as in the root API contract).
- Purpose: check that the iOS app reaches the server. It is a test endpoint, not part of the product.
