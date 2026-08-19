pipeline {

    agent any

    environment {
        APP_NAME       = 'event-management'
        IMAGE_NAME     = 'event-management'
        IMAGE_TAG      = "${BUILD_NUMBER}"

        K8S_NAMESPACE  = 'event-management'

        PROJECT        = 'Event Managment System/Event Managment System.csproj'

        K8S_DIR        = 'k8s'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-registry-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        docker build \
                            -t "$DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG" \
                            -t "$DOCKER_USER/$IMAGE_NAME:latest" \
                            .
                    '''
                }
            }
        }

        stage('Docker Login') {
            steps {
                echo 'Logging in to Docker registry...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-registry-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASSWORD" | \
                        docker login \
                            --username "$DOCKER_USER" \
                            --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                echo 'Pushing Docker image...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-registry-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        docker push "$DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG"
                        docker push "$DOCKER_USER/$IMAGE_NAME:latest"
                    '''
                }
            }
        }

        stage('Create Namespace') {
            steps {
                echo 'Creating Kubernetes namespace if required...'

                sh '''
                    kubectl create namespace "$K8S_NAMESPACE" \
                        --dry-run=client \
                        -o yaml | kubectl apply -f -
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying application to Kubernetes...'

                sh '''
                    kubectl apply \
                        -n "$K8S_NAMESPACE" \
                        -f "$K8S_DIR/"
                '''
            }
        }

        stage('Update Application Image') {
            steps {
                echo 'Updating Kubernetes deployment image...'

                withCredentials([
                    usernamePassword(
                        credentialsId: 'docker-registry-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {
                    sh '''
                        kubectl set image \
                            deployment/"$APP_NAME" \
                            "$APP_NAME=$DOCKER_USER/$IMAGE_NAME:$IMAGE_TAG" \
                            -n "$K8S_NAMESPACE"
                    '''
                }
            }
        }

        stage('Wait for Rollout') {
            steps {
                echo 'Waiting for Kubernetes deployment...'

                sh '''
                    kubectl rollout status \
                        deployment/"$APP_NAME" \
                        -n "$K8S_NAMESPACE" \
                        --timeout=180s
                '''
            }
        }

        stage('Kubernetes Status') {
            steps {
                echo 'Checking Kubernetes resources...'

                sh '''
                    echo "========== PODS =========="
                    kubectl get pods \
                        -n "$K8S_NAMESPACE" \
                        -o wide

                    echo ""
                    echo "========== SERVICES =========="
                    kubectl get svc \
                        -n "$K8S_NAMESPACE"

                    echo ""
                    echo "========== DEPLOYMENT =========="
                    kubectl get deployment \
                        -n "$K8S_NAMESPACE"
                '''
            }
        }
    }

    post {

        success {
            withCredentials([
                usernamePassword(
                    credentialsId: 'docker-registry-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASSWORD'
                )
            ]) {
                echo """
========================================
KUBERNETES DEPLOYMENT SUCCESSFUL
========================================

Application : ${APP_NAME}
Image       : ${DOCKER_USER}/${IMAGE_NAME}:${IMAGE_TAG}
Namespace   : ${K8S_NAMESPACE}

========================================
"""
            }
        }

        failure {
            echo """
========================================
KUBERNETES DEPLOYMENT FAILED
========================================
"""

            sh '''
                echo "========== POD STATUS =========="

                kubectl get pods \
                    -n "$K8S_NAMESPACE" \
                    -o wide || true

                echo ""

                echo "========== APPLICATION LOGS =========="

                kubectl logs \
                    -n "$K8S_NAMESPACE" \
                    -l app="$APP_NAME" \
                    --tail=100 || true

                echo ""

                echo "========== POD EVENTS =========="

                kubectl get events \
                    -n "$K8S_NAMESPACE" \
                    --sort-by=.metadata.creationTimestamp \
                    | tail -30 || true
            '''
        }

        always {
            echo 'Pipeline completed.'
        }
    }
}

