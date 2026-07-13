pipeline {

agent any


options {

buildDiscarder(
logRotator(
numToKeepStr:'10'
)
)

}


stages {


stage('Clone') {

steps {

git 'https://github.com/USER/demo-devops.git'

}

}


stage('Build Docker') {

steps {

sh 'docker build -t demo-html .'

}

}


stage('Deploy') {

steps {

sh 'kubectl apply -f k8s/'

}

}


}

}
