# FASE 3: CI/CD Pipeline y Automatización

## 🎯 Resumen Fase 3

**Objetivo:** Implementar pipeline CI/CD automatizado para despliegues continuos

**Tecnologías:** GitHub Actions, CodeDeploy, CodeBuild, CodePipeline
**Estado:** 📋 Planificado
**Duración Estimada:** 3-5 días
**Costo Estimado:** $20-50/mes

---

## 🔄 Arquitectura CI/CD

```
Developer Push Code
  ↓
GitHub Repository
  ↓
GitHub Actions Trigger
  ├─ Validate (terraform validate)
  ├─ Format Check (terraform fmt)
  ├─ Lint (pylint for Flask)
  ├─ Unit Tests (pytest)
  ├─ Security Scan (bandit)
  └─ Plan (terraform plan)
  ↓
Code Review (Manual)
  ├─ Terraform Plan review
  ├─ Security review
  └─ Approval
  ↓
Merge to Main
  ↓
GitHub Actions Deploy
  ├─ Build (terraform apply)
  ├─ Deploy (CodeDeploy)
  └─ Smoke Tests
  ↓
Production Deployment
  ├─ Blue-Green Deploy
  ├─ Rolling Update
  └─ Canary Release
  ↓
Monitoring & Rollback
  ├─ CloudWatch Alarms
  ├─ Health Checks
  └─ Automatic Rollback (if errors)
```

---

## 📝 GitHub Actions Workflows

### Workflow 1: Terraform Validate & Lint

**Trigger:** Push, Pull Request
**Archivo:** `.github/workflows/terraform-validate.yml`

```yaml
name: Terraform Validate

on:
  push:
    branches: [ main, dev ]
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-validate.yml'
  pull_request:
    branches: [ main ]
    paths:
      - 'terraform/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Initialize Terraform
        run: |
          cd terraform/environments/dev
          terraform init -backend=false
      
      - name: Validate Terraform
        run: |
          cd terraform/environments/dev
          terraform validate
      
      - name: Format Check
        run: |
          cd terraform
          terraform fmt -check -recursive
      
      - name: Security Scan (checkov)
        run: |
          pip install checkov
          checkov --framework terraform \
                  --directory terraform/modules \
                  --framework cloudformation
      
      - name: Comment PR with Results
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v6
        with:
          script: |
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '✅ Terraform validation passed!\n✅ Format check passed!\n✅ Security scan passed!'
            })
```

### Workflow 2: Terraform Plan (PR Review)

**Trigger:** Pull Request
**Archivo:** `.github/workflows/terraform-plan.yml`

```yaml
name: Terraform Plan

on:
  pull_request:
    branches: [ main ]
    paths:
      - 'terraform/**'

jobs:
  plan:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: us-east-1
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: |
          cd terraform/environments/dev
          terraform init \
            -backend-config=../../config/backend.conf
      
      - name: Terraform Plan
        id: plan
        run: |
          cd terraform/environments/dev
          terraform plan -no-color -out=tfplan
          terraform show -json tfplan > plan.json
      
      - name: Analyze Plan
        run: |
          echo "Plan Summary:"
          grep -E "Plan:|Add|Change|Destroy" tfplan.txt || true
      
      - name: Comment Plan on PR
        uses: actions/github-script@v6
        with:
          script: |
            const fs = require('fs');
            const plan = fs.readFileSync('terraform/environments/dev/tfplan.txt', 'utf8');
            
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '```\n' + plan.substring(0, 30000) + '\n```'
            })
      
      - name: Upload Plan
        uses: actions/upload-artifact@v3
        with:
          name: tfplan
          path: terraform/environments/dev/tfplan
          retention-days: 5
```

### Workflow 3: Terraform Apply (CD)

**Trigger:** Merge to Main
**Archivo:** `.github/workflows/terraform-apply.yml`

