// =============================================================================
//  Jenkinsfile — STEP A: check out the repo and build the Spring Boot app.
//
//  This is the first, minimal pipeline. It proves Jenkins can:
//    1. pull your code from GitHub, and
//    2. build + test it with Maven.
//
//  We'll add SonarQube (Step B) and docker build/push (Step C) after this runs
//  green. Place this file at the ROOT of your GitHub repo (pom.xml is in code/).
// =============================================================================
pipeline {
  agent any

  options {
    timestamps()                 // timestamp every log line
    disableConcurrentBuilds()    // don't run two builds of this job at once
  }

  stages {

    stage('Checkout') {
      steps {
        // Uses the Git repo configured in the Jenkins job (Pipeline from SCM).
        checkout scm
        sh 'git log -1 --oneline'
      }
    }

    stage('Build & Test') {
      steps {
        // pom.xml lives in the code/ subfolder, so build from there.
        dir('code') {
          sh 'mvn -B clean package'
        }
      }
    }
  }

  post {
    success {
      // Save the built jar so you can download it from the build page.
      archiveArtifacts artifacts: 'code/target/*.jar', fingerprint: true
      echo 'BUILD OK — jar produced.'
    }
    failure {
      echo 'BUILD FAILED — check the stage logs above.'
    }
  }
}
