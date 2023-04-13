# Manage statefullness

## 1. PV & PVC

As long as there is no data to persist, everything is (relatively) easy.
When data written during the pod lifecycle need to be persisted, we need to add additional part to the configuration.

For those use case, we rely on Persistent Volume and Persistent Volume Claim.

In the following lab, we will use an Azure file for the creation of a PV.

Identify the underling storage account:

```bash

yumemaru@Azure:~/LabAKS$ az storage account list | jq .[].name
"stafile1"
"stafile2"
"stafile3"

yumemaru@Azure:~/LabAKS$ az storage account list | jq .[].resourceGroup
"rsg-aksTraining1"
"rsg-aksTraining2"
"rsg-aksTraining3"

yumemaru@Azure:~/LabAKS$ export STAName='stafile1'
yumemaru@Azure:~/LabAKS$ export STARG='rsg-aksTraining1'

```

Get the storage access key. Kubernetes will need it to be able to acces the storage:

```bash

yumemaru@Azure:~/LabAKS$ export STORAGE_KEY=$(az storage account keys list --resource-group $STARG --account-name $STAName --query "[0].value" -o tsv)

```
Alternatively, you can also nagivate to the Azure Portal to locate the storage acocunt, the access key.
Verify the existence of an azure file share and xwhat it contains.

```bash

yumemaru@Azure:~/LabAKS$ az storage share list --account-name stafile1 --account-key $STORAGE_KEY | jq .[].name
"aksshare"

yumemaru@Azure:~/LabAKS$ az storage file list --account-name stafile1 --account-key $STORAGE_KEY --share-name aksshare | jq .[].name
"index.html"

```

To use the required information, Kubertnetes will relies on a secret : 


```bash

yumemaru@Azure:~/LabAKS$ kubectl create secret generic azure-secret --from-literal=azurestorageaccountname=$STAName --from-literal=azurestorageaccountkey=$STORAGE_KEY

```

We need to create now the Persistent Volume that will point to our Azure File:

```yaml

apiVersion: v1
kind: PersistentVolume
metadata:
  name: azurefile
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  persistentVolumeReclaimPolicy: Retain
  storageClassName: azurefile-csi
  csi:
    driver: file.csi.azure.com
    readOnly: false
    volumeHandle: # Use a random UID Generator to get this b927e987-cabc-42bd-b55b-bc188b59f07a
    volumeAttributes:
      resourceGroup: rsg-aksTraining1  
      shareName: aksshare
    nodeStageSecretRef:
      name: azure-secret
      namespace: default
  mountOptions:
    - dir_mode=0777
    - file_mode=0777
    - uid=0
    - gid=0
    - mfsymlinks
    - cache=strict
    - nosharesock
    - nobrl

```

And afterward, the PVC that is using this PV:

```yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azurefile
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile-csi
  volumeName: azurefile
  resources:
    requests:
      storage: 5Gi

```

Last, we create an nginx pod with the volume mounted to the path that ususally host the index.html.

```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginxwithazurefile
  name: nginxwithazurefile
spec:
  volumes:
  - name: azurefile-pvc
    persistentVolumeClaim:
      claimName: azurefile
  containers:
  - volumeMounts:
    - name: azurefile-pvc
      mountPath: /usr/share/nginx/html/
    image: nginx
    name: nginxwithazurefile
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

If everything is configured correctly, we should have a running pod with the index.html looking like that:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get pod nginxwithazurefile
NAME                                  READY   STATUS    RESTARTS   AGE
nginxwithazurefile                    1/1     Running   0          17s

yumemaru@Azure:~/LabAKS$ kubectl exec nginxwithazurefile -- curl -i -X GET http://localhost
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   263  100   263    0     0   4696      0 --:--:-- --:--:-- --:--:--  4696
HTTP/1.1 200 OK
Server: nginx/1.23.2
Date: Thu, 01 Dec 2022 13:44:08 GMT
Content-Type: text/html
Content-Length: 263
Last-Modified: Thu, 01 Dec 2022 13:42:04 GMT
Connection: keep-alive
ETag: "6388af2c-107"
Accept-Ranges: bytes

<html>
    <h1>Welcome to Cellenza Kubernetes training</h1>
    </br>
    <h2>Hi! This is a an index file from an azure file share </h2>
    <img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
    </html

```


## 2. Storage Class

Storage classes ease the way for storage management.
Check the available storage classes on the cluster:

```bash

yumemaru@Azure:~/LabAKS$ k get storageclasses.storage.k8s.io 
NAME                    PROVISIONER          RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
azurefile               file.csi.azure.com   Delete          Immediate              true                   8d
azurefile-csi           file.csi.azure.com   Delete          Immediate              true                   8d
azurefile-csi-premium   file.csi.azure.com   Delete          Immediate              true                   8d
azurefile-premium       file.csi.azure.com   Delete          Immediate              true                   8d
default (default)       disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   8d
managed                 disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   8d
managed-csi             disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   8d
managed-csi-premium     disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   8d
managed-premium         disk.csi.azure.com   Delete          WaitForFirstConsumer   true                   8d

```

For further detail, check the yaml config with the following command:

```bash

yumemaru@Azure:~/LabAKS$ k get storageclasses.storage.k8s.io azurefile-csi -o yaml

```

