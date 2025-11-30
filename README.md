# Даний проєкт реалізує повний CI/CD-процес для Django-застосунку з використанням сучасних DevOps-практик та інструментів:

* Terraform – інфраструктура як код (IaC) для створення та управління хмарними ресурсами.
* Jenkins – система Continuous Integration для автоматизованої збірки та публікації Docker-образів.
* Argo CD – інструмент Continuous Deployment, що забезпечує GitOps-підхід до доставки застосунку.
* Kubernetes (EKS) – платформа оркестрації контейнерів для масштабованого розгортання.
* Helm – управління конфігураціями Kubernetes через чарт-пакети.
* RDS/Aurora – інтеграція з керованою базою даних AWS (універсальний модуль для роботи з різними сервісами).

**Структура проєкту**
```
Project/
│
├── main.tf         # Головний файл для підключення модулів
├── backend.tf        # Налаштування бекенду для стейтів (S3 + DynamoDB
├── outputs.tf        # Загальні виводи ресурсів
│
├── modules/         # Каталог з усіма модулями
│  ├── s3-backend/     # Модуль для S3 та DynamoDB
│  │  ├── s3.tf      # Створення S3-бакета
│  │  ├── dynamodb.tf   # Створення DynamoDB
│  │  ├── variables.tf   # Змінні для S3
│  │  └── outputs.tf    # Виведення інформації про S3 та DynamoDB
│  │
│  ├── vpc/         # Модуль для VPC
│  │  ├── vpc.tf      # Створення VPC, підмереж, Internet Gateway
│  │  ├── routes.tf    # Налаштування маршрутизації
│  │  ├── variables.tf   # Змінні для VPC
│  │  └── outputs.tf  
│  ├── ecr/         # Модуль для ECR
│  │  ├── ecr.tf      # Створення ECR репозиторію
│  │  ├── variables.tf   # Змінні для ECR
│  │  └── outputs.tf    # Виведення URL репозиторію
│  │
│  ├── eks/           # Модуль для Kubernetes кластера
│  │  ├── eks.tf        # Створення кластера
│  │  ├── aws_ebs_csi_driver.tf # Встановлення плагіну csi drive
│  │  ├── variables.tf   # Змінні для EKS
│  │  └── outputs.tf    # Виведення інформації про кластер
│  │
│  ├── rds/         # Модуль для RDS
│  │  ├── rds.tf      # Створення RDS бази даних  
│  │  ├── aurora.tf    # Створення aurora кластера бази даних  
│  │  ├── shared.tf    # Спільні ресурси  
│  │  ├── variables.tf   # Змінні (ресурси, креденшели, values)
│  │  └── outputs.tf  
│  │ 
│  ├── jenkins/       # Модуль для Helm-установки Jenkins
│  │  ├── jenkins.tf    # Helm release для Jenkins
│  │  ├── variables.tf   # Змінні (ресурси, креденшели, values)
│  │  ├── providers.tf   # Оголошення провайдерів
│  │  ├── values.yaml   # Конфігурація jenkins
│  │  └── outputs.tf    # Виводи (URL, пароль адміністратора)
│  │ 
│  └── argo_cd/       # ✅ Новий модуль для Helm-установки Argo CD
│    ├── jenkins.tf    # Helm release для Jenkins
│    ├── variables.tf   # Змінні (версія чарта, namespace, repo URL тощо)
│    ├── providers.tf   # Kubernetes+Helm. переносимо з модуля jenkins
│    ├── values.yaml   # Кастомна конфігурація Argo CD
│    ├── outputs.tf    # Виводи (hostname, initial admin password)
│		  └──charts/         # Helm-чарт для створення app'ів
│ 	 	  ├── Chart.yaml
│	 	  ├── values.yaml     # Список applications, repositories
│			  └── templates/
│		    ├── application.yaml
│		    └── repository.yaml
├── charts/
│  └── django-app/
│    ├── templates/
│    │  ├── deployment.yaml
│    │  ├── service.yaml
│    │  ├── configmap.yaml
│    │  └── hpa.yaml
│    ├── Chart.yaml
│    └── values.yaml   # ConfigMap зі змінними середовища
└──Django
			 ├── app\
			 ├── Dockerfile
			 ├── Jenkinsfile
			 └── docker-compose.yaml

```


