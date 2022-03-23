## demo app - developing with Kubernetes

This demo app shows a simple user profile app set up using
- server.js run web app
- mongo for data storage

All components are kubernetes

### With minikube

#### To start the application

Step 1: Moving docker environment to kubernetes

    eval $(minikube docker-env)

Step 2: Build python app image

    docker build -t mongo-demo-k8s .

Step 3: Create deployment and service    

    kubectl apply -f mongo-config.yaml
    kubectl apply -f mongo-secret.yaml
    kubectl apply -f mongo.yaml
    kubectl apply -f webapp.yaml

Step 4: Get public IP of minikube

    minikube ip #192.168.49.2

Step 5: Access you python application UI from browser

    curl http://192.168.49.2:30100