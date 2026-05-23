#!/bin/bash

set -e

echo "================================="
echo " Deploying to Kubernetes"
echo "================================="

echo "Applying Kubernetes manifests..."

kubectl apply -f k8s/

echo "Waiting for MySQL rollout..."
kubectl rollout status statefulset/mysql -n skillpulse

echo "Waiting for backend rollout..."
kubectl rollout status deployment/backend -n skillpulse

echo "Waiting for frontend rollout..."
kubectl rollout status deployment/frontend -n skillpulse

echo "Deployment completed successfully!"
