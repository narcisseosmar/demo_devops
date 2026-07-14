pipeline {
    agent any

    environment {
        IMAGE = "narcisser/demo-devops:${BUILD_NUMBER}"
    }

    stages {

        stage('Build') {
            steps {
                sh 'docker build --no-cache -t $IMAGE .'
            }
        }

        stage('Push') {
            steps {
                sh 'docker push $IMAGE'
            }
        }

        stage('Deploy') {
            steps {
                sh '''
                kubectl set image deployment/html-app \
                html=$IMAGE \
                -n production

                kubectl rollout status deployment/html-app -n production
                '''
            }
        }
    }
}
