#!/bin/bash
set -e
AWS_ACCOUNT_ID='787124622819'
AWS_REGION='us-east-1'
DOCKER_IMAGE="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/pcfactory-app"
docker push "$DOCKER_IMAGE:latest"
echo ' ECR push completado'
