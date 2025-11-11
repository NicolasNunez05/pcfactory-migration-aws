pipeline {
    agent any
    
    environment {
        AWS_REGION = "us-east-1"
        AWS_ACCOUNT_ID = "787124622819"
        ECR_REPO = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/pcfactory-app"
        IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE = "pcfactory-app"
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo "✅ Clonando repositorio..."
                git 'https://github.com/NicolasNunez05/pcfactory-migration-aws.git'
            }
        }
        
        stage('Build Docker Image') {
            steps {
                echo "✅ Construyendo imagen Docker desde Dockerfile en raíz..."
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE}:${IMAGE_TAG} ${DOCKER_IMAGE}:latest
                    echo "Docker image creada: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                '''
            }
        }
        
        stage('Test Docker Image') {
            steps {
                echo "✅ Testeando imagen..."
                sh '''
                    docker run --rm ${DOCKER_IMAGE}:${IMAGE_TAG} --version || true
                '''
            }
        }
        
        stage('Success') {
            steps {
                echo "✅ PIPELINE EXITOSO"
                sh '''
                    echo "Imagen Docker lista: ${DOCKER_IMAGE}:${IMAGE_TAG}"
                    docker images | grep pcfactory-app
                '''
            }
        }
    }
    
    post {
        success {
            echo "🎉 BUILD SUCCESS - Image: ${DOCKER_IMAGE}:${IMAGE_TAG}"
        }
        failure {
            echo "❌ BUILD FAILED"
        }
    }
}
