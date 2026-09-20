import json
import logging
import os
import signal
import time

import boto3
from botocore.config import Config

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
)
logger = logging.getLogger("order-worker")

AWS_REGION = os.getenv("AWS_REGION", "us-east-1")
ORDERS_QUEUE_URL = os.environ["ORDERS_QUEUE_URL"]
POLL_WAIT_SECONDS = int(os.getenv("POLL_WAIT_SECONDS", "20"))
PROCESSING_SECONDS = float(os.getenv("PROCESSING_SECONDS", "2"))

sqs = boto3.client(
    "sqs",
    region_name=AWS_REGION,
    config=Config(retries={"max_attempts": 5, "mode": "standard"}),
)

running = True


def stop(_signum: int, _frame: object) -> None:
    global running
    running = False
    logger.info("Shutdown requested")


signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)


def process_order(body: str) -> None:
    order = json.loads(body)
    logger.info("Processing order %s", order["order_id"])
    time.sleep(PROCESSING_SECONDS)
    logger.info("Completed order %s", order["order_id"])


def main() -> None:
    logger.info("Worker started")
    while running:
        response = sqs.receive_message(
            QueueUrl=ORDERS_QUEUE_URL,
            MaxNumberOfMessages=5,
            WaitTimeSeconds=POLL_WAIT_SECONDS,
            VisibilityTimeout=60,
            MessageAttributeNames=["All"],
        )

        for message in response.get("Messages", []):
            try:
                process_order(message["Body"])
                sqs.delete_message(
                    QueueUrl=ORDERS_QUEUE_URL,
                    ReceiptHandle=message["ReceiptHandle"],
                )
            except Exception:
                logger.exception("Order processing failed; message will be retried")

    logger.info("Worker stopped")


if __name__ == "__main__":
    main()

