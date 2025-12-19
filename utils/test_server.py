from fastapi import FastAPI, Request

app = FastAPI()


@app.post("/echo")
@app.put("/echo")
@app.patch("/echo")
async def echo(request: Request):
    data = await request.body()
    print(data)
    return data