**Необхідні пакети:**
- AWS CLI
- Terraform
- kubectl
- Helm
- Docker
- Git


# Terraform-модуль `rds`

Універсальний Terraform-модуль для створення бази даних в AWS, який може розгортати:

- **звичайний RDS інстанс** (PostgreSQL / MySQL), або  
- **Aurora кластер** з репліками,

в залежності від прапора `use_aurora`.

Модуль автоматично створює:

- **DB Subnet Group** (на основі приватних сабнетів),
- **Security Group** з доступом за CIDR та/або з інших SG,
- **Parameter Group** для RDS або Aurora,
- RDS **instance** або **Aurora cluster + instances**.

---

## Приклад використання модуля

### 1. Класичний RDS PostgreSQL

```hcl
module "rds" {
  source = "./modules/rds"

  project_name = "final-project-devops"
  environment  = "dev"

  # Тип БД
  use_aurora     = false
  engine         = "postgres"
  engine_version = "16.9"
  instance_class = "db.t3.micro"

  # База та креденшіали
  db_name         = "djangodb"
  master_username = "djangouser"
  master_password = null # якщо null – пароль згенерується random_password

  # Мережа
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # Доступ
  allowed_cidr_blocks = [
    "10.0.4.0/24",
    "10.0.5.0/24",
    "10.0.6.0/24",
  ]

  # Додаткові налаштування
  multi_az                = false
  storage_encrypted       = true
  allocated_storage       = 20
  storage_type            = "gp2"
  backup_retention_period = 3
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"
  deletion_protection     = false
  skip_final_snapshot     = true
  copy_tags_to_snapshot   = true
  monitoring_interval     = 0
  performance_insights_enabled = false

  custom_db_parameters = [
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "checkpoint_completion_target"
      value = "0.9"
    }
  ]

  tags = {
    Project     = "final-project-devops"
    Environment = "dev"
    ManagedBy   = "terraform"
    Module      = "rds"
    Purpose     = "django-database"
  }
}
```

