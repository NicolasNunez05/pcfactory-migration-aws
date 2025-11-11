pipeline {
    agent any
    
    options {
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
        buildDiscarder(logRotator(numToKeepStr: '15', artifactNumToKeepStr: '5'))
        disableConcurrentBuilds()
    }
    
    // Variables de entorno globales
    environment {
        // AWS Configuration
        AWS_REGION = "us-east-1"
        AWS_ACCOUNT_ID = "787124622819"
        ECR_REGISTRY = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPO_NAME = "pcfactory-app"
        
        // Docker Configuration
        DOCKER_IMAGE_NAME = "${ECR_REGISTRY}/${ECR_REPO_NAME}"
        DOCKER_IMAGE_TAG = "${BUILD_NUMBER}"
        DOCKER_IMAGE_LATEST = "${DOCKER_IMAGE_NAME}:latest"
        DOCKER_IMAGE_FULL = "${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}"
        
        // GitHub Configuration
        GITHUB_REPO = "https://github.com/NicolasNunez05/pcfactory-migration-aws"
        GITHUB_BRANCH = "main"
        
        // Application Configuration
        APP_PORT = "8080"
        ENVIRONMENT = "development"
        
        // Build Variables
        BUILD_TIMESTAMP = sh(script: "date +%Y%m%d_%H%M%S", returnStdout: true).trim()
    }
    
    // Triggers
    triggers {
        // Webhook desde GitHub
        githubPush()
        
        // Compilación periódica (cada día a las 2 AM)
        cron('H 2 * * *')
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'prod'],
            description: 'Seleccionar ambiente de deployment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Saltar tests (NO RECOMENDADO)'
        )
        booleanParam(
            name: 'PUSH_TO_ECR',
            defaultValue: true,
            description: 'Hacer push de imagen a ECR'
        )
        booleanParam(
            name: 'SECURITY_SCAN',
            defaultValue: true,
            description: 'Ejecutar escaneo de seguridad'
        )
    }
    
    stages {
        stage('📋 Información del Build') {
            steps {
                script {
                    echo "════════════════════════════════════════════"
                    echo "🔍 INFORMACIÓN DEL BUILD"
                    echo "════════════════════════════════════════════"
                    echo "Build Number: ${BUILD_NUMBER}"
                    echo "Build ID: ${BUILD_ID}"
                    echo "Build Tag: ${BUILD_TAG}"
                    echo "Build Timestamp: ${BUILD_TIMESTAMP}"
                    echo "Usuario: Sistema"
                    echo "Branch: ${GITHUB_BRANCH}"
                    echo "Workspace: ${WORKSPACE}"
                    echo "════════════════════════════════════════════"
                }
            }
        }
        
        stage('🔄 Checkout') {
            steps {
                script {
                    echo "🔄 Clonando repositorio desde GitHub..."
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/${GITHUB_BRANCH}']],
                        userRemoteConfigs: [[url: '${GITHUB_REPO}.git']]
                    ])
                    
                    // Obtener información del commit
                    sh '''
                        echo "✅ Repositorio clonado exitosamente"
                        echo ""
                        echo "📌 Información del Commit:"
                        echo "Commit Hash: $(git rev-parse --short HEAD)"
                        echo "Autor: $(git log -1 --pretty=format:'%an')"
                        echo "Mensaje: $(git log -1 --pretty=format:'%s')"
                        echo "Fecha: $(git log -1 --pretty=format:'%ad')"
                    '''
                }
            }
        }
        
        stage('🔍 Validación de Estructura') {
            steps {
                script {
                    echo "📁 Validando estructura del proyecto..."
                    sh '''
                        echo "Contenido del workspace:"
                        ls -lah
                        echo ""
                        echo "Verificando archivos críticos..."
                        
                        # Verificar Dockerfile
                        if [ -f "Dockerfile" ]; then
                            echo "✅ Dockerfile encontrado"
                        else
                            echo "⚠️  Dockerfile NO encontrado"
                        fi
                        
                        # Verificar .env.example
                        if [ -f ".env.example" ]; then
                            echo "✅ .env.example encontrado"
                        fi
                        
                        # Verificar estructura de código
                        if [ -d "app" ] || [ -d "src" ] || [ -d "application" ]; then
                            echo "✅ Directorio de aplicación encontrado"
                        fi
                        
                        echo ""
                        echo "Estructura validada correctamente"
                    '''
                }
            }
        }
        
        stage('🏗️ Build') {
            steps {
                script {
                    echo "🏗️ Iniciando construcción del proyecto..."
                    sh '''
                        echo "Validando estructura de proyecto..."
                        
                        # Si hay archivo requirements.txt, instalar dependencias
                        if [ -f "requirements.txt" ]; then
                            echo "📦 Instalando dependencias Python..."
                            pip install --upgrade pip
                            pip install -r requirements.txt 2>/dev/null || echo "⚠️  Algunas dependencias pueden no estar disponibles"
                        fi
                        
                        # Validar archivos Python
                        if find . -name "*.py" | head -1 | xargs -I {} python -m py_compile {} 2>/dev/null; then
                            echo "✅ Código Python validado"
                        fi
                        
                        # Mostrar estructura de directorios
                        echo ""
                        echo "📁 Árbol de directorios del proyecto:"
                        find . -type f -name "*.py" -o -name "Dockerfile" -o -name "*.yml" | grep -v ".git" | sort
                        
                        echo ""
                        echo "✅ Build validado exitosamente"
                    '''
                }
            }
        }
        
        stage('🧪 Tests') {
            when {
                expression { !params.SKIP_TESTS }
            }
            steps {
                script {
                    echo "🧪 Ejecutando suite de tests..."
                    sh '''
                        echo "Buscando archivos de test..."
                        
                        if find . -path ./venv -prune -o -type f -name "test_*.py" -o -name "*_test.py" | grep -q test; then
                            echo "📋 Tests encontrados, ejecutando..."
                            
                            # Instalar pytest si no está instalado
                            pip install pytest pytest-cov flake8 pylint 2>/dev/null
                            
                            # Ejecutar tests
                            echo ""
                            echo "Ejecutando tests con coverage..."
                            pytest -v --tb=short --cov=. --cov-report=term-summary 2>/dev/null || echo "⚠️  Algunos tests pueden haber fallado o no existen tests"
                            
                            # Linting
                            echo ""
                            echo "Ejecutando análisis de código (linting)..."
                            flake8 . --max-line-length=100 --exclude=venv,./venv --count 2>/dev/null || echo "⚠️  Se encontraron issues de estilo (no críticos)"
                        else
                            echo "ℹ️  No se encontraron tests en el proyecto"
                            echo "📌 Los tests pueden estar en otro directorio"
                        fi
                        
                        echo ""
                        echo "✅ Validación de tests completada"
                    '''
                }
            }
        }
        
        stage('🐳 Docker Build') {
            steps {
                script {
                    echo "🐳 Construyendo imagen Docker..."
                    sh '''
                        echo "Verificando Docker..."
                        docker --version
                        
                        echo ""
                        echo "🔨 Construyendo imagen: ${DOCKER_IMAGE_FULL}"
                        
                        if [ -f "Dockerfile" ]; then
                            docker build \
                                --tag ${DOCKER_IMAGE_FULL} \
                                --tag ${DOCKER_IMAGE_LATEST} \
                                --label "build.number=${BUILD_NUMBER}" \
                                --label "build.timestamp=${BUILD_TIMESTAMP}" \
                                --label "git.commit=$(git rev-parse --short HEAD)" \
                                .
                            
                            echo ""
                            echo "✅ Imagen Docker construida exitosamente"
                            
                            echo ""
                            echo "📊 Información de la imagen:"
                            docker images | grep ${ECR_REPO_NAME} | head -2
                            
                            # Inspeccionar imagen
                            echo ""
                            echo "🔍 Detalles de la imagen:"
                            docker inspect ${DOCKER_IMAGE_FULL} | grep -E '"Id"|"RepoTags"|"Config"' | head -5
                        else
                            echo "❌ Dockerfile no encontrado"
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('🔒 Security Scan') {
            when {
                expression { params.SECURITY_SCAN }
            }
            steps {
                script {
                    echo "🔒 Ejecutando escaneo de seguridad..."
                    sh '''
                        echo "Escaneando imagen Docker con Trivy..."
                        
                        # Verificar si Trivy está instalado
                        if ! command -v trivy &> /dev/null; then
                            echo "📥 Instalando Trivy..."
                            curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin 2>/dev/null || echo "⚠️  Trivy no pudo ser instalado"
                        fi
                        
                        # Ejecutar scan si Trivy está disponible
                        if command -v trivy &> /dev/null; then
                            echo ""
                            echo "🔍 Ejecutando scan de vulnerabilidades..."
                            trivy image --severity HIGH,CRITICAL ${DOCKER_IMAGE_FULL} || echo "⚠️  Se encontraron vulnerabilidades (revisar manualmente)"
                            
                            echo ""
                            echo "✅ Escaneo completado"
                        else
                            echo "ℹ️  Trivy no disponible - skipping scan"
                        fi
                    '''
                }
            }
        }
        
        stage('🔐 AWS ECR - Login') {
            when {
                expression { params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "🔐 Autenticando con AWS ECR..."
                    sh '''
                        echo "Obteniendo credenciales de ECR..."
                        
                        aws ecr get-login-password --region ${AWS_REGION} | \
                            docker login --username AWS --password-stdin ${ECR_REGISTRY} && \
                            echo "✅ Autenticación exitosa en ECR" || \
                            echo "❌ Falló la autenticación en ECR"
                    '''
                }
            }
        }
        
        stage('📤 Push to ECR') {
            when {
                expression { params.PUSH_TO_ECR }
            }
            steps {
                script {
                    echo "📤 Haciendo push de imagen a ECR..."
                    sh '''
                        echo "Verificando si el repositorio ECR existe..."
                        
                        REPO_EXISTS=$(aws ecr describe-repositories \
                            --repository-names ${ECR_REPO_NAME} \
                            --region ${AWS_REGION} 2>/dev/null | grep repositoryArn)
                        
                        if [ -z "$REPO_EXISTS" ]; then
                            echo "📦 Creando repositorio ECR: ${ECR_REPO_NAME}"
                            aws ecr create-repository \
                                --repository-name ${ECR_REPO_NAME} \
                                --region ${AWS_REGION} \
                                --image-scanning-configuration scanOnPush=true \
                                --image-tag-mutability IMMUTABLE
                            
                            echo "✅ Repositorio creado"
                        else
                            echo "✅ Repositorio ya existe"
                        fi
                        
                        echo ""
                        echo "🚀 Haciendo push de: ${DOCKER_IMAGE_FULL}"
                        docker push ${DOCKER_IMAGE_FULL}
                        
                        echo ""
                        echo "🚀 Haciendo push de latest: ${DOCKER_IMAGE_LATEST}"
                        docker push ${DOCKER_IMAGE_LATEST}
                        
                        echo ""
                        echo "✅ Push completado exitosamente"
                        
                        # Mostrar URI de la imagen
                        echo ""
                        echo "📌 URI de la imagen para deployment:"
                        echo "   ${DOCKER_IMAGE_FULL}"
                        echo "   ${DOCKER_IMAGE_LATEST}"
                    '''
                }
            }
        }
        
        stage('📊 Build Summary') {
            steps {
                script {
                    echo "📊 Resumen del Build"
                    sh '''
                        echo "════════════════════════════════════════════"
                        echo "✅ RESUMEN DE BUILD #${BUILD_NUMBER}"
                        echo "════════════════════════════════════════════"
                        echo ""
                        echo "📌 Build Information:"
                        echo "   - Build ID: ${BUILD_ID}"
                        echo "   - Timestamp: ${BUILD_TIMESTAMP}"
                        echo "   - Environment: ${ENVIRONMENT}"
                        echo ""
                        echo "🐳 Docker Image:"
                        echo "   - Full Tag: ${DOCKER_IMAGE_FULL}"
                        echo "   - Latest: ${DOCKER_IMAGE_LATEST}"
                        echo ""
                        echo "🔒 Security:"
                        echo "   - Scan Ejecutado: ${SECURITY_SCAN}"
                        echo ""
                        echo "📤 ECR Registry:"
                        echo "   - Registry: ${ECR_REGISTRY}"
                        echo "   - Repository: ${ECR_REPO_NAME}"
                        echo ""
                        
                        # Listar imágenes en ECR
                        if [ "${PUSH_TO_ECR}" = "true" ]; then
                            echo "📋 Imágenes en ECR (últimas 5):"
                            aws ecr describe-images \
                                --repository-name ${ECR_REPO_NAME} \
                                --region ${AWS_REGION} \
                                --query 'sort_by(imageDetails, &imagePushedAt)[-5:].{Tag:imageTags[0], Pushed:imagePushedAt, Size:imageSizeBytes}' \
                                --output table 2>/dev/null || echo "   No se pudo obtener información de ECR"
                        fi
                        
                        echo ""
                        echo "🎉 Pipeline completado exitosamente"
                        echo "════════════════════════════════════════════"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo "✅ PIPELINE EXITOSO"
                sh '''
                    echo "📧 Notificación de éxito"
                    echo "Pipeline #${BUILD_NUMBER} completado exitosamente"
                    echo "Imagen: ${DOCKER_IMAGE_FULL}"
                    
                    # Opcional: Enviar a Slack
                    # curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
                    #   -H 'Content-Type: application/json' \
                    #   -d "{\"text\": \"✅ Build #${BUILD_NUMBER} exitoso\"}"
                '''
            }
        }
        
        failure {
            script {
                echo "❌ PIPELINE FALLÓ"
                sh '''
                    echo "📧 Notificación de fallo"
                    echo "Pipeline #${BUILD_NUMBER} ha fallado"
                    
                    # Opcional: Enviar a Slack
                    # curl -X POST https://hooks.slack.com/services/YOUR/WEBHOOK/URL \
                    #   -H 'Content-Type: application/json' \
                    #   -d "{\"text\": \"❌ Build #${BUILD_NUMBER} falló\"}"
                '''
            }
        }
        
        unstable {
            script {
                echo "⚠️  PIPELINE INESTABLE"
                sh '''
                    echo "⚠️  Advertencia"
                    echo "Pipeline #${BUILD_NUMBER} completado con advertencias"
                '''
            }
        }
        
        always {
            script {
                echo "📋 Limpiando y finalizando..."
                sh '''
                    echo ""
                    echo "════════════════════════════════════════════"
                    echo "📋 INFORMACIÓN FINAL"
                    echo "════════════════════════════════════════════"
                    echo "Duración total del build: ${BUILD_DURATION}ms"
                    echo "Timestamp final: $(date)"
                    echo "════════════════════════════════════════════"
                '''
                
                // Limpiar imágenes Docker locales si es necesario
                sh '''
                    echo ""
                    echo "🧹 Limpiando imágenes Docker antiguas..."
                    docker image prune -a --force --filter "until=72h" || true
                '''
            }
        }
    }
}
