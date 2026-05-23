#!/bin/bash

set -e

REPORT_DIR="security-reports"
BACKEND_IMAGE="trainwithshubham/skillpulse-backend:latest"
FRONTEND_IMAGE="trainwithshubham/skillpulse-frontend:latest"

echo "==================================="
echo " SkillPulse DevSecOps Scan"
echo "==================================="

mkdir -p $REPORT_DIR

echo
echo "[1/6] Scanning backend image for HIGH/CRITICAL vulnerabilities..."

trivy image \
--severity HIGH,CRITICAL \
--exit-code 1 \
--ignore-unfixed \
--format table \
--output $REPORT_DIR/backend-image-scan.txt \
$BACKEND_IMAGE

echo "Backend image scan completed."

echo
echo "[2/6] Scanning frontend image for HIGH/CRITICAL vulnerabilities..."

trivy image \
--severity HIGH,CRITICAL \
--exit-code 1 \
--ignore-unfixed \
--format table \
--output $REPORT_DIR/frontend-image-scan.txt \
$FRONTEND_IMAGE

echo "Frontend image scan completed."

echo
echo "[3/6] Scanning Kubernetes manifests..."

trivy config k8s/ \
--severity HIGH,CRITICAL \
--format table \
--output $REPORT_DIR/k8s-manifest-scan.txt

echo "Kubernetes manifest scan completed."

echo
echo "[4/6] Scanning filesystem for vulnerabilities..."

trivy filesystem . \
--scanners vuln \
--severity HIGH,CRITICAL \
--format table \
--output $REPORT_DIR/filesystem-scan.txt

echo "Filesystem vulnerability scan completed."

echo
echo "[5/6] Scanning repository for secrets using Gitleaks..."

gitleaks detect \
--source . \
--report-format json \
--report-path $REPORT_DIR/gitleaks-report.json

echo "Secret scan completed."

echo
echo "[6/6] Security summary"

echo "Generated reports:"
echo
echo " - backend-image-scan.txt"
echo " - frontend-image-scan.txt"
echo " - k8s-manifest-scan.txt"
echo " - filesystem-scan.txt"
echo " - gitleaks-report.json"

echo
echo "Reports location:"
echo "$REPORT_DIR/"

echo
echo "DevSecOps scan completed successfully."
