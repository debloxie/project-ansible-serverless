import json
import os
import time
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

ssm = boto3.client("ssm")
s3 = boto3.client("s3")

REPORT_BUCKET = os.environ["REPORT_BUCKET"]
CONFIG_PARAM = os.environ["CONFIG_PARAM"]

def lambda_handler(event, context):
    ts = int(time.time())

    # Log start of automation
    logger.info(json.dumps({
        "action": "start_automation",
        "timestamp": ts
    }))

    # Read config from SSM
    config = ssm.get_parameter(Name=CONFIG_PARAM)["Parameter"]["Value"]

    # Build report
    report = {
        "timestamp": ts,
        "config_value": config,
        "message": "automation run completed"
    }

    # Write report to S3
    key = f"reports/{ts}.json"
    s3.put_object(
        Bucket=REPORT_BUCKET,
        Key=key,
        Body=json.dumps(report).encode("utf-8"),
        ContentType="application/json",
    )

    logger.info(json.dumps({
        "action": "report_written",
        "key": key,
        "timestamp": ts
    }))

    # -----------------------------
    # VALIDATION STEP (NEW)
    # -----------------------------
    response = s3.get_object(Bucket=REPORT_BUCKET, Key=key)
    content = json.loads(response["Body"].read())

    is_valid = content.get("timestamp") == ts

    logger.info(json.dumps({
        "action": "report_validated",
        "key": key,
        "valid": is_valid
    }))

    return {
        "statusCode": 200,
        "body": json.dumps({
            "status": "ok",
            "report_key": key,
            "validated": is_valid
        })
    }
