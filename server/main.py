from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from sqlalchemy import select

from db import SessionLocal
from models import User
from security import verify_password

app = FastAPI()

class LoginRequest(BaseModel):
    username: str
    password: str

@app.get("/hello")
def hello():
    return {"message": "iron maiden"}

@app.get("/ironMaiden")
def ironMaiden(): return {"roei big fan"}

@app.post("/customer/login")
def login(request: LoginRequest):
    print("login attempt:", request.username)
    with SessionLocal() as session:
        user = session.scalar(select(User).where(User.username == request.username))
    print("user found:", user)

    if user is None or not verify_password(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Wrong username or password")

    return {"token": "not-yet"}