### 2. Aurora PostgreSQL кластер з репліками
```module "rds" {
  source = "./modules/rds"

  project_name = "final-project-devops"
  environment  = "prod"

  # Вмикаємо Aurora
  use_aurora     = true
  engine         = "postgres"
  engine_version = "16.2"
  instance_class = "db.r6g.large"

  db_name         = "appdb"
  master_username = "appuser"
  master_password = null

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  allowed_security_group_ids = [
    module.eks.worker_sg_id, # приклад
  ]

  aurora_replica_count = 2

  multi_az                = true            # для Aurora – multi-AZ на рівні кластеру
  storage_encrypted       = true
  backup_retention_period = 7
  deletion_protection     = true
  skip_final_snapshot     = false
  copy_tags_to_snapshot   = true

  monitoring_interval          = 60
  performance_insights_enabled = true

  custom_db_parameters = [
    {
      name  = "max_connections"
      value = "500"
    }
  ]

  tags = {
    Project     = "final-project-devops"
    Environment = "prod"
    ManagedBy   = "terraform"
    Module      = "rds"
    Purpose     = "app-database"
  }
}
```
### 3 Опис змінних
| Змінна                         | Тип                             | Обов’язкова | За замовчуванням        | Опис                                                                                                                 |
| ------------------------------ | ------------------------------- | ----------- | ----------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `project_name`                 | `string`                        | ні          | `"final-project-devops"`          | Назва проєкту, використовується в іменах ресурсів і тегах.                                                           |
| `environment`                  | `string`                        | ні          | `"dev"`                 | Назва середовища: `dev`, `stage`, `prod` тощо.                                                                       |
| `use_aurora`                   | `bool`                          | ні          | `false`                 | Якщо `true` — створюється Aurora cluster, якщо `false` — звичайний RDS instance.                                     |
| `engine`                       | `string`                        | ні          | `"postgres"`            | Тип СУБД: підтримуються `"postgres"` або `"mysql"`.                                                                  |
| `engine_version`               | `string`                        | ні          | `"13.7"`                | Версія engine (наприклад `"16.9"` для PostgreSQL). Впливає на `engine` ресурсу та сім’ю parameter group.             |
| `instance_class`               | `string`                        | ні          | `"db.t3.micro"`         | Клас інстансу, наприклад `db.t3.micro`, `db.m5.large` тощо.                                                          |
| `allocated_storage`            | `number`                        | ні          | `20`                    | Об’єм диску в GB для **класичного RDS**. Для Aurora ігнорується.                                                     |
| `storage_type`                 | `string`                        | ні          | `"gp2"`                 | Тип storage для RDS (наприклад, `gp2`, `gp3`, `io1`).                                                                |
| `storage_encrypted`            | `bool`                          | ні          | `true`                  | Чи шифрувати зберігання даних (RDS/Aurora).                                                                          |
| `db_name`                      | `string`                        | ні          | `"djangodb"`            | Назва бази даних, яка буде створена.                                                                                 |
| `master_username`              | `string`                        | ні          | `"admin"`               | Master user для БД.                                                                                                  |
| `master_password`              | `string` (sensitive)            | ні          | `null`                  | Пароль master user. Якщо `null`, модуль генерує пароль за допомогою `random_password`.                               |
| `multi_az`                     | `bool`                          | ні          | `false`                 | Для RDS: чи вмикати Multi-AZ. Для Aurora кластер inherently multi-AZ, але прапор може використовуватися для політик. |
| `backup_retention_period`      | `number`                        | ні          | `7`                     | Кількість днів зберігання бекапів.                                                                                   |
| `backup_window`                | `string`                        | ні          | `"03:00-04:00"`         | Вікно для автоматичних бекапів у форматі `HH:MM-HH:MM`.                                                              |
| `maintenance_window`           | `string`                        | ні          | `"sun:04:00-sun:05:00"` | Вікно для обслуговування (патчі/оновлення).                                                                          |
| `vpc_id`                       | `string`                        | **так**     | –                       | ID VPC, де буде створено БД та security group.                                                                       |
| `subnet_ids`                   | `list(string)`                  | **так**     | –                       | Список **приватних** subnet IDs для DB Subnet Group.                                                                 |
| `allowed_security_group_ids`   | `list(string)`                  | ні          | `[]`                    | Список SG IDs, яким дозволено доступ до БД (наприклад, SG нод EKS).                                                  |
| `allowed_cidr_blocks`          | `list(string)`                  | ні          | `[]`                    | Список CIDR-блоків, яким дозволено доступ до БД. Зручно для внутрішніх підмереж VPC.                                 |
| `port`                         | `number`                        | ні          | `null`                  | Порт БД. Якщо `null`, використовується `5432` для Postgres або `3306` для MySQL.                                     |
| `deletion_protection`          | `bool`                          | ні          | `false`                 | Захист від видалення. Якщо `true`, Terraform не зможе видалити БД без ручних змін.                                   |
| `skip_final_snapshot`          | `bool`                          | ні          | `true`                  | Чи пропускати фінальний snapshot при видаленні БД. Для prod зазвичай ставлять `false`.                               |
| `copy_tags_to_snapshot`        | `bool`                          | ні          | `true`                  | Чи копіювати теги БД на snapshot’и.                                                                                  |
| `monitoring_interval`          | `number`                        | ні          | `0`                     | Інтервал Enhanced Monitoring в секундах. `0` = вимкнено.                                                             |
| `performance_insights_enabled` | `bool`                          | ні          | `false`                 | Чи вмикати Performance Insights. Для prod може бути корисно, але дорожче.                                            |
| `tags`                         | `map(string)`                   | ні          | `{}`                    | Додаткові теги для всіх створених ресурсів.                                                                          |
| `aurora_replica_count`         | `number`                        | ні          | `1`                     | Кількість Aurora instances (реплік). Використовується лише якщо `use_aurora = true`.                                 |
| `custom_db_parameters`         | `list(object({ name, value }))` | ні          | `[]`                    | Список кастомних параметрів, які будуть застосовані до parameter group (RDS або Aurora).                             |


