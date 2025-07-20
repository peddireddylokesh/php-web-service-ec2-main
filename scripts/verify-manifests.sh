#!/bin/bash

# Script to verify that all required Kubernetes manifests exist

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}Kubernetes Manifest Verification${NC}"
echo -e "${GREEN}=======================================${NC}"

# Required manifests
REQUIRED_MANIFESTS=(
  "deployment.yaml"
  "service.yaml"
  "ingress.yaml"
  "configmap.yml"
  "secrets.yml"
  "namespace.yaml"
)

# Optional manifests
OPTIONAL_MANIFESTS=(
  "network-policy.yaml"
  "hpa.yaml"
  "pdb.yaml"
)

# Check if kubernetes directory exists
if [ ! -d "kubernetes" ]; then
  echo -e "${RED}ERROR: kubernetes directory not found!${NC}"
  echo "Creating kubernetes directory..."
  mkdir -p kubernetes
fi

# Check required manifests
echo -e "\n${YELLOW}Checking required manifests...${NC}"
MISSING_MANIFESTS=0

for manifest in "${REQUIRED_MANIFESTS[@]}"; do
  if [ -f "kubernetes/${manifest}" ]; then
    echo -e "✅ ${manifest} - ${GREEN}Found${NC}"
  else
    echo -e "❌ ${manifest} - ${RED}Missing${NC}"
    MISSING_MANIFESTS=$((MISSING_MANIFESTS+1))

    # Generate basic templates for missing files
    case "$manifest" in
      "deployment.yaml")
        echo "Generating basic deployment.yaml template..."
        cat > kubernetes/deployment.yaml << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: php-web-service
  namespace: php-web-service-namespace
  labels:
    app: php-web-service
spec:
  replicas: 2
  selector:
    matchLabels:
      app: php-web-service
  template:
    metadata:
      labels:
        app: php-web-service
    spec:
      containers:
      - name: php-web-service
        image: docker.io/peddireddylokesh/php-web-service:latest
        ports:
        - containerPort: 80
EOF
        ;;
      "service.yaml")
        echo "Generating basic service.yaml template..."
        cat > kubernetes/service.yaml << EOF
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
        ;;
      "namespace.yaml")
        echo "Generating basic namespace.yaml template..."
        cat > kubernetes/namespace.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: php-web-service-namespace
EOF
        ;;
    esac
  fi
done

# Check optional manifests
echo -e "\n${YELLOW}Checking optional manifests...${NC}"

for manifest in "${OPTIONAL_MANIFESTS[@]}"; do
  if [ -f "kubernetes/${manifest}" ]; then
    echo -e "✅ ${manifest} - ${GREEN}Found${NC}"
  else
    echo -e "⚠️ ${manifest} - ${YELLOW}Missing (optional)${NC}"
  fi
done

# Summary
echo -e "\n${GREEN}Summary:${NC}"
if [ $MISSING_MANIFESTS -eq 0 ]; then
  echo -e "${GREEN}All required Kubernetes manifests are present.${NC}"
else
  echo -e "${YELLOW}Generated templates for ${MISSING_MANIFESTS} missing manifest(s).${NC}"
  echo -e "${YELLOW}Please review and update the generated templates with appropriate values.${NC}"
fi

# Validate manifests with kubectl
if command -v kubectl &> /dev/null; then
  echo -e "\n${YELLOW}Validating manifests with kubectl...${NC}"
  for manifest in kubernetes/*.yaml kubernetes/*.yml; do
    if [ -f "$manifest" ]; then
      echo -e "Validating $(basename $manifest)..."
      if kubectl apply --dry-run=client -f "$manifest" &> /dev/null; then
        echo -e "✅ $(basename $manifest) - ${GREEN}Valid${NC}"
      else
        echo -e "❌ $(basename $manifest) - ${RED}Invalid${NC}"
        echo -e "Errors:"
        kubectl apply --dry-run=client -f "$manifest"
      fi
    fi
  done
else
  echo -e "\n${YELLOW}kubectl not found. Skipping manifest validation.${NC}"
fi

echo -e "\n${GREEN}Manifest verification complete.${NC}"
