// =============================================================================
//  Jenkinsfile — Enterprise-Expense-Tracker  (backend + frontend + SonarQube)
//
//  The Quality Gate stage is NON-BLOCKING: whatever SonarQube reports (pass,
//  fail, or even a webhook timeout), the build continues and stays SUCCESS.
// =============================================================================
pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    JAVA_HOME = '/usr/lib/jvm/java-21-openjdk-amd64'
    PATH      = "${JAVA_HOME}/bin:${env.PATH}"
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
            error 'No pom.xml found at repo root or in backend/ — check the repo layout.'
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

    // NON-BLOCKING quality gate: never fails the build.
    stage('Quality Gate') {
      steps {
        catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
          timeout(time: 3, unit: 'MINUTES') {
            script {
              def qg = waitForQualityGate abortPipeline: false
              echo "SonarQube Quality Gate status: ${qg.status}"
            }
          }
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
  }

  post {
    success {
      archiveArtifacts artifacts: "${env.BACKEND_DIR}/target/*.jar",
                       fingerprint: true, allowEmptyArchive: true
      echo 'BUILD OK — backend jar built' + (env.HAS_FRONTEND == 'yes' ? ' + frontend built.' : '.')
    }
    failure {
      echo 'BUILD FAILED — check the stage logs above.'
    }
  }
}