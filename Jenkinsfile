// =============================================================================
// Jenkinsfile — Enterprise-Expense-Tracker
// Builds Spring Boot backend + React frontend + SonarQube Analysis
// =============================================================================

pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
        PATH = "${JAVA_HOME}/bin:${env.PATH}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'git log -1 --oneline'
            }
        }

        stage('Detect Layout') {
            steps {
                script {

                    if (fileExists('backend/pom.xml')) {
                        env.BACKEND_DIR = 'backend'
                    }
                    else if (fileExists('pom.xml')) {
                        env.BACKEND_DIR = '.'
                    }
                    else {
                        error 'No pom.xml found at repository root or backend/'
                    }

                    env.HAS_FRONTEND = fileExists('frontend/package.json') ? 'yes' : 'no'

                    echo "Backend Directory : ${env.BACKEND_DIR}"
                    echo "Frontend Present  : ${env.HAS_FRONTEND}"

                    sh 'java -version'
                }
            }
        }

        stage('Build Backend') {
            steps {
                dir("${env.BACKEND_DIR}") {
                    sh '''
                        if [ -f ./mvnw ]; then
                            chmod +x mvnw
                            ./mvnw -B clean package -DskipTests
                        else
                            mvn -B clean package -DskipTests
                        fi
                    '''
                }
            }
        }

        stage('Build Frontend') {
            when {
                expression {
                    env.HAS_FRONTEND == 'yes'
                }
            }

            steps {
                dir('frontend') {
                    sh '''
                        npm ci
                        npm run build
                    '''
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir("${env.BACKEND_DIR}") {
                    withSonarQubeEnv('SonarQube') {
                        sh '''
                            if [ -f ./mvnw ]; then
                                ./mvnw -B sonar:sonar \
                                    -Dsonar.projectKey=expense-tracker \
                                    -Dsonar.projectName=expense-tracker
                            else
                                mvn -B sonar:sonar \
                                    -Dsonar.projectKey=expense-tracker \
                                    -Dsonar.projectName=expense-tracker
                            fi
                        '''
                    }
                }
            }
        }

        stage('Quality Gate') {
            steps {
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }

    }

    post {

        success {
            archiveArtifacts(
                artifacts: "${env.BACKEND_DIR}/target/*.jar",
                fingerprint: true,
                allowEmptyArchive: true
            )

            echo "Build completed successfully."
        }

        failure {
            echo "Build failed. Check the Jenkins logs."
        }

        always {
            cleanWs()
        }
    }
}