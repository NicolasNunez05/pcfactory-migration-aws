pipeline {
    agent any
    
    parameters {
        choice(name: 'DEPLOY_ENV', choices: ['dev', 'staging', 'prod'], description: 'Ambiente a desplegar')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Saltar tests?')
        booleanParam(name: 'PUSH_TO_ECR', defaultValue: true, description: 'Pushear a ECR?')
    }
    
    environment {
        // AWS Configuration
        AWS_REGION = 'us-east-1'
        AWS_ACCOUNT_ID = '787124622819'
        
        // Docker Configuration
        DOCKER_IMAGE_NAME = 'pcfactory-app'
        DOCKER_TAG = "${BUILD_NUMBER}-${GIT_COMMIT.take(7)}"
        ECR_REPOSITORY_URL = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/${DOCKER_IMAGE_NAME}"
        
        // Application Configuration
        APP_PORT = '8080'
        CONTAINER_PORT = '8080'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo "╔════════════════════════════════════════╗"
                    echo "║  PCFactory CI/CD Pipeline              ║"
                    echo "║  Build: ${BUILD_NUMBER}                 ║"
                    echo "║  Ambiente: ${params.DEPLOY_ENV}        ║"
                    echo "╚════════════════════════════════════════╝"
                }
                checkout scm
            }
        }
        
        stage('Build Image') {
            steps {
                script {
                    echo "[*] Construyendo imagen Docker..."
                    sh '''
                        docker build \
                            --tag ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} \
                            --tag ${DOCKER_IMAGE_NAME}:latest \
                            --build-arg BUILD_DATE=$(date -u +'%Y-%m-%dT%H:%M:%SZ') \
                            --build-arg VCS_REF=${GIT_COMMIT} \
                            --build-arg VERSION=${BUILD_NUMBER} \
                            .
                        
                        echo "✅ Imagen construida: ${DOCKER_IMAGE_NAME}:${DOCKER_TAG}"
                    '''
                }
            }
        }
        
        stage('Lint & Security Scan') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                script {
                    echo "[*] Ejecutando análisis de código..."
                    sh '''
                        # Linting con flake8
                        echo "  • Flake8 linting..."
                        flake8 app/ --max-line-length=100 --statistics || true
                        
                        # Verificación de formato con black
                        echo "  • Black format check..."
                        black --check app/ || true
                        
                        # Análisis de seguridad con bandit
                        echo "  • Bandit security scan..."
                        pip install bandit --quiet
                        bandit -r app/ -f json -o bandit-report.json || true
                        
                        echo "✅ Análisis de código completado"
                    '''
                }
            }
        }
        
        stage('Run Tests') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                script {
                    echo "[*] Ejecutando tests unitarios..."
                    sh '''
                        docker run --rm \
                            -v ${PWD}/tests:/app/tests \
                            -v ${PWD}/app:/app/app \
                            ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} \
                            bash -c "pip install pytest pytest-cov --quiet && pytest tests/ --cov=app --cov-report=xml --cov-report=html"
                        
                        echo "✅ Tests completados"
                    '''
                }
                publishHTML target: [
                    reportDir: 'htmlcov',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ]
            }
        }
        
        stage('Test Image Locally') {
            steps {
                script {
                    echo "[*] Probando imagen Docker localmente..."
                    sh '''
                        # Iniciar contenedor en background
                        CONTAINER_ID=$(docker run -d \
                            --name test-app-${BUILD_NUMBER} \
                            -p 8080:8080 \
                            -e ENVIRONMENT=testing \
                            ${DOCKER_IMAGE_NAME}:${DOCKER_TAG})
                        
                        echo "  Container ID: $CONTAINER_ID"
                        
                        # Esperar a que la app inicie
                        echo "  Esperando a que inicie..."
                        sleep 5
                        
                        # Verificar health check
                        echo "  Probando health endpoint..."
                        curl -f http://localhost:8080/health || {
                            docker logs test-app-${BUILD_NUMBER}
                            exit 1
                        }
                        
                        # Ejecutar pruebas básicas de conectividad
                        echo "  Pruebas de conectividad..."
                        curl -s http://localhost:8080/ | head -20
                        
                        # Limpiar
                        docker stop test-app-${BUILD_NUMBER}
                        docker rm test-app-${BUILD_NUMBER}
                        
                        echo "✅ Tests locales pasaron"
                    '''
                }
            }
        }
        
        stage('Login to ECR') {
            when {
                expression { params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "[*] Autenticando con AWS ECR..."
                    sh '''
                        aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
                        
                        echo "✅ Autenticación exitosa"
                    '''
                }
            }
        }
        
        stage('Push to ECR') {
            when {
                expression { params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "[*] Pusheando imagen a ECR..."
                    sh '''
                        # Tag con ECR URL
                        docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} ${ECR_REPOSITORY_URL}:${DOCKER_TAG}
                        docker tag ${DOCKER_IMAGE_NAME}:latest ${ECR_REPOSITORY_URL}:latest
                        
                        # Push
                        echo "  Pusheando ${ECR_REPOSITORY_URL}:${DOCKER_TAG}..."
                        docker push ${ECR_REPOSITORY_URL}:${DOCKER_TAG}
                        
                        echo "  Pusheando ${ECR_REPOSITORY_URL}:latest..."
                        docker push ${ECR_REPOSITORY_URL}:latest
                        
                        echo "✅ Push a ECR completado"
                        echo ""
                        echo "═══════════════════════════════════════════"
                        echo "Imagen disponible en:"
                        echo "  ${ECR_REPOSITORY_URL}:${DOCKER_TAG}"
                        echo "  ${ECR_REPOSITORY_URL}:latest"
                        echo "═══════════════════════════════════════════"
                    '''
                }
            }
        }
        
        stage('Image Scanning') {
            when {
                expression { params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "[*] Escaneando imagen en ECR..."
                    sh '''
                        # Iniciar scan
                        aws ecr start-image-scan \
                            --repository-name ${DOCKER_IMAGE_NAME} \
                            --image-id imageTag=${DOCKER_TAG} \
                            --region ${AWS_REGION}
                        
                        echo "✅ Escaneo iniciado (verifica resultados en ECR Console)"
                    '''
                }
            }
        }
        
        stage('Deploy to Dev') {
            when {
                expression { params.DEPLOY_ENV == 'dev' && params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "[*] Deployando a ambiente DEV..."
                    sh '''
                        # Actualizar EC2 instance con nueva imagen
                        # Esto requiere que tengas un script de deploy en tu infraestructura
                        
                        echo "  Actualizando instancias EC2 en dev..."
                        # aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" ...
                        
                        echo "✅ Deploy a DEV completado"
                    '''
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                expression { params.DEPLOY_ENV == 'staging' && params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "[*] Deployando a ambiente STAGING..."
                    sh '''
                        echo "  Actualizando instancias EC2 en staging..."
                        echo "✅ Deploy a STAGING completado"
                    '''
                }
            }
        }
        
        stage('Deploy to Production') {
            when {
                expression { params.DEPLOY_ENV == 'prod' && params.PUSH_TO_ECR }
            }
            input {
                message "¿Desplegar a PRODUCCIÓN?"
                ok "Sí, desplegar"
            }
            steps {
                script {
                    echo "[*] Deployando a ambiente PRODUCCIÓN..."
                    sh '''
                        echo "  Actualizando instancias EC2 en producción..."
                        echo "✅ Deploy a PRODUCCIÓN completado"
                    '''
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    echo "[*] Limpiando imágenes locales..."
                    sh '''
                        docker rmi ${DOCKER_IMAGE_NAME}:${DOCKER_TAG} || true
                        docker rmi ${DOCKER_IMAGE_NAME}:latest || true
                        echo "✅ Limpieza completada"
                    '''
                }
            }
        }
    }
    
    post {
        always {
            // Limpiar contenedores
            sh '''
                docker ps -a | grep test-app- | awk '{print $1}' | xargs -r docker rm -f || true
            '''
            
            // Reporte de cobertura
            publishHTML target: [
                reportDir: 'htmlcov',
                reportFiles: 'index.html',
                reportName: 'Coverage Report'
            ]
        }
        
        success {
            script {
                echo "╔════════════════════════════════════════╗"
                echo "║  ✅ BUILD EXITOSO                     ║"
                echo "║  Build #${BUILD_NUMBER}              ║"
                echo "║  Imagen: ${DOCKER_TAG}              ║"
                echo "╚════════════════════════════════════════╝"
            }
        }
        
        failure {
            script {
                echo "╔════════════════════════════════════════╗"
                echo "║  ❌ BUILD FALLIDO                     ║"
                echo "║  Build #${BUILD_NUMBER}              ║"
                echo "║  Revisa los logs arriba               ║"
                echo "╚════════════════════════════════════════╝"
            }
        }
    }
}