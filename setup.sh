#!/bin/bash
#!/bin/bash

set -e

echo "Installing required tools for PHP Web Service deployment..."

# Install Docker
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo usermod -aG docker $USER
    echo "Docker installed successfully!"
else
    echo "Docker is already installed."
fi

# Install kubectl
if ! command -v kubectl &> /dev/null; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    echo "kubectl installed successfully!"
else
    echo "kubectl is already installed."
fi

# Install Minikube if not already installed
if ! command -v minikube &> /dev/null; then
    echo "Installing Minikube..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
    echo "Minikube installed successfully!"
else
    echo "Minikube is already installed."
fi

# Start Minikube if not running
if ! minikube status | grep -q "Running"; then
    echo "Starting Minikube..."
    minikube start --driver=docker
    echo "Minikube started successfully!"
else
    echo "Minikube is already running."
fi

# Enable ingress addon
echo "Enabling Minikube ingress addon..."
minikube addons enable ingress

echo "\nSetup complete! You can now deploy your PHP web service using Kubernetes.\n"
echo "Next steps:"
echo "1. Update deployment.yaml with your Docker image"
echo "2. Run './deploy.sh' to deploy your application"
echo "3. Access your application through the configured ingress"
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Jenkins (if not already installed)
# For Ubuntu/Debian:
echo "Installing Jenkins..."
if ! command -v jenkins &> /dev/null; then
    echo "Jenkins not found, installing..."
    wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
    sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
    sudo apt-get update
    sudo apt-get install -y jenkins
else
    echo "Jenkins already installed"
fi

# Install minikube for local K8s development
echo "Installing Minikube..."
if ! command -v minikube &> /dev/null; then
    echo "Minikube not found, installing..."
    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
    sudo install minikube-linux-amd64 /usr/local/bin/minikube
    rm minikube-linux-amd64
else
    echo "Minikube already installed"
fi

# Setup Minikube if needed
minikube status || minikube start --driver=docker

# Verify Kubernetes manifests
echo "Verifying Kubernetes manifests..."
chmod +x scripts/verify-manifests.sh
./scripts/verify-manifests.sh

# Install Helm
echo "Installing Helm..."
if ! command -v helm &> /dev/null; then
    echo "Helm not found, installing..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm already installed"
fi

echo "Setup complete! You can now use Docker, Kubernetes, and Jenkins for your PHP web service."
