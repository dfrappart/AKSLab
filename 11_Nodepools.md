# Node pools

```bash

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 3


```

Add node pool with dedicated subnet

```bash

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name mynodepool \
    --node-count 3 \
    --vnet-subnet-id <YOUR_SUBNET_RESOURCE_ID>

```

Add Windows node pool

```bash

az aks nodepool add --cluster-name
                    --name
                    --resource-group
                    [--aks-custom-headers]
                    [--enable-cluster-autoscaler]
                    [--enable-encryption-at-host]
                    [--enable-fips-image]
                    [--enable-node-public-ip]
                    [--enable-ultra-ssd]
                    [--eviction-policy {Deallocate, Delete}]
                    [--gpu-instance-profile {MIG1g, MIG2g, MIG3g, MIG4g, MIG7g}]
                    [--host-group-id]
                    [--kubelet-config]
                    [--kubernetes-version]
                    [--labels]
                    [--linux-os-config]
                    [--max-count]
                    [--max-pods]
                    [--max-surge]
                    [--min-count]
                    [--mode {System, User}]
                    [--no-wait]
                    [--node-count]
                    [--node-osdisk-size]
                    [--node-osdisk-type {Ephemeral, Managed}]
                    [--node-public-ip-prefix-id]
                    [--node-taints]
                    [--node-vm-size]
                    [--os-sku {CBLMariner, Ubuntu, Windows2019, Windows2022}]
                    [--os-type]
                    [--pod-subnet-id]
                    [--ppg]
                    [--priority {Regular, Spot}]
                    [--scale-down-mode {Deallocate, Delete}]
                    [--snapshot-id]
                    [--spot-max-price]
                    [--tags]
                    [--vnet-subnet-id]
                    [--zones {1, 2, 3}]

```

spot nodepool

```bash

az aks nodepool add \
    --resource-group myResourceGroup \
    --cluster-name myAKSCluster \
    --name spotnodepool \
    --priority Spot \
    --eviction-policy Delete \
    --spot-max-price -1 \
    --enable-cluster-autoscaler \
    --min-count 1 \
    --max-count 3 \
    --no-wait

```

pod sepc for spot

```yaml

spec:
  containers:
  - name: spot-example
  tolerations:
  - key: "kubernetes.azure.com/scalesetpriority"
    operator: "Equal"
    value: "spot"
    effect: "NoSchedule"
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: "kubernetes.azure.com/scalesetpriority"
            operator: In
            values:
            - "spot"
   ...

```