Як змінити тип БД, engine, клас інстансу тощо
1. Перехід між RDS та Aurora

Звичайний RDS:
```
use_aurora = false
```

Модуль створить:

* aws_db_instance

* aws_db_parameter_group

* aws_db_subnet_group

* aws_security_group

Aurora Cluster:
```
use_aurora = true
aurora_replica_count = 2 # кількість інстансів у кластері
```

Модуль створить:

* aws_rds_cluster

* aws_rds_cluster_instance (N штук)

* aws_rds_cluster_parameter_group

* aws_db_subnet_group

* aws_security_group

⚠️ Перемикання use_aurora з false на true (або навпаки) зазвичай призведе до destroy + create БД. Для продакшену потрібна окрема стратегія міграції.

2. Зміна типу engine (PostgreSQL ↔ MySQL)

Для PostgreSQL:
```
engine         = "postgres"
engine_version = "16.9"
```

Для MySQL:
```
engine         = "mysql"
engine_version = "8.0.35"
```

Модуль:

* сам обере правильний порт (5432 чи 3306, якщо var.port = null),

* побудує правильне parameter_group family (наприклад, postgres16, mysql8 чи aurora-postgresql16, aurora-mysql8).

Важливо, щоб engine_version відповідала реально існуючій сім’ї параметрів в AWS. Якщо сім’ї ще немає (наприклад, дуже нова версія), може знадобитись ручна правка сім’ї.

3. Зміна класу інстансу
```
instance_class = "db.t3.micro"   # dev
instance_class = "db.m6g.large"  # prod
```

Це впливає на:

* aws_db_instance (RDS),

* aws_rds_cluster_instance (Aurora).

При зміні класу інстансу Terraform виконає modify ресурсу (можливий короткий downtime, залежно від налаштувань).

4. Налаштування продуктивності та HA

Multi-AZ (для звичайної RDS):
```
multi_az = true
```

Бекапи та вікна:
```
backup_retention_period = 7
backup_window           = "03:00-04:00"
maintenance_window      = "sun:04:00-sun:05:00"
```

Шифрування, захист та snapshot’и:
```
storage_encrypted     = true
deletion_protection   = true
skip_final_snapshot   = false
copy_tags_to_snapshot = true
```

Enhanced Monitoring та Performance Insights:
```
monitoring_interval          = 60
performance_insights_enabled = true
```
5. Кастомні параметри БД

Через custom_db_parameters можна змінювати параметри у parameter group:
```
custom_db_parameters = [
  {
    name  = "max_connections"
    value = "200"
  },
  {
    name  = "work_mem"
    value = "16MB"
  }
]
```

Модуль однаково додає ці параметри:

* у aws_db_parameter_group (якщо use_aurora = false), або

* у aws_rds_cluster_parameter_group (якщо use_aurora = true).

Цей модуль можна повторно використовувати в різних середовищах (dev/stage/prod), змінюючи тільки вхідні змінні — логику створення інфраструктури він бере на себе.
Якщо треба, його легко розширити (наприклад, додати IAM-ролі для моніторингу, KMS key для шифрування, окремі параметри для prod).

![alt text](/asserts/img-3.png)