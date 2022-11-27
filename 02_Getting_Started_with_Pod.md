# Getting started with pods

Pods are the atomics objects of the Kubernetes API.
In a pod, containers run and share resource.

To create a pod, we need to specify a few parameters in a yaml file.
The example below allows the creation of a pod with an nginx container:

```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: testpod
  name: testpod
spec:
  containers:
  - image: nginx
    name: testpod
  dnsPolicy: ClusterFirst
  restartPolicy: Always

```

Create a file