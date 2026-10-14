import sys
from getpass import getpass

from db import SessionLocal
from models import User
from security import hash_password

username = sys.argv[1]
password = getpass("Password: ")

with SessionLocal() as session:
    session.add(User(username=username, password_hash=hash_password(password)))
    session.commit()

print(f"Created user {username}")
