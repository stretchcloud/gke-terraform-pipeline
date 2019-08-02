terraform init
terraform apply "thoughtwork-clus-plan"
terraform apply "thoughtwork-clus-plan"
gcloud container clusters get-credentials $(terraform output cluster_name) --zone=$(terraform output primary_zone)


kubectl apply -f tiller-role.yaml
helm init --service-account tiller
helm install --name my-jk -f values.yaml stable/jenkins


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