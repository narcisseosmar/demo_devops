pipeline {

    agent any

    stages {

        stage('Clone') {

            steps {

                git 'https://github.com/USER/html-app.git'

            }

        }

        stage('Docker Build') {

            steps {

                sh 'docker build -t USER/html-app:latest .'

            }

        }

        stage('Docker Push') {

            steps {

                sh 'docker push USER/html-app:latest'

            }

        }

        stage('Deploy Kubernetes') {

            steps {

                sh 'kubectl apply -f k8s/'
            }

        }

    }

}
