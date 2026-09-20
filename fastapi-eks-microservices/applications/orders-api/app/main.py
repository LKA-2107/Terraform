import logging
import os
import threading
import uuid
from datetime import datetime, timezone

from fastapi import FastAPI, HTTPException, status
from pydantic import BaseModel, Field

logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"))
logger = logging.getLogger("orders-api")
app = FastAPI(title="Orders API", version="2.0.0")

# Learning-only storage: lost on restart and not shared between replicas.
orders: dict[str, dict] = {}
orders_lock = threading.Lock()


class OrderItem(BaseModel):
    product_id: str = Field(min_length=1, max_length=100)
    quantity: int = Field(ge=1, le=100)


class CreateOrderRequest(BaseModel):
    customer_name: str = Field(min_length=1, max_length=100)
    items: list[OrderItem] = Field(min_length=1, max_length=20)


@app.get("/healthz")
def health() -> dict[str, str]:
    return {"status": "healthy"}


@app.get("/readyz")
def readiness() -> dict[str, str]:
    return {"status": "ready"}


@app.post("/orders", status_code=status.HTTP_201_CREATED)
def create_order(request: CreateOrderRequest) -> dict:
    order_id = str(uuid.uuid4())
    order = {
        "order_id": order_id,
        "customer_name": request.customer_name,
        "items": [item.model_dump() for item in request.items],
        "status": "created",
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    with orders_lock:
        orders[order_id] = order
    logger.info("Order created: %s", order_id)
    return order


@app.get("/orders")
def list_orders() -> list[dict]:
    with orders_lock:
        return list(orders.values())


@app.get("/orders/{order_id}")
def get_order(order_id: str) -> dict:
    with orders_lock:
        order = orders.get(order_id)
    if order is None:
        raise HTTPException(status_code=404, detail="Order not found")
    return order

