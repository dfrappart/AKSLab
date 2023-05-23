# Pod configuration

Pod can be configured with configmap.
The code snippet below is a sample configmap:

```yaml

apiVersion: v1
kind: ConfigMap
metadata:
 name: index-html-configmap
 namespace: demo
data:
 index.html: |
   <html>
   <h1>Welcome to Cellenza Kubernetes training</h1>
   </br>
   <h2>Hi! This is a configmap Index file </h2>
   <img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
   </html

```

Create the configmap from this manifest.
Do not forget to create the namespace before!

Once created, create a pod with the nginx container that use this configmap as its index.html file:

```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: podwithconfig
  name: podwithconfig
  namespace: demo
spec:
  volumes:
  - name: nginx-index-file
    configMap:
      name: index-html-configmap
  containers:
  - image: nginx
    name: podwithconfig
    volumeMounts:
    - name: nginx-index-file
      mountPath: /usr/share/nginx/html/
  dnsPolicy: ClusterFirst
  restartPolicy: Always

```

Once the pod is created, execute inside the container a curl command: 

```bash

yumemaru@Azure:~/LabAKS$ k exec -n demo podwithconfig -- curl -i -X GET 'http://localhost'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   226  100   226    0     0   110k      0 --:--:-- --:--:-- --:--:--  220k
HTTP/1.1 200 OK
Server: nginx/1.23.2
Date: Sun, 27 Nov 2022 22:02:12 GMT
Content-Type: text/html
Content-Length: 226
Last-Modified: Sun, 27 Nov 2022 22:01:55 GMT
Connection: keep-alive
ETag: "6383de53-e2"
Accept-Ranges: bytes

<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is a configmap Index file </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html

```

Check the first nginx container created and compare the output:

```bash

yumemaru@Azure:~/LabAKS$ k exec testpod -- curl -i -X GET 'http://localhost'
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0HTTP/1.1 200 OK
Server: nginx/1.23.2
Date: Sun, 27 Nov 2022 22:02:41 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Wed, 19 Oct 2022 07:56:21 GMT
Connection: keep-alive
ETag: "634fada5-267"
Accept-Ranges: bytes

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
100   615  100   615    0     0   300k      0 --:--:-- --:--:-- --:--:--  300k

```

We changed the index.html by pointing it to a configmap which exist outside of the pod lifecycle.
By separating config from runtime, we rendered the app stateless.
We will see more way to see the result in the service and ingress section.

## 2. Secrets

Secrets are used to store configuration information that should not be in clear text.
Examples could be a password to access a database, or a login...
However, the secret object in itself is not encrypted, only base64 encoded.
Taking that into account, the process of creating a secret require to encode the strings that are secret.
We can use tool from the shell to encode directly the string or use the `kubectl create` command to create the secret either from a file or from string passed to the cli.

The following example create a secret from string passed to the `kubectl` cli:

```bash

yumemaru@Azure:~/LabAKS$ kubectl create secret generic testsecret --from-literal=sqlpassword=p@ssw0rd! 
secret/testsecret created

```

Using `kubectl get` command, we can see now that the string is encoded:

```bash

yumemaru@Azure:~/LabAKS$ k get secret testsecret 
NAME         TYPE     DATA   AGE
testsecret   Opaque   1      8s
yumemaru@Azure:~/LabAKS$ kubectl get secret testsecret -o yaml
apiVersion: v1
data:
  sqlpassword: cEBzc3cwcmQh
kind: Secret
metadata:
  creationTimestamp: "2022-11-28T07:23:12Z"
  name: testsecret
  namespace: default
  resourceVersion: "13827"
  uid: 95b35363-6fd3-4858-9c3f-b3184b1d5a5a

```

Note that with this method, we don't have the manifest file afterward. This is an example of the use of `kubectl` in imperative way.
To generate a secret manifest directly with the `kubectl` command, we can use a combination of arguments from the cli and properties of the shell:

```bash

yumemaru@Azure:~/LabAKS$ k create secret generic testsecret2 --from-literal=sqlpassword=p@ssw0rd! --dry-run=client -o yaml > testsecret2.yaml


```

