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

    
    REPO_URL   = "https://github.com/didukhroma/my-microservice-project.git"
    APP_BRANCH = "dev"

    // GitOps / Helm chart repo 
    GITOPS_REPO_URL = "https://github.com/didukhroma/my-microservice-project.git"
    CHART_BRANCH    = "main"               
    CHART_PATH      = "lesson-7/charts/django-app"

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
          sh '''
            set -eux

            rm -rf gitops-repo || true
            git clone --depth 1 --branch "$CHART_BRANCH" "$GITOPS_REPO_URL" gitops-repo

            cd gitops-repo/"$CHART_PATH"

            sed -i.bak "s/^  tag: .*/  tag: $IMAGE_TAG/" values.yaml
            rm -f values.yaml.bak

            git config user.email "$COMMIT_EMAIL"
            git config user.name "$COMMIT_NAME"

            git add values.yaml
            git commit -m "chore(pipeline): Update Django-App chart tag to $IMAGE_TAG" || echo "No changes to commit"
            git push origin "$CHART_BRANCH"
          '''
        }
      }
    }
  }
}
