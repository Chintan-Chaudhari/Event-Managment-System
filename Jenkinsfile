pipeline {

    agent any

    environment {
        APP_NAME = 'event-management'
        APP_DIR = '/var/www/event-management'
        PROJECT = 'Event Managment System/Event Managment System.csproj'
        SOLUTION = 'Event Managment System.sln'
        PUBLISH_DIR = 'publish'
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
                sh 'dotnet restore "$SOLUTION"'
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
                    TEST_PROJECTS=$(find . -name "*Tests.csproj" -o -name "*Test.csproj")

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

        stage('Deploy') {
   	    steps {
       	        echo 'Deploying application...'
                sh 'sudo /usr/local/bin/deploy-event-management.sh'
   		 }
	    }

        stage('Health Check') {
            steps {
                echo 'Checking application health...'

                sh '''
                    sleep 5

                    curl --fail \
                        --silent \
                        --show-error \
                        http://127.0.0.1:5000/ \
                        > /dev/null

                    echo "Application is UP"
                '''
            }
        }
    }

    post {

        success {
            echo '======================================'
            echo 'CI/CD DEPLOYMENT SUCCESSFUL'
            echo '======================================'
        }

        failure {
            echo '======================================'
            echo 'CI/CD DEPLOYMENT FAILED'
            echo '======================================'
        }

        always {
            echo 'Pipeline completed.'
        }
    }
}
