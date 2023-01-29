
pipeline {

    parameters {
        string(name: 'DOCKER_REGISTRY_URL', defaultValue: 'harbor.stacktonic.com.au', description: 'How should I store the Image?')
        string(name: 'IMAGE_NAME', defaultValue: 'stacktonic/alpine', description: 'How should I store the Image?')
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Do we have a speical TAG?')
    }

    agent {
        kubernetes {
            yaml '''
---
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: docker
    image: docker:dind
    securityContext:
      privileged: true
    env:
    - name: DOCKER_TLS_CERTDIR
      value: ""
'''
        }
    }
    
    environment {
        IMAGE_NAME="${params.IMAGE_NAME}"
        IMAGE_TAG="${params.IMAGE_TAG}"
        BRANCH_NAME= 'main'
        REPOSITORY_URL= 'https://github.com/StackTonic/docker-alpine.git'
        DOCKER_REGISTRY_URL="${params.DOCKER_REGISTRY_URL}"
    }
    stages {
        stage('Get Code') {
            steps {
                git branch:'main', url: 'https://github.com/StackTonic/docker-alpine.git'
            }
        }
        stage('Login to Docker') {
            steps {
                container('docker') {
                    withCredentials([usernamePassword(credentialsId: 'a0cdec83-46ce-49ab-b524-17f748b737db', passwordVariable: 'repo_pass', usernameVariable: 'repo_user')]) {
                        sh "docker login -u ${repo_user} -p ${repo_pass} ${DOCKER_REGISTRY_URL}"
                    }
                }
            }
        }

        stage('Build') { 
            steps {
                container('docker') {
                    sh 'printenv'
                    sh 'docker info'
                    sh "docker build --network host -t ${IMAGE_NAME}:build-${BUILD_ID} ."
                }
            }
        }
            
        stage('Test'){
            steps {
                sh 'echo Testing'
            }
        }
        
        stage('Publish') {
            steps {
                container('docker') {
                    script {
                        sh 'docker tag ${IMAGE_NAME}:build-${BUILD_ID} ${DOCKER_REGISTRY_URL}/${IMAGE_NAME}:latest'
                        sh 'docker tag ${IMAGE_NAME}:build-${BUILD_ID} ${DOCKER_REGISTRY_URL}/${IMAGE_NAME}:build-${BUILD_ID}'
                        sh 'docker push ${DOCKER_REGISTRY_URL}/${IMAGE_NAME}:build-${BUILD_ID}'
                        sh 'docker push ${DOCKER_REGISTRY_URL}/${IMAGE_NAME}:latest'
                    }
                }
            }
        }
    }
}