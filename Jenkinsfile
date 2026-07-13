pipeline {

    agent any

    stages {

        stage('Build Docker') {

            steps {

                sh 'docker build -t narcisser/demo-devops:latest .'

            }

        }

        stage('Push Docker') {

            steps {

                sh 'docker push narcisser/demo-devops:latest'

            }

        }

        stage('Deploy Kubernetes') {

            steps {

                sh 'kubectl apply -f namespace.yaml'

                sh 'kubectl apply -f deployment.yaml'

                sh 'kubectl apply -f service.yaml'

                sh 'kubectl apply -f ingress.yaml'

            }

        }

    }

}
