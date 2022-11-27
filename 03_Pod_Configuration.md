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

Create the config map.
Once create, create a pod with the nginx container that use this configmap as its index.html file:

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

david@Azure:~/LabAKS$ k exec -n demo podwithconfig -- curl -i -X GET 'http://localhost'
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

david@Azure:~/LabAKS$ k exec testpod -- curl -i -X GET 'http://localhost'
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

