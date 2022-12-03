# Controllers

## 1. Deployment

```bash

yumemaru@Azure:~$ k get deployments.apps -A
NAMESPACE           NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
calico-system       calico-kube-controllers             1/1     1            1           8d
calico-system       calico-typha                        1/1     1            1           8d
default             aks-helloworld-one                  1/1     1            1           2d
default             aks-helloworld-two                  1/1     1            1           2d
gatekeeper-system   gatekeeper-audit                    1/1     1            1           8d
gatekeeper-system   gatekeeper-controller               2/2     2            2           8d
ingress-demo        ingress-nginx-controller            1/1     1            1           2d3h
kube-system         azure-policy                        1/1     1            1           8d
kube-system         azure-policy-webhook                1/1     1            1           8d
kube-system         coredns                             2/2     2            2           8d
kube-system         coredns-autoscaler                  1/1     1            1           8d
kube-system         konnectivity-agent                  2/2     2            2           8d
kube-system         metrics-server                      2/2     2            2           8d
kube-system         microsoft-defender-collector-misc   1/1     1            1           134m
tigera-operator     tigera-operator                     1/1     1            1           8d

```

```bash

yumemaru@Azure:~$ k describe deployment -n ingress-demo ingress-nginx-controller 
Name:                   ingress-nginx-controller
Namespace:              ingress-demo
CreationTimestamp:      Tue, 29 Nov 2022 13:47:16 +0100
Labels:                 app.kubernetes.io/component=controller
                        app.kubernetes.io/instance=ingress-nginx
                        app.kubernetes.io/managed-by=Helm
                        app.kubernetes.io/name=ingress-nginx
                        app.kubernetes.io/part-of=ingress-nginx
                        app.kubernetes.io/version=1.5.1
                        helm.sh/chart=ingress-nginx-4.4.0
Annotations:            deployment.kubernetes.io/revision: 1
                        meta.helm.sh/release-name: ingress-nginx
                        meta.helm.sh/release-namespace: ingress-demo
Selector:               app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
Replicas:               1 desired | 1 updated | 1 total | 1 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:           app.kubernetes.io/component=controller
                    app.kubernetes.io/instance=ingress-nginx
                    app.kubernetes.io/name=ingress-nginx
  Service Account:  ingress-nginx
  Containers:
   controller:
    Image:       registry.k8s.io/ingress-nginx/controller:v1.5.1@sha256:4ba73c697770664c1e00e9f968de14e08f606ff961c76e5d7033a4a9c593c629
    Ports:       80/TCP, 443/TCP, 8443/TCP
    Host Ports:  0/TCP, 0/TCP, 0/TCP
    Args:
      /nginx-ingress-controller
      --publish-service=$(POD_NAMESPACE)/ingress-nginx-controller
      --election-id=ingress-nginx-leader
      --controller-class=k8s.io/ingress-nginx
      --ingress-class=nginx
      --configmap=$(POD_NAMESPACE)/ingress-nginx-controller
      --validating-webhook=:8443
      --validating-webhook-certificate=/usr/local/certificates/cert
      --validating-webhook-key=/usr/local/certificates/key
    Requests:
      cpu:      100m
      memory:   90Mi
    Liveness:   http-get http://:10254/healthz delay=10s timeout=1s period=10s #success=1 #failure=5
    Readiness:  http-get http://:10254/healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Environment:
      POD_NAME:        (v1:metadata.name)
      POD_NAMESPACE:   (v1:metadata.namespace)
      LD_PRELOAD:     /usr/local/lib/libmimalloc.so
    Mounts:
      /usr/local/certificates/ from webhook-cert (ro)
  Volumes:
   webhook-cert:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  ingress-nginx-admission
    Optional:    false
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Progressing    True    NewReplicaSetAvailable
  Available      True    MinimumReplicasAvailable
OldReplicaSets:  <none>
NewReplicaSet:   ingress-nginx-controller-7d5fb757db (1/1 replicas created)
Events:          <none>

```

Create a new namespace

```yaml

apiVersion: v1
kind: Namespace
metadata:
  creationTimestamp: null
  name: deploymentns
spec: {}
status: {}

```

And a deployment:

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: testdeployment
  name: testdeployment
  namespace: deploymentns
spec:
  replicas: 3
  selector:
    matchLabels:
      app: testdeployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: testdeployment
    spec:
      containers:
      - image: nginx
        name: nginx
        resources: {}
status: {}

```

Before applying, let's add a few things: 

First, a configmap for the index file.

```yaml

