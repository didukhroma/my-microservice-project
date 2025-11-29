
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
    container('git') {
      withCredentials([
        usernamePassword(
          credentialsId: 'github-pat',
          usernameVariable: 'GIT_USER',
          passwordVariable: 'GIT_TOKEN'
        )
      ]) {
        sh '''
          set -eux

          rm -rf gitops-repo || true

          REPO_URL="https://${GIT_USER}:${GIT_TOKEN}@github.com/didukhroma/my-microservice-project.git"

          # 1) Клонуємо lesson-8-9
          git clone --depth 1 --branch "$CHART_BRANCH" "$REPO_URL" gitops-repo

          cd gitops-repo

          CHART_FILE="charts/django-app/values.yaml"

          # 2) Оновлюємо тег у values.yaml
          sed -i.bak "s/^  tag: \\".*\\"/  tag: \\"$IMAGE_TAG\\"/" "$CHART_FILE"
          rm -f "$CHART_FILE.bak"

          git config user.email "$COMMIT_EMAIL"
          git config user.name "$COMMIT_NAME"

          git add "$CHART_FILE"
          git commit -m "chore(pipeline): Update Django-App image tag to $IMAGE_TAG" || echo "No changes to commit"

          # 3) Пушимо lesson-8-9
          git push "$REPO_URL" "$CHART_BRANCH"

          # 4) Підтягуємо main і створюємо локальну гілку main
          git fetch "$REPO_URL" "$MAIN_BRANCH:$MAIN_BRANCH"
          git checkout "$MAIN_BRANCH"

          # 5) Fast-forward merge lesson-8-9 -> main
          git merge --ff-only "$CHART_BRANCH"

          # 6) Пушимо main
          git push "$REPO_URL" "$MAIN_BRANCH"
        '''
      }
    }
  }
}


  }
}