Check the file that was juste created:

```bash

yumemaru@Azure:~/LabAKS$ cat testsecret2.yaml 
apiVersion: v1
data:
  sqlpassword: cEBzc3cwcmQh
kind: Secret
metadata:
  creationTimestamp: null
  name: testsecret2

```

Now we can create the secret by using the `kubectl apply` command as usual:

```bash

yumemaru@Azure:~/LabAKS$ kubectl apply -f testsecret2.yaml 
secret/testsecret2 created

```
Using the `kubectl get` command, we should see 2 secrets at least in the default namespace:

```bash

yumemaru@Azure:~$ k get secrets
NAME                              TYPE                 DATA   AGE
testsecret                        Opaque               1      12m
testsecret2                       Opaque               1      2m21s

```

### 2.1.Secrets as volume

Now that we have secrets available, let's create a pod manifest with a secret mounted as a volume.
Because we just learnt how to create yaml manifest from the `kubectl` cli, let's carry on and create a pod manifest with the following command:

```bash

yumemaru@Azure:~$ kubectl run podwithsecret --image=nginx --dry-run=client -o yaml > podwithsecret.yaml

```

Open the manifest file with vim. We should have the following configuration:

```yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: podwithsecret
  name: podwithsecret
spec:
  containers:
  - image: nginx
    name: podwithsecret
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

Now we want to modify the manifest so that the secret `testsecret` is mounted as a volume:


```yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: podwithsecret
  name: podwithsecret
spec:
  volumes:
  - name: secretvolume
    secret:
      secretName: testsecret
  containers:
  - image: nginx
    name: podwithsecret
    volumeMounts:
    - name: secretvolume
      mountPath: "/mnt/sqlpassword"
      readOnly: true
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

``` 

The pod may take a little more time before being in a running state.
Once its running, use `kubectl exec` command to check the secret content in the file that was mounted:

```bash

yumemaru@Azure:~$ kubectl exec podwithsecret -- cat /mnt/sqlpassword/sqlpassword
p@ssw0rd!

```

The password contained in the secret is available in the path specified as a file.


### 2.2. Secrets as environment variables

Secrets can also be referenced as environment variables for containers.
In this case, there is no update of the secret in the pod, as opposite to secret mounted as volume.

Start by creating a new secret:

```bash

yumemaru@Azure:~/LabAKS$ kubectl create secret generic testsecretforenvvar --from-literal=sqlpassword=p@ssw0rd! --dry-run=client -o yaml > testsecretforenvvar.yaml

```
Once the manifest file is created, create the secret:

```bash

yumemaru@Azure:~/LabAKS$ kubectl apply -f testsecretforenvvar.yaml 
secret/testsecretforenvvar created
yumemaru@Azure:~/LabAKS$ kubectl get secret testsecretforenvvar
NAME                  TYPE                                  DATA   AGE
testsecretforenvvar   Opaque                                1      4s


```

Once the secret is created, create a pod manifest:

```bash

yumemaru@Azure:~/LabAKS$ kubectl run podwithsecretenvvar --image=nginx --dry-run=client -o yaml > podwithsecretenvvar.yaml

```

Open the file and add the configuration for an environment variable pointing to the secret.

```yaml

apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  labels:
    run: podwithsecretenvvar
  name: podwithsecretenvvar
spec:
  containers:
  - image: nginx
    name: podwithsecretenvvar
    env:
    - name: SQLPWD
      valueFrom:
        secretKeyRef: 
          name: testsecretforenvvar
          key: sqlpassword
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

Create the pod with `kubectl apply` command

```bash

yumemaru@Azure:~/LabAKS$ kubectl apply -f podwithsecretenvvar.yaml 
pod/podwithsecretenvvar created

```

Once the pod is running, test the environment variable existance:

```bash

yumemaru@Azure:~/LabAKS$ kubectl exec podwithsecretenvvar -- printenv | grep -i sqlpwd
sqlpassword=p@ssw0rd2!

```