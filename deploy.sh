#!/bin/bash
#!/bin/bash

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}PHP Web Service Deployment Script${NC}"
echo -e "${GREEN}=======================================${NC}"

# Check for prerequisites
for cmd in docker kubectl; do
    if ! command -v $cmd &> /dev/null; then
        echo -e "${RED}$cmd is not installed. Please run setup.sh first.${NC}"
        exit 1
    fi
done

# Check if running in Minikube context
if ! kubectl config current-context | grep -q "minikube"; then
    echo -e "${YELLOW}Warning: You are not using Minikube context. Make sure you're deploying to the correct cluster.${NC}"
    read -p "Continue? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Deployment aborted.${NC}"
        exit 1
    fi
fi

# 1. Build and push Docker image
echo -e "\n${YELLOW}Step 1: Building Docker image...${NC}"
DOCKER_USERNAME="peddireddylokesh"
IMAGE_NAME="php-web-service"
IMAGE_TAG="$(date +%Y%m%d-%H%M%S)"

echo "Building image: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest

# Skip Docker Hub push for local development with Minikube
if kubectl config current-context | grep -q "minikube"; then
    echo "Using Minikube, loading image directly..."
    minikube image load ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
    minikube image load ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
else
    echo "Logging in to Docker Hub..."
    echo "Please enter your Docker Hub password:"
    docker login -u ${DOCKER_USERNAME}

    echo "Pushing images..."
    docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
    docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest
fi

# 2. Update Kubernetes manifests
echo -e "\n${YELLOW}Step 2: Updating Kubernetes manifests...${NC}"

# Make sure the scripts are executable
chmod +x scripts/create-deployment.sh scripts/ensure-k8s-manifests.sh

# Run the script to ensure all K8s manifests exist
./scripts/ensure-k8s-manifests.sh

# Update the image tag in deployment file
sed -i.bak "s|image: docker.io/peddireddylokesh/php-web-service:.*|image: docker.io/peddireddylokesh/php-web-service:${IMAGE_TAG}|" kubernetes/deployment.yaml

# 3. Create the namespace if it doesn't exist
echo -e "\n${YELLOW}Step 3: Creating Kubernetes namespace...${NC}"
kubectl apply -f kubernetes/namespace.yaml

# 4. Deploy to Kubernetes
echo -e "\n${YELLOW}Step 4: Deploying to Kubernetes...${NC}"
kubectl apply -f kubernetes/configmap.yaml
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml
kubectl apply -f kubernetes/ingress.yaml

# 5. Verify deployment
echo -e "\n${YELLOW}Step 5: Verifying deployment...${NC}"
kubectl rollout status deployment/php-web-service -n php-web-service-namespace --timeout=300s

# 6. Show deployment info
echo -e "\n${GREEN}Deployment Information:${NC}"
echo -e "${YELLOW}Pods:${NC}"
kubectl get pods -n php-web-service-namespace
echo -e "\n${YELLOW}Services:${NC}"
kubectl get services -n php-web-service-namespace
echo -e "\n${YELLOW}Ingress:${NC}"
kubectl get ingress -n php-web-service-namespace

# 7. Setup port-forwarding for local testing
PORT=8080
echo -e "\n${GREEN}Setting up port forwarding to access the application locally on port ${PORT}...${NC}"
echo -e "${YELLOW}Access your application at: http://localhost:${PORT}${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop port forwarding${NC}"
kubectl port-forward service/php-web-service 8080:80 -n php-web-service-namespace
set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}PHP Web Service Deployment Script${NC}"
echo -e "${GREEN}=======================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Docker is not installed. Installing...${NC}"
    bash setup.sh
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl is not installed. Installing...${NC}"
    bash setup.sh
fi

# 1. Build and push Docker image
echo -e "\n${YELLOW}Step 1: Building and pushing Docker image...${NC}"
DOCKER_USERNAME="peddireddylokesh"
IMAGE_NAME="php-web-service"
IMAGE_TAG="$(date +%Y%m%d-%H%M%S)"

echo "Building image: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}"
docker build -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} .
docker tag ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} ${DOCKER_USERNAME}/${IMAGE_NAME}:latest

echo "Logging in to Docker Hub..."
echo "Please enter your Docker Hub password:"
docker login -u ${DOCKER_USERNAME}

echo "Pushing images..."
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest

# 2. Update Kubernetes manifests
echo -e "\n${YELLOW}Step 2: Updating Kubernetes manifests...${NC}"
sed -i "s|image: docker.io/peddireddylokesh/php-web-service:.*|image: docker.io/peddireddylokesh/php-web-service:${IMAGE_TAG}|" kubernetes/deployment.yaml

# 3. Create the namespace if it doesn't exist
echo -e "\n${YELLOW}Step 3: Creating Kubernetes namespace...${NC}"
kubectl get namespace php-web-service-namespace >/dev/null 2>&1 || kubectl apply -f kubernetes/namespace.yaml

# 4. Deploy to Kubernetes
echo -e "\n${YELLOW}Step 4: Deploying to Kubernetes...${NC}"
kubectl apply -f kubernetes/configmap.yml || echo -e "${YELLOW}Warning: Failed to apply configmap.yml${NC}"
kubectl apply -f kubernetes/secrets.yml || echo -e "${YELLOW}Warning: Failed to apply secrets.yml${NC}"
kubectl apply -f kubernetes/deployment.yaml || echo -e "${YELLOW}Warning: Failed to apply deployment.yaml${NC}"
kubectl apply -f kubernetes/service.yaml || echo -e "${YELLOW}Warning: Failed to apply service.yaml${NC}"
kubectl apply -f kubernetes/ingress.yaml || echo -e "${YELLOW}Warning: Failed to apply ingress.yaml${NC}"

# 5. Verify deployment
echo -e "\n${YELLOW}Step 5: Verifying deployment...${NC}"
kubectl rollout status deployment/php-web-service -n php-web-service-namespace --timeout=300s

# 6. Show deployment info
echo -e "\n${GREEN}Deployment Information:${NC}"
echo -e "${YELLOW}Pods:${NC}"
kubectl get pods -n php-web-service-namespace
echo -e "\n${YELLOW}Services:${NC}"
kubectl get services -n php-web-service-namespace
echo -e "\n${YELLOW}Ingress:${NC}"
kubectl get ingress -n php-web-service-namespace

# 7. Setup port-forwarding for local testing
PORT=8080
echo -e "\n${GREEN}Setting up port forwarding to access the application locally on port ${PORT}...${NC}"
echo -e "${YELLOW}Access your application at: http://localhost:${PORT}${NC}"
echo -e "${YELLOW}Press Ctrl+C to stop port forwarding${NC}"
kubectl port-forward service/php-web-service 8080:80 -n php-web-service-namespace
