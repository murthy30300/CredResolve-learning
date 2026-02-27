pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME = "sbdemo3"
        CONTAINER_NAME = "sbdemo3-container"
        NOTIFY_EMAIL = "2200030300cseh@gmail.com"

        LISTENER_ARN = "arn:aws:elasticloadbalancing:us-east-1:975894387333:listener/app/alb-spring-app/a03f2f010177033c/845688c248988e04"
        TG_BLUE_ARN  = "arn:aws:elasticloadbalancing:us-east-1:975894387333:targetgroup/tg-blue/303e7203f0c0993d"
        TG_GREEN_ARN = "arn:aws:elasticloadbalancing:us-east-1:975894387333:targetgroup/tg-green/280adc1bd29826c0"

        GREEN_1 = "172.31.74.33"   
        GREEN_2 = "172.31.73.107"  
        GREEN_3 = "172.31.74.43"  

        GREEN_1_ID = "i-0e2ef091231b286b4"   
        GREEN_2_ID = "i-02c6d2a003c039cf2"   
        GREEN_3_ID = "i-0c218a848720348a0"   
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
                        subject: " UNIT TESTS FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2 style="color:red;">Unit Tests Failed!</h2>
                            <p><b>Job:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
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
                        subject: " UAT TESTS FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                        body: """
                            <h2 style="color:red;">UAT Tests Failed!</h2>
                            <p><b>Job:</b> ${env.JOB_NAME}</p>
                            <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
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

     
        stage('Copy JAR to Green Instances') {
            steps {
                sh '''
                    JAR_PATH=$(find PROJECT3/sbdemo3/target -name "*.jar" | head -1)

                    scp -i /var/jenkins_home/jenkins.pem -o StrictHostKeyChecking=no \
                    $JAR_PATH ubuntu@${GREEN_1}:/home/ubuntu/app.jar

                    scp -i /var/jenkins_home/jenkins.pem -o StrictHostKeyChecking=no \
                    $JAR_PATH ubuntu@${GREEN_2}:/home/ubuntu/app.jar

                    scp -i /var/jenkins_home/jenkins.pem -o StrictHostKeyChecking=no \
                    $JAR_PATH ubuntu@${GREEN_3}:/home/ubuntu/app.jar
                '''
            }
        }

        stage('Deploy to Green Instances') {
            steps {
                sh '''
                    for HOST in $GREEN_1 $GREEN_2 $GREEN_3; do
                        ssh -i /var/jenkins_home/jenkins.pem -o StrictHostKeyChecking=no ubuntu@$HOST "
                            sudo systemctl stop springapp || true
                            sudo systemctl start springapp
                        "
                    done
                '''
            }
        }

        stage('Health Check Green') {
            steps {
                sh '''
                    echo "Waiting for green instances to warm up..."
                    sleep 20

                    for HOST in $GREEN_1 $GREEN_2 $GREEN_3; do
                        STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$HOST:1700/actuator/health)
                        if [ "$STATUS" != "200" ]; then
                            echo " Health check FAILED on $HOST (got HTTP $STATUS)"
                            exit 1
                        fi
                        echo "$HOST is healthy"
                    done
                '''
            }
        }

        stage('Register Green to Target Group') {
    steps {
        sh '''
            aws elbv2 register-targets \
                --target-group-arn $TG_GREEN_ARN \
                --targets Id=$GREEN_1_ID,Port=1700 \
                         Id=$GREEN_2_ID,Port=1700 \
                         Id=$GREEN_3_ID,Port=1700

            echo "Registered green targets - waiting 15 seconds..."
            sleep 15
            echo "Ready to switch!"
        '''
    }
}

        stage('Approval Before Switch') {
            steps {
                input message: ' Green is healthy. Switch ALB traffic from Blue → Green?',
                      ok: 'Yes, Switch Now'
            }
        }

        stage('Switch ALB to Green') {
            steps {
                sh '''
                    aws elbv2 modify-listener \
                        --listener-arn $LISTENER_ARN \
                        --default-actions Type=forward,TargetGroupArn=$TG_GREEN_ARN

                    echo "ALB now pointing to GREEN"
                '''
            }
        }

        stage('Smoke Test via ALB') {
            steps {
                sh '''
                    sleep 10
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
                        http://alb-spring-app-857952563.us-east-1.elb.amazonaws.com/actuator/health)
                    
                    if [ "$STATUS" != "200" ]; then
                        echo "Smoke test FAILED (HTTP $STATUS) — rolling back to Blue!"

                        aws elbv2 modify-listener \
                            --listener-arn $LISTENER_ARN \
                            --default-actions Type=forward,TargetGroupArn=$TG_BLUE_ARN

                        echo " Rolled back to BLUE"
                        exit 1
                    fi

                    echo " Smoke test passed — GREEN is live!"
                '''
            }
        }

        stage('Deregister Blue from Target Group') {
            steps {
                 sh '''
                    aws elbv2 deregister-targets \
                        --target-group-arn $TG_BLUE_ARN \
                        --targets Id=$GREEN_1_ID Id=$GREEN_2_ID Id=$GREEN_3_ID

                    echo " Blue deregistered — Green is now production"
                '''
            }
        }

        stage('Update Blue-1 Container') {
            steps {
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true
                    docker run -d -p 1700:8080 --name $CONTAINER_NAME $IMAGE_NAME
                '''
            }
        }
    }

    post {
        success {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "B/G DEPLOY SUCCESS: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2 style="color:green;">Blue/Green Deployment Successful!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Status:</b> GREEN is now live </p>
                    <p><b>App URL:</b> http://alb-spring-app-857952563.us-east-1.elb.amazonaws.com</p>
                    <p><a href="${env.BUILD_URL}">View Build</a></p>
                """,
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: " B/G DEPLOY FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2 style="color:red;">Deployment Failed!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Note:</b> If ALB was switched, auto-rollback to Blue was attempted.</p>
                    <p><a href="${env.BUILD_URL}console">View Console Logs</a></p>
                """,
                mimeType: 'text/html'
            )
        }
    }
}