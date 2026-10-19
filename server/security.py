from datetime import UTC, datetime, timedelta

import jwt
from pwdlib import PasswordHash

from config import settings

hasher = PasswordHash.recommended()


def hash_password(password: str) -> str:
    return hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return hasher.verify(password, password_hash)

def create_token(user_id: str) -> str:
    payload = {"sub": user_id, "exp": datetime.now(UTC) + timedelta(days=7)}
    return jwt.encode(payload, settings.jwt_secret, algorithm="HS256")