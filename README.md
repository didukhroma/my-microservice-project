# Final Project DevOps – AWS + Terraform + EKS + Jenkins + Argo CD + Prometheus/Grafana + Django

Цей проєкт реалізує повний шлях від інфраструктури до CI/CD та моніторингу для Django-застосунку в AWS.

## Архітектура

Інфраструктура описана за допомогою **Terraform** та розгортається в AWS (регіон `us-west-2`):

- **VPC**

  - Приватні та публічні підмережі
  - Internet Gateway, маршрути

- **EKS (Kubernetes)**

  - Кластер EKS
  - Node Group (наприклад, `t3.medium`, autoscaling)
  - AWS EBS CSI driver для persistent volume

- **ECR**

  - Репозиторій для Docker-образів Django-застосунку

- **RDS (PostgreSQL / Aurora)**

  - База даних для Django
  - Доступ тільки з EKS (через VPC / SG)

- **Jenkins** (CI)

  - Розгорнутий у namespace `jenkins` через Helm
  - Пайплайн збирає Docker-образ (Kaniko), пушить у ECR, оновлює Helm-чарт

- **Argo CD** (CD / GitOps)

  - namespace `argocd`
  - Helm chart `argocd-apps` створює `Application` для `django-app`
  - Витягує Helm-чарт із репозиторію та застосовує до кластера

- **Monitoring**

  - Prometheus + exporters
  - Grafana (namespace `monitoring`)
  - Базові дашборди для моніторингу кластера та застосунків

- **Django App**
  - Код у директорії `Django/`
  - Dockerfile для контейнеризації
  - Helm-чарт: `charts/django-app`
  - CI/CD → розгортання в namespace `django-app`

**Структура проєкту**

```
Project/
│
├── main.tf         # Головний файл для підключення модулів
├── backend.tf      # Налаштування бекенду для стейтів (S3 + DynamoDB
├── outputs.tf      # Загальні виводи ресурсів
├── secrets.yaml    # Налаштування доступу
├── modules/        # Каталог з усіма модулями
│  ├── s3-backend/  # Модуль для S3 та DynamoDB
│  ├── vpc/         # Модуль для VPC
│  ├── ecr/         # Модуль для ECR
│  ├── eks/         # Модуль для Kubernetes кластера
│  ├── rds/         # Модуль для RDS
│  ├── jenkins/     # Модуль для Helm-установки Jenkins 
│  ├── monitoring/  # Модуль для Prometheus та Grafana 
│  └── argo_cd/     # Модуль для Helm-установки Argo CD
├── charts/
│  └── django-app/
│    ├── templates/
│    │  ├── deployment.yaml
│    │  ├── service.yaml
│    │  ├── postgress.yaml
│    │  ├── configmap.yaml
│    │  └── hpa.yaml
│    ├── Chart.yaml
│    └── values.yaml  
└── Django/
    ├── Jenkinsfile       # Jenkins pipeline (CI/CD)
    ├── Dockerfile        # Docker-образ Django
    └── django-app/...    # Код Django-застосунку

```

---

**Необхідні пакети:**

- AWS CLI
- Terraform
- kubectl
- Helm
- Docker
- Git

---

## 1. **Підготовка середовища**

_Клонування репозиторію та перехід у гілку:_

```
git clone https://github.com/didukhroma/my-microservice-project.git
cd my-microservice-project
git checkout final_project
```

_Налаштування AWS CLI_

```
aws configure
```

_Перевірте підключення_

```
aws sts get-caller-identity
```

_Підготовка секретів_

```
echo -n "YOUR_AWS_ACCESS_KEY_ID" | base64
echo -n "YOUR_AWS_SECRET_ACCESS_KEY" | base64

```

_Оновіть файл secrets.yaml вашими закодованими значеннями:_

```
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
  namespace: jenkins
type: Opaque
data:
  aws-access-key-id: <BASE64_ENCODED_ACCESS_KEY>
  aws-secret-access-key: <BASE64_ENCODED_SECRET_KEY>
```

_Застосування секретів_

