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
            emailext(
                to: '2200030300cseh@gmail.com',
                subject: " BUILD SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>Build Successful!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Status:</b> SUCCESS</p>
                    <p><a href="${env.BUILD_URL}">View Build</a></p>
                """,
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                to: 'srivis2005@gmail.com',
                subject: "❌ BUILD FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2>Build Failed!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Status:</b> FAILED</p>
                    <p><a href="${env.BUILD_URL}">View Build Logs</a></p>
                """,
                mimeType: 'text/html'
            )
        }
    }
}
