#!/bin/bash
set -e

echo "--- Starting Auto-Configuration ---"

# --- GitLab Configuration ---
echo "--> Waiting for GitLab pods to be ready..."
kubectl wait --for=condition=ready pod -l app=webservice -n gitlab --timeout=900s

echo "--> Configuring GitLab..."
GITLAB_URL="http://127.0.0.1:10080" # Vagrant port forwarding
GITLAB_INTERNAL_URL="http://gitlab-webservice-default.gitlab.svc.cluster.local" # K8s internal service URL
GITLAB_POD=$(kubectl get pod -n gitlab -l app=webservice -o name | head -n 1)

echo "--> Creating GitLab Personal Access Token for root..."
TOKEN_COMMAND="token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :write_repository], name: 'ArgoCD-Token', expires_at: 365.days.from_now); token.set_token('argocd-token-secret-12345'); token.save!"
kubectl exec -n gitlab ${GITLAB_POD#pod/} -c webservice -- gitlab-rails runner "$TOKEN_COMMAND"
GITLAB_ACCESS_TOKEN="argocd-token-secret-12345"

echo "--> Creating GitLab project 'iot-project-app'..."
curl --retry 5 --retry-delay 10 --silent --show-error --header "PRIVATE-TOKEN: ${GITLAB_ACCESS_TOKEN}" -X POST "${GITLAB_URL}/api/v4/projects?name=iot-project-app&visibility=public"

echo "--> Pushing manifests to new GitLab project..."
cd /tmp
rm -rf iot-project-app
git clone "http://root:${GITLAB_ACCESS_TOKEN}@127.0.0.1:10080/root/iot-project-app.git"
cd iot-project-app
cp /vagrant/confs/deployment.yaml .
cp /vagrant/confs/service.yaml .
git config --global user.email "admin@example.com"
git config --global user.name "Administrator"
git add .
git commit -m "Initial commit of application manifests"
git push -u origin master
cd /tmp && rm -rf iot-project-app

# --- Argo CD Configuration ---
echo "--> Configuring Argo CD..."
echo "--> Waiting for Argo CD pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

echo "--> Applying Argo CD application manifest..."
# application.yaml'daki repoURL'yi küme içi adresle değiştirerek uygula
sed "s|http://gitlab.local:8080/root/iot-project-app.git|${GITLAB_INTERNAL_URL}/root/iot-project-app.git|g" /vagrant/confs/application.yaml | kubectl apply -n argocd -f -

echo "--- Auto-Configuration Finished ---"
GITLAB_ROOT_PASSWORD=$(kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode)
ARGOCD_ADMIN_PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

echo
echo "================================================="
echo "ACCESS INFORMATION:"
echo "-------------------------------------------------"
echo "GitLab UI: http://localhost:10080"
echo "GitLab User: root"
echo "GitLab Pass: ${GITLAB_ROOT_PASSWORD}"
echo "-------------------------------------------------"
echo "Argo CD UI: http://localhost:8080"
echo "Argo CD User: admin"
echo "Argo CD Pass: ${ARGOCD_ADMIN_PASSWORD}"
echo "-------------------------------------------------"
echo "Application: http://localhost:8888"
echo "================================================="