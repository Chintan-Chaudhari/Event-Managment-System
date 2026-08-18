pipeline {

    agent any

    environment {
        APP_NAME       = 'event-management'
        IMAGE_NAME     = 'event-management'
        NETWORK_NAME   = 'event-network'

        PROJECT        = 'Event Managment System/Event Managment System.csproj'
        SOLUTION       = 'Event Managment System.sln'
        PUBLISH_DIR    = 'publish'

        // Application container port
        CONTAINER_PORT = '8084'

        // Host port used by Nginx
        HOST_PORT      = '5000'

        // Production environment file
        ENV_FILE       = '/etc/event-management/event-management.env'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Restore') {
            steps {
                echo 'Restoring NuGet packages...'

                sh '''
                    dotnet restore "$SOLUTION"
                '''
            }
        }

        stage('Build') {
            steps {
                echo 'Building application...'

                sh '''
                    dotnet build "$SOLUTION" \
                        --configuration Release \
                        --no-restore
                '''
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'

                sh '''
                    TEST_PROJECTS=$(find . \
                        \\( -name "*Tests.csproj" -o -name "*Test.csproj" \\))

                    if [ -n "$TEST_PROJECTS" ]; then
                        dotnet test "$SOLUTION" \
                            --configuration Release \
                            --no-build \
                            --verbosity normal
                    else
                        echo "No test projects found. Skipping tests."
                    fi
                '''
            }
        }

        stage('Publish') {
            steps {
                echo 'Publishing ASP.NET Core application...'

                sh '''
                    rm -rf "$PUBLISH_DIR"

                    dotnet publish "$PROJECT" \
                        --configuration Release \
                        --no-restore \
                        --output "$PUBLISH_DIR"
                '''
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'

                sh '''
                    docker build \
                        -t ${IMAGE_NAME}:${BUILD_NUMBER} \
                        -t ${IMAGE_NAME}:latest \
                        .
                '''
            }
        }

        stage('Docker Network') {
            steps {
                echo 'Checking Docker network...'

                sh '''
                    if ! docker network inspect "$NETWORK_NAME" >/dev/null 2>&1; then
                        echo "Creating Docker network: $NETWORK_NAME"
                        docker network create "$NETWORK_NAME"
                    else
                        echo "Docker network already exists: $NETWORK_NAME"
                    fi
                '''
            }
        }

        stage('Deploy Docker Container') {
            steps {
                echo 'Deploying Docker container...'

                sh '''
                    set -e

                    echo "Stopping old container..."

                    docker rm -f "$APP_NAME" 2>/dev/null || true

                    echo "Starting new container..."

                    docker run -d \
                        --name "$APP_NAME" \
                        --restart unless-stopped \
                        --network "$NETWORK_NAME" \
                        --env-file "$ENV_FILE" \
                        -e ASPNETCORE_ENVIRONMENT=Production \
                        -e ASPNETCORE_URLS=http://0.0.0.0:${CONTAINER_PORT} \
                        -p ${HOST_PORT}:${CONTAINER_PORT} \
                        "$IMAGE_NAME:${BUILD_NUMBER}"

                    echo "Container started."

                    docker ps \
                        --filter "name=$APP_NAME"
                '''
            }
        }

        stage('Docker Health Check') {
            steps {
                echo 'Checking Docker container health...'

                sh '''
                    set -e

                    echo "Waiting for application to start..."
                    sleep 10

                    if ! docker ps --filter "name=$APP_NAME" --filter "status=running" | grep -q "$APP_NAME"; then
                        echo "Container is not running."
                        docker logs "$APP_NAME" --tail 100
                        exit 1
                    fi

                    echo "Testing application..."

                    curl --fail \
                        --silent \
                        --show-error \
                        http://127.0.0.1:${HOST_PORT}/ \
                        > /dev/null

                    echo "Application is UP"
                '''
            }
        }

        stage('Docker Status') {
            steps {
                echo 'Docker deployment status...'

                sh '''
                    docker ps \
                        --filter "name=$APP_NAME" \
                        --format "table {{.Names}}\\t{{.Image}}\\t{{.Status}}\\t{{.Ports}}"
                '''
            }
        }
    }

    post {

        success {
            echo '''
========================================
CI/CD DOCKER DEPLOYMENT SUCCESSFUL
========================================
Application : event-management
Image       : event-management:${BUILD_NUMBER}
Network     : event-network
Host Port   : 127.0.0.1:5000
========================================
'''
        }

        failure {
            echo '''
========================================
CI/CD DOCKER DEPLOYMENT FAILED
========================================
Showing container logs...
========================================
'''

            sh '''
                docker logs "$APP_NAME" --tail 100 2>/dev/null || true
            '''
        }

        always {
            echo 'Pipeline completed.'
        }
    }
}
