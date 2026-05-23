#!/bin/bash

NAMESPACE="skillpulse"
# Usage: ./rollback.sh          → rolls back to previous revision
#        ./rollback.sh 3        → rolls back to specific revision number
#        ./rollback.sh --list   → lists available revisions
REVISION=${1:-}

echo "==================================="
echo " SkillPulse Rollback"
echo "==================================="
echo

# --list flag: show available revisions and exit
if [ "$REVISION" == "--list" ]; then
  echo "Available revisions for backend:"
  kubectl rollout history deployment/backend -n $NAMESPACE
  echo
  echo "Available revisions for frontend:"
  kubectl rollout history deployment/frontend -n $NAMESPACE
  exit 0
fi

# build the --to-revision flag only if a revision number was passed
REVISION_FLAG=""
if [ -n "$REVISION" ]; then
  echo "Rolling back to revision: $REVISION"
  REVISION_FLAG="--to-revision=$REVISION"
else
  echo "Rolling back to previous revision..."
fi
echo

echo "[1/2] Rolling back backend deployment..."
kubectl rollout undo deployment/backend -n $NAMESPACE $REVISION_FLAG
echo

echo "[2/2] Rolling back frontend deployment..."
kubectl rollout undo deployment/frontend -n $NAMESPACE $REVISION_FLAG
echo

echo "Waiting for rollouts to stabilize..."
kubectl rollout status deployment/backend  -n $NAMESPACE --timeout=120s
kubectl rollout status deployment/frontend -n $NAMESPACE --timeout=60s
echo

echo "Current image tags after rollback:"
kubectl get deployment backend  -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' && echo
kubectl get deployment frontend -n $NAMESPACE -o jsonpath='{.spec.template.spec.containers[0].image}' && echo
echo

echo "✅ Rollback completed successfully."