#!/usr/bin/env bash
# NutriTrack Pro — upgrade Lambda to Node.js streaming
# Run this AFTER the initial deploy.sh succeeded.
# Usage: bash update-streaming.sh

set -euo pipefail

REGION="us-east-1"
FUNCTION_NAME="nutri-openai-proxy"
AWS_PROFILE="${AWS_PROFILE:-nutri}"
export AWS_PROFILE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Checking AWS credentials..."
aws sts get-caller-identity --query Account --output text > /dev/null
echo "    OK"

# ── 1. Package new Node.js code ───────────────────────────────────────────────
echo ""
echo "==> Packaging Node.js Lambda..."
cd "$SCRIPT_DIR"
zip -j function-stream.zip index.mjs
echo "    function-stream.zip ready."

# ── 2. Upload new code ────────────────────────────────────────────────────────
echo ""
echo "==> Uploading new Lambda code..."
aws lambda update-function-code \
  --function-name "$FUNCTION_NAME" \
  --zip-file fileb://function-stream.zip \
  --region "$REGION" > /dev/null

aws lambda wait function-updated \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION"

# ── 3. Switch runtime to Node.js 20 ──────────────────────────────────────────
echo ""
echo "==> Switching runtime → nodejs20.x ..."
aws lambda update-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --runtime nodejs20.x \
  --handler index.handler \
  --region "$REGION" > /dev/null

aws lambda wait function-updated \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION"

# ── 4. Delete existing Function URL ──────────────────────────────────────────
# InvokeMode cannot be changed in-place; must delete + recreate.
echo ""
echo "==> Deleting old Function URL (InvokeMode cannot be updated in-place)..."
aws lambda delete-function-url-config \
  --function-name "$FUNCTION_NAME" \
  --region "$REGION" 2>/dev/null || echo "    (no existing URL to delete)"

sleep 3

# ── 5. Recreate with RESPONSE_STREAM ─────────────────────────────────────────
echo "==> Creating streaming Function URL..."
NEW_URL=$(aws lambda create-function-url-config \
  --function-name "$FUNCTION_NAME" \
  --auth-type NONE \
  --invoke-mode RESPONSE_STREAM \
  --region "$REGION" \
  --query FunctionUrl --output text)

# ── 6. Re-apply public access permission ─────────────────────────────────────
aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id FunctionURLAllowPublicAccess \
  --action lambda:InvokeFunctionUrl \
  --principal "*" \
  --function-url-auth-type NONE \
  --region "$REGION" > /dev/null 2>/dev/null || true

# Cleanup
rm -f function-stream.zip

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Streaming Lambda deployed!"
echo "=========================================="
echo ""
echo "  New endpoint (URL CHANGED — update Swift):"
echo "  $NEW_URL"
echo ""
echo "  In AppConstants.swift change openAIEndpoint to:"
echo "  \"$NEW_URL\""
echo "=========================================="
