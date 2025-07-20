#!/bin/bash

# Script to ensure all required Kubernetes manifests exist

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}Ensuring Kubernetes Manifests Exist${NC}"
echo -e "${GREEN}=======================================${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
K8S_DIR="${PROJECT_ROOT}/kubernetes"

# Create kubernetes directory if it doesn't exist
mkdir -p "${K8S_DIR}"

# Create namespace.yaml if it doesn't exist
if [ ! -f "${K8S_DIR}/namespace.yaml" ]; then
    echo -e "${YELLOW}Creating namespace.yaml...${NC}"
    cat > "${K8S_DIR}/namespace.yaml" << 'EOF'
apiVersion: v1
kind: Namespace
metadata:
  name: php-web-service-namespace
EOF
fi

# Create service.yaml if it doesn't exist
if [ ! -f "${K8S_DIR}/service.yaml" ]; then
    echo -e "${YELLOW}Creating service.yaml...${NC}"
    cat > "${K8S_DIR}/service.yaml" << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: php-web-service
  namespace: php-web-service-namespace
spec:
  selector:
    app: php-web-service
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
EOF
fi

# Create configmap.yml if it doesn't exist
if [ ! -f "${K8S_DIR}/configmap.yml" ]; then
    echo -e "${YELLOW}Creating configmap.yml...${NC}"
    cat > "${K8S_DIR}/configmap.yml" << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: php-web-service-config
  namespace: php-web-service-namespace
data:
  app.environment: "production"
  app.debug: "false"
  app.config.php: |
    <?php
    return [
        'debug' => false,
        'environment' => 'production',
        'database' => [
            'host' => getenv('DB_HOST'),
            'name' => getenv('DB_NAME'),
            'user' => getenv('DB_USER'),
            'password' => getenv('DB_PASSWORD'),
        ]
    ];
EOF
fi

# Create secrets.yml if it doesn't exist
if [ ! -f "${K8S_DIR}/secrets.yml" ]; then
    echo -e "${YELLOW}Creating secrets.yml...${NC}"
    cat > "${K8S_DIR}/secrets.yml" << 'EOF'
apiVersion: v1
kind: Secret
metadata:
  name: php-web-service-secrets
  namespace: php-web-service-namespace
type: Opaque
data:
  db-username: cGhwX3VzZXI=  # php_user (base64 encoded)
  db-password: cGhwX3Bhc3N3b3Jk  # php_password (base64 encoded)
  api-key: ZXhhbXBsZS1hcGkta2V5  # example-api-key (base64 encoded)
EOF
fi

# Create ingress.yaml if it doesn't exist
if [ ! -f "${K8S_DIR}/ingress.yaml" ]; then
    echo -e "${YELLOW}Creating ingress.yaml...${NC}"
    cat > "${K8S_DIR}/ingress.yaml" << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: php-web-service-ingress
  namespace: php-web-service-namespace
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  rules:
  - host: php-service.example.com  # Replace with your actual domain
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: php-web-service
            port:
              number: 80
EOF
fi

# Run the deployment creation script
echo -e "${YELLOW}Creating deployment.yaml...${NC}"
"${SCRIPT_DIR}/create-deployment.sh"

# Create network-policy.yaml if it doesn't exist
if [ ! -f "${K8S_DIR}/network-policy.yaml" ]; then
    echo -e "${YELLOW}Creating network-policy.yaml...${NC}"
    cat > "${K8S_DIR}/network-policy.yaml" << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: php-web-service-network-policy
  namespace: php-web-service-namespace
spec:
  podSelector:
    matchLabels:
      app: php-web-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: database-namespace
      podSelector:
        matchLabels:
          app: mysql
    ports:
    - protocol: TCP
      port: 3306
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80
    - protocol: TCP
      port: 443
EOF
fi

echo -e "${GREEN}All Kubernetes manifests have been created successfully.${NC}"
