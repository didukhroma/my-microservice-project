
pipeline {
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
    - name: git
      image: alpine/git
      command: ["cat"]
      tty: true
      workingDir: "/workspace"
"""
    }
  }

  environment {
    // AWS / ECR
    AWS_REGION   = "us-west-2"
    ECR_REGISTRY = "757370076418.dkr.ecr.us-west-2.amazonaws.com"
    IMAGE_NAME   = "lesson-8-9-django-app"
    IMAGE_TAG    = "v1.0.${BUILD_NUMBER}"

    // App repo (цей же репозиторій з Dockerfile)
    REPO_URL   = "https://github.com/didukhroma/my-microservice-project.git"
    APP_BRANCH = "dev"

    // GitOps / Helm chart repo (МОЖЕ бути інший репозиторій)
    GITOPS_REPO_URL = "https://github.com/didukhroma/my-microservice-project.git"
    CHART_BRANCH    = "lesson-8-9"          
    MAIN_BRANCH     = "main"                
    CHART_PATH      = "charts/django-app"

    COMMIT_EMAIL = "jenkins@example.com"
    COMMIT_NAME  = "Jenkins Pipeline"
  }

  stages {

    stage('Checkout App Code') {
      steps {
        container('git') {
          sh '''
            set -eux
            rm -rf app-src || true
            git clone --depth 1 --branch "$APP_BRANCH" "$REPO_URL" app-src
            test -f app-src/docker/django_app/Dockerfile
          '''
        }
      }
    }

    stage('Build & Push Docker Image to ECR') {
      steps {
        container('kaniko') {
          withCredentials([
            string(credentialsId: 'aws-access-key-id',    variable: 'AWS_ACCESS_KEY_ID'),
            string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
          ]) {
            withEnv(["AWS_DEFAULT_REGION=${AWS_REGION}"]) {
              sh '''
                set -eux

                mkdir -p /kaniko/.aws/
                echo "[default]" > /kaniko/.aws/credentials
                echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> /kaniko/.aws/credentials
                echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> /kaniko/.aws/credentials

                mkdir -p /kaniko/.docker/
                echo "{\\"credsStore\\": \\"ecr-login\\"}" > /kaniko/.docker/config.json

                /kaniko/executor \
                  --context `pwd`/app-src/docker/django_app \
                  --dockerfile `pwd`/app-src/docker/django_app/Dockerfile \
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
        // Використовуємо Jenkins Credentials для безпечного отримання токена
        withCredentials([usernamePassword(
            credentialsId: 'github-pat', // Переконайтеся, що це правильний ID
            usernameVariable: 'GIT_USERNAME', 
            passwordVariable: 'GIT_TOKEN'
        )]) {
            container('git') {
                // Створення URL з токеном, який буде використовуватися для clone/push
                // Це призводить до попередження Groovy, але є необхідним для автентифікації
                sh "GITOPS_PUSH_URL=https://${GIT_USERNAME}:${GIT_TOKEN}@github.com/didukhroma/my-microservice-project.git"

                sh """
                    set -eux

                    # 1. Встановлюємо безпечну директорію для Git (виправлення "dubious ownership")
                    # Переконайтеся, що /workspace/workspace/Django-Kaniko-CI-CD є коректним шляхом до кореня пайплайну
                    git config --global --add safe.directory /workspace/workspace/Django-Kaniko-CI-CD
                    
                    rm -rf gitops-repo

                    # 2. Клонуємо репозиторій, використовуючи URL, що містить токен (\$GITOPS_PUSH_URL)
                    # \$CHART_BRANCH та \$GITOPS_PUSH_URL - змінні Groovy/Bash
                    git clone --depth 1 --branch "\$CHART_BRANCH" "\$GITOPS_PUSH_URL" gitops-repo

                    cd gitops-repo

                    CHART_FILE="charts/django-app/values.yaml"

                    # 3. Оновлюємо тег у values.yaml
                    sed -i.bak "s/^  tag: \\".*\\"/  tag: \\"\$IMAGE_TAG\\"/" "\$CHART_FILE"
                    rm -f charts/django-app/values.yaml.bak

                    # 4. Коміт у гілку \$CHART_BRANCH
                    git config user.email "\$COMMIT_EMAIL"
                    git config user.name "\$COMMIT_NAME"

                    git add "\$CHART_FILE"
                    git commit -m "chore(pipeline): Update Django-App image tag to \$IMAGE_TAG" || echo "No changes to commit (skipping commit)"
                    
                    # 5. Push у робочу гілку (origin тепер містить токен завдяки клонуванню)
                    git push origin "\$CHART_BRANCH"

                    # 6. Мержимо \$CHART_BRANCH -> \$MAIN_BRANCH
                    git fetch origin "\$MAIN_BRANCH"
                    git checkout "\$MAIN_BRANCH"
                    git merge --ff-only "\$CHART_BRANCH" || echo "Failed to merge (non-fast-forward or conflicts)"
                    
                    # 7. Push у головну гілку
                    git push origin "\$MAIN_BRANCH"
                """
            }
        }
    }
}

  }
}
