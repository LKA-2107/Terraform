#!/usr/bin/env bash
set -euo pipefail

aws_region="${AWS_REGION:-us-east-1}"
project_name="${PROJECT_NAME:-migration}"
image_tag="${IMAGE_TAG:-v1}"
aws_account_id="$(aws sts get-caller-identity --query Account --output text)"
registry="${aws_account_id}.dkr.ecr.${aws_region}.amazonaws.com"

aws ecr get-login-password --region "${aws_region}" \
  | docker login --username AWS --password-stdin "${registry}"

for service in frontend orders-api order-worker; do
  image="${registry}/${project_name}/${service}:${image_tag}"
  docker build --tag "${image}" "applications/${service}"
  docker push "${image}"
  printf '%s\n' "Pushed ${image}"
done

