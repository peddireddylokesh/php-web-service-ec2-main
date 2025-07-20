#!/bin/bash

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}Docker Build Script${NC}"
echo -e "${GREEN}=======================================${NC}"

# Set variables
DOCKER_USERNAME="peddireddylokesh"
IMAGE_NAME="php-web-service"
IMAGE_TAG="$(date +%Y%m%d-%H%M%S)"
DOCKERFILE_PATH="Dockerfile"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --slim)
      DOCKERFILE_PATH="Dockerfile.slim"
      echo -e "${YELLOW}Using slim Dockerfile${NC}"
      shift
      ;;
    --multistage)
      DOCKERFILE_PATH="Dockerfile.multistage"
      echo -e "${YELLOW}Using multi-stage Dockerfile${NC}"
      shift
      ;;
    --tag=*)
      IMAGE_TAG="${1#*=}"
      echo -e "${YELLOW}Using custom tag: ${IMAGE_TAG}${NC}"
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}"
      echo "Usage: $0 [--slim|--multistage] [--tag=custom-tag]"
      exit 1
      ;;
  esac
done

# Check if Dockerfile exists
if [ ! -f "$DOCKERFILE_PATH" ]; then
  echo -e "${RED}Error: Dockerfile not found at $DOCKERFILE_PATH${NC}"
  exit 1
fi

# Build the image
echo -e "\n${YELLOW}Building Docker image: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}${NC}"
echo -e "${YELLOW}Using Dockerfile: ${DOCKERFILE_PATH}${NC}"

docker build \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG} \
  -t ${DOCKER_USERNAME}/${IMAGE_NAME}:latest \
  --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  --build-arg VERSION="${IMAGE_TAG}" \
  --build-arg VCS_REF="$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
  -f ${DOCKERFILE_PATH} \
  .

if [ $? -eq 0 ]; then
  echo -e "\n${GREEN}Build successful!${NC}"
  echo -e "${GREEN}Image: ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}${NC}"

  # Ask if user wants to push the image
  read -p "Do you want to push the image to Docker Hub? (y/n): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Logging in to Docker Hub...${NC}"
    docker login -u ${DOCKER_USERNAME}

    echo -e "\n${YELLOW}Pushing images...${NC}"
    docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:${IMAGE_TAG}
    docker push ${DOCKER_USERNAME}/${IMAGE_NAME}:latest

    echo -e "\n${GREEN}Images pushed successfully!${NC}"
  fi
else
  echo -e "\n${RED}Build failed!${NC}"
  exit 1
fi
