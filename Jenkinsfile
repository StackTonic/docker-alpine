
pipeline {

    parameters {
        string(name: 'BASE_DOCKER_REGISTRY_URL', defaultValue: 'registry.hub.docker.com', description: 'Where should I get the base image?')
        string(name: 'BASE_IMAGE_NAME', defaultValue: 'library/alpine', description: 'What is the base image name?')
        string(name: 'BASE_IMAGE_TAG', defaultValue: '3.17', description: 'Do we have a speical base image tag?')

        string(name: 'DOCKER_REGISTRY_URL', defaultValue: 'harbor.stacktonic.au', description: 'How should I store the image?')
        string(name: 'IMAGE_NAME', defaultValue: 'stacktonic/alpine', description: 'How should I store the image?')
        string(name: 'IMAGE_TAG', defaultValue: 'latest', description: 'Do we have a speical tag?')
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
        BASE_IMAGE_NAME="${params.BASE_IMAGE_NAME}"
        BASE_IMAGE_TAG="${params.BASE_IMAGE_TAG}"
        BASE_REPOSITORY_URL="${params.BASE_DOCKER_REGISTRY_URL}"
        IMAGE_NAME="${params.IMAGE_NAME}"
        IMAGE_TAG="${params.IMAGE_TAG}"
        REPOSITORY_URL= 'https://git.stacktonic.au/StackTonic/docker-alpine.git'
        BRANCH_NAME= 'main'
        DOCKER_REGISTRY_URL="${params.DOCKER_REGISTRY_URL}"
    }
    stages {
        stage('Get Code') {
            steps {
                git branch:'main', url: 'https://git.stacktonic.au/StackTonic/docker-alpine.git'
            }
        }
        stage('Login to Docker registry') {
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
                    sh "docker build --network host -t ${IMAGE_NAME}:build-${BUILD_ID} --build-arg BASE_REPOSITORY_URL=${BASE_REPOSITORY_URL} --build-arg BASE_IMAGE_NAME=${BASE_IMAGE_NAME} --build-arg BASE_IMAGE_TAG=${BASE_IMAGE_TAG}  ."
                }
            }
        }
            
        stage('Test'){
            steps {
                sh 'echo Testing'
            }
        }
        
        stage('Publish to Docker registry') {
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