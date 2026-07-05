// =============================================================================
//  Jenkinsfile — Enterprise-Expense-Tracker  (backend + frontend)
//  STEP A: check out the repo, build the Spring Boot backend AND the React
//          frontend. Proves Jenkins can build your real app end to end.
//
//  Prereqs on the Jenkins EC2:
//    - JDK 21:   sudo apt-get install -y openjdk-21-jdk
//    - Node 20:  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash - && sudo apt-get install -y nodejs
// =============================================================================
pipeline {
  agent any

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  environment {
    // Force Java 21 for the Maven build (the app targets Java 21).
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

    // Figure out where the Maven project and frontend live, so the rest of the
    // pipeline works regardless of exact folder layout.
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
          sh "java -version"
        }
      }
    }

    stage('Build backend (Maven)') {
      steps {
        dir("${env.BACKEND_DIR}") {
          sh '''
            # Prefer the Maven wrapper if the repo ships one; else use system mvn.
            if [ -f ./mvnw ]; then
              chmod +x ./mvnw
              ./mvnw -B clean package -DskipTests
            else
              mvn -B clean package -DskipTests
            fi
          '''
        }
      }
    }

    stage('Build frontend (npm)') {
      when { expression { env.HAS_FRONTEND == 'yes' } }
      steps {
        dir('frontend') {
          sh '''
            # npm ci = clean, reproducible install from package-lock.json
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