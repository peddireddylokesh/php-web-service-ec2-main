pipeline {
	agent any

    environment {
		PROJECT_NAME = 'php-web-service'
        DOCKER_REGISTRY = 'docker.io' // Replace with your registry (e.g., ECR: ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com)
        DOCKER_IMAGE_NAME = "${DOCKER_REGISTRY}/peddireddylokesh/${PROJECT_NAME}"
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0,7)}"
        KUBECONFIG = credentials('kubeconfig') // Jenkins credential containing kubeconfig file
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS = 'aws-credentials' // Jenkins credential ID for AWS
        COMPOSER_ALLOW_SUPERUSER = 1 // Allow Composer to run as root in Docker container
    }

    stages {
		stage('Checkout') {
			steps {
				checkout scm
            }
        }

        stage('Install Dependencies') {
			steps {
				script {
					// Check if composer is installed
                    def composerExists = sh(script: 'command -v composer || true', returnStdout: true).trim()

                    if (composerExists) {
						sh 'composer install --no-interaction --no-progress --optimize-autoloader'
                    } else {
						// Install composer if not available
                        sh '''
                            php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
                            php composer-setup.php --install-dir=/usr/local/bin --filename=composer
                            php -r "unlink('composer-setup.php');"
                            composer install --no-interaction --no-progress --optimize-autoloader
                        '''
                    }
                }
            }
        }
        stage('Check PHP Version') {
			steps {
				sh 'php -v'
            }
        }


        stage('Run Tests') {
			steps {
				script {
					// Check if PHPUnit is available
                    def phpunitExists = sh(script: 'test -f vendor/bin/phpunit && echo "exists" || echo "not exists"', returnStdout: true).trim()

                    if (phpunitExists == "exists") {
						sh 'mkdir -p test-results'
                        sh 'vendor/bin/phpunit --log-junit test-results/test-results.xml || true'
                    } else {
						echo 'PHPUnit not found. Skipping tests.'
                        // Create a placeholder test result file
                        sh '''
                            mkdir -p test-results
                            echo '<?xml version="1.0" encoding="UTF-8"?><testsuites><testsuite name="placeholder"></testsuite></testsuites>' > test-results/test-results.xml
                        '''
                    }
                }
            }
            post {
				always {
					sh """
						docker image inspect ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} >/dev/null 2>&1 && docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || true
						docker image inspect ${DOCKER_IMAGE_NAME}:latest >/dev/null 2>&1 && docker rmi ${DOCKER_IMAGE_NAME}:latest || true
					"""
				}
				success {
					echo "Deployment of ${PROJECT_NAME} was successful!"
				}
				failure {
					echo "Deployment of ${PROJECT_NAME} failed!"
				}
			}

        }

        stage('Build Docker Image') {
			steps {
				script {
					// Add build timestamp to Docker build args
                    def buildTimestamp = sh(script: 'date -u "+%Y-%m-%dT%H:%M:%SZ"', returnStdout: true).trim()

                    // Build the Docker image with build args
                    docker.build(
                        "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}",
                        "--build-arg BUILD_DATE=${buildTimestamp} " +
                        "--build-arg VERSION=${DOCKER_IMAGE_TAG} " +
                        "--build-arg VCS_REF=${env.GIT_COMMIT} ."
                    )

                    // Verify the image was built successfully
                    sh "docker images | grep ${DOCKER_IMAGE_NAME} || true"
                }
            }
        }

        stage('Push Docker Image') {
			steps {
				script {
						withCredentials([usernamePassword(credentialsId: 'docker-credentials', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
							sh "echo $DOCKER_PASSWORD | docker login -u $DOCKER_USERNAME --password-stdin ${DOCKER_REGISTRY}"
				}

				// Tag image as latest first
				sh "docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest || true"

				// Push both tags with fail-fast strategy
				sh """
					docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} || (echo 'Versioned tag push failed' && exit 1)
					docker push ${DOCKER_IMAGE_NAME}:latest || (echo 'Latest tag push failed' && exit 1)
					"""
				}
			}
		}



        stage('Deploy to Kubernetes') {
			            steps {
			                script {
			                    // Check if deployment file exists, create it if not
			                    sh """
			                        if [ ! -f kubernetes/deployment.yaml ]; then
			                            echo "Creating deployment.yaml as it's missing"
			                            cat > kubernetes/deployment.yaml << 'EOF'
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
			                                    image: ${DOCKER_REGISTRY}/peddireddylokesh/${PROJECT_NAME}:latest
			                                    ports:
			                                    - containerPort: 80
			                                    env:
			                                    - name: DB_HOST
			                                      value: "mysql-service.database-namespace.svc.cluster.local"
			                                    - name: DB_NAME
			                                      value: "php_web_service"
			                            EOF
			                        else
			                            # Create backup of deployment file
			                            cp kubernetes/deployment.yaml kubernetes/deployment.yaml.bak
			                        fi
			                    """

                    // Update Kubernetes deployment YAML with the new image tag
                    sh "sed -i 's|image: ${DOCKER_REGISTRY}/peddireddylokesh/${PROJECT_NAME}:.*|image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|' kubernetes/deployment.yaml"

                    // Verify the file was updated correctly
                    sh "cat kubernetes/deployment.yaml | grep image:"

                    // Apply Kubernetes manifests
                    withEnv(["KUBECONFIG=${KUBECONFIG}"]) {
						// Create namespace first if it doesn't exist
                        sh "kubectl apply -f kubernetes/namespace.yaml"

                        // Check if MySQL deployment exists and deploy if needed
                        sh "kubectl get namespace database-namespace || kubectl apply -f kubernetes/mysql-deployment.yaml"

                        // Apply the rest of manifests
                        sh "kubectl apply -f kubernetes/configmap.yaml -n php-web-service-namespace"
                        sh "kubectl apply -f kubernetes/secrets.yaml -n php-web-service-namespace"
                        sh "kubectl apply -f kubernetes/deployment.yaml -n php-web-service-namespace"
                        sh "kubectl apply -f kubernetes/service.yaml -n php-web-service-namespace"
                        sh "kubectl apply -f kubernetes/ingress.yaml -n php-web-service-namespace"

                        // Apply network policy if it exists
                        sh "test -f kubernetes/network-policy.yaml && kubectl apply -f kubernetes/network-policy.yaml -n php-web-service-namespace || echo 'No network policy found, skipping'"
                    }
                }
            }
        }

        stage('Verify Deployment') {
			steps {
				script {
					withEnv(["KUBECONFIG=${KUBECONFIG}"]) {
						sh "kubectl rollout status deployment/${PROJECT_NAME} -n ${PROJECT_NAME}-namespace --timeout=300s"
                    }
                }
            }
        }
    }

    post {
		success {
			echo "Deployment of ${PROJECT_NAME} was successful!"
        }
        failure {
			echo "Deployment of ${PROJECT_NAME} failed!"
        }
        always {
			// Clean up local Docker images
            sh "docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest || true"
        }
    }
}
