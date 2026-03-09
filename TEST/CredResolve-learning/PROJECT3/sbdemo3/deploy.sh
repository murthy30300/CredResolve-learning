#!/bin/bash

VM_NAME="springboot-vm"
ZONE="asia-south1-a"

echo "Building jar..."
mvn clean package

echo "Copying jar to VM..."
gcloud compute scp target/*.jar $VM_NAME:/opt/app/app.jar --zone=$ZONE

echo "Restarting app..."
gcloud compute ssh $VM_NAME --zone=$ZONE --command="sudo systemctl restart app"

echo "Deployment complete!"