```yaml
name: Terraform Apply

on:
  push:
    branches: [ main ]
    paths:
      - 'terraform/**'
      - '.github/workflows/terraform-apply.yml'

jobs:
  apply:
    runs-on: ubuntu-latest
    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: us-east-1
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.5.0
      
      - name: Terraform Init
        run: |
          cd terraform/environments/dev
          terraform init \
            -backend-config=../../config/backend.conf
      
      - name: Terraform Apply
        run: |
          cd terraform/environments/dev
          terraform apply -auto-approve
      
      - name: Get Outputs
        id: outputs
        run: |
          cd terraform/environments/dev
          ALB_DNS=$(terraform output -raw alb_dns)
          RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
          echo "alb_dns=$ALB_DNS" >> $GITHUB_OUTPUT
          echo "rds_endpoint=$RDS_ENDPOINT" >> $GITHUB_OUTPUT
      
      - name: Notify Slack
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: |
            ✅ Terraform Apply Completed
            ALB: ${{ steps.outputs.outputs.alb_dns }}
            RDS: ${{ steps.outputs.outputs.rds_endpoint }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
        if: always()
```

### Workflow 4: Application Deploy

**Trigger:** Merge to Main
**Archivo:** `.github/workflows/deploy-app.yml`

```yaml
name: Deploy Flask Application

on:
  push:
    branches: [ main ]
    paths:
      - 'app/**'
      - '.github/workflows/deploy-app.yml'

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: 3.11
      
      - name: Install Dependencies
        run: |
          pip install -r app/requirements.txt
          pip install pytest pylint bandit
      
      - name: Lint Code
        run: |
          pylint app/app.py --fail-under=8.0 || true
      
      - name: Security Scan
        run: |
          bandit -r app/ -f csv -o bandit-report.csv || true
      
      - name: Unit Tests
        run: |
          pytest app/tests/ -v --cov=app --cov-report=xml
      
      - name: Build Docker Image
        run: |
          docker build -t pcfactory-flask:latest -f app/Dockerfile app/
          docker tag pcfactory-flask:latest \
                     ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com/pcfactory-flask:latest
      
      - name: Push to ECR
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws ecr get-login-password --region us-east-1 | \
            docker login --username AWS --password-stdin \
              ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com
          docker push ${{ secrets.AWS_ACCOUNT_ID }}.dkr.ecr.us-east-1.amazonaws.com/pcfactory-flask:latest
      
      - name: Deploy to EC2 (CodeDeploy)
        env:
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        run: |
          aws deploy create-deployment \
            --application-name pcfactory-app \
            --deployment-group-name pcfactory-dg \
            --deployment-config-name CodeDeployDefault.AllAtOnce \
            --s3-location s3://pcfactory-deployments/app-${{ github.sha }}.zip \
            --region us-east-1
```

---

## 🚀 Estrategias de Despliegue

### 1. Blue-Green Deployment

```
Estado Actual (BLUE):
├─ ALB → Target Group Blue (v1.0)
│  ├─ EC2 Instance 1 (v1.0)
│  └─ EC2 Instance 2 (v1.0)

Nueva Release (GREEN):
├─ Target Group Green (v1.1)
│  ├─ EC2 Instance 3 (v1.1)
│  └─ EC2 Instance 4 (v1.1)

Validación:
├─ Health checks en GREEN
├─ Smoke tests
└─ Si OK → Switchear ALB a GREEN
   Si ERROR → Rollback a BLUE (automático)
```

**Implementación:**

