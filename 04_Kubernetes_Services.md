# Services

Services are the (basic) way to expose application on Kubernetes.

Create your first service manifest:

```yaml

apiVersion: v1
kind: Service
metadata:
  labels:
    run: podwithconfig
  name: podwithconfig-svc
  namespace: demo
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 80  
  selector:
    run: podwithconfig

```

Once the service is created, check the ip of the service and try to access the exposed pod:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get service -n demo
NAME                TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)          AGE
podwithconfig-svc   LoadBalancer   10.0.27.107   20.127.252.47   8080:30192/TCP   80s

```

We used the pod with config map that we created earlier. Use curl and your navigator to access the pod on its associated public IP.

```bash

yumemaru@Azure:~/LabAKS$ curl http://20.127.252.47:8080
<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is a configmap Index file </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html

```

The service is working with selector that match labels. Modify your service as follow:

```yaml

apiVersion: v1
kind: Service
metadata:
  labels:
    run: podwithconfig
  name: podwithconfig-svc
  namespace: demo
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    protocol: TCP
    targetPort: 80  
  selector:
    tier: front

```

If you now try to curl your service, you will get an error:

```bash

curl http://20.127.252.47:8080
curl: (28) Failed to connect to 20.127.252.47 port 8080 after 130843 ms: Connexion terminée par expiration du délai d'attente

```

that's because we change the label used as a selector. As of now, the pod does not have this label.
Let's add it:

```bash

yumemaru@Azure:~/LabAKS$ kubectl label pods -n demo podwithconfig tier=front
pod/podwithconfig labeled

```

Check that the label was added:


```bash

yumemaru@Azure:~/LabAKS$ kubectl get pods -n demo podwithconfig -o jsonpath='{.metadata.labels}'
{"run":"podwithconfig","tier":"front"}

```

If we try to curl the IP of the service, it should work:

```bash

yumemaru@Azure:~/LabAKS$ curl http://20.127.252.47:8080
<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is a configmap Index file </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html

```

It is possible to create a pod and a service in an imperative way, with only one command. This can sometime be useful for troubleshoting or testing.
Try this with the below command:

```bash

yumemaru@Azure:~/LabAKS$ kubectl run pod --image=nginx --labels="tier=front,app=nginxdemo" --expose --port=80 --dry-run=client -o yaml > podexposed.yaml

```

You shoud have created the configuration in the `podexposed.yaml` file:

```yaml

apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: nginxdemo
    tier: front
  name: pod
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: nginxdemo
    tier: front
status:
  loadBalancer: {}
---
---
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    app: nginxdemo
    tier: front
  name: pod
spec:
  containers:
  - image: nginx
    name: pod
    ports:
    - containerPort: 80
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}


```

Create the pod and the service either with the previous command, without the `--dry-run` argument or by using `kubectl apply`

```bash

yumemaru@Azure:~/LabAKS$ kubectl run pod --image=nginx --labels="tier=front,app=nginxdemo" --expose --port=80
service/pod created
pod/pod created

```

Let's verify that we have the selectors that match the labels. First use the following command to disply the labels of the pod:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get pod pod -o jsonpath='{.metadata.labels}'
{"app":"nginxdemo","tier":"front"}

```

The use the following command to display the selector of the service:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get service pod -o jsonpath='{.spec.selector}'
{"app":"nginxdemo","tier":"front"}

```

Note that the service does not have a public IP:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get service pod
NAME   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
pod    ClusterIP   10.0.104.202   <none>        80/TCP    6m11s

```

That's because its type is clusterIP rather than LoadBalancer:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get service pod -o jsonpath={'.spec.type'}
ClusterIP

```

We did not specify the type in the yaml manifest and it created a Cluster IP by default. 
On the other hand, the previous service was type LoadBalancer, as specified in the yaml manifest

```bash

yumemaru@Azure:~/LabAKS$ kubectl get service -n demo podwithconfig-svc -o jsonpath='{.spec.type}'
LoadBalancer

```