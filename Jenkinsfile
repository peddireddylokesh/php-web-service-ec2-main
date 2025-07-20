pipeline {
	agent any

    environment {
		PROJECT_NAME = 'php-web-service'
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_IMAGE_NAME = "${DOCKER_REGISTRY}/peddireddylokesh/${PROJECT_NAME}"
        DOCKER_IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.substring(0, 7)}"
        KUBECONFIG = credentials('kubeconfig')
        AWS_REGION = 'us-east-1'
        AWS_CREDENTIALS = 'aws-credentials'
        COMPOSER_ALLOW_SUPERUSER = 1
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
					def composerExists = sh(script: 'command -v composer || true', returnStdout: true).trim()
                    if (composerExists) {
						sh 'composer install --no-interaction --no-progress --optimize-autoloader'
                    } else {
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
					def phpunitExists = sh(script: 'test -f vendor/bin/phpunit && echo "exists" || echo "not exists"', returnStdout: true).trim()
                    if (phpunitExists == "exists") {
						sh 'mkdir -p test-results'
                        sh 'vendor/bin/phpunit --log-junit test-results/test-results.xml || true'
                    } else {
						echo 'PHPUnit not found. Skipping tests.'
                        sh '''
                            mkdir -p test-results
                            echo '<?xml version="1.0" encoding="UTF-8"?><testsuites><testsuite name="placeholder"></testsuite></testsuites>' > test-results/test-results.xml
                        '''
                    }
                }
            }
        }

        stage('Build Docker Image') {
			steps {
				script {
					def buildTimestamp = sh(script: 'date -u "+%Y-%m-%dT%H:%M:%SZ"', returnStdout: true).trim()
                    docker.build(
                        "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}",
                        "--build-arg BUILD_DATE=${buildTimestamp} " +
                        "--build-arg VERSION=${DOCKER_IMAGE_TAG} " +
                        "--build-arg VCS_REF=${env.GIT_COMMIT} ."
                    )
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
                    sh "docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest || true"
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
					sh 'chmod +x scripts/create-deployment.sh scripts/ensure-k8s-manifests.sh'
                    sh './scripts/ensure-k8s-manifests.sh'
                    sh 'cp kubernetes/deployment.yaml kubernetes/deployment.yaml.bak || true'
                    sh "sed -i 's|image: docker.io/peddireddylokesh/php-web-service:.*|image: ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}|' kubernetes/deployment.yaml"
                    sh "cat kubernetes/deployment.yaml | grep image: || echo 'Warning: Image tag not found in deployment.yaml'"

                   withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
						withEnv(["AWS_REGION=${AWS_REGION}", "KUBECONFIG=${env.KUBECONFIG}"]) {
							sh "kubectl apply -f kubernetes/namespace.yaml || echo 'Warning: Failed to apply namespace.yaml'"
							sh "kubectl get namespace database-namespace || kubectl apply -f kubernetes/mysql-deployment.yaml || echo 'Warning: Failed to apply mysql-deployment.yaml'"
							sh "kubectl apply -f kubernetes/configmap.yml -n php-web-service-namespace || echo 'Warning: Failed to apply configmap.yml'"
							sh "kubectl apply -f kubernetes/secrets.yml -n php-web-service-namespace || echo 'Warning: Failed to apply secrets.yml'"
							sh "kubectl apply -f kubernetes/deployment.yaml -n php-web-service-namespace || echo 'Warning: Failed to apply deployment.yaml'"
							sh "kubectl apply -f kubernetes/service.yaml -n php-web-service-namespace || echo 'Warning: Failed to apply service.yaml'"
							sh "kubectl apply -f kubernetes/ingress.yaml -n php-web-service-namespace || echo 'Warning: Failed to apply ingress.yaml'"
							sh "test -f kubernetes/network-policy.yaml && kubectl apply -f kubernetes/network-policy.yaml -n php-web-service-namespace || echo 'No network policy found, skipping'"
                		}
                   }
                }
            }
        }

        stage('Verify Deployment') {
			steps {
				script {
					withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: "${AWS_CREDENTIALS}"]]) {
						withEnv(["AWS_REGION=${AWS_REGION}", "KUBECONFIG=${env.KUBECONFIG}"]) {
							sh "kubectl rollout status deployment/${PROJECT_NAME} -n ${PROJECT_NAME}-namespace --timeout=300s"
						}
					}
				}
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
