
#!/bin/bash

NAMESPACE="skillpulse"
FAILED=0

echo "==================================="
echo " SkillPulse Health Check"
echo "==================================="
echo

echo "[1/4] Checking Pods..."
kubectl get pods -n $NAMESPACE
echo

# check any pods are in CrashLoopBackOff or Error state
UNHEALTHY=$(kubectl get pods -n $NAMESPACE --no-headers | awk '{print $3}' | grep -vE "^Running$|^Completed$" | wc -l)
if [ "$UNHEALTHY" -gt 0 ]; then
  echo "WARNING: Some pods are not in Running state."
  FAILED=1
fi

echo "[2/4] Checking Services..."
kubectl get svc -n $NAMESPACE
echo

echo "[3/4] Checking Application Health..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/health)
if [ "$HTTP_STATUS" == "200" ]; then
  echo "  /health → OK (200)"
  curl -s http://localhost:8888/health
else
  echo "  ERROR: /health returned HTTP $HTTP_STATUS"
  FAILED=1
fi
echo

echo "[4/4] Checking Dashboard API..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8888/api/dashboard)
if [ "$HTTP_STATUS" == "200" ]; then
  echo "  /api/dashboard → OK (200)"
  curl -s http://localhost:8888/api/dashboard
else
  echo "  ERROR: /api/dashboard returned HTTP $HTTP_STATUS"
  FAILED=1
fi
echo

if [ "$FAILED" -eq 0 ]; then
  echo "✅ All health checks passed."
  exit 0
else
  echo "❌ One or more health checks FAILED."
  exit 1
fi