apiVersion: v1
kind: ConfigMap
metadata:
 name: index-html-configmap
 namespace: deploymentns
data:
 index.html: |
   <html>
   <h1>Welcome to Cellenza Kubernetes training</h1>
   </br>
   <h2>Hi! This is a configmap Index file for the deployment</h2>
   <img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
   </html

```

A PVC, for the nginx logs.

```yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azurefile3
  namespace: deploymentns
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile-csi
  resources:
    requests:
      storage: 10Gi

```
A service to expose the deployment:

```yaml

apiVersion: v1
kind: Service
metadata:
  labels:
    app: testdeployment
  name: nginxdeploy-svc
  namespace: deploymentns
spec:
  type: LoadBalancer
  ports:
  - port: 8088
    protocol: TCP
    targetPort: 80  
  selector:
    app: testdeployment
status:
  loadBalancer: {}

```

And last we modify the deployment so that it use the configmap:

```yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: testdeployment
  name: testdeployment
  namespace: deploymentns
spec:
  replicas: 3
  selector:
    matchLabels:
      app: testdeployment
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: testdeployment
    spec:
      volumes:
      - name: nginx-index-file
        configMap:
          name: index-html-configmap
      - name: nginxlogs
        persistentVolumeClaim:
          claimName: azurefile3      
      containers:
      - image: nginx
        name: nginx
        volumeMounts:
        - name: nginx-index-file
          mountPath: /usr/share/nginx/html/
        - name: nginxlogs
          mountPath: /var/log/nginx/          
        resources: {}
status: {}

```

Check the object in the namespace:

```bash

yumemaru@Azure:~/LabAKS$ k get all -n deploymentns 
NAME                                 READY   STATUS    RESTARTS   AGE
pod/testdeployment-d4ff8fb4f-dk7tq   1/1     Running   0          9m2s
pod/testdeployment-d4ff8fb4f-p7cdj   1/1     Running   0          9m2s
pod/testdeployment-d4ff8fb4f-pcz9j   1/1     Running   0          9m2s

NAME                      TYPE           CLUSTER-IP    EXTERNAL-IP    PORT(S)          AGE
service/nginxdeploy-svc   LoadBalancer   10.0.63.234   52.146.26.37   8088:30497/TCP   8m53s

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/testdeployment   3/3     3            3           9m3s

NAME                                       DESIRED   CURRENT   READY   AGE
replicaset.apps/testdeployment-d4ff8fb4f   3         3         3       9m4s

yumemaru@Azure:~/LabAKS$ k get configmaps -n deploymentns 
NAME                   DATA   AGE
index-html-configmap   1      9m27s
kube-root-ca.crt       1      9m38s

yumemaru@Azure:~/LabAKS$ k get pvc -n deploymentns 
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
azurefile3   Bound    pvc-9cce201b-388b-4f20-815d-0098e5c6a4d9   10Gi       RWX            azurefile-csi   6m40s

```

Note the object related to the deployment.
Now let's test the resiliency of the deployment. Destroy one of the pod of the deployment:

```bash

k delete pod -n deploymentns testdeployment-d4ff8fb4f-pcz9j
pod "testdeployment-d4ff8fb4f-pcz9j" deleted
yumemaru@Azure:~/LabAKS$ k get pod -n deploymentns 
NAME                             READY   STATUS    RESTARTS   AGE
testdeployment-d4ff8fb4f-4rfrq   1/1     Running   0          10s
testdeployment-d4ff8fb4f-dk7tq   1/1     Running   0          11m
testdeployment-d4ff8fb4f-p7cdj   1/1     Running   0          11m

```

Notice the age of one of the pods. It was redeployed automatically by the deployment controller so that the number of replicasis kept to 3.
If we want to change the number of replicas, we can use the following command:

```bash

yumemaru@Azure:~/LabAKS$ k scale deployment -n deploymentns testdeployment --replicas=6 
deployment.apps/testdeployment scaled
yumemaru@Azure:~/LabAKS$ k get deployments.apps -n deploymentns 
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
testdeployment   6/6     6            6           13m
yumemaru@Azure:~/LabAKS$ k get pod -n deploymentns 
NAME                             READY   STATUS    RESTARTS   AGE
testdeployment-d4ff8fb4f-4bnhr   1/1     Running   0          17s
testdeployment-d4ff8fb4f-4rfrq   1/1     Running   0          2m23s
testdeployment-d4ff8fb4f-dk7tq   1/1     Running   0          14m
testdeployment-d4ff8fb4f-kxvtf   1/1     Running   0          17s
testdeployment-d4ff8fb4f-p7cdj   1/1     Running   0          14m
testdeployment-d4ff8fb4f-xx249   1/1     Running   0          17s

