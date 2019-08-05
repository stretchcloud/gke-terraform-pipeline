# Future Work

As per the client requirement, they should be able to extend these Infrastructure as Code scripts via a CI server to build a deployment pipeline.

Also they should be able to add more environments and extend and harden the system later on.



### Deploy a CI Server



We will use Jenkins as our CI server to extend the Terraform scripts to add and manage envionment. 

For deploying Jenkins, we will use Helm chart.



Install the helm binary, initialise it and deploy the Jenkins.

```bash
$ curl -LO https://git.io/get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh

$ kubectl apply -f tiller-role.yaml
$ helm init --service-account tiller
$ helm install --name my-jk stable/jenkins

$ printf $(kubectl get secret --namespace default my-jk-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
$ export SERVICE_IP=$(kubectl get svc --namespace default my-jk-jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
$ echo http://$SERVICE_IP:8080/login

```



#### Configure Jenkins Server



Let's prepare the Jenkins server to serve the Pipeline for managing the GKE using Terraform state and Git hook.

Login to your Jenkins UI and navigate to **Manage Jenkins > Configure System**. Scroll down to the section for **Cloud > Kubernetes**, then look for **Kubernetes Pod Template **and **Container Template**.

Click **Add Container > Container Template** and use the following values:



![img](https://github.com/stretchcloud/twork/blob/master/container-template.png)



Then click **Save** at the bottom of this page.



We need to add the service account credentials to the Jenkins so that it can talk to the GCE and manage the state of the GKE Cluster.

```bash
$ base64 creds/serviceaccount.json
```



From the Jenkins UI, navigate to **Credentials > System > Global Credentials** then click **Add Credentials**, then:

1. From the **Kind** drop down select **Secret text.**
2. Leave the Scope as **Global**
3. Specify the ID of `terraform-auth`
4. Copy the output of `base64` command entirely and paste it into the **Secret** box, then click **OK**.



#### Create the Pipeline

Let's create a pipeline in Jenkins to manage and add future environment of GKE. 

For this we need to upload the entire local code repo to a github. In this case we have it uploaded to the this [Github](https://github.com/stretchcloud/twork) repo. This repo also have the Jenkins Pipeline file already that we will be using to configure the pipeline.

Also, for this pipeline, rather than using Jenkins's default UI, we will use [Blue Ocean](https://plugins.jenkins.io/blueocean). 



Login to your Jenkins UI and navigate to **Manage Jenkins > Manage Plugins**. Click on **Available**, then type `blue ocean` on the Filter box.

Select the **Blue Ocean** and click on **Install without restart**.



This should get the Blue Ocean pipeline plug-in installed.



From the Jenkins UI, select **New Item** from the homepage. Specify that this item is a **Pipeline** and give it a name, then click **OK.**

Scroll down to the Pipeline section, and select **Pipeline script from SCM**, then choose **Git** and enter your repository [URL](https://github.com/stretchcloud/twork). Then click **Save**.

Select **Open Blue Ocean** from the menu on the left and Click **Run**.

On the **Terraform Apply** stage, click on Approve. 



At this stage as we have not changed our intial Terraform code, it won't apply any change to the K8S cluster that you have deployed. 



### Adding More Environment

The way we have configured the Jenkins, it will sync up the state information from the object store and sync it with Git hook to make sure that updates are applied.

To demonstrate this, add another K8S Node Pool to the `gkecluster.tf` file.



```bash
resource "google_container_node_pool" "extra-pool" {
  name               = "extra-node-pool"
  location              = "europe-west4-a"
  cluster            = "${google_container_cluster.primary.name}"
  initial_node_count = 1

  node_config {
    preemptible  = true
    machine_type = "n1-standard-1"

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/devstorage.read_only",
    ]
  }

}

```



Let's push this to the original Github repo.

```bash
$ git commit -m "adding more environment"
$ git push origin master
```



Go to the Jenkins UI.

Select **Open Blue Ocean** from the left panel.

Click on the **Pipeline**.

Click on **Run**.



It will spin up terraform pod on the kubernetes cluster and run git checkout to see a new commit.

![image-20190805170343158](https://github.com/stretchcloud/twork/blob/master/pipeline.png)



It will run terraform init and terraform plan -out myplan. 

At the approval stage, click on **Approve**.

It will apply the plan and retuen the output.



### Hardening the K8S Environment

Hardening a production k8s environment comes with many steps such as configuring Network Policies, Pod Security Policies, Adding CVE Vulnerability scanner to the Pipeline, restrict client authentication mode for the Kubernetes Dashboard, configure mTLS for the microservices that use certificates to authenticate etc.



In this case, we will demonstarte the lockdown of your Kubernetes Cluster Dashboard using a Read-Only token.

For Read-Only token, we need to first create a role and then a role binding with a custom definition. Then we will deploy the dashboard and login to the dashboard. Let's create the roles and binding first.



```bash
$ kubectl create -f dashboardcr.yaml
$ kubectl create -f dashboard-rolebinding.yaml
```



You are now ready to deploy your Dashboard and login with a token:

```bash
$ kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0-beta1/aio/deploy/recommended.yaml
```



Get the token to login to the Dashboard

```bash
$ kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep -i kubernetes-token-kqwjq | awk '{print $1}')
$ kubectl proxy

Access the Dashboard:

http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

Login with the token that you generate above.
```