```
kubectl apply -f kubernetes-secrets.yaml
kubectl get secrets -n jenkins

```

_Ініціалізація Terraform:_

```
terraform init

```

Перевірка плану:

```
terraform plan
```

---

## 2. **Розгортання інфраструктури**

_Запуск розгортання:_

```
terraform apply
```

Після успішного apply будуть створені:

- VPC, EKS, RDS, ECR

- Jenkins (namespace: jenkins)

- Argo CD (namespace: argocd)

- Prometheus + Grafana (namespace: monitoring)

- Застосунок (namespace django-app)

- Argo CD Application для Django (django-app)

_Перевірка основних ресурсів_

```
kubectl get ns
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
kubectl get all -n django-app

```

---

## 3. **Доступ до Jenkins (CI)**

_Port-forward:_

```

kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

_Відкрити в браузері:_

```
http://localhost:8080

```

_Початковий пароль admin (якщо використовується стандартний Jenkins chart):_

```
kubectl get secret jenkins -n jenkins -o jsonpath='{.data.jenkins-admin-password}' | base64 -d; echo
```

_Налаштування Pipeline:_

New Item → Pipeline \
Pipeline script from SCM \
Git Repository: https://github.com/<YOUR_REPOSITORY>.git \
Branch: YOUR_REPOSITORY_BRANCH \
Script Path: Django/Jenkinsfile

У Jenkins налаштований pipeline (Jenkinsfile у Django/Jenkinsfile), який:

- клонує код із гілки final_project;
- збирає Docker-образ за допомогою Kaniko;
- пушить образ у ECR:
- final-project-devops-django-app:v1.0.<BUILD_NUMBER>;
- оновлює charts/django-app/values.yaml (поле tag);
- пушить зміну у Git → Argo CD підхоплює нову версію образу.

---

## 4. **Доступ до Argo CD (CD / GitOps)**

_Port-forward:_

```
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

_Відкрити в браузері:_

```
http://localhost:8081
```

_Початковий пароль admin:_

```
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath='{.data.password}' | base64 -d; echo
```

Після логіну в Argo CD видно Application:

- django-app

- Source → GitHub (final_project, charts/django-app)

- Destination → namespace: django-app

Argo CD синхронізує Helm-чарт і розгортає Django-застосунок в EKS.

---

## 5. **Моніторинг: Prometheus + Grafana**

### Prometheus

_Port-forward (якщо треба зайти напряму):_

```
 kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

\_Перевірка метрик (up, kube\_\_, тощо) через:\*

```
 http://localhost:9090
```

### Grafana

_Port-forward:_

```
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

_Вхід:_

```
 http://localhost:3000
```

логін/пароль — згідно з modules/monitoring/values (наприклад, admin / Admin12345!!, якщо так задано).

На дашбордах можна переглядати:

- стан кластеру EKS;

- статуси pod’ів;

- ресурси Django-застосунку.

## 6. **CI/CD: повний потік**

1. Розробник пушить зміни в гілку final_project (код або Dockerfile / Helm values).

2. Jenkins pipeline (з Django/Jenkinsfile):

- Checkout App Code → клон repo.

- Build & Push Docker Image to ECR → Kaniko збирає образ із Django/Dockerfile, пушить у ECR.

- Update Chart Tag in Git (GitOps) → оновлює charts/django-app/values.yaml (tag: v1.0.<BUILD_NUMBER>), пушить у GitHub.

3. Argo CD:

- відстежує репозиторій (final_project, charts/django-app);

- бачить новий тег → синхронізує Application;

- оновлює Deployment у namespace django-app на новий образ.

4. Prometheus + Grafana:

- збирають метрики з кластера та застосунку;

- на дашбордах видно статус релізів, ресурси, навантаження.

## 7. **Видалення інфраструктури (важливо!)**

⚠️ При роботі з хмарою завжди видаляйте невикористані ресурси, щоб уникнути зайвих витрат.

Після завершення роботи з проєктом:

```
terraform destroy -auto-approve
```

![Alt text](/asserts/img-1.png)

![Alt text](/asserts/img-2.png)

![Alt text](/asserts/img-3.png)
