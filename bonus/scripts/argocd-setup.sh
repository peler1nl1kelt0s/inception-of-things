#!/bin/bash

set -e

echo "Argo CD kurulumu başlatılıyor..."

KUBE_NAMESPACE_ARGOCD="argocd"

# Argo CD kur
kubectl apply -n ${KUBE_NAMESPACE_ARGOCD} -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Argo CD pod'larının başlamasını bekle
kubectl wait --for=condition=ready pod --all -n ${KUBE_NAMESPACE_ARGOCD} --timeout=300s

# Insecure mode etkinleştir
kubectl patch configmap argocd-cmd-params-cm -n ${KUBE_NAMESPACE_ARGOCD} --type merge -p '{"data": {"server.insecure": "true"}}'
kubectl rollout restart deployment argocd-server -n ${KUBE_NAMESPACE_ARGOCD}

# Argo CD'nin yeniden başlamasını bekle
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n ${KUBE_NAMESPACE_ARGOCD} --timeout=120s

# Ingress oluştur
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: ${KUBE_NAMESPACE_ARGOCD}
spec:
  ingressClassName: traefik
  rules:
  - host: argocd.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: argocd-server
            port:
              number: 80
EOF

echo "Argo CD kurulumu tamamlandı."