```bash
#!/bin/bash
# scripts/blue-green-deploy.sh

TG_BLUE="tg-blue"
TG_GREEN="tg-green"
ALB_LISTENER="listener-80"

# 1. Obtener instancias GREEN
GREEN_INSTANCES=$(aws ec2 describe-instances \
  --filters "Name=tag:Version,Values=v1.1" \
  --query 'Reservations[0].Instances[*].InstanceId' \
  --output text)

# 2. Registrar instancias en Target Group GREEN
for instance in $GREEN_INSTANCES; do
  aws elbv2 register-targets \
    --target-group-arn "arn:aws:elasticloadbalancing:.../$TG_GREEN" \
    --targets Id=$instance
done

# 3. Health checks (esperar 30s)
sleep 30

# 4. Obtener estado de instancias
HEALTHY=$(aws elbv2 describe-target-health \
  --target-group-arn "arn:aws:elasticloadbalancing:.../$TG_GREEN" \
  --query 'length(TargetHealthDescriptions[?TargetHealth.State==`healthy`])')

if [ $HEALTHY -eq ${#GREEN_INSTANCES[@]} ]; then
  # 5. Switchear ALB listener de BLUE a GREEN
  aws elbv2 modify-listener \
    --listener-arn "arn:aws:elasticloadbalancing:.../$ALB_LISTENER" \
    --default-actions "Type=forward,TargetGroupArn=arn:.../$TG_GREEN"
  
  echo "✅ Deployment successful"
else
  echo "❌ Health check failed, rollback to BLUE"
  aws elbv2 modify-listener \
    --listener-arn "arn:aws:elasticloadbalancing:.../$ALB_LISTENER" \
    --default-actions "Type=forward,TargetGroupArn=arn:.../$TG_BLUE"
fi
```

### 2. Rolling Update

```
Fase 1:
├─ Total 3 instancias
├─ Terminar 1 instancia (v1.0)
├─ Crear 1 nueva (v1.1)
└─ Esperar health check

Fase 2:
├─ Terminar 1 instancia (v1.0)
├─ Crear 1 nueva (v1.1)
└─ Esperar health check

Fase 3:
├─ Terminar última (v1.0)
├─ Crear 1 nueva (v1.1)
└─ Esperar health check

Resultado: 0% downtime, 100% v1.1
```

### 3. Canary Release

```
Envío Inicial:
├─ 95% tráfico a v1.0 (estable)
└─ 5% tráfico a v1.1 (canary)

Monitoreo:
├─ Error rate en v1.1 < 1% ✅
├─ Latency en v1.1 < 2x v1.0 ✅
└─ CPU usage en v1.1 normal ✅

Incremento Gradual:
├─ 5% → 25% (5 min)
├─ 25% → 50% (5 min)
├─ 50% → 75% (5 min)
└─ 75% → 100% (5 min)

Total: 20 min para rollout completo

Si Error en Canary:
└─ Rollback automático a v1.0
```

---

## 🔐 Secrets Management

### GitHub Secrets

```
AWS_ACCESS_KEY_ID: AKIA... (IAM user terraform-deployer)
AWS_SECRET_ACCESS_KEY: wJal... (secret key)
SLACK_WEBHOOK: https://hooks.slack.com/...
DOCKER_REGISTRY: 123456.dkr.ecr.us-east-1.amazonaws.com
AWS_ACCOUNT_ID: 123456789012
```

### AWS Secrets Manager

```
/rds/pcfactory/master:
  {
    "username": "postgres",
    "password": "SecureP@ssw0rd123",
    "host": "pcfactory-db.xxxxx.rds.amazonaws.com",
    "port": 5432
  }

/app/config:
  {
    "debug": false,
    "log_level": "INFO",
    "max_connections": 100
  }
```

---

## 📊 Monitoreo de Despliegues

### CloudWatch Dashboards

```
Dashboard: CI/CD Metrics
├─ Últimos 5 despliegues
├─ Success rate (%)
├─ Deployment time (min)
├─ Rollback count
└─ Error rate post-deploy
```

### SNS Notifications

```
Topic: pcfactory-ci-cd-notifications
├─ Deployment Start
├─ Deployment Success
├─ Deployment Failure
├─ Rollback Triggered
└─ Health Check Failed
```

---

## 🧪 Testing Strategy

### Unit Tests

```bash
# tests/test_app.py
import pytest
from app.app import app, get_products

@pytest.fixture
def client():
    return app.test_client()

def test_health_endpoint(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json['status'] == 'healthy'

def test_products_endpoint(client):
    response = client.get('/products')
    assert response.status_code == 200
    assert len(response.json) > 0

def test_create_product(client):
    response = client.post('/products', json={
        'name': 'Test Product',
        'price': 99.99
    })
    assert response.status_code == 201
```

