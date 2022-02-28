#!/bin/sh

# Installing Kops
wget -O kops https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64
chmod +x ./kops
sudo mv ./kops /usr/local/bin/

# Installing Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Cluster Creation
kops create cluster \
    --name $NAME \
    --master-count 3 \
    --master-size t2.small \
    --node-count 2 \
    --node-size t2.medium \
    --zones $ZONES \
    --master-zones $ZONES \
    --networking kubenet \
    --kubernetes-version v1.14.8 \
    --cloud aws \
    --yes

# Installing Ingress
kubectl create \
    -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/ingress-nginx/v1.6.0.yaml

# Downloading files
mkdir pv &&\ 
cd pv &&\
wget https://raw.githubusercontent.com/CourseMaterial/practical-kubernetes/main/pv.yml https://raw.githubusercontent.com/CourseMaterial/practical-kubernetes/main/pvc.yml https://raw.githubusercontent.com/CourseMaterial/practical-kubernetes/main/jenkins-pv.yml &&\
cd ..

# Creating persistent volumes
cat pv/pv.yml \
    | sed -e \
    "s@REPLACE_ME_1@$VOLUME_ID_1@g" \
    | sed -e \
    "s@REPLACE_ME_2@$VOLUME_ID_2@g" \
    | sed -e \
    "s@REPLACE_ME_3@$VOLUME_ID_3@g" \
    | kubectl create -f - \
    --save-config

# Claiming persistent volumes
kubectl create namespace jenkins &&\
kubectl create -f pv/pvc.yml \
    --save-config

# Deploying Jenkins
kubectl apply \
    -f pv/jenkins-pv.yml