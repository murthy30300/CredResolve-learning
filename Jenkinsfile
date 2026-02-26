pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = "sbdemo3"
        CONTAINER_NAME = "sbdemo3-container"
        NOTIFY_EMAIL = "your-email@gmail.com"
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

        stage('Unit Tests') {
            steps {
                dir('PROJECT3/sbdemo3') {
                    sh 'mvn test -Dgroups=!UAT'
                }
            }
            post {
                always {
                    dir('PROJECT3/sbdemo3') {
                        junit '**/target/surefire-reports/*.xml'
                    }
                }
                failure {
                    emailext(
                        to: "${NOTIFY_EMAIL}",
                        subject: "❌ UNIT TESTS FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2 style="color:red;">Unit Tests Failed!</h2>
                            <p><b>Job:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                            <p><b>Failed Stage:</b> Unit Tests</p>
                            <p><b>Root Cause:</b> One or more unit tests failed. Check the test report below.</p>
                            <p><a href="${env.BUILD_URL}testReport/">View Test Report</a></p>
                            <p><a href="${env.BUILD_URL}console">View Console Logs</a></p>
                        """,
                        mimeType: 'text/html',
                        attachmentsPattern: '**/surefire-reports/*.txt'
                    )
                }
            }
        }

        stage('UAT Tests') {
            steps {
                dir('PROJECT3/sbdemo3') {
                    sh 'mvn test -Dgroups=UAT'
                }
            }
            post {
                always {
                    dir('PROJECT3/sbdemo3') {
                        junit '**/target/surefire-reports/*.xml'
                    }
                }
                failure {
                    emailext(
                        to: "${NOTIFY_EMAIL}",
                        subject: "❌ UAT TESTS FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2 style="color:red;">UAT Tests Failed!</h2>
                            <p><b>Job:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                            <p><b>Failed Stage:</b> UAT Tests</p>
                            <p><b>Root Cause:</b> User Acceptance Tests failed. App may have broken endpoints or context load issues.</p>
                            <p><a href="${env.BUILD_URL}testReport/">View Test Report</a></p>
                            <p><a href="${env.BUILD_URL}console">View Console Logs</a></p>
                        """,
                        mimeType: 'text/html',
                        attachmentsPattern: '**/surefire-reports/*.txt'
                    )
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
                to: "${NOTIFY_EMAIL}",
                subject: "✅ BUILD SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2 style="color:green;">Build & Deployment Successful!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>All Tests Passed:</b> ✅ Unit Tests + UAT Tests</p>
                    <p><b>App Running At:</b> http://34.236.33.124:1700</p>
                    <p><a href="${env.BUILD_URL}testReport/">View Test Report</a></p>
                    <p><a href="${env.BUILD_URL}">View Build</a></p>
                """,
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "❌ BUILD FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2 style="color:red;">Build Failed!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Failed Stage:</b> ${env.STAGE_NAME}</p>
                    <p><b>Root Cause:</b> Check the console logs and test report for details.</p>
                    <p><a href="${env.BUILD_URL}testReport/">View Test Report</a></p>
                    <p><a href="${env.BUILD_URL}console">View Console Logs</a></p>
                """,
                mimeType: 'text/html'
            )
        }
    }
}