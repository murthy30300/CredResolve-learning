pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = "sbdemo3"
        CONTAINER_NAME = "sbdemo3-container"
    }

    tools {
        maven 'Maven3'
    }

    stages {

        stage('Clone Repo') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/murthy30300/CredResolve-learning.git'
            }
        }

        stage('Build JAR') {
            steps {
                dir('PROJECT3/sbdemo3') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('PROJECT3/sbdemo3') {
                    sh 'docker build -t $IMAGE_NAME .'
                }
            }
        }

        stage('Stop Old Container') {
            steps {
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true
                '''
            }
        }

        stage('Run Container') {
            steps {
                sh 'docker run -d -p 1700:8080 --name $CONTAINER_NAME $IMAGE_NAME'
            }
        }
    }

    post {
        success {
            echo 'Deployment successful! App running at http://<your-ec2-ip>:1700'
        }
        failure {
            echo 'Pipeline failed. Check the logs above.'
        }
    }
}
