import os
import socket
from datetime import datetime, timezone

from fastapi import FastAPI
from fastapi.responses import JSONResponse

app = FastAPI(title="thatch-api")

ready = True


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def readiness():
    if not ready:
        return JSONResponse(status_code=503, content={"status": "not_ready"})
    return {"status": "ready"}


@app.get("/info")
def info():
    return {
        "version": os.environ.get("APP_VERSION", "dev"),
        "hostname": socket.gethostname(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
