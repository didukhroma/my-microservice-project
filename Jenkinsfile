// Цей декларативний пайплайн виконує збірку Docker-образу в Kaniko (без daemon),
// пушить його до ECR, а потім оновлює values.yaml у гілці конфігурації (GitOps).

pipeline {
  // Динамічно створюємо Kubernetes Pod з двома контейнерами:
  // 1. kaniko (для збірки Docker-образів)
  // 2. git (для клонування, модифікації та пушу змін Git)
  agent {
    kubernetes {
      yaml """
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: jenkins-kaniko
spec:
  serviceAccountName: jenkins-admin 
  containers:
    - name: kaniko
      image: gcr.io/kaniko-project/executor:v1.16.0-debug
      imagePullPolicy: Always
      command: ["sleep"]
      args: ["99d"]
      workingDir: "/workspace" 
      # volumeMounts для AWS Secret ВИДАЛЕНО
    - name: git
      image: alpine/git
      command: ["cat"]
      tty: true
      workingDir: "/workspace"
  # volumes для AWS Secret ВИДАЛЕНО
"""
    }
  }

  environment {
    // AWS / ECR (Оновлено з Terraform output)
    AWS_REGION   = "us-west-2"
    ECR_REGISTRY = "757370076418.dkr.ecr.us-west-2.amazonaws.com"
    IMAGE_NAME   = "lesson-8-9-django-app"
    IMAGE_TAG    = "v1.0.${BUILD_NUMBER}"

    // Git
    REPO_URL     = "https://github.com/didukhroma/my-microservice-project.git"
    APP_BRANCH   = "dev"
    CHART_BRANCH = "lesson-7"
    CHART_PATH   = "lesson-5/charts/django-app"

    COMMIT_EMAIL = "jenkins@localhost"
    COMMIT_NAME  = "Jenkins CI"
  }

  stages {

    stage('Checkout App Code') {
      steps {
        container('git') {
          sh '''
            set -eux
            rm -rf app-src || true
            git clone --depth 1 --branch "$APP_BRANCH" "$REPO_URL" app-src
            test -f app-src/django-docker-project/Dockerfile
          '''
        }
      }
    }

    stage('Build & Push Docker Image to ECR') {
      steps {
        container('kaniko') {
            
          withCredentials([
            string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
          ]) {
            withEnv(["AWS_DEFAULT_REGION=${AWS_REGION}"]) {
              sh '''
                set -eux
                
                # Створюємо файл конфігурації AWS (credentials) для Kaniko
                # Kaniko може зчитувати облікові дані AWS з цього шляху
                mkdir -p /kaniko/.aws/
                echo "[default]" > /kaniko/.aws/credentials
                echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /kaniko/.aws/credentials
                echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /kaniko/.aws/credentials

                # Налаштовуємо Kaniko на використання ecr-login
                mkdir -p /kaniko/.docker/
                echo "{\\"credsStore\\": \\"ecr-login\\"}" > /kaniko/.docker/config.json
                
                # Запускаємо Kaniko executor
                /kaniko/executor \
                  --context `pwd`/app-src/django-docker-project \
                  --dockerfile `pwd`/app-src/django-docker-project/Dockerfile \
                  --destination=$ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG \
                  --destination=$ECR_REGISTRY/$IMAGE_NAME:latest \
                  --cache=true
                  
                echo "Successfully pushed image $ECR_REGISTRY/$IMAGE_NAME:$IMAGE_TAG to ECR."
              '''
            }
          }
        }
      }
    }

    stage('Update Chart Tag (GitOps)') {
      steps {
        container('git') {
          // Використовуємо Jenkins Secret Text Credential, що містить GitHub PAT
          withCredentials([string(credentialsId: 'github-pat-token', variable: 'GIT_PAT')]) {
            sh '''
              set -eux
              rm -rf chart-repo || true
              
              # Використовуємо Jenkins Secret Text (PAT) для автентифікації
              git clone --branch "$CHART_BRANCH" "https://oauth2:$GIT_PAT@github.com/didukhroma/my-microservice-project.git" chart-repo
              
              cd chart-repo/$CHART_PATH

              # Надійна заміна значення 'tag:' у values.yaml
              sed -i "" "s/^[[:space:]]*tag:[[:space:]].*/  tag: $IMAGE_TAG/" values.yaml

              git config user.email "$COMMIT_EMAIL"
              git config user.name "$COMMIT_NAME"
              
              # Комміт і Пуш змін
              if git diff --exit-code values.yaml; then
                echo "values.yaml already contains the tag $IMAGE_TAG. Nothing to commit."
              else
                git add values.yaml
                git commit -m "CI: Update image tag to $IMAGE_TAG by Jenkins build $BUILD_NUMBER"
                git push origin HEAD:"$CHART_BRANCH"
                echo "Successfully committed and pushed tag $IMAGE_TAG to $CHART_BRANCH."
              fi
            '''
          }
        }
      }
    }
  }
}