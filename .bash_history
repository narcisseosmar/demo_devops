msg["From"] = os.environ["EMAIL_HOST_USER"]
msg["To"] = os.environ["EMAIL_HOST_USER"]
smtp.sendmail(msg["From"], msg["To"], msg.as_string())
smtp.quit()
print("SMTP OK !")
'
exit
ls
mkdir pdl
nano rbac.yaml
kubectl create namespace pdl
mv rbac.yaml pdl/
cd pdl/
cat rbac.yaml 
kubectl apply -f rbac.yaml 
kubectl get pods -n pdl
kubectl get deployment -n pdl
kubectl get svc -n pdl
kubectl create secret generic pdl-backend-secret   -n pdl   --from-env-file=.env.production
kubectl get namespaces
kubectl get pods -n postgresql
kubectl get svc -n postgresql
history
kubectl get svc -n postgresql
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
kubectl create secret generic pdl-backend-secret   -n pdl   --from-literal=NODE_ENV=production   --from-literal=PORT=5000   --from-literal=DATABASE_URL='postgresql://pdluser:pdlpass2026@postgres-main.postgresql.svc.cluster.local:5432/pdl'   --from-literal=JWT_SECRET='CHANGE_ME_WITH_A_LONG_RANDOM_SECRET'   --from-literal=JWT_EXPIRES_IN='1h'   --from-literal=REFRESH_TOKEN_EXPIRES_HOURS='168'   --from-literal=RESET_PASSWORD_TOKEN_EXPIRES_MINUTES='60'   --from-literal=FRONTEND_URL='http://141.95.29.23:30088'   --from-literal=CORS_ORIGINS='http://141.95.29.23:30088'
kubectl get secret pdl-backend-secret -n pdl
ls
kubectl create secret generic pdl-backend-secret   -n pdl   --from-literal=NODE_ENV=production   --from-literal=PORT=5000   --from-literal=DATABASE_URL='postgresql://pdluser:pdlpass2026@postgres-main.postgresql.svc.cluster.local:5432/pdl'   --from-literal=JWT_SECRET='METS_UNE_CLE_SECRETE_TRES_LONGUE'
sudo su
history
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U postgres
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
kubectl cp /tmp/mindforge.sql postgresql/postgres-main-7dcdccd666-4s6v6:/tmp/mindforge.sql
kubectl exec -i postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres < /tmp/mindforge.sql
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d mindforge
sudo su
sudo su
ls
kubectl get pods -A
ls
tree
kubectl get pods -A
ls
kubectl rollout status deployment/g-connex-api -n g-connex
kubectl describe deployment g-connex-api -n g-connex | grep Image
kubectl get deployment g-connex-api -n g-connex -o jsonpath='{.spec.template.spec.containers[*].image}'
kubectl logs -f deployment/g-connex-api -n g-connex
kubectl logs g-connex-api-54f6d4b7cf-jgzqz -n g-connex
kubectl exec -it deployment/g-connex-api -n g-connex -- sh
kubectl describe deployment g-connex-api -n g-connex
kubectl exec -it deployment/g-connex-api -n g-connex -- env | grep -i DB
kubectl get pods -n g-connex -w
psql -U postgres
npx sequelize-cli db:migrate:status
kubectl exec -it deployment/g-connex-api -n g-connex -- env | grep -i DB
kubectl exec -it deployment/g-connex-api -n g-connex -- sh
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- bash
kubectl exec -it deployment/g-connex-api -n g-connex -- sh
g-connex-frontend-56574475db-8vfts   AGE 30d
kubectl describe deployment g-connex-frontend -n g-connex | grep Image
kubectl logs deployment/g-connex-api -n g-connex | grep 404
# Depuis le pod Jenkins
kubectl cp /var/jenkins_home/workspace/api_g-connex/src/migrations g-connex/g-connex-api-54f6d4b7cf-jgzqz:/app/src/migrations
kubectl cp /var/jenkins_home/workspace/api_g-connex/src/config g-connex/g-connex-api-54f6d4b7cf-jgzqz:/app/src/config
kubectl exec -it deployment/g-connex-api -n g-connex -- sh
cat > /var/jenkins_home/workspace/api_g-connex/Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --omit=dev
COPY dist ./dist
COPY src/migrations ./src/migrations
COPY src/config ./src/config
ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000
CMD ["node", "dist/app.js"]
EOF

