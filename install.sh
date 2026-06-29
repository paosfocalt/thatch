#!/bin/bash
set -euo pipefail

# Configuration
K3S_CHANNEL="stable"
ARGOCD_CHART_VERSION="7.7.23"
ARGOCD_NAMESPACE="argocd"
KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
GIT_REPO_URL="https://github.com/paosfocalt/thatch.git"
GIT_TARGET_REVISION="main"
GIT_ARGOCD_PATH="argocd/apps"

export KUBECONFIG

echo "=== Prerequisites ==="

apt-get update
apt-get install -y curl apt-transport-https ca-certificates open-iscsi nfs-common

swapoff -a
sed -i '/\sswap\s/d' /etc/fstab

modprobe br_netfilter
modprobe overlay

cat > /etc/modules-load.d/k3s.conf <<EOF
br_netfilter
overlay
EOF

cat > /etc/sysctl.d/99-k3s.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system

echo "=== Installing k3s ==="

mkdir -p /etc/rancher/k3s

cat > /etc/rancher/k3s/config.yaml <<EOF
write-kubeconfig-mode: "0644"
disable:
  - traefik
  - servicelb
EOF

if ! command -v k3s &> /dev/null; then
    curl -sfL https://get.k3s.io | INSTALL_K3S_CHANNEL="$K3S_CHANNEL" sh -
fi

systemctl enable k3s
systemctl start k3s

echo "Waiting for node to be ready..."
until kubectl get nodes | grep -q " Ready"; do
    sleep 10
done
echo "Node ready."

echo "=== Installing ArgoCD ==="

if ! command -v helm &> /dev/null; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

helm repo add argo https://argoproj.github.io/argo-helm 2>/dev/null || true
helm repo update

helm upgrade --install argocd argo/argo-cd \
    --namespace "$ARGOCD_NAMESPACE" \
    --create-namespace \
    --version "$ARGOCD_CHART_VERSION" \
    --set server.service.type=NodePort \
    --set server.service.nodePortHttps=30443 \
    --wait \
    --timeout 300s

kubectl rollout status deployment argocd-server -n "$ARGOCD_NAMESPACE" --timeout=300s

echo "=== Applying root app-of-apps ==="

cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: ${ARGOCD_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${GIT_REPO_URL}
    targetRevision: ${GIT_TARGET_REVISION}
    path: ${GIT_ARGOCD_PATH}
    directory:
      recurse: false
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ARGOCD_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF

echo "=== Done ==="
echo "ArgoCD is running. Access the UI:"
echo "  https://<node-ip>:30443"
echo "  Default admin password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"
