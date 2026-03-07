#!/usr/bin/env bash
# NutriTrack Pro — AWS Lambda proxy deployer
# Requires: aws CLI configured (run: aws configure --profile nutri)
# Usage: bash deploy.sh

set -euo pipefail

REGION="us-east-1"
FUNCTION_NAME="nutri-openai-proxy"
ROLE_NAME="nutri-proxy-lambda-role"
AWS_PROFILE="${AWS_PROFILE:-nutri}"
export AWS_PROFILE
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Checking AWS credentials..."
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "    Account: $ACCOUNT_ID  Region: $REGION"

# ── 1. IAM Role ──────────────────────────────────────────────────────────────
echo ""
echo "==> Creating IAM role for Lambda..."

TRUST='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

ROLE_ARN=$(aws iam create-role \
  --role-name "$ROLE_NAME" \
  --assume-role-policy-document "$TRUST" \
  --query Role.Arn --output text 2>/dev/null) \
  || ROLE_ARN=$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text)

aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole \
  2>/dev/null || true

echo "    Role ARN: $ROLE_ARN"
echo "    Waiting 12 s for IAM to propagate..."
sleep 12

# ── 2. Zip function ───────────────────────────────────────────────────────────
echo ""
echo "==> Packaging Lambda function..."
cd "$SCRIPT_DIR"
zip -j function.zip lambda_function.py
echo "    function.zip ready."

# ── 3. Create or update Lambda ────────────────────────────────────────────────
echo ""
echo "==> Deploying Lambda function..."

if aws lambda get-function --function-name "$FUNCTION_NAME" --region "$REGION" &>/dev/null; then
  echo "    Function exists — updating code..."
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file fileb://function.zip \
    --region "$REGION" > /dev/null
else
  echo "    Creating new function..."
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime python3.12 \
    --role "$ROLE_ARN" \
    --handler lambda_function.lambda_handler \
    --zip-file fileb://function.zip \
    --timeout 60 \
    --memory-size 256 \
    --region "$REGION" > /dev/null
fi

# ── 4. Set OpenAI key as env variable ────────────────────────────────────────
echo ""
read -rsp "==> Paste your OpenAI API key (hidden): " OPENAI_KEY
echo ""

aws lambda update-function-configuration \
  --function-name "$FUNCTION_NAME" \
  --environment "Variables={OPENAI_API_KEY=$OPENAI_KEY}" \
  --region "$REGION" > /dev/null

echo "    Key saved to Lambda environment (encrypted at rest by AWS)."

# ── 5. Create Function URL (public HTTPS endpoint) ───────────────────────────
echo ""
echo "==> Setting up Function URL..."

aws lambda add-permission \
  --function-name "$FUNCTION_NAME" \
  --statement-id FunctionURLAllowPublicAccess \
  --action lambda:InvokeFunctionUrl \
  --principal "*" \
  --function-url-auth-type NONE \
  --region "$REGION" > /dev/null 2>/dev/null || true

FUNCTION_URL=$(aws lambda create-function-url-config \
  --function-name "$FUNCTION_NAME" \
  --auth-type NONE \
  --region "$REGION" \
  --query FunctionUrl --output text 2>/dev/null) \
  || FUNCTION_URL=$(aws lambda get-function-url-config \
       --function-name "$FUNCTION_NAME" \
       --region "$REGION" \
       --query FunctionUrl --output text)

# ── 6. Done ───────────────────────────────────────────────────────────────────
echo ""
echo "=========================================="
echo "  Proxy deployed successfully!"
echo "=========================================="
echo ""
echo "  Your endpoint:"
echo "  $FUNCTION_URL"
echo ""
echo "  Next step — update AppConstants.swift:"
echo "  Change openAIEndpoint to: $FUNCTION_URL"
echo "=========================================="

# Cleanup
rm -f function.zip
