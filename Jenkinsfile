pipeline {
    agent any

    triggers {
        githubPush()
    }

    environment {
        IMAGE_NAME     = "sbdemo3"
        CONTAINER_NAME = "sbdemo3-container"
        NOTIFY_EMAIL   = "2200030300cseh@gmail.com"

        LISTENER_ARN = "arn:aws:elasticloadbalancing:us-east-1:975894387333:listener/app/alb-spring-app/a03f2f010177033c/845688c248988e04"
        TG_BLUE_ARN  = "arn:aws:elasticloadbalancing:us-east-1:975894387333:targetgroup/tg-blue/303e7203f0c0993d"
        TG_GREEN_ARN = "arn:aws:elasticloadbalancing:us-east-1:975894387333:targetgroup/tg-green/280adc1bd29826c0"

        // Blue instance details
        BLUE_1_IP = "172.31.76.47"
        BLUE_2_IP = "172.31.69.120"
        BLUE_3_IP = "172.31.72.132"
        BLUE_1_ID = "i-09d0c85c83afa1a47"
        BLUE_2_ID = "i-08bfd35be387dcbb2"
        BLUE_3_ID = "i-0b62d83a8c08ee7b5"

        // Green instance details
        GREEN_1_IP = "172.31.74.33"
        GREEN_2_IP = "172.31.73.107"
        GREEN_3_IP = "172.31.74.43"
        GREEN_1_ID = "i-0e2ef091231b286b4"
        GREEN_2_ID = "i-02c6d2a003c039cf2"
        GREEN_3_ID = "i-0c218a848720348a0"

        PEM     = "/var/jenkins_home/jenkins.pem"
        ALB_URL = "http://alb-spring-app-857952563.us-east-1.elb.amazonaws.com"
    }

    tools {
        maven 'Maven3'
    }

    stages {

        // ─── DETECT ACTIVE ENVIRONMENT ───────────────

        stage('Detect Active Environment') {
            steps {
                sh '''
                    CURRENT_TG=$(aws elbv2 describe-listeners \
                        --listener-arns $LISTENER_ARN \
                        --query 'Listeners[0].DefaultActions[0].TargetGroupArn' \
                        --output text)

                    echo "Current active TG: $CURRENT_TG"

                    if [ "$CURRENT_TG" = "$TG_BLUE_ARN" ]; then
                        echo "ACTIVE_ENV=blue"          >  /tmp/bg_state
                        echo "IDLE_ENV=green"           >> /tmp/bg_state
                        echo "ACTIVE_TG=$TG_BLUE_ARN"  >> /tmp/bg_state
                        echo "IDLE_TG=$TG_GREEN_ARN"   >> /tmp/bg_state
                        echo "DEPLOY_1_IP=$GREEN_1_IP" >> /tmp/bg_state
                        echo "DEPLOY_2_IP=$GREEN_2_IP" >> /tmp/bg_state
                        echo "DEPLOY_3_IP=$GREEN_3_IP" >> /tmp/bg_state
                        echo "DEPLOY_1_ID=$GREEN_1_ID" >> /tmp/bg_state
                        echo "DEPLOY_2_ID=$GREEN_2_ID" >> /tmp/bg_state
                        echo "DEPLOY_3_ID=$GREEN_3_ID" >> /tmp/bg_state
                        echo "STOP_1_ID=$BLUE_2_ID"    >> /tmp/bg_state
                        echo "STOP_2_ID=$BLUE_3_ID"    >> /tmp/bg_state
                    else
                        echo "ACTIVE_ENV=green"         >  /tmp/bg_state
                        echo "IDLE_ENV=blue"            >> /tmp/bg_state
                        echo "ACTIVE_TG=$TG_GREEN_ARN" >> /tmp/bg_state
                        echo "IDLE_TG=$TG_BLUE_ARN"    >> /tmp/bg_state
                        echo "DEPLOY_1_IP=$BLUE_1_IP"  >> /tmp/bg_state
                        echo "DEPLOY_2_IP=$BLUE_2_IP"  >> /tmp/bg_state
                        echo "DEPLOY_3_IP=$BLUE_3_IP"  >> /tmp/bg_state
                        echo "DEPLOY_1_ID=$BLUE_1_ID"  >> /tmp/bg_state
                        echo "DEPLOY_2_ID=$BLUE_2_ID"  >> /tmp/bg_state
                        echo "DEPLOY_3_ID=$BLUE_3_ID"  >> /tmp/bg_state
                        echo "STOP_1_ID=$GREEN_1_ID"   >> /tmp/bg_state
                        echo "STOP_2_ID=$GREEN_2_ID"   >> /tmp/bg_state
                    fi

                    echo "======= Deployment Plan ======="
                    cat /tmp/bg_state
                    echo "================================"
                '''
            }
        }

        // ─── BUILD STAGES ────────────────────────────

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
                        subject: "UNIT TESTS FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
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
                        subject: "UAT TESTS FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
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

        // ─── START IDLE INSTANCES ─────────────────────

        stage('Start Idle Instances') {
            steps {
                sh '''
                    . /tmp/bg_state
                    echo "Deploying to: $IDLE_ENV instances"
                    aws ec2 start-instances --instance-ids $DEPLOY_1_ID $DEPLOY_2_ID $DEPLOY_3_ID

                    echo "Waiting for instances to be running..."
                    aws ec2 wait instance-running --instance-ids $DEPLOY_1_ID $DEPLOY_2_ID $DEPLOY_3_ID

                    echo "Waiting 60s for OS to fully boot..."
                    sleep 60
                    echo "$IDLE_ENV instances are up!"
                '''
            }
        }

        // ─── DEPLOY TO IDLE ENVIRONMENT ──────────────

        stage('Copy JAR to Idle Instances') {
            steps {
                sh '''
                    . /tmp/bg_state
                    JAR_PATH=$(find PROJECT3/sbdemo3/target -name "*.jar" | head -1)

                    scp -i $PEM -o StrictHostKeyChecking=no $JAR_PATH ubuntu@${DEPLOY_1_IP}:/home/ubuntu/app.jar
                    scp -i $PEM -o StrictHostKeyChecking=no $JAR_PATH ubuntu@${DEPLOY_2_IP}:/home/ubuntu/app.jar
                    scp -i $PEM -o StrictHostKeyChecking=no $JAR_PATH ubuntu@${DEPLOY_3_IP}:/home/ubuntu/app.jar

                    echo "JAR copied to all $IDLE_ENV instances"
                '''
            }
        }

        stage('Deploy to Idle Instances') {
            steps {
                sh '''
                    . /tmp/bg_state
                    for HOST in $DEPLOY_1_IP $DEPLOY_2_IP $DEPLOY_3_IP; do
                        ssh -i $PEM -o StrictHostKeyChecking=no ubuntu@$HOST "
                            sudo systemctl stop springapp || true
                            sudo systemctl start springapp
                        "
                        echo "Deployed to $HOST"
                    done
                '''
            }
        }

        stage('Health Check Idle Instances') {
            steps {
                sh '''
                    . /tmp/bg_state
                    echo "Waiting for $IDLE_ENV instances to warm up..."
                    sleep 20

                    for HOST in $DEPLOY_1_IP $DEPLOY_2_IP $DEPLOY_3_IP; do
                        RETRIES=5
                        COUNT=0
                        STATUS=000
                        until [ $COUNT -ge $RETRIES ]; do
                            STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://$HOST:1700/actuator/health)
                            if [ "$STATUS" = "200" ]; then
                                echo "$HOST is healthy"
                                break
                            fi
                            COUNT=$((COUNT+1))
                            echo "Attempt $COUNT failed on $HOST (HTTP $STATUS) - retrying in 15s..."
                            sleep 15
                        done
                        if [ "$STATUS" != "200" ]; then
                            echo "Health check FAILED on $HOST after $RETRIES attempts"
                            exit 1
                        fi
                    done
                    echo "All $IDLE_ENV instances healthy!"
                '''
            }
        }

        stage('Register Idle Instances to Target Group') {
            steps {
                sh '''
                    . /tmp/bg_state
                    aws elbv2 register-targets \
                        --target-group-arn $IDLE_TG \
                        --targets Id=$DEPLOY_1_ID,Port=1700 \
                                 Id=$DEPLOY_2_ID,Port=1700 \
                                 Id=$DEPLOY_3_ID,Port=1700

                    echo "Registered $IDLE_ENV targets - waiting 15 seconds..."
                    sleep 15
                    echo "Ready to switch!"
                '''
            }
        }

        // ─── SWITCH TRAFFIC ───────────────────────────

        stage('Approval Before Switch') {
            steps {
                sh '. /tmp/bg_state && echo "Switching from $ACTIVE_ENV → $IDLE_ENV"'
                input message: 'Idle environment is healthy. Switch ALB traffic now?',
                      ok: 'Yes, Switch Now'
            }
        }

        stage('Switch ALB') {
            steps {
                sh '''
                    . /tmp/bg_state
                    aws elbv2 modify-listener \
                        --listener-arn $LISTENER_ARN \
                        --default-actions Type=forward,TargetGroupArn=$IDLE_TG

                    echo "ALB now pointing to $IDLE_ENV"
                '''
            }
        }

        stage('Smoke Test via ALB') {
            steps {
                sh '''
                    . /tmp/bg_state
                    sleep 10
                    STATUS=$(curl -s -o /dev/null -w "%{http_code}" $ALB_URL/actuator/health)

                    if [ "$STATUS" != "200" ]; then
                        echo "Smoke test FAILED (HTTP $STATUS) - rolling back to $ACTIVE_ENV!"
                        aws elbv2 modify-listener \
                            --listener-arn $LISTENER_ARN \
                            --default-actions Type=forward,TargetGroupArn=$ACTIVE_TG
                        echo "Rolled back to $ACTIVE_ENV"
                        exit 1
                    fi

                    echo "Smoke test passed - $IDLE_ENV is now live!"
                '''
            }
        }

        stage('Deregister Old Active Instances') {
            steps {
                sh '''
                    . /tmp/bg_state
                    aws elbv2 deregister-targets \
                        --target-group-arn $ACTIVE_TG \
                        --targets Id=$DEPLOY_1_ID Id=$DEPLOY_2_ID Id=$DEPLOY_3_ID

                    echo "$ACTIVE_ENV deregistered - $IDLE_ENV is now production"
                '''
            }
        }

        // ─── UPDATE BLUE-1 CONTAINER (always) ────────

        stage('Update Blue-1 Container') {
            steps {
                sh '''
                    docker stop $CONTAINER_NAME || true
                    docker rm $CONTAINER_NAME || true
                    docker run -d -p 1700:8080 --name $CONTAINER_NAME $IMAGE_NAME
                    echo "Blue-1 container updated"
                '''
            }
        }

        // ─── STOP OLD ACTIVE INSTANCES ────────────────

        stage('Stop Old Active Instances') {
            steps {
                sh '''
                    . /tmp/bg_state
                    echo "Stopping old $ACTIVE_ENV instances (now idle)..."
                    aws ec2 stop-instances --instance-ids $STOP_1_ID $STOP_2_ID
                    echo "Stopped $STOP_1_ID and $STOP_2_ID. Deployment complete!"
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
                    <p><b>App URL:</b> http://alb-spring-app-857952563.us-east-1.elb.amazonaws.com</p>
                    <p><a href="${env.BUILD_URL}">View Build</a></p>
                """,
                mimeType: 'text/html'
            )
        }
        failure {
            emailext(
                to: "${NOTIFY_EMAIL}",
                subject: "B/G DEPLOY FAILED: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                body: """
                    <h2 style="color:red;">Deployment Failed!</h2>
                    <p><b>Job:</b> ${env.JOB_NAME}</p>
                    <p><b>Build Number:</b> ${env.BUILD_NUMBER}</p>
                    <p><b>Note:</b> If ALB was switched, auto-rollback was attempted.</p>
                    <p><a href="${env.BUILD_URL}console">View Console Logs</a></p>
                """,
                mimeType: 'text/html'
            )
        }
    }
}