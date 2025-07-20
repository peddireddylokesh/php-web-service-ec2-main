# Kubernetes Manifests

This directory contains all the Kubernetes manifests required to deploy the PHP Web Service application.

## Required Files

- **namespace.yaml**: Creates the dedicated namespace for the application
- **deployment.yaml**: Defines the application pods and deployment strategy
- **service.yaml**: Creates a service to expose the application within the cluster
- **ingress.yaml**: Sets up external access to the application
- **configmap.yml**: Contains non-sensitive configuration parameters
- **secrets.yml**: Contains sensitive information like database credentials

## Optional Files

- **network-policy.yaml**: Defines network security rules
- **hpa.yaml**: Horizontal Pod Autoscaler for scaling
- **pdb.yaml**: Pod Disruption Budget for availability

## Troubleshooting

If any of these files are missing, you can generate them by running:

```bash
./scripts/ensure-k8s-manifests.sh
```

If you're experiencing issues with your Jenkins pipeline related to these files, try running:

```bash
./scripts/fix-jenkins-pipeline.sh
```

## File Extensions

Note that some files use the `.yaml` extension while others use `.yml`. Both are valid YAML file extensions, but the scripts in this project expect the specific extensions mentioned above.

## Versioning

The deployment configuration will be updated automatically by the CI/CD pipeline with the current image tag.