cat > /var/jenkins_home/workspace/api_g-connex/Jenkinsfile << 'EOF'
pipeline {
    agent any
    environment {
        PROJECT_NAME   = 'g-connex-api'
        REGISTRY       = '141.95.29.23:30500'
        IMAGE_NAME     = "${REGISTRY}/${PROJECT_NAME}"
        NAMESPACE      = 'g-connex'
        CONTAINER_PORT = '3000'
    }
    stages {
        stage('Checkout') {
            steps { checkout scm }
        }
        stage('Set Build Tag') {
            steps {
                script {
                    GIT_COMMIT_SHORT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    BUILD_TAG = "${env.BUILD_NUMBER}-${GIT_COMMIT_SHORT}"
                    echo "Build tag: ${BUILD_TAG}"
                }
            }
        }
        stage('Build & Push Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${BUILD_TAG} .
                    docker tag ${IMAGE_NAME}:${BUILD_TAG} ${IMAGE_NAME}:latest
                    docker push ${IMAGE_NAME}:${BUILD_TAG}
                    docker push ${IMAGE_NAME}:latest
                """
            }
        }
        stage('Deploy to Kubernetes (k3s)') {
            steps {
                sh """
                    kubectl set image deployment/${PROJECT_NAME} \
                    ${PROJECT_NAME}=${IMAGE_NAME}:${BUILD_TAG} \
                    -n ${NAMESPACE}
                    kubectl rollout status deployment/${PROJECT_NAME} \
                    -n ${NAMESPACE} --timeout=300s
                """
            }
        }
        stage('Run Migrations') {
            steps {
                sh """
                    kubectl exec deployment/${PROJECT_NAME} -n ${NAMESPACE} -- \
                    sh -c "cd /app && npx sequelize-cli db:migrate"
                """
            }
        }
        stage('Check Status') {
            steps {
                sh """
                    kubectl get pods -n ${NAMESPACE} -l app=${PROJECT_NAME}
                    kubectl get svc -n ${NAMESPACE}
                """
            }
        }
    }
    post {
        success {
            echo "Deployed: ${IMAGE_NAME}:${BUILD_TAG}"
        }
        failure {
            echo "Failed - rolling back"
            sh "kubectl rollout undo deployment/${PROJECT_NAME} -n ${NAMESPACE} || true"
        }
    }
}
EOF

cat ~/api_g-connex/Jenkinsfile
ls ~/api_g-connex/src/migrations/
# ou
ls ~/api_g-connex/migrations/
kubectl exec -it deployment/g-connex-api -n g-connex -- sh
grep -R "commandes/pro\|professional/trial" /app/dist/routes/
# Trouver le workspace Jenkins
ls /var/lib/jenkins/workspace/
# Voir le Jenkinsfile du backend
cat /var/lib/jenkins/workspace/api_g-connex/Jenkinsfile
# Chercher les migrations
find /var/lib/jenkins/workspace/api_g-connex -type d -name migrations
find /var/lib/jenkins/workspace/api_g-connex -name "*.js" | grep migrat
find /var/lib/jenkins/workspace/api_g-connex -name "*.ts" | grep migrat
cat /var/lib/jenkins/workspace/api_g-connex/Dockerfile
devops@vps-3c312592:~$ kubectl exec -it deployment/g-connex-api -n g-connex -- sh
grep -R "commandes/pro\|professional/trial" /app/dist/routes/
/app # exit
grep: /app/dist/routes/: No such file or directory
devops@vps-3c312592:~$ # Trouver le workspace Jenkins
ls /var/lib/jenkins/workspace/
# Voir le Jenkinsfile du backend
cat /var/lib/jenkins/workspace/api_g-connex/Jenkinsfile
# Chercher les migrations
find /var/lib/jenkins/workspace/api_g-connex -type d -name migrations
find /var/lib/jenkins/workspace/api_g-connex -name "*.js" | grep migrat
find /var/lib/jenkins/workspace/api_g-connex -name "*.ts" | grep migrat
ls: cannot access '/var/lib/jenkins/workspace/': No such file or directory
cat: /var/lib/jenkins/workspace/api_g-connex/Jenkinsfile: No such file or directory
find: '/var/lib/jenkins/workspace/api_g-connex': No such file or directory
devops@vps-3c312592:~$ cat /var/lib/jenkins/workspace/api_g-connex/Dockerfile
cat: /var/lib/jenkins/workspace/api_g-connex/Dockerfile: No such file or directory
devops@vps-3c312592:~$ 
ls /var/jenkins_home/workspace/
find / -name "Jenkinsfile" 2>/dev/null | grep -v proc | grep -v sys
ls ~/
ls ~/api_g-connex/
cat ~/api_g-connex/Jenkinsfile
cat ~/api_g-connex/Dockerfile
find ~/api_g-connex -type d -name migrations
cat ~/api_g-connex/deployment.yaml 
cat ~/api_g-connex/pvc-uploads.yaml 
cat ~/api_g-connex/service.yaml 
kubectl exec -it deployment/jenkins -n jenkins -- bash
kubectl cp jenkins/jenkins-547d95df9c-qdl26:/var/jenkins_home/workspace/api_g-connex/src/migrations /tmp/migrations
kubectl exec -it deployment/jenkins -n jenkins -- cat /var/jenkins_home/workspace/api_g-connex/src/config/database.js 2>/dev/null || kubectl exec -it deployment/jenkins -n jenkins -- ls /var/jenkins_home/workspace/api_g-connex/src/config/
kubectl cp /tmp/migrations g-connex/g-connex-api-54f6d4b7cf-jgzqz:/app/src/migrations
kubectl exec -it deployment/jenkins -n jenkins -- bash
kubectl logs -f deployment/g-connex-api -n g-connex
kubectl logs deployment/g-connex-api -n g-connex --tail=50 | grep -E "ERROR|error|404|migrat"
kubectl exec -it deployment/g-connex-api -n g-connex -- sh -c "wget -qO- http://localhost:3000/api/formations/professional/trial/eligibility 2>&1 | head -20"
kubectl exec -it deployment/g-connex-api -n g-connex -- find /app/dist -name "*.js" | grep -i format
kubectl exec -it deployment/g-connex-api -n g-connex -- find /app/dist -name "*.js" | grep -i commande
kubectl exec -it deployment/g-connex-api -n g-connex -- grep -r "professional\|commandes/pro" /app/dist/ 2>/dev/null | head -20
kubectl exec -it deployment/g-connex-api -n g-connex -- mkdir -p /app/src/migrations /app/src/config
kubectl cp /tmp/migrations/. g-connex/g-connex-api-54f6d4b7cf-jgzqz:/app/src/migrations/
kubectl exec -it deployment/jenkins -n jenkins -- cat /var/jenkins_home/workspace/api_g-connex/src/config/database.ts
kubectl cp jenkins/jenkins-547d95df9c-qdl26:/var/jenkins_home/workspace/api_g-connex/src/config /tmp/config
kubectl cp /tmp/config/. g-connex/g-connex-api-54f6d4b7cf-jgzqz:/app/src/config/
kubectl exec -it deployment/g-connex-api -n g-connex -- sh -c 'mkdir -p /app/config && cat > /app/config/config.json << EOF
{
  "production": {
    "username": "admin",
    "password": "admin123",
    "database": "yvcbyszjhu_gconnexDB",
    "host": "postgres-main.postgresql.svc.cluster.local",
    "port": 5432,
    "dialect": "postgres"
  }
}
EOF'
kubectl exec -it deployment/g-connex-api -n g-connex -- sh -c "cd /app && npx sequelize-cli db:migrate --migrations-path src/migrations --config config/config.json --env production"
kubectl exec -it deployment/g-connex-api -n g-connex -- sh -c "cd /app && npx sequelize-cli db:migrate:undo --migrations-path src/migrations --config config/config.json --env production"
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d yvcbyszjhu_gconnexDB -c "
CREATE TABLE IF NOT EXISTS \"SequelizeMeta\" (name VARCHAR(255) NOT NULL UNIQUE);
INSERT INTO \"SequelizeMeta\" (name) VALUES
('0001-create-utilisateurs.js'),
('0002-create-profiles.js'),
('0003-create-products-formations.js'),
('0004-create-produit-categories.js'),
('0005-create-abonnements.js'),
('0006-create-community-posts.js'),
('0007-create-community-comments.js'),
('0008-create-community-likes.js'),
('0009-create-transactions.js'),
('0010-create-transaction-products.js'),
('0011-create-soldes.js'),
('0012-create-info-paiement-vendeurs.js'),
('0013-create-retraits.js'),
('0014-create-frais-retrait.js'),
('0015-create-journaux-solde.js'),
('0016-create-litiges-transactions.js'),
('0017-create-services-agrobanking.js'),
('0018-create-supports.js'),
('20251223210230-create-retraits.js'),
('20260503161433-add-statut-commande-to-transactions.js'),
('20260505195805-add-en-attente-paiement-to-statut-commande.js'),
('20260515200943-migrer-mots-de-passe.js')
ON CONFLICT DO NOTHING;
"
kubectl exec -it deployment/g-connex-api -n g-connex -- sh -c "cd /app && npx sequelize-cli db:migrate --migrations-path src/migrations --config config/config.json --env production"
kubectl exec -it deployment/jenkins -n jenkins -- bash
clear
sudo su
kubectl get pods -n g-connex
kubectl logs g-connex-59cdb9b6b-76lp8 -n g-connex
df -h
sudo du -sh /var/lib/rancher/k3s/* 2>/dev/null | sort -rh | head -20
sudo du -sh /var/lib/docker/* 2>/dev/null | sort -rh | head -10
sudo k3s crictl images | sort -k4 -rh
sudo k3s crictl images --no-trunc | grep '<none>'
kubectl get deployment -n geyris -o jsonpath='{.items[*].spec.template.spec.containers[*].image}'
sudo k3s crictl images | grep 'geyris-api' | awk '{print $2, $3}' | grep -v '^\s*154 ' | awk '{print $2}' | sort -u | xargs -r sudo k3s crictl rmi
sudo k3s crictl images | grep 'geyris-front' | awk '{print $2, $3}' | grep -v '^\s*26 ' | awk '{print $2}' | sort -u | xargs -r sudo k3s crictl rmi
sudo k3s crictl images | grep 'g-connex-api' | awk '{print $2, $3}' | grep -v '34-06a5187' | awk '{print $2}' | sort -u | xargs -r sudo k3s crictl rmi
sudo k3s crictl images | grep 'g-connex' | grep '<none>' | awk '{print $3}' | xargs -r sudo k3s crictl rmi
sudo k3s crictl images | grep 'geyris-api' | awk '{print $2, $3}' | grep -v '^\s*154 ' | awk '{print $2}' | sort -u | while read id; do   echo "Suppression de $id...";   sudo k3s crictl rmi "$id";   sleep 1; done
sudo k3s crictl images | grep 'geyris-api'
df -h /
sudo k3s crictl rmi --prune
df -h
kubectl get pods -n g-connex
kubectl get pods -n geyris
kubectl get pods -n mfl
kubectl get pods -n pdl
kubectl get pods -n g-connex
kubectl get deployment g-connex -n g-connex -o jsonpath='{.spec.template.spec.containers[*].imagePullPolicy}'
kubectl get pods -n g-connex -o jsonpath='{.items[*].spec.containers[*].image}'
sudo k3s crictl inspect $(sudo k3s crictl ps | grep g-connex | grep -v frontend | grep -v api | awk '{print $1}' | head -1) | grep -i 'createdAt\|image'
sudo k3s crictl inspecti 141.95.29.23:30500/g-connex:latest | grep -i 'repoDigest\|id'
kubectl describe deployment g-connex -n g-connex | tail -20
curl -s http://141.95.29.23:30500/v2/g-connex/manifests/latest   -H "Accept: application/vnd.docker.distribution.manifest.v2+json"   | python3 -m json.tool | grep -i 'digest\|schemaVersion' | head -5
sudo k3s crictl rmi 141.95.29.23:30500/g-connex:latest
kubectl rollout restart deployment/g-connex -n g-connex
kubectl rollout status deployment/g-connex -n g-connex
sudo k3s crictl inspecti 141.95.29.23:30500/g-connex:latest | grep '"id"'
sudo find /var/lib/jenkins/jobs -name "log" -path "*/lastBuild/*" | xargs grep -l "g-connex" 2>/dev/null | head -5
kubectl get pods -n jenkins
kubectl get pods -n registry
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- bash -c "cat /var/jenkins_home/jobs/*/builds/lastBuild/log 2>/dev/null | tail -50"
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- docker ps 2>&1 | head -5
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- curl -s http://141.95.29.23:30500/v2/_catalog
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- ls /var/jenkins_home/jobs/
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- bash -c "ls /var/jenkins_home/jobs/G-Connex/builds/ 2>/dev/null || ls /var/jenkins_home/jobs/g-connex/builds/ 2>/dev/null"
kubectl get svc -n jenkins
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- bash -c "cat /var/jenkins_home/jobs/g-connex/builds/17/log"
kubectl exec -n g-connex $(kubectl get pods -n g-connex | grep '^g-connex-' | grep -v 'api\|frontend\|postgres\|chatbot' | awk '{print $1}' | head -1) -- ls /usr/share/nginx/html/assets/
kubectl get pods -n g-connex
kubect get svc -n g-connex
kubectl get svc -n g-connex
kubectl exec -n g-connex g-connex-f477fcf46-7w28s -- ls /usr/share/nginx/html/assets/
cd /etc/nginx/sites-available/
ls
cat g-connex 
curl -s https://g-connex.com/auth | grep -o 'assets/index[^"]*'
curl -s http://127.0.0.1:30090/auth | grep -o 'assets/index[^"]*'
kubectl get endpoints g-connex-service -n g-connex
kubectl get svc g-connex-service -n g-connex -o yaml | grep -A5 'selector'
kubectl get pods -n g-connex -l app=g-connex --show-labels
kubectl label pod g-connex-frontend-56574475db-8vfts -n g-connex app=g-connex-frontend-old --overwrite
kubectl get endpoints g-connex-service -n g-connex
curl -s http://127.0.0.1:30090/auth | grep -o 'assets/index[^"]*'
kubectl get deployment g-connex-frontend -n g-connex -o yaml | grep -A5 'selector\|labels'
kubectl get pods -n g-connex -o wide | grep -E '10.42.0.206|10.42.0.207|10.42.0.208'
kubectl delete deployment g-connex-frontend -n g-connex
kubectl get endpoints g-connex-service -n g-connex
curl -s http://127.0.0.1:30090/auth | grep -o 'assets/index[^"]*'
kubectl get deployments -A | grep -v 'Running\|kube-system\|cert-manager'
kubectl get pods -n kampfield
kubectl describe deployment kampfield-api -n kampfield | tail -20
cd
ls
cd g-connex/
ls
rm deployment.yaml 
kubectl get pods -n g-connex
kubectl get deployement -n g-connex
kubectl get deployment -n g-connex
kubectl get deployment g-connex-frontend -n g-connex
kubectl delete deployment g-connex-frontend -n g-connex
kubectl delete pod g-connex-frontend-56574475db-8vfts -n g-connex
kubectl get endpoints g-connex-service -n g-connex
curl -s http://127.0.0.1:30090/auth | grep -o 'assets/index[^"]*'
kubectl get pods -n g-connex
kubectl get deployment g-connex-api -n g-connex -o jsonpath='{.spec.template.spec.containers[*].image}'
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- bash -c "ls /var/jenkins_home/jobs/api_g-connex/builds/ 2>/dev/null || ls /var/jenkins_home/jobs/g-connex-api/builds/ 2>/dev/null"
# Voir le tag actuel qui tourne
kubectl get pods -n g-connex -l app=g-connex-api -o jsonpath='{.items[0].spec.containers[0].image}'
kubectl get pods -n g-connex -o wide --show-labels | grep api
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- bash -c "cat /var/jenkins_home/jobs/api_g-connex/builds/34/log | tail -30"
kubectl exec -n jenkins jenkins-547d95df9c-qdl26 -- bash -c "cd /var/jenkins_home/workspace/api_g-connex && git log --oneline -5"
ls
cat rbac-jenkins.yaml 
cat > ~/rbac-jenkins.yaml << 'EOF'
# ─────────────────────────────────────────────────────────────
# rbac-jenkins.yaml
# ─────────────────────────────────────────────────────────────

---
# 1. Droit de lire/créer les namespaces (scope cluster)
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: jenkins-namespace-role
rules:
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: jenkins-namespace-binding
subjects:
  - kind: ServiceAccount
    name: jenkins-sa
    namespace: jenkins
roleRef:
  kind: ClusterRole
  name: jenkins-namespace-role
  apiGroup: rbac.authorization.k8s.io

---
# 2. Droits complets sur le namespace mfl
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: mfl
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "pods", "pods/exec", "pods/log"]
    verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-binding
  namespace: mfl
subjects:
  - kind: ServiceAccount
    name: jenkins-sa
    namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-deploy-role
  apiGroup: rbac.authorization.k8s.io

---
# 3. Droits complets sur le namespace g-connex
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: g-connex
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "pods", "pods/exec", "pods/log"]
    verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-binding
  namespace: g-connex
subjects:
  - kind: ServiceAccount
    name: jenkins-sa
    namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-deploy-role
  apiGroup: rbac.authorization.k8s.io

---
# 4. Droits complets sur le namespace geyris
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: geyris
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "pods", "pods/exec", "pods/log"]
    verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-binding
  namespace: geyris
subjects:
  - kind: ServiceAccount
    name: jenkins-sa
    namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-deploy-role
  apiGroup: rbac.authorization.k8s.io

---
# 5. Droits complets sur le namespace pdl
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-deploy-role
  namespace: pdl
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["services", "pods", "pods/exec", "pods/log"]
    verbs: ["get", "list", "create", "update", "patch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-deploy-binding
  namespace: pdl
subjects:
  - kind: ServiceAccount
    name: jenkins-sa
    namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-deploy-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f ~/rbac-jenkins.yaml
kubectl exec -n g-connex g-connex-api-5548bd5c95-bbm85 -- cat /app/.sequelizerc
kubectl get pods -n g-connex
kubectl exec -n g-connex g-connex-api-64d69dfff4-4jmzn -- ./node_modules/.bin/sequelize db:migrate
kubectl exec -it -n g-connex g-connex-api-64d69dfff4-4jmzn -- ./node_modules/.bin/sequelize db:migrate
kubectl exec -n g-connex g-connex-api-64d69dfff4-4jmzn -- find /app -name "sequelize" -type f 2>/dev/null
kubectl exec -n g-connex g-connex-api-64d69dfff4-4jmzn -- ls /app
kubectl exec -n g-connex g-connex-api-64d69dfff4-4jmzn -- cat /app/package.json | grep -A5 sequelize
kubectl exec -n g-connex g-connex-api-64d69dfff4-4jmzn -- npm run db:migrate
kubectl exec -n g-connex g-connex-api-54f75686d5-hpvf8 -- cat /app/sequelize.config.js
kubectl get pods -n g-connex
kubectl exec -n g-connex g-connex-api-58cb55fd8c-dbxlw -- cat /app/sequelize.config.js
kubectl get pods -n g-connex
kubectl exec -n g-connex g-connex-api-6cc74d5b7c-285q4 -- sh -c 'NODE_ENV=development ./node_modules/.bin/sequelize db:migrate --migrations-path dist/migrations'
kubectl exec -n g-connex g-connex-api-6cc74d5b7c-285q4 -- ls /app/dist
history
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d yvcbyszjhu_gconnexDB -c '\dt'
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d yvcbyszjhu_gconnexDB -c 'SELECT * FROM utilisateurs LIMIT 10;'
ls
cat rbac-jenkins.yaml 
ls
cat rbac-jenkins.yaml 
kubectl get pods -n pdl
kubectl logs -n pdl pdl-backend-55df74d7d5-gq6ck
kubectl get pods -n pdl
kubectl logs -n pdl pdl-backend-854bf69d87-9vqp5
kubectl get deployment pdl-backend -n pdl -o yaml
kubectl get secret pdl-backend-secret -n pdl
kubectl describe secret pdl-backend-secret -n pdl
kubectl get secret pdl-backend-secret -n pdl -o yaml
kubectl get pods -n pdl
kubectl create secret generic pdl-backend-secret   -n pdl   --from-literal=DATABASE_URL='...'   --from-literal=JWT_SECRET='...'   --from-literal=JWT_REFRESH_SECRET='81645e2f6fb707c5d18d9699cc741d2a13b84927c9f084760683ef49d4787201400b94abd2942ab1588f55ab96466f00'   --from-literal=JWT_EXPIRES_IN='...'   --from-literal=NODE_ENV='production'   --from-literal=PORT='5000'   --from-literal=FRONTEND_URL='...'   --from-literal=CORS_ORIGINS='...'   --from-literal=REFRESH_TOKEN_EXPIRES_HOURS='...'   --from-literal=RESET_PASSWORD_TOKEN_EXPIRES_MINUTES='...'   --from-literal=CLOUDINARY_CLOUD_NAME='dnyczeaq3'   --from-literal=CLOUDINARY_API_KEY='455791186726267'   --from-literal=CLOUDINARY_API_SECRET='0VV2IY_5zgOQ1UbvtuBy3PUWJFE'
kubectl delete secret pdl-backend-secret -n pdl
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: pdl-backend-secret
  namespace: pdl
type: Opaque
stringData:
  CORS_ORIGINS: "http://141.95.29.23:30088"
  DATABASE_URL: "postgresql://pdluser:pdlpass2026@postgres-main.postgresql.svc.cluster.local:5432/pdl"
  FRONTEND_URL: "http://141.95.29.23:30088"

  JWT_SECRET: "CHANGE_ME_WITH_LONG_SECRET"
  JWT_REFRESH_SECRET: "81645e2f6fb707c5d18d9699cc741d2a13b84927c9f084760683ef49d4787201400b94abd2942ab1588f55ab96466f00"

  JWT_EXPIRES_IN: "1h"
  NODE_ENV: "production"
  PORT: "5000"

  REFRESH_TOKEN_EXPIRES_HOURS: "168"
  RESET_PASSWORD_TOKEN_EXPIRES_MINUTES: "60"

  CLOUDINARY_CLOUD_NAME: "dnyczeaq3"
  CLOUDINARY_API_KEY: "455791186726267"
  CLOUDINARY_API_SECRET: "0VV2IY_5zgOQ1UbvtuBy3PUWJFE"
  CLOUDINARY_URL: "cloudinary://455791186726267:0VV2IY_5zgOQ1UbvtuBy3PUWJFE@dnyczeaq3"
EOF

kubectl rollout restart deployment pdl-backend -n pdl
kubectl get pods -n pdl -w
kubectl logs -n pdl pod/pdl-backend-786d959dd4-fjbfj
kubectl get secret pdl-backend-secret -n pdl -o jsonpath="{.data.JWT_SECRET}" | base64 -d
echo
kubectl patch secret pdl-backend-secret -n pdl   -p '{"stringData":{"JWT_SECRET":"c35eea28071511a05c0453068152f5bcfc626a66917c5bd9e06e6faa82f46fa6a1344d80dc86bce18f8e3f7ee12af8cc"}}'
kubectl rollout restart deployment pdl-backend -n pdl
kubectl get pods -n pdl -w
kubectl logs -n pdl pod/pdl-backend-6f99558d77-td52w --previous
kubectl get pods -n pdl
kubectl logs -n pdl deploy/pdl-backend
ls
history
sudo su
cd ~/.ssh/
ls
nano authorized_keys 
sudo systemctl restart ssh
sudo nano /etc/ssh/sshd_config
sudo iptables -L -n -v
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -L | head
devops@vps-3c312592:~/.ssh$ sudo iptables -L | head
Chain INPUT (policy ACCEPT)
target     prot opt source               destination         
KUBE-ROUTER-INPUT  all  --  anywhere             anywhere             /* kube-router netpol - 4IA2OSFRMVNDXBVV */
KUBE-PROXY-FIREWALL  all  --  anywhere             anywhere             ctstate NEW /* kubernetes load balancer firewall */
KUBE-NODEPORTS  all  --  anywhere             anywhere             /* kubernetes health check service ports */
KUBE-EXTERNAL-SERVICES  all  --  anywhere             anywhere             ctstate NEW /* kubernetes externally-visible service portals */
KUBE-FIREWALL  all  --  anywhere             anywhere            
ACCEPT     all  --  anywhere             anywhere             /* KUBE-ROUTER rule to explicitly ACCEPT traffic that comply to network policies */ mark match 0x20000/0x20000
ACCEPT     tcp  --  anywhere             anywhere             tcp dpt:ssh
devops@vps-3c312592:~/.ssh$ 
sudo systemctl status fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip 92.118.39.62
sudo fail2ban-client set sshd unbanip 102.68.192.229
sudo fail2ban-client set sshd unbanip 2.57.122.177
sudo fail2ban-client set sshd unbanip 45.156.87.34
sudo fail2ban-client set sshd unbanip 2.57.121.25
sudo fail2ban-client status sshd
ls
kubectl get pods -n pdl
kubectl logs pdl-backend-6bb8df6fdf-496q9 -n pdl
ls /etc/nginx/sites-available/
cat /etc/nginx/sites-available/pdl 
ls
sudo certbot --nginx -d api.pdl.padnove.com
kubectl get pods -n pdl
kubectl logs -n pdl deploy/pdl-backend --tail=200
kubectl exec -it -n pdl deploy/pdl-backend -- printenv | grep DATABASE_URL
kubectl get pods -A | grep postgres
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- psql -U admin
history
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
kubectl exec -it -n pdl deploy/pdl-backend -- npx prisma db seed
kubectl exec -it -n pdl deploy/pdl-backend -- ls prisma
kubectl exec -it -n pdl deploy/pdl-backend -- npm ls bcrypt
kubectl exec -it -n pdl deploy/pdl-backend -- npm ls tsx
kubectl exec -it -n pdl deploy/pdl-backend -- npm ls ts-node
kubectl exec -it -n pdl deploy/pdl-backend -- sh
kubectl get pods -n pdl
kubectl logs pdl-backend-7dd5b96d94-xdkpw -n pdl
kubectl get pods -n pdl
kubectl logs pdl-backend-97f4b667d-kwc62 -n pdl
kubectl get pods -n pdl
kubectl logs pdl-backend-97f4b667d-kwc62 -n pdl
kubectl logs pdl-backend-97f4b667d-kwc62 -n pdl --previous
kubectl describe pod pdl-backend-97f4b667d-kwc62 -n pdl
kubectl get pods -n pdl
kubectl logs pdl-backend-66cb49bbd7-pl22t -n pdl
kubectl get pods -n pdl
kubectl logs pdl-backend-7b56798788-w5qz2 -n pdl --tail=100
kubectl logs pdl-backend-7b56798788-w5qz2 -n pdl -p   # logs du précédent conteneur
kubectl describe pod pdl-backend-7b56798788-w5qz2 -n pdl
kubectl logs pdl-backend-7b56798788-w5qz2 -n pdl --tail=200
kubectl logs pdl-backend-7b56798788-w5qz2 -n pdl -p --tail=200
kubectl describe pod pdl-backend-7b56798788-w5qz2 -n pdl
kubectl edit deployment pdl-backend -n pdl
kubectl get pods -n pdl
kubectl logs pdl-backend-7b56798788-w5qz2 -n pdl --previous
kubectl get pods -n pdl -l app=pdl-backend
kubectl logs -f <nom-du-nouveau-pod> -n pdl
kubectl get pods -n pdl -l app=pdl-backend
kubectl logs -f pdl-backend-6ff89468d6-wm87c -n pdl
# Logs actuels (le plus important)
kubectl logs -f pdl-backend-6ff89468d6-wm87c -n pdl
# Si rien n'apparaît, essaie les logs du précédent conteneur
kubectl logs pdl-backend-6ff89468d6-wm87c -n pdl -p
kubectl get pods -n pdl -l app=pdl-backend
kubectl exec -n pdl deployment/pdl-backend -- ls -la /app/dist
kubectl exec -n pdl deployment/pdl-backend -- ls -la /app/dist/prisma 2>/dev/null || echo "Dossier prisma inexistant dans dist"
kubectl exec -n pdl deployment/pdl-backend -- npx prisma migrate deploy
kubectl exec -n pdl deployment/pdl-backend -- npx prisma db pull --print
kubectl exec -n pdl deployment/pdl-backend -- npx prisma migrate deploy
kubectl exec -n pdl deployment/pdl-backend -- npx prisma db pull --print
kubectl exec -n pdl deployment/pdl-backend -- cat prisma/schema.prisma | grep -A 60 "model User"
MIGRATION_NAME="$(date +%Y%m%d%H%M%S)_add_banni_column"
kubectl exec -n pdl deployment/pdl-backend -- sh -c "
  mkdir -p prisma/migrations/${MIGRATION_NAME} && \
  cat > prisma/migrations/${MIGRATION_NAME}/migration.sql << 'EOF'
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"banni\" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"raisonSuspension\" TEXT;
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"dateSuspensionFin\" TIMESTAMP(3);
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"raisonBannissement\" TEXT;
EOF
"
kubectl exec -n pdl deployment/pdl-backend -- npx prisma migrate deploy
kubectl logs -n pdl deployment/pdl-backend --tail=50
exit
nslookup smtp.gmail.com
find /app -type f | xargs grep -n "createTransport" 2>/dev/null
nslookup mail.panove.com
nc -vz smtp.gmail.com 587
nslookup smtp.gmail.com
find /app -type f | xargs grep -n "createTransport" 2>/dev/null
find . -type f | xargs grep -n "nodemailer" 2>/dev/null
kubectl exec -it pdl-backend-5d854dd7b5-k8g2x -n pdl -- env | grep SMTP_USER
env | grep SMTP
nslookup mail.panove.com
nslookup smtp.gmail.com
nc -vz smtp.gmail.com 465
nc -vz smtp.gmail.com 587
ls
cd pdl
ls
cat rbac.yaml 
kubectl get pods -n pdl
kubectl get deployments -n pdl
kubectl get svc -n pdl
kubectl exec -it <pod> -n pdl -- env | grep -i mail
kubectl exec -it <pod> -n pdl -- env | grep -i smtp
kubectl get secrets -n pdl
kubectl describe secret <nom-secret> -n pdl
kubectl get secret <nom-secret> -n pdl -o yaml
kubectl exec -it <pod> -n pdl -- sh
nc -vz smtp.gmail.com 587
telnet smtp.gmail.com 587
kubectl get pods -n pdl
kubectl exec -it pdl-backend-6b4447b799-4n64g -n pdl -- env | grep -i smtp
kubectl exec -it pdl-backend-6b4447b799-4n64g -n pdl -- env | grep -Ei "mail|smtp"
kubectl get secrets -n pdl
pdl-backend-secret
kubectl get secret pdl-backend-secret -n pdl -o jsonpath='{.data}' | jq
kubectl describe secret pdl-backend-secret -n pdl
kubectl get secret pdl-backend-secret -n pdl -o yaml
kubectl logs deployment/pdl-backend -n pdl --tail=200
kubectl logs pdl-backend-6b4447b799-4n64g -n pdl --tail=200
kubectl exec -it pdl-backend-6b4447b799-4n64g -n pdl -- sh
nc -vz smtp.gmail.com 587
nc -vz mail.panove.com 465
openssl s_client -connect mail.panove.com:465
kubectl get pods -n pdl
kubectl exec -it pdl-backend-6b4447b799-7tnht -n pdl -- sh
nc -vz mail.panove.com 465
wget -qO- https://google.com
kubectl logs -f deployment/pdl-backend -n pdl
openssl s_client -connect mail.panove.com:465
nslookup mail.panove.com
nslookup panove.com
nslookup pdl.panove.com
dig MX panove.com
host panove.com
host pdl.panove.com
dig MX panove.com +short
kubectl exec -it pdl-backend-5d854dd7b5-k8g2x -n pdl -- sh
kubectl edit secret pdl-backend-secret -n pdl
kubectl get secret pdl-backend-secret -n pdl -o yaml
kubectl get secret pdl-backend-secret -n pdl -o yaml | grep panove
kubectl get secret pdl-backend-secret -n pdl -o yaml | grep padnove
kubectl exec -it <pod> -n pdl -- env | grep SMTP
kubectl exec -it <pod> -n pdl -- env | grep panove
grep -R "panove" .
grep -R "SMTP_HOST" .
grep -R "mail.panove" .
kubectl describe pod pdl-backend-xxxxx -n pdl | grep Image
kubectl get secret pdl-backend-secret -n pdl -o yaml
cat /etc/hosts
kubectl get ingress -A
kubectl exec -n postgresql deployment/postgres-main -- psql -U postgres -d pdl -c "
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"banni\" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"raisonSuspension\" TEXT;
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"dateSuspensionFin\" TIMESTAMP(3);
ALTER TABLE \"User\" ADD COLUMN IF NOT EXISTS \"raisonBannissement\" TEXT;
"
history
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- psql -U admin
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
kubectl rollout restart deployment/pdl-backend -n pdl
kubectl get pods -n pdl -l app=pdl-backend
kubectl logs -n pdl deployment/pdl-backend --tail=30
kubectl get secret -n pdl pdl-backend-secret -o yaml
kubectl patch secret pdl-backend-secret -n pdl --type='json' -p='[
  {"op":"add","path":"/data/SMTP_HOST","value":"'$(echo -n "mail.panove.com" | base64)'"},
  {"op":"add","path":"/data/SMTP_PORT","value":"'$(echo -n "465" | base64)'"},
  {"op":"add","path":"/data/SMTP_USER","value":"'$(echo -n "support@pdl.panove.com" | base64)'"},
  {"op":"add","path":"/data/SMTP_PASSWORD","value":"'$(echo -n "fR[=5vR[Tw" | base64)'"},
  {"op":"add","path":"/data/SMTP_SECURE","value":"'$(echo -n "true" | base64)'"}
]'
kubectl rollout restart deployment/pdl-backend -n pdl
kubectl get pods -n pdl -l app=pdl-backend
kubectl get secret
kubectl get secret -n g-connex
kubectl get secret g-connex-api-secret -n g-connex -o yaml
kubectl get secret g-connex-api-secret -n g-connex -o json | jq -r '.data | to_entries[] | "\(.key)=\(.value)"' | while IFS="=" read -r key value; do     echo "$key=$(echo $value | base64 -d)";   done
ls
kubectl get pods -n g-connex
kubectl get deployment g-connex -n g-connex -o yaml
kubectl exec -it g-connex-57b765797c-lkcz5 -n g-connex -- sh
kubectl get pods -n pdl
kubectl get deployment pdl-backend -n pdl -o yaml
kubectl exec -it pdl-backend-5d854dd7b5-k8g2x -n pdl -- sh
kubectl get secret pdl-backend-secret -n pdl -o yaml
kubectl create secret generic pdl-backend-secret -n pdl --from-literal=SMTP_HOST=node224-eu.n0c.com --from-literal=SMTP_USER=support@pdl.padnove.com --from-literal=SMTP_PORT=465 --from-literal=SMTP_SECURE=true -o yaml --dry-run=client | kubectl apply -f -
kubectl exec -it pdl-backend-5d854dd7b5-k8g2x -n pdl -- printenv | grep SMTP
kubectl get pods -n pdl
kubectl exec -it pdl-backend-764cdbfc44-h8tz7 -n pdl -- printenv | grep SMTP
kubectl exec -it pdl-backend-764cdbfc44-qdkxj -n pdl -- printenv | grep SMTP
kubectl get secret pdl-backend-secret -n pdl -o yaml
kubectl exec -it pdl-backend-764cdbfc44-h8tz7 -n pdl -- printenv | grep SMTP
kubectl get pods -n pdl
kubectl exec -it pdl-backend-5845cbd7c7-52gtr -n pdl -- printenv | grep SMTP
clear
ls
kubectl get pods -n g-connex
kubectl get pods -n geyris
kubectl get svc -n g-connex
kubectl get svc -n geyris
kubectl get ingress -n g-connex
kubectl get ingress -n geyris
kubectl get pods,svc,ingress -n g-connex && kubectl get pods,svc,ingress -n geyris
# État du nginx
sudo systemctl status nginx
# Vérifier les domaines qui répondent
curl -I http://localhost:30090   # g-connex front
curl -I http://localhost:31285   # g-connex api
curl -I http://localhost:30800   # geyris api
curl -I http://localhost:30081   # geyris front
# G-connex API — tester un endpoint connu
curl -I http://localhost:31285/api/health
curl -I http://localhost:31285/api
# Geyris API — tester un endpoint connu
curl -I http://localhost:30800/api/health
curl -I http://localhost:30800/api/
# Vérifier aussi les logs récents des APIs
kubectl logs -n g-connex deployment/g-connex-api --tail=20
kubectl logs -n geyris deployment/geyris-api --tail=20
exit
sudo certbot --nginx -d app.geyris.com 
sudo certbot --nginx -d www.app.geyris.com 
sudo su
sudo certbot --nginx -d www.app.geyris.com 
sudo certbot --nginx -d www.app.geyris.com -d app.geyris.com 
lecho "========== CPU & RAM ==========" && free -h && echo "" && top -bn1 | grep "Cpu(s)" && echo "" && echo "========== STOCKAGE DISQUE ==========" && df -h && echo "" && echo "========== UTILISATION PAR DOSSIER (home) ==========" && du -sh ~/* 2>/dev/null && echo "" && echo "========== CHARGE SERVEUR ==========" && uptime && echo "" && echo "========== MEMOIRE SWAP ==========" && swapon --show && echo "" && echo "========== PODS CPU/RAM - G-CONNEX ==========" && kubectl top pods -n g-connex 2>/dev/null && echo "" && echo "========== PODS CPU/RAM - GEYRIS ==========" && kubectl top pods -n geyris 2>/dev/null && echo "" && echo "========== NOEUDS K3S ==========" && kubectl top nodes 2>/dev/null && echo "" && echo "========== PROCESSUS LES PLUS LOURDS ==========" && ps aux --sort=-%mem | head -10 && echo "" && echo "========== ESPACE DOCKER/REGISTRY ==========" && docker system df 2>/dev/null || echo "Docker non accessible" && echo "========== FIN DU RAPPORT =========="
echo "========== CPU & RAM ==========" && free -h && echo "" && top -bn1 | grep "Cpu(s)" && echo "" && echo "========== STOCKAGE DISQUE ==========" && df -h && echo "" && echo "========== UTILISATION PAR DOSSIER (home) ==========" && du -sh ~/* 2>/dev/null && echo "" && echo "========== CHARGE SERVEUR ==========" && uptime && echo "" && echo "========== MEMOIRE SWAP ==========" && swapon --show && echo "" && echo "========== PODS CPU/RAM - G-CONNEX ==========" && kubectl top pods -n g-connex 2>/dev/null && echo "" && echo "========== PODS CPU/RAM - GEYRIS ==========" && kubectl top pods -n geyris 2>/dev/null && echo "" && echo "========== NOEUDS K3S ==========" && kubectl top nodes 2>/dev/null && echo "" && echo "========== PROCESSUS LES PLUS LOURDS ==========" && ps aux --sort=-%mem | head -10 && echo "" && echo "========== KAMPFIELD ==========" && kubectl get pods,svc -n kampfield && echo "" && echo "========== FIN DU RAPPORT =========="
# État des pods kampfield
kubectl get pods -n kampfield
# Services et ports
kubectl get svc -n kampfield
# Logs récents
kubectl logs -n kampfield deployment/kampfield --tail=30 2>/dev/null || kubectl logs -n kampfield $(kubectl get pods -n kampfield -o name | head -1) --tail=30
# Test direct du port
kubectl get svc -n kampfield -o wide
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
kubectl get pods -A | grep ingress
kubectl get svc -A | grep ingress
monitoring-grafana-c5784c798-t7vxs 0/3 ContainerCreating
kubectl get pods -n monitoring
kubectl describe pod monitoring-grafana-c5784c798-t7vxs -n monitoring
kubectl logs monitoring-grafana-c5784c798-t7vxs -n monitoring
helm install postgres-exporter prometheus-community/prometheus-postgres-exporter -n monitoring
kubectl get deploy -A | grep postgres
kubectl get secrets -A | grep postgres
kubectl exec -it -n g-connex postgres-5b5877698b-zmn48 -- env | grep -i POSTGRES
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- env | grep -i POSTGRES
kubectl get namespaces
kubectl get pods -n kampfield
kubectl logs kampfield-api-7d9f5ddbb-54ttc -n kampfiels
kubectl logs kampfield-api-7d9f5ddbb-54ttc -n kampfield
df -h
ls
kubectl get pods -n monitoring
# doit retourner : "No resources found"
kubectl get ns | grep monitoring
# doit retourner : rien
# Supprimer les releases Helm
helm uninstall monitoring -n monitoring
helm uninstall loki -n monitoring
helm uninstall postgres-exporter -n monitoring
helm uninstall blackbox-exporter -n monitoring
# Supprimer le namespace monitoring
kubectl delete namespace monitoring
cd /etc/nginx/sites-enabled/grafana
cd /etc/nginx/sites-enabled/
ls
sudo rm -rf grafana 
cd /etc/nginx/sites-available
ls
sudo rm -rf grafana 
helm upgrade postgres-exporter   prometheus-community/prometheus-postgres-exporter   -n monitoring   --set config.datasource.host=10.43.119.222   --set config.datasource.user=admin   --set config.datasource.password=admin123   --set config.datasource.database=postgres   --set config.datasource.sslmode=disable
kubectl logs -n monitoring   $(kubectl get pods -n monitoring -l app.kubernetes.io/name=prometheus-postgres-exporter \
  -o jsonpath='{.items[0].metadata.name}')
cat /etc/nginx/sites-available/grafana
sudo nano /etc/nginx/sites-available/grafana
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
ls
kubectl get pods
kubectl get pods -A
kubectl get nodes -o wide
kubectl get ns
kubectl get ingress -A
kubectl get pvc -A
kubectl get storageclass
kubectl top nodes
kubectl top pods -A
kubectl top nodes
helm version
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack -n monitoring
kubectl get pods -n monitoring
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install loki grafana/loki-stack -n monitoring
g-connex/postgres
helm install postgres-exporter prometheus-community/prometheus-postgres-exporter -n monitoring
api.g-connex.com
g-connex.com
geyris.com
api.geyris.com
helm install blackbox-exporter prometheus-community/prometheus-blackbox-exporter -n monitoring
kubectl get secret -n monitoring monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
helm install postgres-exporter   prometheus-community/prometheus-postgres-exporter   -n monitoring   --set config.datasource.host=10.43.119.222   --set config.datasource.user=admin   --set config.datasource.password=admin123   --set config.datasource.database=postgres   --set config.datasource.sslmode=disable
psql -U admin -d postgress
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
helm install postgres-exporter   prometheus-community/prometheus-postgres-exporter   -n monitoring   --set config.datasource.host=10.43.119.222   --set config.datasource.user=admin   --set config.datasource.password=admin123   --set config.datasource.database=postgres   --set config.datasource.sslmode=disable
kubectl get pods -n monitoring | grep postgres
kubectl get secret -n monitoring monitoring-grafana   -o jsonpath="{.data.admin-password}" | base64 -d; echo
kubectl get svc -n monitoring monitoring-grafana
kubectl port-forward svc/monitoring-grafana 3000:80 -n monitoring
history
df -l
sudo du -h --max-depth=1 / | sort -hr
docker system df
docker system prune -a -f
df -h
docker system prune -a -f
df -h
docker volume prune -f
sudo crictl images
sudo du -sh /var/lib/containerd
sudo crictl rmi --prune
sudo du -sh /var/log/*
sudo journalctl --disk-usage
sudo du -sh /var/lib/kubelet
sudo du -xh /var/lib/kubelet --max-depth=2 2>/dev/null | sort -hr | head -50
sudo du -xh /var/lib/kubelet/pods --max-depth=3 2>/dev/null | sort -hr | head -50
kubectl get pod -A --field-selector metadata.uid=15f034bc-10ea-4a14-8da8-7cd7814acf27
sudo grep -R "15f034bc-10ea-4a14-8da8-7cd7814acf27" /var/lib/kubelet/pods/*/etc-hosts 2>/dev/null
kubectl get pods -A -o wide
sudo ls -lah /var/lib/kubelet/pods/15f034bc-10ea-4a14-8da8-7cd7814acf27/volumes/kubernetes.io~empty-dir
sudo du -xh /var/lib/kubelet/pods/15f034bc-10ea-4a14-8da8-7cd7814acf27/volumes/kubernetes.io~empty-dir/* 2>/dev/null | sort -hr | head -20
sudo du -sh /var/lib/kubelet/pods/15f034bc-10ea-4a14-8da8-7cd7814acf27/volumes/kubernetes.io~empty-dir/registry-data/*
sudo su
ls
df -h
kubectl exec -it -n registry deploy/registry -- registry garbage-collect /etc/docker/registry/config.yml
kubectl exec -n registry deploy/registry -- du -sh /var/lib/registry/docker/registry/v2/blobs
kubectl exec -n registry deploy/registry -- du -sh /var/lib/registry/docker/registry/v2/blobs
df -h
sudo du -xh /var/lib/kubelet --max-depth=2 2>/dev/null | sort -hr | head -20
sudo du -sh /var/lib/kubelet/pods/15f034bc-10ea-4a14-8da8-7cd7814acf27/volumes/kubernetes.io~empty-dir/registry-data
kubectl get deployment -n registry registry -o yaml | grep -A20 volumes:
kubectl describe deployment registry -n registry
kubectl rollout restart deployment/registry -n registry
kubectl rollout status deployment/registry -n registry
kubectl get pods -n registry -o wide
sudo du -sh /var/lib/kubelet/pods/* | sort -hr | head
sudo du -sh /var/lib/kubelet/pods/15f034bc-10ea-4a14-8da8-7cd7814acf27/volumes/kubernetes.io~empty-dir/registry-data
df -h
ls
df -h
kubectl get pods -A
kubectl get namespaces
kubectl get deployment
kubectl get deployment -n monitoring
kubectl delete deployment monitoring-grafana -n monitoring
kubectl delete deployment monitoring-kube-prometheus-operator -n monitoring
kubectl delete deployment monitoring-kube-state-metrics -n monitoring
kubectl delete deployment postgres-exporter-prometheus-postgres-exporter -n monitoring
kubectl delete deployment blackbox-exporter-prometheus-blackbox-exporter -n monitoring
kubectl delete namespace monitoring
kubectl get namespace
df -h
kubectl get svc -A
kubectl get secret -n kampfield
cat ~/kampfield/.env 2>/dev/null || ls ~/kampfield/
# Voir le contenu du dossier kampfield
ls -la ~/kampfield/
# Voir le deployment complet pour savoir quelles variables sont attendues
kubectl get deployment kampfield-api -n kampfield -o yaml
# Extraire le .env depuis l'image du registry
docker run --rm 141.95.29.23:30500/kampfield-api:latest cat .env 2>/dev/null || docker run --rm 141.95.29.23:30500/kampfield-api:latest env
ls
cd kampfield
cd 
# Voir si git est configuré dans le dossier kampfield
cd ~/kampfield && git remote -v
# Ou chercher dans les autres dossiers qui ont un .git
find ~/ -name ".git" -type d 2>/dev/null
# Chercher tous les .env sur le serveur
find /home -name ".env*" -type f 2>/dev/null
# Chercher JWT_SECRET partout
grep -r "JWT_SECRET" /home/ 2>/dev/null
grep -r "JWT_SECRET" /var/lib/rancher/k3s/ 2>/dev/null
# Chercher dans les volumes k3s (là où kubernetes stocke les données)
find /var/lib/rancher/k3s/storage/ -name "*.env*" 2>/dev/null
# Chercher EMAIL_USER aussi
grep -r "EMAIL_USER" /home/ 2>/dev/null
clear
cd 
ls
cd kampField
cd kampfield
ls
clear
cd
clear
ls
sudo systemctl status nginx
systemctl status nginx
cd kampfield && ls -la
sudo docker ps -a
docker ps -a
docker compose logs --tail=50 -f
ls -la /etc/nginx/sites-enabled/
cat /etc/nginx/sites-available/kampfield-api
pm2 status
ss -tunlp
tcp                LISTEN              0                   4096                                             *:11434                                        *:*                                                                            
tcp                LISTEN              0                   4096                                             *:10250                                        *:*                                                                            
tcp                LISTEN              0                   20                                           [::1]:25                                        [::]:*                                                                            
tcp                LISTEN              0                   4096                                         [::1]:3000                                      [::]:*                  users:(("kubectl",pid=3536322,fd=9))                      
tcp                LISTEN              0                   4096                                             *:9100                                         *:*                                                                            
tcp                LISTEN              0                   4096                                             *:6443                                         *:*                                                                            
tcp                LISTEN              0                   4096                                          [::]:5355                                      [::]:*                                                                            
tcp                LISTEN              0                   128                                           [::]:22                                        [::]:*                                                                            
devops@vps-3c312592:~/kampfield$ 
kubectl get pods,svc,deploy -A | grep -i kampfield
kubectl logs pod/kampfield-api-7d9f5ddbb-54ttc -n kampfield --tail=100
kubectl get deployment kampfield-api -n kampfield -o yaml > deployment-kampfield.yaml
cat deployment-kampfield.yaml | grep -A 20 -i env
kubectl get secrets -n kampfield
ls -la /etc/nginx/sites-available/
cat /etc/nginx/sites-available/default
ls
cat deployment-kampfield.yaml
ls
kubectl get all -n kampfield
exit
ls
kubectl get pods -n  kampfield 
cd kampfield/
ls
cat deployment-kampfield.yaml 
kubectl exec -it -n jenkins   $(kubectl get pods -n jenkins -o jsonpath='{.items[0].metadata.name}') -- bash
kubectl exec -it -n jenkins   $(kubectl get pods -n jenkins -o jsonpath='{.items[0].metadata.name}') -- bash
ls ~/.ssh/
cat ~/.ssh/id_rsa
# ou
cat ~/.ssh/id_ed25519
cat >> ~/rbac-jenkins.yaml << 'EOF'

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: jenkins-role
  namespace: kampfield
rules:
  - apiGroups: ["apps"]
    resources: ["deployments"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]
  - apiGroups: [""]
    resources: ["services", "pods"]
    verbs: ["get", "list", "create", "update", "patch", "delete"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: jenkins-rolebinding
  namespace: kampfield
subjects:
  - kind: ServiceAccount
    name: jenkins-sa
    namespace: jenkins
roleRef:
  kind: Role
  name: jenkins-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f ~/rbac-jenkins.yaml
kubectl get rolebinding -n kampfield
kubectl get pods -n kampfield
sudo nano /etc/nginx/sites-available/kampfield-frontend
sudo ln -s /etc/nginx/sites-available/kampfield-frontend /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx
sudo certbot --nginx -d kampfield.com -d www.kampfield.com
ls /etc/nginx/sites-available/
grep -rl "api.pdf.padnove.com" /etc/nginx/sites-available/
cat /etc/nginx/sites-available/api.pdf.padnove.com
cat /etc/nginx/sites-available/pdl
kubectl get svc -n pdl
sudo nano /etc/nginx/sites-available/pdl
sudo nginx -t && sudo systemctl reload nginx
cat /etc/nginx/sites-available/pdl
POD=$(kubectl get pods -n pdl -l app=pdl-backend -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"
kubectl exec -it $POD -n pdl -- find . -name "*.js" | xargs grep -l "multer\|fileupload\|bodyParser\|limit\|maxSize" 2>/dev/null
POD=$(kubectl get pods -n pdl -l app=pdl-backend -o jsonpath='{.items[0].metadata.name}')
echo "Pod: $POD"
# Chercher les limites d'upload dans le code
kubectl exec -it $POD -n pdl -- find . -name "*.js" | xargs grep -l "multer\|fileupload\|bodyParser\|limit\|maxSize" 2>/dev/null
# Multer
grep -r "limits\|fileSize" .
# body-parser / express
grep -r "limit.*mb\|limit.*kb\|bodyParser" .
POD=$(kubectl get pods -n pdl -l app=pdl-backend -o jsonpath='{.items[0].metadata.name}')
# Voir la structure du code dans le pod
kubectl exec -it $POD -n pdl -- find . -name "*.js" -not -path "*/node_modules/*" | head -20
# Chercher les limites d'upload dans le code applicatif uniquement
kubectl exec -it $POD -n pdl -- sh -c "grep -rl 'multer\|limit\|maxSize\|fileSize' . --include='*.js' --exclude-dir=node_modules"
# multer fileSize limit
kubectl exec -it $POD -n pdl -- sh -c "grep -r 'fileSize\|limits' . --include='*.js' --exclude-dir=node_modules"
# express body-parser limit
kubectl exec -it $POD -n pdl -- sh -c "grep -r 'bodyParser\|json.*limit\|urlencoded.*limit' . --include='*.js' --exclude-dir=node_modules"
grep -n "client_max_body_size\|proxy_read_timeout\|proxy_send_timeout" /etc/nginx/sites-available/pdl
grep -n "client_max_body_size" /etc/nginx/sites-available/pdl
sudo sed -i 's/client_max_body_size 100M/client_max_body_size 200M/' /etc/nginx/sites-available/pdl
# Vérifier
grep -n "client_max_body_size" /etc/nginx/sites-available/pdl
# Tester et recharger
sudo nginx -t && sudo systemctl reload nginx
grep -n "client_max_body_size" /etc/nginx/sites-available/pdl
ls
# Padnove - trouver le pod frontend
kubectl get pods -n pdl
kubectl exec -it <pdl-frontend-pod> -n pdl -- find . -name "index.html" | head -5
# G-Connex
kubectl get pods -n g-connex
kubectl exec -it <gconnex-frontend-pod> -n g-connex -- find . -name "index.html" | head -5
# Geyris
kubectl get pods -n geyris
kubectl exec -it <geyris-frontend-pod> -n geyris -- find . -name "index.html" | head -5
cd /etc/nginx/sites-available/
ls
cat api.mfl.padnove.com 
cat pdl 
sudo nano pdl 
nano pdl 
sudo nano pdl 
sudo systemctl reload nginx
sudo nano pdl 
sudo systemctl reload nginx
sudo su
sudo su
sudo su
df -h
htop
# Snapshot texte de l'état système (sans interface interactive)
top -bn1 | head -30
sudo du -h --max-depth=3 /var/lib/rancher/ 2>/dev/null | sort -rh | head -20
sudo du -sh /var/lib/rancher/k3s/data/
sudo du -sh /var/lib/rancher/k3s/agent/containerd/
# Voir toutes les images et leur taille
sudo k3s crictl images | sort -k2
# Voir les images NON utilisées par des pods actifs
sudo k3s crictl images | grep -v "k8s.gcr.io\|rancher\|pause"
# Lister les pods qui tournent actuellement
sudo k3s crictl pods
sudo k3s crictl rmi   8a586dd7c7158   0311fe666709c   3166c8559e345   7fc1a7eff17f4   56db3a42ac55a   7180b3f1d3d60   cd2741350966d   be7c19a5c3752   05c1d85c7df12   35166d3f2060d   820a2839af0df   4be2f08dcbf6e   5b7eaa3eab477   9c054eb2112aa   bdeb630c93166   884bf867479a7   aa16c25a8df35   25cd604d8912c   85e445e0f35ce
sudo k3s crictl rmi   5799da5b1a2cf   53174dda51607   f71177f37f7c8   2b4e3eb7d3719   8c4053279cdb8   5f142432ade0e
sudo k3s crictl rmi   3311c48397dfc   0c73c11e48d0e   d8b3e457157c2   75feda0bc8738
df -h /
sudo du -sh /var/lib/rancher/k3s/agent/containerd/
sudo k3s crictl pods | grep -v Ready
find / -name "*clean*" -o -name "*prune*" -o -name "*cleanup*" -o -name "*purge*" 2>/dev/null | grep -v proc | grep "\.sh$"
cat /home/devops/cleanup-registry.sh
nano /home/devops/cleanup-registry.sh
sudo nano /home/devops/cleanup-registry.sh
chmod +x /home/devops/cleanup-registry.sh
sudo chmod +x /home/devops/cleanup-registry.sh
cat /home/devops/cleanup-registry.sh
sudo crontab -e
# Ajouter cette ligne :
0 2 * * 0 /home/devops/cleanup-registry.sh >> /var/log/cleanup-registry.log 2>&1
sudo crontab -l
exit
df -h /
du -sh /var/lib/rancher/k3s/agent/containerd/* 2>/dev/null | sort -rh | head -20
curl -s http://localhost:5000/v2/_catalog | python3 -m json.tool
sudo crictl images | grep -E "<none>|none"
kubectl get pods -A | grep -v Running | grep -v Completed
devops@vps-3c312592:~$ du -sh /var/lib/rancher/k3s/agent/containerd/* 2>/dev/null | sort -rh | head -20
devops@vps-3c312592:~$ curl -s http://localhost:5000/v2/_catalog | python3 -m json.tool
Expecting value: line 1 column 1 (char 0)
devops@vps-3c312592:~$ curl -s http://localhost:5000/v2/_catalog | python3 -m json.tool
Expecting value: line 1 column 1 (char 0)
devops@vps-3c312592:~$ sudo crictl images | grep -E "<none>|none"
[sudo] password for devops: 
devops@vps-3c312592:~$ kubectl get pods -A | grep -v Running | grep -v Completed
NAMESPACE      NAME                                       READY   STATUS             RESTARTS            AGE
kampfield      kampfield-api-7d9f5ddbb-54ttc              0/1     ImagePullBackOff   10369 (3d20h ago)   40d
kampfield      kampfield-api-7d9f5ddbb-8lj2v              0/1     ImagePullBackOff   10369 (3d20h ago)   40d
devops@vps-3c312592:~$ 
kubectl get svc -A | grep registry
kubectl describe pod -n kampfield kampfield-api-7d9f5ddbb-54ttc | tail -20
sudo du -sh /var/log/pods/* 2>/dev/null | sort -rh | head -15
sudo journalctl --disk-usage
sudo du -sh /tmp /root /home/devops 2>/dev/null
sudo du -sh /root/* 2>/dev/null | sort -rh | head -20
[200~du -sh /home/devops/* 2>/dev/null | sort -rh | head -20~
du -sh /home/devops/* 2>/dev/null | sort -rh | head -20
curl -s http://141.95.29.23:30500/v2/_catalog
curl -s http://141.95.29.23:30500/v2/kampfield-api/tags/list
ls -lh /home/devops/backups/
ls -lh /home/devops/front-dev-geyris/
sudo journalctl --vacuum-time=7d
df -h /
curl -s http://141.95.29.23:30500/v2/pdl-frontend/tags/list
curl -s http://141.95.29.23:30500/v2/pdl-backend/tags/list
sudo k3s crictl pods | grep -E "geyris|pdl|kampfield"
# Voir la config de déploiement de ses apps
sudo k3s kubectl get deployment -A -o wide
# Voir le ImagePullPolicy de ses pods
sudo k3s kubectl describe deployment geyris-front -n geyris | grep -i "image\|pull"
sudo k3s kubectl describe deployment pdl-frontend -n pdl | grep -i "image\|pull"
# Voir pourquoi kampfield-api est down
sudo k3s kubectl describe pods -n kampfield -l app=kampfield-api | tail -20
curl -s http://localhost:30500/v2/kampfield-api/tags/list
curl -s http://localhost:30500/v2/_catalog | python3 -m json.tool
sudo k3s kubectl get svc -n jenkins
df -h
# Voir le ImagePullPolicy actuel de geyris
sudo k3s kubectl describe deployment geyris-front -n geyris | grep -i "image\|pull"
sudo k3s kubectl describe deployment geyris-landing -n geyris | grep -i "image\|pull"
sudo k3s kubectl describe deployment geyris-api -n geyris | grep -i "image\|pull"
sudo su
sudo su
ls
cat cleanup-registry.sh 
df -h
kubectl get pods -n pdl
exit
ls
cat cleanup-registry.sh
crontab -l
ls
sudo su
ls
df -h
/dev/sda1       197G   83G  107G  44% /
ls
kubectl get namespaces
kubectl get pods -n pdl
htop
top
htop
ls
cd pdl/
ls
cat rbac.yaml 
ls
cd
ls
cd mfl/
ls
cd
ls
ls sites-geyris/
ls front-dev-geyris/
ls g-connex/
ls geyris-api/
ls kampfield/
ls postgresql/
df -h
sudo crontab -e
crontab -l
sudo crontab -l
sudo chown -R devops:devops ~/front-dev-geyris/geyris-admin/ && sudo chmod -R u+rwX ~/front-dev-geyris/geyris-admin/
sudo su
kubectl exec -it deployment/geyris-api -n geyris -- bash
kubectl exec -it deployment/geyris-api -n geyris -- python manage.py createsuperuser
sudo crontab -l
cat /var/log/cleanup-registry.log
cat /home/devops/cleanup-registry.sh
sudo su
sudo su
sudo su
cat /var/log/cleanup-registry.log
sudo k3s crictl pods | grep -E "geyris-landing|geyris-api"
ls
sudo cat cleanup-registry.sh
sudo cat cleanup-registry.sh.save 
sudo nano cleanup-registry.sh
sudo cat /home/devops/cleanup-registry.sh
sudo nano /home/devops/cleanup-registry.sh
sudo head -5 /home/devops/cleanup-registry.sh
sudo bash /home/devops/cleanup-registry.sh
# Voir ce que crictl ps retourne pour les images actives
sudo k3s crictl ps | awk 'NR>1 {print $2}' | sort -u
sudo k3s crictl ps -o json | python3 -c "
import sys,json
data=json.load(sys.stdin)
for c in data.get('containers',[]):
    img = c.get('image',{}).get('image','')
    if img:
        # extraire juste repo:tag sans le registry prefix
        if '/' in img:
            parts = img.split('/')
            print('/'.join(parts[-2:]) if len(parts)>2 else img)
        else:
            print(img)
" | sort -u
sudo k3s crictl ps -o json | python3 -c "
import sys, json, subprocess

# Récupérer la liste des images avec leurs IDs et noms
images_raw = subprocess.check_output(['sudo', 'k3s', 'crictl', 'images', '-o', 'json'])
images_data = json.loads(images_raw)

# Construire un dict sha256 -> nom:tag
id_to_name = {}
for img in images_data.get('images', []):
    img_id = img.get('id', '')
    for tag in img.get('repoTags', []):
        id_to_name[img_id] = tag

# Récupérer les conteneurs actifs
ps_data = json.load(sys.stdin)
for c in ps_data.get('containers', []):
    img_id = c.get('imageRef', '')
    name = id_to_name.get(img_id, img_id)
    print(name)
" | sort -u
sudo nano /home/devops/cleanup-registry.sh
sudo bash /home/devops/cleanup-registry.sh 2>&1 | head -30
sudo bash /home/devops/cleanup-registry.sh
sudo crontab -l
df -h /
curl -s http://localhost:30500/v2/geyris-api/tags/list
curl -s http://localhost:30500/v2/geyris-landing/tags/list
curl -s http://localhost:30500/v2/geyris-api/tags/list | python3 -m json.tool
curl -s http://localhost:30500/v2/geyris-landing/tags/list | python3 -m json.tool
# Voir la config du registry
sudo k3s kubectl get configmap -n registry -o yaml 2>/dev/null
sudo k3s kubectl exec -n registry deployment/registry -- cat /etc/docker/registry/config.yml
df -h
exit
sudo k3s kubectl exec -n registry deployment/registry -- cat /etc/docker/registry/config.yml
sudo k3s kubectl get configmap -n registry -o yaml 2>/dev/null
exit
sudo k3s kubectl get pods -A
/home/devops/cleanup-registry.sh
df -h
history 
df -h
history
df -h
# Voir le deployment du registry
sudo k3s kubectl get deployment registry -n registry -o yaml | grep -A5 "volumes\|configMap"
# 1. Créer la configmap avec delete activé
sudo k3s kubectl create configmap registry-config   --namespace registry   --from-literal=config.yml='version: 0.1
log:
  fields:
    service: registry
storage:
  delete:
    enabled: true
  cache:
    blobdescriptor: inmemory
  filesystem:
    rootdirectory: /var/lib/registry
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
health:
  storagedriver:
    enabled: true
    interval: 10s
    threshold: 3'   --dry-run=client -o yaml | sudo k3s kubectl apply -f -
# 2. Patcher le deployment pour monter la configmap
sudo k3s kubectl patch deployment registry -n registry --patch '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "registry",
          "volumeMounts": [
            {"mountPath": "/var/lib/registry", "name": "registry-data"},
            {"mountPath": "/etc/docker/registry", "name": "registry-config"}
          ]
        }],
        "volumes": [
          {"emptyDir": {}, "name": "registry-data"},
          {"configMap": {"name": "registry-config"}, "name": "registry-config"}
        ]
      }
    }
  }
}'
# 3. Redémarrer et vérifier
sudo k3s kubectl rollout restart deployment/registry -n registry
sudo k3s kubectl rollout status deployment/registry -n registry
# 4. Tester que le DELETE fonctionne
curl -s http://localhost:30500/v2/geyris-landing/tags/list | python3 -m json.tool
sudo k3s kubectl get pods -A | grep -v Running
sudo k3s kubectl get pods -A
history
sudo su
sudo su
sudo su
sudo su
sudo su
cd /etc/fail2ban/
ls
cat jail.local 
sudo su
sudo su
sudo su
sudo su
sudo su
sudo su
sudo su
ls
kubectl get pods -n geyris
kubectl logs -n geyris-api-67687477bb-5g8gq
kubectl logs -n geyris-api-67687477bb-5g8gq -n geyris
kubectl logs geyris-api-67687477bb-5g8gq -n geyris
kubectl logs dashboard-geyris-85d9878694-fqpnk -n geyris
kubectl get pods -n geyris
kubectl logs geyris-front-77788bcd9f-pbdvd -n geyris
kubectl get pods -n geyris
exit
sudo su
sudo su
sudo su
sudo su
sudo su
sudo su
sdo su
sudo su
ls
kubectl get pods -n jenkins
kubectl logs jenkins-5d7d48bff5-mjkbp -n jenkins
sudo su
sudo su
sudo su
sudo su
sudo su
sudo su
sudo su
sudo su
# État du cluster
sudo k3s kubectl get pods -A
# Résultat du dernier nettoyage automatique
tail -50 /var/log/cleanup-registry.log
# État du disque
df -h /
sudo nano /home/devops/cleanup-registry.sh
cat cleanup-registry.sh
sudo sed -i   's|k3s crictl|/usr/local/bin/k3s crictl|g'   /home/devops/cleanup-registry.sh
# Vérifier
grep "k3s" /home/devops/cleanup-registry.sh
ls
sydo su
sudo su
# Surveiller les pods Geyris en temps réel
sudo k3s kubectl get pods -n geyris -w
# Surveiller l'espace disque toutes les 30 secondes
watch -n 30 df -h /
sudo k3s crictl rmi --prune
df -h /
sudo k3s kubectl get pods -n geyris
# Vue d'ensemble disque + RAM + CPU
echo "=== DISQUE ===" && df -h /
echo "=== RAM ===" && free -h
echo "=== CPU/LOAD ===" && uptime
echo "=== TOP PROCESSUS ===" && top -bn1 | head -15
echo "=== PODS PROBLÉMATIQUES ===" && sudo k3s kubectl get pods -A | grep -v Running
exit
sudo certbot --nginx -d geyris.com
sudo certbot --nginx -d geyris.com -d www.geyris.com
sudo su
sudo certbot --nginx -d geyris.com -d www.geyris.com
suso su
clear
sudo su
ls
cd ..
cd 
ls
lscpu
ls
cd geyris-
cd geyris-api/
ls
clear
ls
tree
cat deployment.yaml
clear
cd ..
mkdir dev-geyris-api
cd dev-geyris-api/
clera
clear
git clone https://github.com/PADNOVE/API_Geyris.git
ls
lcear
clear
sudo su
curl http://141.95.29.23:30800/api/v1/assistant/health/
curl http://localhost:8000/api/v1/assistant/health/
docker imgaes
docker images
clear
htop
top 
clear
sudo su
clear
cd ..
cd admin-geyris/
pwd
ls
git status
docker ps
docker exec -it geyris-api-dev bash
ls
npm run dev
node -v
npm install
docker ps
docker inspect geyris-api-dev | grep -i port
docker imgaes
docker images
clear
kubectl get all pods
kubectl get pods
kubectl get namespaces
kubectl get pods -n postgresql
ls
cd api_g-connex/
ls
cat deployment.yaml 
kubectl get secrets -n postgresql
kubectl get secret postgres-gconnex-secret -n postgresql -o jsonpath='{.data}' | jq
kubectl get secret postgres-gconnex-secret -n postgresql -o json
kubectl get secret g-connex-api-secret -n g-connex -o go-template='{{range $k, $v := .data}}{{$k}}={{$v | base64decode}}{{"\n"}}{{end}}'
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- psql -U admin -d yvcbyszjhu_gconnexDB
kubectl get secret 
kubectl get secrets -n postgresql
kubectl get secret postgres-geyris-secret -n postgresql -o json
kubectl get secret geyris-api-secret -n geyris -o go-template='{{range $k, $v := .data}}{{$k}}={{$v | base64decode}}{{"\n"}}{{end}}'
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- env PGPASSWORD='geyris123@G' psql -U admin -l
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- env PGPASSWORD='geyris123@G' psql -U geyris_user -d geyris_db
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- env PGPASSWORD='admin123' psql -U admin -d uptdzpna_geyris_db
kubectl get secret
kubectl get secret -n postgresql
kubectl get secret postgres-geyris-secret -n geyris -o go-template='{{range $k, $v := .data}}{{$k}}={{$v | base64decode}}{{"\n"}}{{end}}'
kubectl exec -it -n postgresql postgres-main-7dcdccd666-4s6v6 -- env PGPASSWORD='admin123' psql -U admin -d uptdzpna_geyris_db
htop
df -h
ls
./cleanup-registry.sh
sudo ./cleanup-registry.sh
df -h
sudo du -xh / --max-depth=1 2>/dev/null | sort -hr
sudo du -xh /var --max-depth=1 2>/dev/null | sort -hr
journalctl --disk-usage
sudo journalctl --vacuum-time=7d
docker system df
dh -h
df -h
docker image prune -a
df -h
docker system df
docker builder prune -a
docker system df
kubectl get pods
kubectl get pods --all
kubectl get pods -all
kubectl get pods -a
kubectl get pods --a
kubectl get pods -n g-connex
kubectl get pods -n geyris
kubectl get pods -n pdl
docker system df
df -h
sudo du -xh / --max-depth=1 2>/dev/null | sort -hr
sudo du -sh /var/lib/docker
journalctl --disk-usage
sudo du -xh / --max-depth=1 2>/dev/null | sort -hr
sudo du -xh /var --max-depth=1 2>/dev/null | sort -hr
sudo find /root -type f -exec du -h {} + 2>/dev/null | sort -hr | head -20
ollama list
sudo du -xh /var/lib --max-depth=1 2>/dev/null | sort -hr
sudo du -xh /var/lib/rancher --max-depth=2 2>/dev/null | sort -hr | head -30
sudo du -xh /var/lib/kubelet --max-depth=2 2>/dev/null | sort -hr | head -30
sudo ctr -n k8s.io images ls
kubectl get pods -A
sudo ls -lah /var/lib/kubelet/pods/c16ca8c7-b9ab-4307-a784-17e70cb0284e
sudo ls -lah /var/lib/kubelet/pods/4e422ea2-fc34-4075-ac42-767f82287123
kubectl get pods -A -o wide
kubectl get pv,pvc -A
sudo cat /var/lib/kubelet/pods/c16ca8c7-b9ab-4307-a784-17e70cb0284e/containers/*/* 2>/dev/null
kubectl get pod -A --field-selector metadata.uid=c16ca8c7-b9ab-4307-a784-17e70cb0284e
df -h
ls
kubectl get pods -n geyris
ls
df -h
htop
neofetch
sudo apt install neofetch
sudo apt update
sudo apt install neofetch
kubectl get namespaces
kubectl get create namespace security
kubectl create namespace security
kubectl delete namespace security
clear
kubectl delete namespace security
clear
kubectl create namespace security
kubectl get namespaces
helm version
clear
helm version
clear
helm repo add sonarqube https://SonarSource.github.io/helm-chart-sonarqube
helm repo update
mkdir security
cd security/
mkdir sonarqube
cd sonarqube/
nano soonarqube-values.yaml
sudo sysctl -w vm.max_map_count=524288
sudo sysctl -w fs.file-max=131072
clear
helm install sonarqube sonarqube/sonarqube   --namespace security   -f sonarqube-values.yaml
clear
helm install sonarqube --namespace security   -f sonarqube-values.yaml
clear
helm install sonarqube sonarqube/sonarqube   --namespace security   -f sonarqube-values.yaml
ls
mv soonarqube-values.yaml sonarqube-values.yaml
clear
helm install sonarqube sonarqube/sonarqube   --namespace security   -f sonarqube-values.yaml
cat sonarqube-values.yaml 
sed -i '1i community:\n  enabled: true' sonarqube-values.yaml
clear
echo "" > sonarqube-values.yaml 
nano sonarqube-values.yaml 
clear
cat sonarqube-values.yaml 
clear
helm install sonarqube sonarqube/sonarqube   --namespace security   -f sonarqube-values.yaml
kubectl get pods -n security -w
kubectl get pods -n security
kubectl get pvc -n security
kubectl get svc -n security
curl -I http://141.95.29.23:9000
ls
nano sonarqube-values.yaml 
helm upgrade sonarqube sonarqube/sonarqube   --namespace security   -f sonarqube-values.yaml
kubectl get svc -n security
curl -I http://127.0.0.1:30900
sudo nano /etc/nginx/sites-available/sonarqube.geyris.com
sudo ln -s /etc/nginx/sites-available/sonarqube.geyris.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
sudo certbot --nginx -d sonarqube.geyris.com
kubectl get pods -n security
helm get values sonarqube -n security
kubectl get namespaces
kubectl get pods -n postgresql
kubectl get svc -n postgresql
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U postgres
kubectl describe pod postgres-main-7dcdccd666-4s6v6 -n postgresql | grep -A 10 "Environment"
kubectl get deployment -n postgresql -o yaml | grep -A 5 "POSTGRES_"
kubectl get secret postgres-secret -n postgresql -o jsonpath='{.data.POSTGRES_USER}' | base64 -d
echo
kubectl get secret postgres-secret -n postgresql -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
echo
kubectl exec -it postgres-main-7dcdccd666-4s6v6 -n postgresql -- psql -U admin -d postgres
cat sonarqube-values.yaml 
echo "" > sonarqube-values.yaml 
nano sonarqube-values.yaml 
helm upgrade sonarqube sonarqube/sonarqube   --namespace security   -f sonarqube-values.yaml
kubectl get pods -n security -w
kubectl logs sonarqube-sonarqube-0 -n security | grep -i "jdbc\|database\|postgresql"
kubectl create namespace Geyris-Front-Preprod
kubectl create namespace preprod
ls
cd ..
mkdir preprod-geyris
ls
cd
ls
cd geyris-front/
ls
cat deployment.yaml 
cd 
cd security/
ls
cd preprod-geyris/
nano deployment-preprod.yaml
kubectl get svc -A | grep 30091
kubectl get svc -A | grep 30092
kubectl get svc -A | grep 30093
nano deployment-preprod.yaml
kubectl apply -f deployment-preprod.yaml
kubectl get pods -n preprod
kubectl get svc -n preprod
kubectl get pods -n preprod
kubectl describe pod -n preprod | grep -A 5 "Events"
htop
sudo systemctl status jenkins
kubectl get pods jenkins
kubectl get pods -n jenkins
kubectl logs jenkins-5d7d48bff5-mjkbp -n jenkins
kubectl exec -it jenkins-5d7d48bff5-mjkbp -n jenkins -- rm -rf /var/jenkins_home/workspace/securityGeyris-test
kubectl exec -it jenkins-5d7d48bff5-mjkbp -n jenkins -- rm -rf "/var/jenkins_home/workspace/securityGeyris-test@tmp"
kubectl get pods -n jenkins
kubectl describe pod jenkins-5d7d48bff5-mjkbp -n jenkins | tail -30
kubectl top pod jenkins-5d7d48bff5-mjkbp -n jenkins
kubectl get deployment jenkins -n jenkins -o jsonpath='{.spec.template.spec.containers[0].resources}'
echo
cd
ls
cd Jenkins/
ls
cat deployment.yaml 
nano deployment.yaml 
kubectl apply -f deployment.yaml 
kubectl get pods -n jenkins -w
cd 
cd security/
ls
kubectl get pods -n jenkins
kubectl logs jenkins-6b6687f9b7-gbhz5 -n jenkins
cd
cd Jenkins/
ls
cat deployment.yaml 
echo "" > deployment.yaml 
nano deployment.yaml 
kubectl apply -f deployment.yaml 
kubectl get pods -n jenkins -w
kubectl get pods -n jenkins
which kubectl
kubectl version --client
echo "" > deployment.yaml 
nano deployment.yaml 
kubectl apply -f deployment.yaml 
kubectl get pods -n jenkins
kubectl exec -it $(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}') -n jenkins -- bash
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- docker --version
kubectl exec -it $JENKINS_POD -n jenkins -- kubectl version --client
docker buildx version
which docker-buildx
ls -la /usr/libexec/docker/cli-plugins/ 2>/dev/null
ls -la ~/.docker/cli-plugins/ 2>/dev/null
echo "" > deployment.yaml 
nano deployment.yaml 
kubectl apply -f deployment.yaml
kubectl get pods -n jenkins
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- docker buildx version
ls -la /usr/local/bin/kubectl
file /usr/local/bin/kubectl
echo "" > deployment.yaml 
nano deployment.yaml 
kubectl apply -f deployment.yaml
cd 
cd security/
ls
mkdir rbac
cd rbac/
ls
nano jenkins-role.yaml
kubectl apply -f jenkins-role.yaml
cat jenkins-role.yaml 
nano jenkins-rolebinding.yaml
kubectl apply -f jenkins-rolebinding.yaml
kubectl get pods -n preprod
kubectl get pods -n geyris
kubectl logs geyris-api-5bf8d68688-qrwsv -n geyris
kubectl get pods -n geyris
kubectl delete pods geyris-front-6f8f68bd9d-7wmbm -n geyris
kubectl delete pods geyris-front-6f8f68bd9d-sbfqq -n geyris
kubectl delete pods geyris-landing-7bb5987bc5-7t2vr -n geyris
kubectl delete pods geyris-landing-7bb5987bc5-pc4hw -n geyris
kubectl delete pods geyris-api-5bf8d68688-ljxt5 -n geyris
kubectl delete pods geyris-api-5bf8d68688-qrwsv -n geyris
kubectl delete pods dashboard-geyris-fbd9cf5d8-dk9x7 -n geyris
kubectl delete pods dashboard-geyris-fbd9cf5d8-mf7mn -n geyris
kubectl get pods -n geyris
kubectl logs geyris-front-6f8f68bd9d-jpbv5 -n geyris
kubectl get pods -n geyris
kubectl logs geyris-landing-7bb5987bc5-kdp2l -n geyris
ls
tree
ls
ls dashboard-geyris/
ls dev-geyris-api/
ls front-dev-geyris/
ls geyris-api/
ls geyris-front/
ls sites-geyris/
ls front-dev-geyris/Geyris_Web/
ls front-dev-geyris/admin-geyris/
ls front-dev-geyris/geyris-admin/

kubectl get pods -n geyris
kubectl get svc -n geyris
kubectl get ingress -n geyris
kubectl logs -n geyris deployment/geyris-front --tail=100
kubectl logs -n geyris geyris-front-6f8f68bd9d-jpbv5 --tail=100
kubectl logs -n geyris deployment/geyris-api --tail=100
kubectl get endpoints -n geyris
curl -I https://app.geyris.com
curl https://app.geyris.com/api/health
curl https://app.geyris.com/api/v1/
kubectl get ingress -A
kubectl get pods -A | grep -E "traefik|nginx|caddy"
sudo ss -tulpn | grep ':80\|:443'
sudo systemctl status nginx
sudo systemctl status apache2
sudo systemctl status caddy
sudo nginx -T
grep -R "app.geyris.com" /etc/nginx
curl -I https://app.geyris.com/sw.js
curl -I https://app.geyris.com/manifest.webmanifest
grep -R "location.reload" src
grep -R "window.location" src
grep -R "registerSW" src
grep -R "skipWaiting" .
npm run dev
docker compose up --build
sudo su
npm run dev
sudo su
df -h
htop
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- bash -c "which python3; which pip3"
clear
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- bash
clear
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- bash
htop
clear
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- bash
ls
clear
JENKINS_POD=$(kubectl get pods -n jenkins -l app=jenkins -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $JENKINS_POD -n jenkins -- bash
npm run dev
sudo sur
sudo su
sudo ufw allow 3000
sudo iptables -L -n
sudo iptables -L INPUT -n --line-numbers | head -20
curl -I http://localhost:3000
sudo ss -tlnp | grep 3000
curl -I http://141.95.29.23:3000
npm run dev
sudo su
htop
exit
npm run dev
sudo which node
sudo which npm
sudo find / -name "npm" -type f 2>/dev/null
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
source ~/.bashrc
nvm install 24
node -v
npm -v
npm install
npm run dev
sudo chown -R devops:devops ~/front-dev-geyris/Geyris_Web
npm run dev
rm -rf dev-dist
npm run dev
git status
git checkout -b dev origin/dev
git branch
git status
git diff
git stash push -m "Nicolas WIP main - proxy vite.config + PhoneInput - 08/07"
ls -la .git/objects | head -20
sudo chown -R devops:devops .git
git stash push -m "Nicolas WIP main - proxy vite.config + PhoneInput - 08/07"
git branch
git status
git log --oneline -5
sudo su
sudo su
htop
ls /etc/nginx/sites-available/
cat /etc/nginx/sites-available/app.geyris.com
kubectl get pods -n geyris
kubectl get svc -n geyris
kubectl logs -n geyris geyris-front-688b69dddf-h97b4 --tail=50 -f
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- cat /usr/share/nginx/html/sw.js | md5sum
kubectl exec -n geyris geyris-front-688b69dddf-m9nlw -- cat /usr/share/nginx/html/sw.js | md5sum
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- ps aux
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- readlink -f /proc/1/cwd
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- sh -c 'ls $(readlink -f /proc/1/cwd)/dist'
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- sh -c 'md5sum $(readlink -f /proc/1/cwd)/dist/sw.js'
kubectl exec -n geyris geyris-front-688b69dddf-m9nlw -- sh -c 'md5sum $(readlink -f /proc/1/cwd)/dist/sw.js'
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- sh -c "grep -o 'controllerchange' /app/dist/assets/*.js | head"
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- sh -c "grep -o 'skipWaiting\|clients.claim\|location.reload' /app/dist/assets/*.js | sort | uniq -c"
htop
kubectl exec -n geyris geyris-front-688b69dddf-h97b4 -- sh -c   "curl -sI http://localhost:3000/sw.js"
kubectl get pods -n geyris
kubectl exec -n geyris geyris-front-df46875fc-s4nzb -- sh -c "curl -sI http://localhost:3000/sw.js"
kubectl exec -n geyris geyris-front-df46875fc-s4nzb -- sh -c 'md5sum $(readlink -f /proc/1/cwd)/dist/sw.js'
kubectl exec -n geyris geyris-front-df46875fc-v28m8 -- sh -c 'md5sum $(readlink -f /proc/1/cwd)/dist/sw.js'
kubectl exec -n geyris geyris-front-df46875fc-s4nzb -- sh -c 'ls $(readlink -f /proc/1/cwd)/dist'
kubectl exec -n geyris geyris-front-df46875fc-s4nzb -- sh -c "grep -o 'serviceWorker\|registerSW\|/sw.js' /app/dist/assets/*.js | sort | uniq -c"
htop
top
npm run dev
clear
sudo su
npm run dev
sudo su
sudo su
sudo su
kubectl get pods -n g-connex
kubectl logs g-connex-api-76d78c5c5f-fjgms -n g-connex
kubectl get secret -n g-connex
kubectl get secret g-connex-api-secret -n g-connex -o jsonpath='{.data}' | jq
kubectl describe secret g-connex-api-secret -n g-connex
kubectl get secret g-connex-api-secret -n g-connex -o json | jq -r '.data | to_entries[] | "\(.key)=\(.value|@base64d)"'
kubectl get secret g-connex-api-secret -n g-connex -o yaml
for key in $(kubectl get secret g-connex-api-secret -n g-connex -o jsonpath='{.data}' | jq -r 'keys[]'); do   echo -n "$key=";   kubectl get secret g-connex-api-secret -n g-connex -o jsonpath="{.data.$key}" | base64 -d;   echo; done
kubectl get deployments -n g-connex
kubectl get deployment g-connex-api -n g-connex -o yaml > deploy.yaml
cat deploy.yaml 
htop
ps -a
crontab -l
sudo su
kubectl get logs -n g-connex
kubectl get pdss -n g-connex
kubectl get pods -n g-connex
kubectl logs g-connex-api-9fd7df54c-7cknj -n g-connex
kubectl get pods -n g-connex
echo "YXBwLmdjb25uZXhAZ21haWwuY29t" > base64 -d
kubectl exec -it -n g-connex g-connex-api-9fd7df54c-7cknj -- env | grep -E 'SMTP|GMAIL|MAIL'" > base64 -d
kubectl exec -it -n g-connex g-connex-api-9fd7df54c-7cknj -- env | grep -E 'SMTP|GMAIL|MAIL'
kubectl patch secret g-connex-api-secret -n g-connex -p='{
  "data": {
    "GMAIL_USER":"'$(echo -n "support@g-connex.com" | base64 -w0)'",
    "GMAIL_APP_PASSWORD":"'$(echo -n "aN^_kHz9af" | base64 -w0)'",
    "DEFAULT_EMAIL":"'$(echo -n "support@g-connex.com" | base64 -w0)'"
  }
}'
kubectl rollout restart deployment/g-connex-api -n g-connex
kubectl get pods -n g-connex
kubectl exec -it -n g-connex $(kubectl get pod -n g-connex -l app=g-connex-api -o jsonpath='{.items[0].metadata.name}') -- env | grep -E 'GMAIL|MAIL'
kubectl get pods -n g-connex
kubectl logs g-connex-api-5d7694569-b2p28 -n g-connex
htop
kubectl logs g-connex-api-5d7694569-b2p28 -n g-connex
exit
kubectl get pods -n g-connex
kubectl logs chatbot-ai-6cd47bfb8d-xbr2q -n g-connex
kubectl describe pods chatbot-ai-6cd47bfb8d-xbr2q -n g-connex
kubectl get pods -n g-connex
kubectl get secret g-connex-api-secret -n g-connex -o yaml
kubectl get secret g-connex-api-secret -n g-connex -o jsonpath='{.data.FEDAPAY_API_KEY}' | base64 -d
echo
kubectl get secret g-connex-api-secret -n g-connex -o jsonpath='{.data.FEDAPAY_PUBLIC_KEY}' | base64 -d
echo
kubectl patch secret g-connex-api-secret -n g-connex -p='{
  "data": {
    "FEDAPAY_API_KEY":"'$(echo -n 'sk_live_JIi85-udHJ-DA6wvYx4ZwTzI' | base64 -w0)'",
    "FEDAPAY_PUBLIC_KEY":"'$(echo -n 'pk_live_0UoGb1e_1-n-NZVF1Z8YKafc' | base64 -w0)'"
  }
}'
kubectl rollout restart deployment/g-connex-api -n g-connex
kubectl rollout status deployment/g-connex-api -n g-connex
kubectl exec -it -n g-connex <nouveau-pod> -- env | grep FEDAPAY
kubectl get pods -n g-connex
kubectl exec -it -n g-connex g-connex-api-7865c47ccc-4rw5w -- env | grep FEDAPAY
kubectl get pods -n g-connex
kubectl exec -it -n g-connex g-connex-api-7865c47ccc-4rw5w -- env | grep FEDAPAY
npm run dev
sudo lsof -i :3000
ps -p 484124 -o pid,ppid,user,cmd
sudo cat /proc/484124/cmdline | tr '\0' ' '; echo
sudo ls -l /proc/484124/exe
sudo kill 484124
sudo lsof -i :3000
git status
git log origin/dev..HEAD --oneline
git log --oneline --graph --decorate -5
npm run dev
npx tsc --noEmit
rm -f tsconfig.tsbuildinfo
npx tsc --noEmit
ls -la src/services/
cat src/services/axios.ts
npm run dev
rm -rf node_modules/.vite && npm run dev
clear
git status
clear
git add .
git commit -m "cache"
sudo su
sudo su
sudo su
sudo su
suod su
U2V2YTA3LzEwLzIwMDEK
sudo su
npm run dev
