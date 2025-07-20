#!/bin/bash

# Script to create deployment.yaml if it doesn't exist

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
K8S_DIR="${PROJECT_ROOT}/kubernetes"

# Create kubernetes directory if it doesn't exist
mkdir -p "${K8S_DIR}"

# Check if deployment.yaml exists
if [ ! -f "${K8S_DIR}/deployment.yaml" ]; then
    echo "Creating deployment.yaml as it doesn't exist"

    cat > "${K8S_DIR}/deployment.yaml" << 'EOF'
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
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: php-web-service
    spec:
      containers:
      - name: php-web-service
        image: docker.io/peddireddylokesh/php-web-service:latest
        imagePullPolicy: Always
        ports:
        - containerPort: 80
          name: http
        resources:
          limits:
            cpu: "500m"
            memory: "512Mi"
          requests:
            cpu: "200m"
            memory: "256Mi"
        livenessProbe:
          httpGet:
            path: /health.php
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
        readinessProbe:
          httpGet:
            path: /health.php
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        env:
        - name: DB_HOST
          value: "mysql-service.database-namespace.svc.cluster.local"
        - name: DB_NAME
          value: "php_web_service"
        - name: DB_USER
          valueFrom:
            secretKeyRef:
              name: php-web-service-secrets
              key: db-username
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: php-web-service-secrets
              key: db-password
        - name: APP_ENV
          valueFrom:
            configMapKeyRef:
              name: php-web-service-config
              key: app.environment
              optional: true
        - name: DEBUG_MODE
          valueFrom:
            configMapKeyRef:
              name: php-web-service-config
              key: app.debug
              optional: true
        volumeMounts:
        - name: config-volume
          mountPath: /var/www/html/config
          optional: true
      volumes:
      - name: config-volume
        configMap:
          name: php-web-service-config
          optional: true
      securityContext:
        runAsUser: 33 # www-data user in Apache container
        fsGroup: 33
      terminationGracePeriodSeconds: 30
EOF

    echo "deployment.yaml created successfully"
else
    echo "deployment.yaml already exists"
fi