```yaml

allowVolumeExpansion: true
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  creationTimestamp: "2022-11-22T17:20:17Z"
  labels:
    addonmanager.kubernetes.io/mode: EnsureExists
    kubernetes.io/cluster-service: "true"
  name: azurefile-csi
  resourceVersion: "423"
  uid: 370d5189-7785-4a45-82ae-16c354d73602
mountOptions:
- mfsymlinks
- actimeo=30
parameters:
  skuName: Standard_LRS
provisioner: file.csi.azure.com
reclaimPolicy: Delete
volumeBindingMode: Immediate

```

We will now create a PVC directly using the storage class azurefile-csi:

```yaml

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: azurefile2
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: azurefile-csi
  resources:
    requests:
      storage: 100Gi

```

Check the existence of the PVC

```bash

yumemaru@Azure:~/LabAKS$ kubectl get pvc azurefile2
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
azurefile2   Bound    pvc-38b69205-1feb-4105-bc9d-fa3b7a6622cf  100Gi      RWX            azurefile-csi   22s

```

Note the volume name.

Now we want to check what happened on the Azure side:

```bash

yumemaru@Azure:~/LabAKS$ az storage account list | jq .[].name
"f4ed328cf15fd4d5fbaeed7"
"stafile1"

yumemaru@Azure:~/LabAKS$ az storage account list | jq .[].resourceGroup
"rsg-dfitcfr-dev-tfmodule-aksobjects1"
"rsg-aksTraining1"

yumemaru@Azure:~/LabAKS$ export STORAGE_KEY2=$(az storage account keys list --resource-group rsg-dfitcfr-dev-tfmodule-aksobjects1 --account-name f4ed328cf15fd4d5fbaeed7 --query "[0].value" -o tsv)

yumemaru@Azure:~/LabAKS$ az storage share list --account-name f4ed328cf15fd4d5fbaeed7 --account-key $STORAGE_KEY2 | jq .[].name
"pvc-919eeb9d-2fce-46db-ac54-bbbe36a6102a"


```

We have a new storage account wit an Azure file share created automatically.
Now let's retake the example from the multi-container pod and change a few thing

```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: multi-container-playground
  name: multi-container-playground-withpvc
spec:
  containers:
  - image: nginx:1.17.6-alpine
    name: c1
    resources: {}
    env:                
    - name: MY_NODE_NAME
      valueFrom:        
        fieldRef:       
          fieldPath: spec.nodeName
    volumeMounts:
    - name: vol
      mountPath: /vol
  - image: busybox:1.31.1
    name: c2
    command: ["sh", "-c", "while true; do date >> /vol/date.log; sleep 1; done"]
    volumeMounts:
    - name: vol
      mountPath: /vol
  - image: busybox:1.31.1
    name: c3
    command: ["sh", "-c", "tail -f /vol/date.log"]
    volumeMounts:
    - name: vol
      mountPath: /vol
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  volumes:                 
    - name: vol            
      persistentVolumeClaim:
        claimName: azurefile2

```

This pods write the date in a file on the volume.
Let's check the azure file share to see our file

```bash

yumemaru@Azure:~/LabAKS$ az storage file list --account-name f4ed328cf15fd4d5fbaeed7 --account-key $STORAGE_KEY2 --share-name pvc-38b69205-1feb-4105-bc9d-fa3b7a6622cf| jq .[].name
"date.log"

yumemaru@Azure:~/LabAKS$ az storage file download --account-name f4ed328cf15fd4d5fbaeed7 --account-key $STORAGE_KEY2 --share-name pvc-38b69205-1feb-4105-bc9d-fa3b7a6622cf--path ./date.log

yumemaru@Azure:~/LabAKS$ cat date.log 
Thu Dec  1 15:11:16 UTC 2022
Thu Dec  1 15:11:17 UTC 2022
Thu Dec  1 15:11:18 UTC 2022
Thu Dec  1 15:11:19 UTC 2022
Thu Dec  1 15:11:20 UTC 2022
Thu Dec  1 15:11:21 UTC 2022
Thu Dec  1 15:11:22 UTC 2022
Thu Dec  1 15:11:23 UTC 2022
Thu Dec  1 15:11:24 UTC 2022
Thu Dec  1 15:11:25 UTC 2022
Thu Dec  1 15:11:26 UTC 2022
Thu Dec  1 15:11:27 UTC 2022
Thu Dec  1 15:11:28 UTC 2022
Thu Dec  1 15:11:29 UTC 2022
Thu Dec  1 15:11:30 UTC 2022
Thu Dec  1 15:11:31 UTC 2022

```

Let's delete the pod:

```bash

yumemaru@Azure:~/LabAKS$ k delete pod multi-container-playground-withpvc 
pod "multi-container-playground-withpvc" deleted

```

The pvc still exists, as planned:


```bash

yumemaru@Azure:~/LabAKS$ k get pvc
NAME         STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS    AGE
azurefile    Bound    azurefile                                  5Gi        RWX            azurefile-csi   94m
azurefile2   Bound    pvc-38b69205-1feb-4105-bc9d-fa3b7a6622cf   100Gi      RWX            azurefile-csi   6m44s

```