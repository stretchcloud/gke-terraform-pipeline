terraform init
terraform plan -out thoughtwork-clus-plan
terraform apply "thoughtwork-clus-plan"
gcloud container clusters get-credentials $(terraform output cluster_name) --zone=$(terraform output primary_zone)


kubectl apply -f tiller-role.yaml
helm init --service-account tiller
sleep 30
helm install --name my-jk stable/jenkins


NOTES:
1. Get your 'admin' user password for Jenkins by running:

printf $(kubectl get secret --namespace default my-jk-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

2. Get the Jenkins URL to visit by running these commands in the same shell:
  NOTE: It may take a few minutes for the LoadBalancer IP to be available.
        You can watch the status of by running 'kubectl get svc --namespace default -w my-jk-jenkins'

export SERVICE_IP=$(kubectl get svc --namespace default my-jk-jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
echo http://$SERVICE_IP:8080/login

3. Login with the password from step 1 and the username: admin


gcloud compute firewall-rules create jk-svc --allow tcp:8080


gsutil mb -c regional -l europe-west4 gs://nth-record-246512-tfstate
terraform init
yes

base64 ./creds/serviceaccount.json


frontend - 

export NEWSFEED_SERVICE_TOKEN="T1&eWbYXNWG1w1^YGKDPxAWJ@^et^&kX"
export NEWSFEED_SERVICE_URL=http://newsfeed:8080
export QUOTE_SERVICE_URL=http://quotes:8080
export STATIC_URL=""
export APP_PORT=8080

docker network create tw
docker cp . 4c0583c4220d:/home/

docker run -e APP_PORT=8080 -e STATIC_URL="" -e QUOTE_SERVICE_URL=http://quotes:8080 -e NEWSFEED_SERVICE_URL=http://newsfeed:8080 -e NEWSFEED_SERVICE_TOKEN="T1&eWbYXNWG1w1^YGKDPxAWJ@^et^&kX" --name frontend -p 8082:8080 --network tw frontend:1.0

docker run -e APP_PORT=8080 --name newsfeed -p 8081:8080 --network tw newsfeed:1.0

docker run -e APP_PORT=8080 --name quotes -p 8080:8080 --network tw quotes:1.0


kubectl create -f quotes-deploy.yaml
kubectl create -f quotes-service.yaml 

kubectl create -f newsfeed-deploy.yaml
kubectl create -f newsfeed-service.yaml

kubectl create -f secret.yaml
kubectl create -f frontend-deploy.yaml
kubectl create -f frontend-service.yaml 

1.13.7-gke.8