# Shipping server

FastAPI backend for the shipping app. Design and API contract: root `CLAUDE.md`.

## Every day

Run all commands from `~/shipping/server`.

| What | Command |
|---|---|
| Start PostgreSQL (only after a Mac restart) | `brew services run postgresql@17` |
| Run the server | `poetry run uvicorn main:app --reload` |
| Stop the server | Ctrl + C in the server terminal |
| Test the server | open http://localhost:8000/hello |

## Sometimes

| What | Command |
|---|---|
| Add a library | `poetry add <name>` |
| Create a migration after changing `models.py` | `poetry run alembic revision --autogenerate -m "what changed"` |
| Apply migrations to the database | `poetry run alembic upgrade head` |
| Check models vs database | `poetry run alembic check` |
| Add a test user (asks for the password) | `poetry run python create_user.py <username>` |
| Look at a table | `psql shipping -c "\d users"` |
| See the rows | `psql shipping -c "select * from users"` |

## One-time setup (new Mac)

```bash
brew install python@3.12 postgresql@17
echo 'export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
brew services run postgresql@17
createdb shipping

cd ~/shipping/server
poetry env use python3.12
poetry install
```

Then create `.env` (never committed):

```
DATABASE_URL=postgresql+psycopg://<mac-username>@localhost:5432/shipping
JWT_SECRET=<output of: poetry run python -c "import secrets; print(secrets.token_hex(32))">
```

And build the tables: `poetry run alembic upgrade head`.

## Files

| File | What it is |
|---|---|
| `main.py` | The FastAPI app and its endpoints |
| `config.py` | Settings read from `.env` |
| `db.py` | Database connection (`engine`, `SessionLocal`) |
| `models.py` | Tables as Python classes |
| `security.py` | Password hashing (Argon2) |
| `create_user.py` | Script to add a user |
| `alembic/versions/` | Migrations, one file per database change |
| `pyproject.toml` / `poetry.lock` | Libraries and their exact versions |
