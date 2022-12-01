# Ingress

Ingress goes beyond service by giving capabilities to expose application with http path.
We will start by installing the nginx ingress controller. For this, we will rely on helm and the chart provided by the community

```bash

yumemaru@Azure:~/LabAKS$ export IngressNamespace='ingress-demo'

yumemaru@Azure:~/LabAKS$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
yumemaru@Azure:~/LabAKS$ helm repo update

yumemaru@Azure:~/LabAKS$ helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $IngressNamespace \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

```

After the helm deployment, we have a new namespace `ingress-demo` with the ingress controller resources

```bash

yumemaru@Azure:~/LabAKS$ kubectl get all -n ingress-demo 
NAME                                            READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-7d5fb757db-gbkhw   1/1     Running   0          3h27m

NAME                                         TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   10.0.19.73    52.151.229.94   80:32604/TCP,443:31891/TCP   3h27m
service/ingress-nginx-controller-admission   ClusterIP      10.0.235.14   <none>          443/TCP                      3h27m

NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/ingress-nginx-controller   1/1     1            1           3h27m

NAME                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/ingress-nginx-controller-7d5fb757db   1         1         1       3h27m

```

To illustrate the capabilities of the ingress object, we will create 2 nginx pods with a configmap as the index.html:

```yaml

apiVersion: v1
kind: Namespace
metadata:
  name: ingressapp-demo
---
apiVersion: v1
kind: ConfigMap
metadata:
 name: index-html-main
 namespace: ingressapp-demo
data:
 index.html: |
   <html>
   <h1>Welcome to Cellenza Kubernetes training</h1>
   </br>
   <h2>Hi! This is the main page of the app </h2>
   <img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
   </html
---
apiVersion: v1
kind: ConfigMap
metadata:
 name: index-html-doc
 namespace: ingressapp-demo
data:
 index.html: |
   <html>
   <h1>Welcome to Cellenza Kubernetes training</h1>
   </br>
   <h2>Hi! This is the doc page of the app </h2>
   <img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
   </html
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: mainpage
  name: ingressdemoapp-main
  namespace: ingressapp-demo
spec:
  volumes:
  - name: nginx-index-file
    configMap:
      name: index-html-main  
  containers:
  - image: nginx
    name: ingressdemoapp-main
    volumeMounts:
    - name: nginx-index-file
      mountPath: /usr/share/nginx/html/
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: docpage
  name: ingressdemoapp-doc
  namespace: ingressapp-demo
spec:
  volumes:
  - name: nginx-index-file
    configMap:
      name: index-html-doc  
  containers:
  - image: nginx
    name: ingressdemoapp-doc
    volumeMounts:
    - name: nginx-index-file
      mountPath: /usr/share/nginx/html/
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

Then we will add services, pointing to those 2 pods:

```yaml

apiVersion: v1
kind: Service
metadata:
  labels:
    app: docpage
  name: docpage-svc
  namespace: ingressapp-demo
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: docpage
---
apiVersion: v1
kind: Service
metadata:
  labels:
    app: rootpage
  name: mainpage-svc
  namespace: ingressapp-demo
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    app: mainpage

```

With those services created, we can test the access from an existing pod

```bash

yumemaru@Azure:~/LabAKS$ kubectl exec pod -- curl -i -X GET http://mainpage-svc.ingressapp-demo
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   228  100   228    0     0  45600      0 --:--:-- --:--:-- --:--HTTP/1.1 200 OK
Server: nginx/1.23.2
Date: Tue, 29 Nov 2022 16:23:18 GMT
Content-Type: text/html
Content-Length: 228
Last-Modified: Tue, 29 Nov 2022 15:12:13 GMT
Connection: keep-alive
ETag: "6386214d-e4"
Accept-Ranges: bytes

<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is the main page of the app </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html
:-- 45600

yumemaru@Azure:~/LabAKS$ kubectl exec pod -- curl -i -X GET http://docpage-svc.ingressapp-demo
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   227  100   227    0     0  45400      0 --:--:-- --:--:-- --:--:-- 45400
HTTP/1.1 200 OK
Server: nginx/1.23.2
Date: Tue, 29 Nov 2022 16:23:27 GMT
Content-Type: text/html
Content-Length: 227
Last-Modified: Tue, 29 Nov 2022 15:12:13 GMT
Connection: keep-alive
ETag: "6386214d-e3"
Accept-Ranges: bytes

<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is the doc page of the app </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html

```

Now we want to use an ingress so that the main page is available on the `/main` path and the doc page is available on the `/doc` path.
We will create the ingress manifest with 2 rules:

```yaml

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-demo
  namespace: ingressapp-demo
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /main(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: mainpage-svc
            port: 
              number: 80
      - path: /doc(/|$)(.*)
        pathType: Prefix
        backend:
          service:
            name: docpage-svc
            port: 
              number: 80

```

We can check the ingress status:

```bash

yumemaru@Azure:~/LabAKS$ kubectl get ingress -n ingressapp-demo 
NAME           CLASS   HOSTS   ADDRESS         PORTS   AGE
ingress-demo   nginx   *       52.151.229.94   80      75m

```

And navigate the page with curl or a navigator:

```bash

f@df2204lts:~/Documents/myrepo/AKSLab/yamlmanifest$ k exec pod -- curl -i -X GET http://52.151.229.94/main
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   228  100   228    0     0   111k      0 --:--:-- --:--:-- --:--:--  111kHTTP/1.1 200 OK
Date: Tue, 29 Nov 2022 16:36:01 GMT
Content-Type: text/html
Content-Length: 228
Connection: keep-alive
Last-Modified: Tue, 29 Nov 2022 15:12:13 GMT
ETag: "6386214d-e4"
Accept-Ranges: bytes

<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is the main page of the app </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html

yumemaru@Azure:~/LabAKS$ kubectl exec pod -- curl -i -X GET http://52.151.229.94/doc
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   227  100   227    0     0   221k      0 --:--:-- --:--:-- --:--:--  221k
HTTP/1.1 200 OK
Date: Tue, 29 Nov 2022 16:36:07 GMT
Content-Type: text/html
Content-Length: 227
Connection: keep-alive
Last-Modified: Tue, 29 Nov 2022 15:12:13 GMT
ETag: "6386214d-e3"
Accept-Ranges: bytes

<html>
<h1>Welcome to Cellenza Kubernetes training</h1>
</br>
<h2>Hi! This is the doc page of the app </h2>
<img src="https://i0.wp.com/training.cellenza.com/wp-content/uploads/2021/08/logo-Cellenza-Training-VF2.jpg" />
</html

```