# CI/CD-процес із використанням Jenkins + Helm + Terraform + Argo CD, який:

1. Автоматично збирає Docker-образ для Django-застосунку;

2. Публікує образ в Amazon ECR;

3. Оновлює Helm chart у репозиторії з правильним тегом;

4. Синхронізує застосунок у кластері через Argo CD, який підхоплює зміни з Git.

**Структура проєкту**
```
Progect/
│
├── main.tf                  # Головний файл для підключення модулів
├── backend.tf               # Налаштування бекенду для стейтів (S3 + DynamoDB
├── outputs.tf               # Загальні виводи ресурсів
│
├── modules/                 # Каталог з усіма модулями
│   ├── s3-backend/          # Модуль для S3 та DynamoDB
│   │   ├── s3.tf            # Створення S3-бакета
│   │   ├── dynamodb.tf      # Створення DynamoDB
│   │   ├── variables.tf     # Змінні для S3
│   │   └── outputs.tf       # Виведення інформації про S3 та DynamoDB
│   │
│   ├── vpc/                 # Модуль для VPC
│   │   ├── vpc.tf           # Створення VPC, підмереж, Internet Gateway
│   │   ├── routes.tf        # Налаштування маршрутизації
│   │   ├── variables.tf     # Змінні для VPC
│   │   └── outputs.tf  
│   ├── ecr/                 # Модуль для ECR
│   │   ├── ecr.tf           # Створення ECR репозиторію
│   │   ├── variables.tf     # Змінні для ECR
│   │   └── outputs.tf       # Виведення URL репозиторію
│   │
│   ├── eks/                      # Модуль для Kubernetes кластера
│   │   ├── eks.tf                # Створення кластера
│   │   ├── aws_ebs_csi_driver.tf # Встановлення плагіну csi drive
│   │   ├── variables.tf     # Змінні для EKS
│   │   └── outputs.tf       # Виведення інформації про кластер
│   │
│   ├── jenkins/             # Модуль для Helm-установки Jenkins
│   │   ├── jenkins.tf       # Helm release для Jenkins
│   │   ├── variables.tf     # Змінні (ресурси, креденшели, values)
│   │   ├── providers.tf     # Оголошення провайдерів
│   │   ├── values.yaml      # Конфігурація jenkins
│   │   └── outputs.tf       # Виводи (URL, пароль адміністратора)
│   │ 
│   └── argo_cd/             # ✅ Новий модуль для Helm-установки Argo CD
│       ├── jenkins.tf       # Helm release для Jenkins
│       ├── variables.tf     # Змінні (версія чарта, namespace, repo URL тощо)
│       ├── providers.tf     # Kubernetes+Helm.  переносимо з модуля jenkins
│       ├── values.yaml      # Кастомна конфігурація Argo CD
│       ├── outputs.tf       # Виводи (hostname, initial admin password)
│		    └──charts/                  # Helm-чарт для створення app'ів
│ 	 	    ├── Chart.yaml
│	  	    ├── values.yaml          # Список applications, repositories
│			    └── templates/
│		        ├── application.yaml
│		        └── repository.yaml
├── charts/
│   └── django-app/
│       ├── templates/
│       │   ├── deployment.yaml
│       │   ├── service.yaml
│       │   ├── configmap.yaml
│       │   └── hpa.yaml
│       ├── Chart.yaml
│       └── values.yaml     # ConfigMap зі змінними середовища

```


**Необхідні пакети:**
- AWS CLI
- Terraform
- kubectl
- Helm
- Docker
- Git


**Команди для ініціалізації та запуску:**

1. ***Підготовка доступу**

aws eks update-kubeconfig --region us-west-2 --name lesson-8-9-eks-cluster #update cluster

1. **Підготовка інфраструктури**

```
git clone https://github.com/didukhroma/my-microservice-project.git

cd my-microservice-project

# Ініціалізація Terraform
terraform init

# Перевірка плану змін
terraform plan

# Створення інфраструктури
terraform apply

```
2. **Налаштування Kubernetes**

```
# Підключення до EKS-кластеру
aws eks update-kubeconfig --region us-west-2 --name lesson-8-9-eks-cluster

# Перевірка нод
kubectl get nodes
```

3. **Підготовка Docker-образу**
```
# Перехід в Django-проєкт
cd ./docker/django_app

# Збірка образу 
docker build --no-cache -t lesson-8-9-django-app .

# Логін у ECR
aws ecr get-login-password --region us-west-2 \
  | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com

# Додавання тегу
docker tag lesson-8-9-django-app:latest ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-django-app:latest

# Завантаження
docker push ACCOUNT_ID.dkr.ecr.us-west-2.amazonaws.com/lesson-8-9-django-app:latest
```
4. **Helm**
```
#Перехід в корінь проекту
cd ../../

# Встановлення Helm
helm install django-app ./charts/django-app

# Перевірка статусу
helm status django-app
kubectl get all
```
![alt text](asserts/all.png)

5. **Доступ до застосунку**
```
# Отримання зовнішнього IP 
kubectl get service django-app
```

Робоча сторінка
![alt text](asserts/web-page.png)