```



## 2. Other controllers

Other controller have different use case.

Try the following command to see what is deployed on your cluster:

```bash

yumemaru@Azure:~/LabAKS$ k get daemonsets.apps -A

yumemaru@Azure:~/LabAKS$ k get statefulsets.apps -A

```

Now let's have a look at one daemonset in particular:

```bash

yumemaru@Azure:~/LabAKS$ k describe daemonsets.apps -n kube-system microsoft-defender-collector-ds
Name:           microsoft-defender-collector-ds
Selector:       dsName=microsoft-defender-collector
Node-Selector:  <none>
Labels:         addonmanager.kubernetes.io/mode=Reconcile
                tier=node
Annotations:    deprecated.daemonset.template.generation: 1
Desired Number of Nodes Scheduled: 2
Current Number of Nodes Scheduled: 2
Number of Nodes Scheduled with Up-to-date Pods: 2
Number of Nodes Scheduled with Available Pods: 2
Number of Nodes Misscheduled: 0
Pods Status:  2 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:           app=defender
                    dsName=microsoft-defender-collector
  Annotations:      container.apparmor.security.beta.kubernetes.io/microsoft-defender-low-level-collector: unconfined
  Service Account:  microsoft-defender-collector-sa
  Init Containers:
   low-level-init:
    Image:        mcr.microsoft.com/azuredefender/stable/low-level-init:1.3.57
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:
      /ebpf from ebpf (rw)
      /host/lib/modules from modules (ro)
      /host/usr/src from usr-src (ro)
  Containers:
   microsoft-defender-pod-collector:
    Image:      mcr.microsoft.com/azuredefender/stable/pod-collector:1.0.71
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     60m
      memory:  64Mi
    Requests:
      cpu:     30m
      memory:  32Mi
    Environment:
      WATCH_WINDOWS_NODES:    false
      NODE_RESYNC_DURATION:   1h
      NODE_NAME:               (v1:spec.nodeName)
      COMPONENT_NAME:         PodCollector
      CLUSTER_DISTRIBUTION:   AKS
      AZURE_RESOURCE_REGION:  eastus
      AZURE_RESOURCE_ID:      /subscriptions/16e85b36-5c9d-48cc-a45d-c672a4393c36/resourceGroups/rsg-aksTraining1/providers/Microsoft.ContainerService/managedClusters/aks-1
      IMAGE_VERSION:          mcr.microsoft.com/azuredefender/stable/pod-collector:1.0.71
      RESYNC_DURATION:        1h
    Mounts:
      /var/log from host-log (rw)
   microsoft-defender-low-level-collector:
    Image:      mcr.microsoft.com/azuredefender/stable/low-level-collector:1.3.57
    Port:       <none>
    Host Port:  <none>
    Limits:
      cpu:     150m
      memory:  128Mi
    Requests:
      cpu:     30m
      memory:  64Mi
    Environment:
      AZURE_RESOURCE_ID:      /subscriptions/16e85b36-5c9d-48cc-a45d-c672a4393c36/resourceGroups/rsg-aksTraining1/providers/Microsoft.ContainerService/managedClusters/aks-1
      AZURE_RESOURCE_REGION:  eastus
      CLUSTER_DISTRIBUTION:   AKS
      IMAGE_VERSION:          mcr.microsoft.com/azuredefender/stable/low-level-collector:1.3.57
      NODE_NAME:               (v1:spec.nodeName)
    Mounts:
      /ebpf from ebpf (ro)
      /host/proc from proc (ro)
      /run/containerd/containerd.sock from containerd-file-sock (ro)
      /var/log from host-log (rw)
  Volumes:
   host-log:
    Type:          HostPath (bare host directory volume)
    Path:          /var/log
    HostPathType:  
   ebpf:
    Type:       EmptyDir (a temporary directory that shares a pod\'s lifetime)
    Medium:     
    SizeLimit:  <unset>
   modules:
    Type:          HostPath (bare host directory volume)
    Path:          /lib/modules
    HostPathType:  
   usr-src:
    Type:          HostPath (bare host directory volume)
    Path:          /usr/src
    HostPathType:  
   containerd-file-sock:
    Type:          HostPath (bare host directory volume)
    Path:          /run/containerd/containerd.sock
    HostPathType:  
   proc:
    Type:          HostPath (bare host directory volume)
    Path:          /proc
    HostPathType:  
Events:            <none>

```