#!/bin/bash

# Script to fix common Jenkins pipeline issues

set -e

# Colors for output
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
NC="\033[0m" # No Color

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}Jenkins Pipeline Fix Script${NC}"
echo -e "${GREEN}=======================================${NC}"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Fix 1: Ensure all required scripts exist and are executable
echo -e "\n${YELLOW}Fix 1: Ensuring scripts exist and are executable...${NC}"
mkdir -p "${SCRIPT_DIR}"

for script in create-deployment.sh ensure-k8s-manifests.sh verify-manifests.sh; do
    if [ ! -f "${SCRIPT_DIR}/${script}" ]; then
        echo -e "${RED}Error: ${script} is missing!${NC}"
        echo -e "Please run git pull to update your repository or create the script manually."
    else
        chmod +x "${SCRIPT_DIR}/${script}"
        echo -e "${GREEN}Made ${script} executable.${NC}"
    fi
done

# Fix 2: Create the kubernetes directory if it doesn't exist
echo -e "\n${YELLOW}Fix 2: Ensuring kubernetes directory exists...${NC}"
mkdir -p "${PROJECT_ROOT}/kubernetes"
echo -e "${GREEN}Kubernetes directory created/verified.${NC}"

# Fix 3: Run the manifest creation script
echo -e "\n${YELLOW}Fix 3: Creating required Kubernetes manifests...${NC}"
if [ -f "${SCRIPT_DIR}/ensure-k8s-manifests.sh" ]; then
    "${SCRIPT_DIR}/ensure-k8s-manifests.sh"
fi

# Fix 4: Check Jenkinsfile for heredoc issues
echo -e "\n${YELLOW}Fix 4: Checking Jenkinsfile for heredoc issues...${NC}"
if [ -f "${PROJECT_ROOT}/Jenkinsfile" ]; then
    # Look for potential heredoc issues
    if grep -q "<<\s*EOF" "${PROJECT_ROOT}/Jenkinsfile"; then
        echo -e "${YELLOW}Warning: Found potential heredoc issues in Jenkinsfile.${NC}"
        echo -e "Consider using 'EOFMARKER' instead of 'EOF' as the delimiter and make sure it appears at the beginning of the line."
    else
        echo -e "${GREEN}No obvious heredoc issues found.${NC}"
    fi
fi

# Fix 5: Check file references in Jenkinsfile
echo -e "\n${YELLOW}Fix 5: Checking file references in Jenkinsfile...${NC}"
if [ -f "${PROJECT_ROOT}/Jenkinsfile" ]; then
    # Check for references to .yaml vs .yml
    if grep -q "configmap.yaml" "${PROJECT_ROOT}/Jenkinsfile" && [ -f "${PROJECT_ROOT}/kubernetes/configmap.yml" ]; then
        echo -e "${YELLOW}Warning: Jenkinsfile references configmap.yaml but file is named configmap.yml${NC}"
    fi

    if grep -q "secrets.yaml" "${PROJECT_ROOT}/Jenkinsfile" && [ -f "${PROJECT_ROOT}/kubernetes/secrets.yml" ]; then
        echo -e "${YELLOW}Warning: Jenkinsfile references secrets.yaml but file is named secrets.yml${NC}"
    fi
fi

echo -e "\n${GREEN}Pipeline fix script completed.${NC}"
echo -e "${GREEN}Run your Jenkins pipeline again to see if the issues are resolved.${NC}"
