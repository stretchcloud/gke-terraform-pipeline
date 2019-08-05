# Basic Cloud Test Environment

As per the client requirement, we need to deploy and run the given three Microservices in such a way that it require minimal developer interaction to create and deploy the infrastructure stack.



### Step

First of all, we need to make sure that we create three different container image to run the given three microservices and then deploy it on top of a container orchestration layer.

For the sake of simplicity and faster turn around, we choose Docker as the runtime of the container image and Kubernetes as the Orchestration Layer.

The fastest and cheaper way to get a Kubernetes environment is to use a Managed Kubernetes environment. 

We choose Google Cloud's Managed Kubernets Cluster to fulfill client's requirement. 



### Create the Docker Containers



We need to build the JAR first that we will use later on to create the Dockerfile.

```bash
$ git clone https://github.com/ThoughtWorksInc/infra-problem
$ cd infra-problem
$ brew install leiningen
$ make libs
$ make clean all
```



Let's construct three Dockerfiles namely Dockerfile.frontend, Dockerfile.newsfeed and Dockerfile.quotes.



##### Dockerfile.frontend

```dockerfile
FROM openjdk:8
COPY build/front-end.jar /usr/app/
WORKDIR /usr/app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "front-end.jar"]
```



##### Dockerfile.newsfeed

```dockerfile
FROM openjdk:8
COPY build/newsfeed.jar /usr/app/
WORKDIR /usr/app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "newsfeed.jar"]
```



##### Dockerfile.quotes

```dockerfile
FROM openjdk:8
COPY build/quotes.jar /usr/app/
WORKDIR /usr/app
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "quotes.jar"]
```



Let's build the containers, tag it appropriately and push it to docker hub.

```bash
$ docker build -f Dockerfile.quotes -t newsfeed:1.0 .
$ docker build -f Dockerfile.newsfeed -t newsfeed:1.0 .
$ docker build -f Dockerfile.frontend -t frontend:1.0 .
$ docker tag quotes:1.0 jit2600/quotes:latest
$ docker tag newsfeed:1.0 jit2600/newsfeed:latest
$ docker tag frontend:1.0 jit2600/frontend:latest
$ docker push jit2600/quotes:latest
$ docker psuh jit2600/newsfeed:latest
$ docker push jit2600/newsfeed:latest
$ docker push jit2600/frontend:latest

```



At this stage, our containers are ready to be deployed on top of GKE (Managed Kubernetes Engine of Google Cloud). 

As per the client's requirement, we need to deliver a Infrastructure as Code that they will use to deploy this entire software stack and also make sure that coplies with future work.

We assume that the customer is going to procure their own GCE environment.



#### Deploy GKE using Terraform

We will use Terraform to deploy the GKE and save the state of the Infrastructure in Google's Object Storage and we will use this method for our Future Scope of work (described in future section).



##### Create a Service Account, Enable API & create a bucket

Go to the Cloud Console, navigate to **IAM & Admin** > **Service Accounts**, and click **Create Service Account**.

Name the service account `terraform` and assign it the **Project Editor** role. Tick **Furnish a new private key** and click **Create**.

Download and save the file as `serviceaccount.json` under **creds/** directory.

From the Cloud Console, navigate to **APIs & Services** > **Dashboard**, then click **Enable APIs and Services**. Type ‘kubernetes’ in the search box, and you should find the Kubernetes Engine API. Then just click **Enable**.



Let’s create a Google Cloud Storage bucket to save the Terraform State (change *your-project-id*accordingly):

```bash
$ git clone https://github.com/stretchcloud/twork
$ cd twork
$ gsutil mb -c regional -l europe-west4 gs://nth-record-246512-tfstate
```



Let's deploy the GKE using Terraform

```bash
$ terraform init
$ terraform plan -out thoughtwork-clus-plan
$ terraform apply "thoughtwork-clus-plan"
```



Once your GKE is fully deployed, you should be able to get the K8S credentials and set it up to access your cluster using [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/). 

```bash
$ gcloud container clusters get-credentials $(terraform output cluster_name) --zone=$(terraform output primary_zone)
```



### Deploy the Microservices

Our K8S Cluster is ready and we should be able to deploy our application on top of it.

Let's deploy the newsfeed app.

```bash
$ kubectl create -f quotes-deploy.yaml
$ kubectl create -f quotes-service.yaml 

$ kubectl create -f newsfeed-deploy.yaml
$ kubectl create -f newsfeed-service.yaml

$ kubectl create -f secret.yaml
$ kubectl create -f frontend-deploy.yaml
$ kubectl create -f frontend-service.yaml 
```



Let's access the service load balancer url to see whether the application is up and running.

```bash
$ export SERVICE_IP=$(kubectl get svc --namespace default frontend --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
$ echo http://$SERVICE_IP:8080
```