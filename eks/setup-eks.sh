#!/bin/bash
# =============================================================
#  SkillPulse — EKS Setup Script (Resume-safe)
#  Skips any step already completed.
# =============================================================
set -e

CLUSTER_NAME="skillpulse"
REGION="ap-south-1"

echo "==========================================="
echo " SkillPulse EKS Setup"
echo "==========================================="
echo

# ensure local bin dir exists and is in PATH
mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# ─────────────────────────────────────────────
# STEP 1 — AWS CLI
# ─────────────────────────────────────────────
echo "[1/6] Checking AWS CLI..."
if command -v aws &>/dev/null; then
  echo "  Already installed: $(aws --version)"
else
  echo "  Installing..."
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  ./aws/install --install-dir "$HOME/.aws-cli" --bin-dir "$HOME/.local/bin"
  rm -rf awscliv2.zip aws/
  echo "  Installed: $(aws --version)"
fi
echo

# ─────────────────────────────────────────────
# STEP 2 — eksctl
# ─────────────────────────────────────────────
echo "[2/6] Checking eksctl..."
if command -v eksctl &>/dev/null; then
  echo "  Already installed: $(eksctl version)"
else
  echo "  Installing..."
  PLATFORM=$(uname -s)_amd64
  curl -sLO "https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_$PLATFORM.tar.gz"
  tar -xzf eksctl_$PLATFORM.tar.gz -C /tmp
  mv /tmp/eksctl "$HOME/.local/bin/eksctl"
  chmod +x "$HOME/.local/bin/eksctl"
  rm -f eksctl_$PLATFORM.tar.gz
  echo "  Installed: $(eksctl version)"
fi
echo

# ─────────────────────────────────────────────
# STEP 3 — kubectl
# ─────────────────────────────────────────────
echo "[3/6] Checking kubectl..."
if command -v kubectl &>/dev/null; then
  echo "  Already installed"
else
  echo "  Installing..."
  K8S_VER=$(curl -Ls https://dl.k8s.io/release/stable.txt)
  curl -sLO "https://dl.k8s.io/release/${K8S_VER}/bin/linux/amd64/kubectl"
  chmod +x kubectl
  mv kubectl "$HOME/.local/bin/kubectl"
  echo "  Installed"
fi
echo

# ─────────────────────────────────────────────
# STEP 4 — AWS credentials
# ─────────────────────────────────────────────
echo "[4/6] Configuring AWS credentials..."
echo
echo "  Get keys from:"
echo "  AWS Console → top-right your name → Security Credentials → Access Keys → Create Access Key"
echo
aws configure
echo

# verify credentials work
echo "  Verifying credentials..."
aws sts get-caller-identity
echo

# ─────────────────────────────────────────────
# STEP 5 — EKS cluster
# ─────────────────────────────────────────────
echo "[5/6] Creating EKS cluster (~15 min)..."
echo "  Cluster : $CLUSTER_NAME"
echo "  Region  : $REGION"
echo

if eksctl get cluster --name $CLUSTER_NAME --region $REGION &>/dev/null 2>&1; then
  echo "  Cluster already exists — skipping create."
else
  eksctl create cluster -f eks/cluster.yaml
fi

# update local kubeconfig
aws eks update-kubeconfig --name $CLUSTER_NAME --region $REGION
echo
echo "  Nodes ready:"
kubectl get nodes
echo

# ─────────────────────────────────────────────
# STEP 6 — nginx Ingress via Helm
# ─────────────────────────────────────────────
echo "[6/6] Installing nginx Ingress Controller..."

if ! command -v helm &>/dev/null; then
  echo "  Installing Helm..."
  export HELM_INSTALL_DIR="$HOME/.local/bin"
  curl -s https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | USE_SUDO=false bash
fi

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx 2>/dev/null || true
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer \
  --wait --timeout 5m

echo
echo "  Ingress controller ready."
echo "  Your AWS Load Balancer (EXTERNAL-IP) — save this:"
kubectl get svc -n ingress-nginx ingress-nginx-controller
echo

# ─────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────
echo "==========================================="
echo " EKS Setup Complete!"
echo "==========================================="
echo
echo "IMPORTANT — copy this for GitHub Actions secret (KUBECONFIG):"
echo
cat ~/.kube/config | base64
echo
echo "Add it as: Settings → Secrets → Actions → New secret → name it KUBECONFIG"
