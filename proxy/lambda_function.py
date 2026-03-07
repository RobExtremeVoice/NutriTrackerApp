import json
import os
import urllib.request
import urllib.error


def lambda_handler(event, context):
    api_key = os.environ.get("OPENAI_API_KEY", "")
    if not api_key:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": "OPENAI_API_KEY not configured"}),
        }

    # Parse body sent by the iOS app
    try:
        body = json.loads(event.get("body") or "{}")
    except json.JSONDecodeError:
        return {"statusCode": 400, "body": json.dumps({"error": "Invalid JSON body"})}

    payload = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        "https://api.openai.com/v1/chat/completions",
        data=payload,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=60) as response:
            result = response.read()
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": result.decode("utf-8"),
        }
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        return {"statusCode": e.code, "body": error_body}
    except Exception as e:
        return {"statusCode": 502, "body": json.dumps({"error": str(e)})}