### Integration Tests

```bash
# tests/integration_test.py
def test_end_to_end_flow():
    # 1. Connect to RDS
    conn = psycopg2.connect(...)
    
    # 2. Insert test data
    cursor = conn.cursor()
    cursor.execute("INSERT INTO products VALUES ...")
    
    # 3. Query via Flask API
    response = client.get('/products')
    
    # 4. Verify response
    assert len(response.json) > 0
    
    # 5. Cleanup
    cursor.execute("DELETE FROM products WHERE ...")
    conn.close()
```

### Smoke Tests (Post-Deploy)

```bash
#!/bin/bash
# scripts/smoke-tests.sh

ALB_DNS="$1"

# Test 1: Health endpoint
curl -f http://$ALB_DNS/health || exit 1

# Test 2: Products endpoint
curl -f http://$ALB_DNS/products || exit 1

# Test 3: Create product
curl -f -X POST http://$ALB_DNS/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Test","price":10.0}' || exit 1

echo "✅ All smoke tests passed"
```

---

## 📈 Métricas y KPIs

| Métrica | Target | Actual |
|---------|--------|--------|
| **Deployment Frequency** | Daily | 1-2x/day |
| **Lead Time** | < 1 hour | 30 min |
| **Mean Time to Recovery (MTTR)** | < 5 min | 2 min |
| **Change Failure Rate** | < 5% | 0% |
| **Deployment Success Rate** | > 99% | 100% |
| **Test Coverage** | > 80% | 85% |

---

## 🛠️ Implementación Paso a Paso

### Día 1-2: GitHub Actions Setup

```bash
# 1. Crear carpeta workflows
mkdir -p .github/workflows

# 2. Copiar archivos workflow
cp workflows/*.yml .github/workflows/

# 3. Crear GitHub Secrets
# Ir a Settings → Secrets and variables → Actions
# Agregar: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.

# 4. Test workflow
git push origin feature/ci-cd
# Verificar Actions tab en GitHub
```

### Día 3: CodeDeploy Setup

```bash
# 1. Crear IAM role para CodeDeploy
aws iam create-role \
  --role-name CodeDeployRole \
  --assume-role-policy-document '{...}'

# 2. Crear CodeDeploy application
aws deploy create-app \
  --application-name pcfactory-app

# 3. Crear deployment group
aws deploy create-deployment-group \
  --application-name pcfactory-app \
  --deployment-group-name pcfactory-dg \
  --service-role-arn arn:aws:iam::...
```

### Día 4-5: Testing & Validation

```bash
# 1. Crear PR con cambios
git checkout -b feature/test-ci-cd
echo "test change" >> terraform/main.tf
git push origin feature/test-ci-cd

# 2. Verificar que workflow se ejecute
# GitHub Actions → terraform-validate

# 3. Approbar y merge
# Verificar que terraform-apply se ejecute

# 4. Validar en AWS
aws ec2 describe-instances
```

---

## ✅ Checklist Fase 3

- [ ] GitHub Actions workflows creados
- [ ] AWS Secrets Manager configurado
- [ ] CodeDeploy aplicación creada
- [ ] IAM roles para CI/CD configurados
- [ ] Unit tests implementados
- [ ] Integration tests implementados
- [ ] Smoke tests automatizados
- [ ] Blue-Green deployment preparado
- [ ] Rollback automático configurado
- [ ] CloudWatch dashboards creados
- [ ] SNS notifications configuradas
- [ ] Slack integration activa
- [ ] PR templates actualizados
- [ ] Documentation completada

---

**Fase 3 Status:** 📋 Pendiente

**Próxima Fase:** Fase 4 - Kubernetes/EKS (Modernización)

---

*Planificado para: Finales de noviembre 2025*
*Proyecto: PCFactory Migration AWS - Capstone DuocUC 2025*
