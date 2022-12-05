# CSI Secret Store Addon

```yaml

apiVersion: secrets-store.csi.x-k8s.io/v1alpha1
kind: SecretProviderClass
metadata:
  name: ${SecretProviderClassName}
spec:
  provider: azure
  parameters:
    useVMManagedIdentity: "true"               
    userAssignedIdentityID: ${CSIAddonUAIClientId}
    keyvaultName: ${KVName}
    cloudName: ""                               
    objects:  |
      array:
        - |
          objectName: ${SecretName}
          objectAlias: ${SecretName}            
          objectType: secret                    
          objectVersion: ${SecretVersion}       
    tenantId: ${TenantId}                      

```

```yaml

apiVersion: v1
kind: Pod
metadata:
  name: ${PodName}
spec:
  containers:
    - name: nginx
      image: nginx
      volumeMounts:
        - name: secrets-store-inline
          mountPath: "/mnt/secrets-store"
          readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: ${SecretProviderClassName}

```