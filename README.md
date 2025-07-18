# PHP Web Service with Docker and Kubernetes

This project demonstrates deploying a PHP web service using Docker, Kubernetes, and Jenkins CI/CD pipeline.

## Prerequisites

- Docker
- Kubernetes (Minikube or a cloud provider)
- kubectl
- Jenkins

## Quick Start

### Using Automated Setup

Run the setup script to install all required tools:

```bash
chmod +x setup.sh
./setup.sh
```

### Manual Deployment

Run the deployment script:

```bash
chmod +x deploy.sh
./deploy.sh
```

### Using Jenkins Pipeline

1. Configure Jenkins with required plugins and credentials
2. Create a new pipeline job using the Jenkinsfile
3. Run the pipeline

## Project Structure

```
├── Dockerfile          # Docker image definition
├── Jenkinsfile         # Jenkins CI/CD pipeline
├── kubernetes/         # Kubernetes manifests
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── ingress.yaml
│   ├── namespace.yaml
│   ├── network-policy.yaml
│   ├── secrets.yaml
│   └── service.yaml
├── src/                # Application source code
├── setup.sh            # Setup script for tools installation
└── deploy.sh           # Deployment script
```

## Configuration

### Docker

The application is containerized using Docker. You can customize the Docker image by editing the `Dockerfile`.

### Kubernetes

Kubernetes manifests are located in the `kubernetes/` directory:
# PHP Web Service with Docker and Kubernetes

This project demonstrates deploying a PHP web service using Docker, Kubernetes, and Jenkins CI/CD pipeline.

## Quick Start

### Setup

1. Install required tools:

```bash
chmod +x setup.sh
./setup.sh
```

This script installs Docker, kubectl, and Minikube (for local development).

### Deployment

To deploy the application:

```bash
chmod +x deploy.sh
./deploy.sh
```

The deployment script will:
- Build a Docker image
- Deploy the application to Kubernetes
- Set up port forwarding for local testing

## Structure

- `Dockerfile`: PHP 8.0 with Apache configuration
- `kubernetes/`: Kubernetes manifests
  - `namespace.yaml`: Creates php-web-service-namespace
  - `deployment.yaml`: Defines application deployment
  - `service.yaml`: Exposes the application
  - `ingress.yaml`: Sets up external access
  - `configmap.yaml`: Application configuration
  - `secrets.yaml`: Sensitive data
  - `mysql-deployment.yaml`: Database deployment
- `Jenkinsfile`: CI/CD pipeline definition
- `health.php`: Health check endpoint

## Using Jenkins

1. Install the required Jenkins plugins:
   - Docker Pipeline
   - Kubernetes CLI

2. Configure Jenkins credentials:
   - Docker Hub credentials (ID: docker-credentials)
   - Kubernetes config file (ID: kubeconfig)

3. Create a new pipeline job using the Jenkinsfile

## Accessing the Application

- Local development: http://localhost:8080 (via port forwarding)
- With Minikube: `minikube service php-web-service -n php-web-service-namespace`
- Production: Configure your domain in ingress.yaml

## Monitoring

```bash
# View all resources
kubectl get all -n php-web-service-namespace

# Check logs
kubectl logs deployment/php-web-service -n php-web-service-namespace
```
- `namespace.yaml`: Creates a dedicated namespace
- `deployment.yaml`: Defines the application deployment
- `service.yaml`: Exposes the application within the cluster
- `ingress.yaml`: Exposes the application externally
- `configmap.yaml`: Stores non-sensitive configuration
- `secrets.yaml`: Stores sensitive information
- `network-policy.yaml`: Defines network security rules

### Jenkins Pipeline

The CI/CD pipeline is defined in the `Jenkinsfile` and includes stages for:

1. Checking out code
2. Installing dependencies
3. Running tests
4. Building and pushing the Docker image
5. Deploying to Kubernetes
6. Verifying the deployment

## Accessing the Application

After deployment, the application can be accessed:

- **Local development**: `http://localhost:8080` (after running port forwarding)
- **Minikube**: `minikube service php-web-service -n php-web-service-namespace`
- **Production**: Configure your domain in `ingress.yaml`

## Monitoring and Management

Check the status of your deployment:

```bash
kubectl get all -n php-web-service-namespace
```

View application logs:

```bash
kubectl logs -f deployment/php-web-service -n php-web-service-namespace
```

## Security Considerations

- Update the secrets with proper values before deploying
- The network policy restricts traffic to necessary services only
- Database credentials are stored as Kubernetes secrets

## License

MIT
