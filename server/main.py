from fastapi import FastAPI

app = FastAPI()


@app.get("/hello")
def hello():
    return {"message": "iron maiden"}

@app.get("/ironMaiden")
def ironMaiden(): return {"roei big fan"}