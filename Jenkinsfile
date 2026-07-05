pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
    PATH      = "${JAVA_HOME}/bin:${env.PATH}"
    TAG       = "${env.BUILD_NUMBER}"
  }

  stages {

    stage('Checkout') {
      steps {
        checkout scm
        sh 'git log -1 --oneline'
      }
    }

    stage('Detect layout') {
      steps {
        script {
          if (fileExists('backend/pom.xml')) {
            env.BACKEND_DIR = 'backend'
          } else if (fileExists('pom.xml')) {
            env.BACKEND_DIR = '.'
          } else {
            error 'No pom.xml found at repo root or in backend/.'
          }
          env.HAS_FRONTEND = fileExists('frontend/package.json') ? 'yes' : 'no'
          echo "Backend dir     : ${env.BACKEND_DIR}"
          echo "Frontend present: ${env.HAS_FRONTEND}"
          sh 'java -version'
        }
      }
    }

    stage('Build backend (Maven)') {
      steps {
        dir("${env.BACKEND_DIR}") {
          sh 'mvn -B clean package -DskipTests'
        }
      }
    }

    stage('SonarQube Analysis') {
      steps {
        dir("${env.BACKEND_DIR}") {
          withSonarQubeEnv('SonarQube') {
            sh '''
              mvn -B sonar:sonar \
                -Dsonar.projectKey=expense-tracker \
                -Dsonar.projectName=expense-tracker
            '''
          }
        }
      }
    }

    stage('Quality Gate') {
      steps {
        timeout(time: 5, unit: 'MINUTES') {
          waitForQualityGate abortPipeline: false
        }
      }
    }

    stage('Build frontend (npm)') {
      when { expression { env.HAS_FRONTEND == 'yes' } }
      steps {
        dir('frontend') {
          sh '''
            npm ci
            npm run build
          '''
        }
      }
    }

    stage('Docker Build & Push') {
      steps {
        withCredentials([usernamePassword(credentialsId: 'dockerhub-creds',
                         usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
          sh '''
            set -e
            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin

            BE="$DH_USER/expense-tracker-backend"
            FE="$DH_USER/expense-tracker-frontend"

            docker build -t "$BE:$TAG" -t "$BE:latest" "$BACKEND_DIR"
            docker build -t "$FE:$TAG" -t "$FE:latest" frontend

            docker push "$BE:$TAG"
            docker push "$BE:latest"
            docker push "$FE:$TAG"
            docker push "$FE:latest"

            docker logout
          '''
        }
      }
    }
  }

  post {
    success {
      archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar",
                       fingerprint: true, allowEmptyArchive: true
      echo "BUILD OK — images pushed with tag ${env.TAG} (and :latest)."
    }
    failure {
      echo 'BUILD FAILED — check the stage logs above.'
    }
    always {
      sh 'docker image prune -f || true'
    }
  }
}