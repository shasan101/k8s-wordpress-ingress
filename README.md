# K8s deployment of Wordpress Site with MySql

The following document will take you granularly to host your wordpress site over a k8s cluster with a persistent storage setup for the Database.

## Pre-requisites: 
Vagrant machines or any cluster provided by any cloud provider. The machines should be able to communicate with each other, preferably over a private network.

This guide has been tested on:

## Steps to Follow:

Configure the cluster to setup NFS. One machine, preferably master, will be the NFS server and the rest would be the NFS clients.

To setup the machine as NFS Server, modify the &quot;install\_nfs\_server.sh&quot; script. You can change the directory where the drives will be mapped over the network and also update the CIDR block as per your cluster&#39;s network configurations.

To configure NFS client(s), run &quot;install\_nfs\_client.sh&quot;. Note: You can test your NFS setup by mapping a directory in the client to the server&#39;s directory that you have seen in the &quot;install\_nfs\_server.sh&quot; script.

The k8s cluster was setup with the help of: [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

In order to make use of the NFS in our K8s cluster we first need to create a Persistent Volume (PV) Object. This object will hold information such as which directory over which server has been chosen as the persistent volume from within our cluster. The PV object also contains reference to the Persistent Volume Claim (PVC) and to which namespace does the PVC belong to.

We can create the PV by running the following commands:

<code>kubectl apply -f nfs-pv.yml </code>

Before going with the usual flow, we need to take a detour so that we don&#39;t have to get stuck in the middle. Since we need to expose our app to the outside using Ingress and we&#39;ll be using the NGINX ingress. The guide from Nginx makes us create a namespace and then spawns the resources required to setup the Ingress. To achieve all that run:

<code> 
git clone [https://github.com/vipin-k/kubernetes-ingress.git](https://github.com/vipin-k/kubernetes-ingress.git) 
</code>
<br>
<code> 
cd kubernetes-ingress/
</code><br><code> 
cd deployments/ 
</code><br><code> 
kubectl apply -f common/ns-and-sa.yaml 
</code><br><code> 
kubectl apply -f common/default-server-secret.yaml 
</code><br><code> 
kubectl apply -f common/nginx-config.yaml 
</code><br><code> 
kubectl apply -f rbac/rbac.yaml 
</code><br><code> 
kubectl apply -f daemon-set/nginx-ingress.yaml 
</code><br><code> 
kubectl get pods -n nginx-ingress
</code><br>

After we have completely setup Nginx Ingress, we set the path based routing for our app:

<code>cd ../.. </code><br>
<code>kubectl apply -f ingress-nginx.yml</code>

Now we have an Ingress Listening on port 80 for any request for url, as specified in the &quot;ingress-nginx.yml&quot; file: &quot;wordpress.local.co&quot;.

Even though our Ingress has been set, we will only be getting 404 since there is no backend Service configured to serve the web requests.

Now we create PVC for our app.

<code>kubectl apply -f nfs-pvc.yml</code><br>

Once the PV and PVC has been created we can go ahead and start creating the deployment for our MySql backend.

As per our requirements, we needed to write the node IP of the pod to a -- persistent -- file whenever the DB pod gets started.

So for that to happen, we made use of InitContainer Property of the Deployment of our Pod(s). Also, we create a volume mapping of the volume, containing a log file inside the pod, with the PVC, so that we can get permission to store the data from outside the pod, too.

We create a Deployment which keeps track of all the pods that are, either, living or dead. Then we create a Service which will enable the communication between deployments (that are in a healthy and running state) and the other components of the cluster.

We do the same for our Wordpress frontend. Except we do not set the volume mapping for any pod and also, we do not create any InitContainer. If we want we can also map the volumes from the wordpress pod to the outside. (Here, we are assuming that our site is storing all the dynamic data inside the DB).

To create the Deployment and Service for MySql and Wordpress, run:

<code>kubectl apply -k myapp/</code><br>

To see if the complete setup is ready to serve run:

<code>kubectl get pods --namespace nginx-ingress</code><br>

Keep checking the output of the above command until the Status of the Wordpress and MySql pods is showing as Running.

In the end you will be able to browse your Wordpress app by either the browser or by just simply running:

<code>curl http:///wordpress.local.co/wp-admin/install.php</code><br>

Note: your system will only be able to route to this domain name if, either, it&#39;s hosted over a global DNS provider or you have an entry in the /etc/hosts file.

Simply run: 
<code>sudo echo &quot;127.0.0.1 wordpress.local.co&quot; \&gt;\&gt; /etc/hosts</code><br>

Voila!
