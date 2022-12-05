# Node pools

## 1. Explore the node pools 

Node pools are the Compute poart of the AKS cluster.
Also they are the more IaaS part of AKS since, as opposite to the Control plane, they do live in a Virtual Network as virtual Machine Scale Set.
Find the node pools of your cluster with the following command:

```bash

yumemaru@Azure:~/LabAKS$ az aks list | jq .[].name
"aks-1"
"akscli-1"


yumemaru@Azure:~/LabAKS$ az aks list | jq .[].resourceGroup
"rsg-aksTraining1"
"rsg-aksTraining1"


yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].name
"nodepool1"
yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1
[
  {
    "availabilityZones": [
      "1",
      "2",
      "3"
    ],
    "count": 3,
    "creationData": null,
    "currentOrchestratorVersion": "1.24.3",
    "enableAutoScaling": false,
    "enableEncryptionAtHost": false,
    "enableFips": false,
    "enableNodePublicIp": false,
    "enableUltraSsd": false,
    "gpuInstanceProfile": null,
    "hostGroupId": null,
    "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rsg-aksTraining1/providers/Microsoft.ContainerService/managedClusters/akscli-1/agentPools/nodepool1",
    "kubeletConfig": null,
    "kubeletDiskType": "OS",
    "linuxOsConfig": null,
    "maxCount": null,
    "maxPods": 110,
    "minCount": null,
    "mode": "System",
    "name": "nodepool1",
    "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2022.11.02",
    "nodeLabels": null,
    "nodePublicIpPrefixId": null,
    "nodeTaints": null,
    "orchestratorVersion": "1.24.3",
    "osDiskSizeGb": 128,
    "osDiskType": "Managed",
    "osSku": "Ubuntu",
    "osType": "Linux",
    "podSubnetId": null,
    "powerState": {
      "code": "Running"
    },
    "provisioningState": "Succeeded",
    "proximityPlacementGroupId": null,
    "resourceGroup": "rsg-aksTraining1",
    "scaleDownMode": null,
    "scaleSetEvictionPolicy": null,
    "scaleSetPriority": null,
    "spotMaxPrice": null,
    "tags": null,
    "type": "Microsoft.ContainerService/managedClusters/agentPools",
    "typePropertiesType": "VirtualMachineScaleSets",
    "upgradeSettings": {
      "maxSurge": null
    },
    "vmSize": "Standard_DS2_v2",
    "vnetSubnetId": null,
    "workloadRuntime": null
  }
]

```

note the node count:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].count
3

```

Which should give us the same number as the command `kubectl get nodes`:

```bash

# Start by getting the context
yumemaru@Azure:~/LabAKS$ k config get-contexts 
CURRENT   NAME       CLUSTER    AUTHINFO                                NAMESPACE
          akscli-1   akscli-1   clusterUser_rsg-akstraining1_akscli-1   
*         akscli-2   akscli-2   clusterUser_rsg-aksTraining1_akscli-2   

# Switch context if required
yumemaru@Azure:~/LabAKS$ k config use-context akscli-1
Switched to context "akscli-1".

# List the nodes
yumemaru@Azure:~/LabAKS$ k get nodes
NAME                                STATUS   ROLES   AGE   VERSION
aks-nodepool1-23978515-vmss000003   Ready    agent   34h   v1.24.3
aks-nodepool1-23978515-vmss000004   Ready    agent   34h   v1.24.3
aks-nodepool1-23978515-vmss000005   Ready    agent   34h   v1.24.3

```

Notice the mode of the node pool:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].mode
"System"

```

Which is the mode for the default node pool.

Now that we had a look at the default node pool, let's add a new node pool to our cluster:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool add --resource-group rsg-akstraining1 --cluster-name akscli-1 --node-count 3 --nodepool-name nodepool2
{
  "availabilityZones": null,
  "count": 3,
  "creationData": null,
  "currentOrchestratorVersion": "1.24.3",
  "enableAutoScaling": false,
  "enableEncryptionAtHost": false,
  "enableFips": false,
  "enableNodePublicIp": false,
  "enableUltraSsd": false,
  "gpuInstanceProfile": null,
  "hostGroupId": null,
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rsg-akstraining1/providers/Microsoft.ContainerService/managedClusters/akscli-1/agentPools/nodepool2",
  "kubeletConfig": null,
  "kubeletDiskType": "OS",
  "linuxOsConfig": null,
  "maxCount": null,
  "maxPods": 110,
  "minCount": null,
  "mode": "User",
  "name": "nodepool2",
  "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2022.11.12",
  "nodeLabels": null,
  "nodePublicIpPrefixId": null,
  "nodeTaints": null,
  "orchestratorVersion": "1.24.3",
  "osDiskSizeGb": 128,
  "osDiskType": "Managed",
  "osSku": "Ubuntu",
  "osType": "Linux",
  "podSubnetId": null,
  "powerState": {
    "code": "Running"
  },
  "provisioningState": "Succeeded",
  "proximityPlacementGroupId": null,
  "resourceGroup": "rsg-akstraining1",
  "scaleDownMode": "Delete",
  "scaleSetEvictionPolicy": null,
  "scaleSetPriority": null,
  "spotMaxPrice": null,
  "tags": null,
  "type": "Microsoft.ContainerService/managedClusters/agentPools",
  "typePropertiesType": "VirtualMachineScaleSets",
  "upgradeSettings": {
    "maxSurge": null
  },
  "vmSize": "Standard_DS2_v2",
  "vnetSubnetId": null,
  "workloadRuntime": null
}


```

Let's check our cluster node pools now:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].name
"nodepool1"
"nodepool2"
yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].count
3
3
yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].mode
"System"
"User"

```

And the nodes from the Kubernetes side:

```bash

yumemaru@Azure:~/LabAKS$ k get nodes
NAME                                STATUS   ROLES   AGE     VERSION
aks-nodepool1-23978515-vmss000003   Ready    agent   34h     v1.24.3
aks-nodepool1-23978515-vmss000004   Ready    agent   34h     v1.24.3
aks-nodepool1-23978515-vmss000005   Ready    agent   34h     v1.24.3
aks-nodepool2-17493705-vmss000000   Ready    agent   2m46s   v1.24.3
aks-nodepool2-17493705-vmss000001   Ready    agent   2m46s   v1.24.3
aks-nodepool2-17493705-vmss000002   Ready    agent   2m52s   v1.24.3

```

## 2. Interact on scheduling with taint and toleration

Nodes are managed from the Azure plane.
It is possible to scale the number of nodes, enable autoscaling and also add taints.
Usually, taint would be added on the Kubernetes plane, but because of their managed nature, nodes lifecycle is independant of the Kubernetes plane and can be destroyed / added.
Thus a taint management from the Azure plane.

The following command allows to update the new node pool so that autoscaling is enabled, and that the nodes have a new taint

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool update --nodepool-name nodepool2 --cluster-name akscli-1 -g rsg-akstraining1 --enable-cluster-autoscaler --min-count 3 --max-count 6 --max-surge 33% --node-taints agentpool=nodepool2:NoSchedule
{
  "availabilityZones": null,
  "count": 3,
  "creationData": null,
  "currentOrchestratorVersion": "1.24.3",
  "enableAutoScaling": true,
  "enableEncryptionAtHost": false,
  "enableFips": false,
  "enableNodePublicIp": false,
  "enableUltraSsd": false,
  "gpuInstanceProfile": null,
  "hostGroupId": null,
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rsg-akstraining1/providers/Microsoft.ContainerService/managedClusters/akscli-1/agentPools/nodepool2",
  "kubeletConfig": null,
  "kubeletDiskType": "OS",
  "linuxOsConfig": null,
  "maxCount": 6,
  "maxPods": 110,
  "minCount": 3,
  "mode": "User",
  "name": "nodepool2",
  "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2022.11.12",
  "nodeLabels": null,
  "nodePublicIpPrefixId": null,
  "nodeTaints": [
    "agentpool=nodepool2:NoSchedule"
  ],
  "orchestratorVersion": "1.24.3",
  "osDiskSizeGb": 128,
  "osDiskType": "Managed",
  "osSku": "Ubuntu",
  "osType": "Linux",
  "podSubnetId": null,
  "powerState": {
    "code": "Running"
  },
  "provisioningState": "Succeeded",
  "proximityPlacementGroupId": null,
  "resourceGroup": "rsg-akstraining1",
  "scaleDownMode": "Delete",
  "scaleSetEvictionPolicy": null,
  "scaleSetPriority": null,
  "spotMaxPrice": null,
  "tags": null,
  "type": "Microsoft.ContainerService/managedClusters/agentPools",
  "typePropertiesType": "VirtualMachineScaleSets",
  "upgradeSettings": {
    "maxSurge": "33%"
  },
  "vmSize": "Standard_DS2_v2",
  "vnetSubnetId": null,
  "workloadRuntime": null
}

```

Let's add also a taint on the default node pool:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool update --nodepool-name nodepool1 --cluster-name akscli-1 -g rsg-akstraining1 --enable-cluster-autoscaler --min-count 3 --max-count 6 --max-surge 33% --node-taints CriticalAddonsOnly=true:NoSchedule
{
  "availabilityZones": [
    "1",
    "2",
    "3"
  ],
  "count": 3,
  "creationData": null,
  "currentOrchestratorVersion": "1.24.3",
  "enableAutoScaling": true,
  "enableEncryptionAtHost": false,
  "enableFips": false,
  "enableNodePublicIp": false,
  "enableUltraSsd": false,
  "gpuInstanceProfile": null,
  "hostGroupId": null,
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rsg-aksTraining1/providers/Microsoft.ContainerService/managedClusters/akscli-1/agentPools/nodepool1",
  "kubeletConfig": null,
  "kubeletDiskType": "OS",
  "linuxOsConfig": null,
  "maxCount": 6,
  "maxPods": 110,
  "minCount": 3,
  "mode": "System",
  "name": "nodepool1",
  "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2022.11.02",
  "nodeLabels": null,
  "nodePublicIpPrefixId": null,
  "nodeTaints": [
    "CriticalAddonsOnly=true:NoSchedule"
  ],
  "orchestratorVersion": "1.24.3",
  "osDiskSizeGb": 128,
  "osDiskType": "Managed",
  "osSku": "Ubuntu",
  "osType": "Linux",
  "podSubnetId": null,
  "powerState": {
    "code": "Running"
  },
  "provisioningState": "Succeeded",
  "proximityPlacementGroupId": null,
  "resourceGroup": "rsg-aksTraining1",
  "scaleDownMode": null,
  "scaleSetEvictionPolicy": null,
  "scaleSetPriority": null,
  "spotMaxPrice": null,
  "tags": null,
  "type": "Microsoft.ContainerService/managedClusters/agentPools",
  "typePropertiesType": "VirtualMachineScaleSets",
  "upgradeSettings": {
    "maxSurge": "33%"
  },
  "vmSize": "Standard_DS2_v2",
  "vnetSubnetId": null,
  "workloadRuntime": null
}

```

checking the taints on the node pools again, we get the following:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-1 -g rsg-akstraining1 | jq .[].nodeTaints
[
  "CriticalAddonsOnly=true:NoSchedule"
]
[
  "agentpool=nodepool2:NoSchedule"
]

```

If we try to schedule pod on the cluster :

```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginxwitouttoleration
  name: nginxwitouttoleration
spec:
  containers:
  - image: nginx:alpine
    name: nginxwitouttoleration
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}

```

We have a pod in a pending state: 

```bash

yumemaru@Azure:~/LabAKS$ k get pod
NAME                    READY   STATUS    RESTARTS   AGE
nginxwitouttoleration   0/1     Pending   0          3s

```

that's becasue the taints block scheduling:

```bash

yumemaru@Azure:~/LabAKS$ k describe pod nginxwitouttoleration 
Name:             nginxwitouttoleration
Namespace:        default
Priority:         0
Service Account:  default
Node:             <none>
Labels:           run=nginxwitouttoleration
Annotations:      <none>
Status:           Pending
IP:               
IPs:              <none>
Containers:
  nginxwitouttoleration:
    Image:        nginx:alpine
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-99kbv (ro)
Conditions:
  Type           Status
  PodScheduled   False 
Volumes:
  kube-api-access-99kbv:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type     Reason             Age   From                Message
  ----     ------             ----  ----                -------
  Warning  FailedScheduling   20s   default-scheduler   0/6 nodes are available: 3 node(s) had untolerated taint {CriticalAddonsOnly: true}, 3 node(s) had untolerated taint {agentpool: nodepool2}. preemption: 0/6 nodes are available: 6 Preemption is not helpful for scheduling.
  Normal   NotTriggerScaleUp  12s   cluster-autoscaler  pod didn't trigger scale-up: 1 node(s) had untolerated taint {CriticalAddonsOnly: true}, 1 node(s) had untolerated taint {agentpool: nodepool2}

```

Let's add a toleration to our pod manifest:

```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginxwitouttoleration
  name: nginxwitouttoleration
spec:
  containers:
  - image: nginx:alpine
    name: nginxwitouttoleration
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
  tolerations:
  - key: "agentpool"
    operator: "Equal"
    value: "nodepool2"
    effect: "NoSchedule"
status: {}


```

And apply the chyange:

```bash

f@df2204lts:~/Documents/myrepo/AKSLab$ k apply -f yamlmanifest/Lab11/podtoleration.yaml 
pod/nginxwitouttoleration configured
yumemaru@Azure:~/LabAKS$ k get pod
NAME                    READY   STATUS    RESTARTS   AGE
nginxwitouttoleration   1/1     Running   0          6m7s


```

# 3. Node pool with dedicated subnet

It may be necessary to isolate from a network perspective a node pool.
In this case, the node pool will require a dedicated subnet.
It is configurable through the `az aks` cli.
However, we need to create the virtual network before the aks cluster.
Otherwise, the virtual network is considered as managed, and it is not possible to select a dedicated subnet for a nodepool.

We would get a message similar to this:


```bash

(InvalidParameter) Cannot use a custom subnet because agent pool nodepool1 is using a managed subnet. Please omit the vnetSubnetID parameter from the request.
Code: InvalidParameter
Message: Cannot use a custom subnet because agent pool nodepool1 is using a managed subnet. Please omit the vnetSubnetID parameter from the request.

```

Let's start by creating a new virtual network:

```bash

yumemaru@Azure:~/LabAKS$ az network vnet create --name vnet-akscli-3 -g rsg-akstraining1 --address-prefixes 10.225.0.0/24
{
  "newVNet": {
    "addressSpace": {
      "addressPrefixes": [
        "10.225.0.0/24"
      ]
    },
    "bgpCommunities": null,
    "ddosProtectionPlan": null,
    "dhcpOptions": {
      "dnsServers": []
    },
    "enableDdosProtection": false,
    "enableVmProtection": null,
    "encryption": null,
    "etag": "W/\"6bdd2eb9-3e6b-4f98-ace8-d20219fda776\"",
    "extendedLocation": null,
    "flowTimeoutInMinutes": null,
    "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3",
    "ipAllocations": null,
    "location": "eastus",
    "name": "vnet-akscli-3",
    "provisioningState": "Succeeded",
    "resourceGroup": "rsg-akstraining1",
    "resourceGuid": "ea0f625b-4b73-4cf6-a08c-6c400447ffea",
    "subnets": [],
    "tags": {},
    "type": "Microsoft.Network/virtualNetworks",
    "virtualNetworkPeerings": []
  }
}

```

And 2 subnets: 

```bash

yumemaru@Azure:~/LabAKS$ az network vnet subnet create --name akssubnet --vnet-name $vnetname --resource-group $rgname --address-prefixes 10.225.0.0/26
{
  "addressPrefix": "10.225.0.0/26",
  "addressPrefixes": null,
  "applicationGatewayIpConfigurations": null,
  "delegations": [],
  "etag": "W/\"84efdebe-9fe6-4e54-af7f-ca7ce627c181\"",
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/akssubnet",
  "ipAllocations": null,
  "ipConfigurationProfiles": null,
  "ipConfigurations": null,
  "name": "akssubnet",
  "natGateway": null,
  "networkSecurityGroup": null,
  "privateEndpointNetworkPolicies": "Disabled",
  "privateEndpoints": null,
  "privateLinkServiceNetworkPolicies": "Enabled",
  "provisioningState": "Succeeded",
  "purpose": null,
  "resourceGroup": "rsg-akstraining1",
  "resourceNavigationLinks": null,
  "routeTable": null,
  "serviceAssociationLinks": null,
  "serviceEndpointPolicies": null,
  "serviceEndpoints": null,
  "type": "Microsoft.Network/virtualNetworks/subnets"
}

yumemaru@Azure:~/LabAKS$ az network vnet subnet create --name winsubnet --vnet-name $vnetname --resource-group $rgname --address-prefixes 10.225.0.64/26
{
  "addressPrefix": "10.225.0.64/26",
  "addressPrefixes": null,
  "applicationGatewayIpConfigurations": null,
  "delegations": [],
  "etag": "W/\"cd176d13-405a-482a-8c12-6bd6a5200c92\"",
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/winsubnet",
  "ipAllocations": null,
  "ipConfigurationProfiles": null,
  "ipConfigurations": null,
  "name": "winsubnet",
  "natGateway": null,
  "networkSecurityGroup": null,
  "privateEndpointNetworkPolicies": "Disabled",
  "privateEndpoints": null,
  "privateLinkServiceNetworkPolicies": "Enabled",
  "provisioningState": "Succeeded",
  "purpose": null,
  "resourceGroup": "rsg-akstraining1",
  "resourceNavigationLinks": null,
  "routeTable": null,
  "serviceAssociationLinks": null,
  "serviceEndpointPolicies": null,
  "serviceEndpoints": null,
  "type": "Microsoft.Network/virtualNetworks/subnets"
}

```
Identify the appropriate network and export the name and resource group name:

```bash
yumemaru@Azure:~/LabAKS$ export vnetname='aks-vnet-16914537'

yumemaru@Azure:~/LabAKS$ export rgname='MC_rsg-aksTraining1_akscli-1_eastus'

```

We also need information regarding the available range on the Virtual Network and the address space allocated to the subnets:

```bash

yumemaru@Azure:~/LabAKS$ az network vnet list | jq .[0].addressSpace
{
  "addressPrefixes": [
    "10.224.0.0/12"
  ]
}

yumemaru@Azure:~/LabAKS$ az network vnet list | jq .[0].subnets[].addressPrefix
"10.224.0.0/16"

```

In this case, we have 1 subnet with a range of `10.224.0.0/16` taken from the address space of the Virtual Network `10.224.0.0/12`

We will create first a new subnet with a range taken in the Virtual Network address space:

```bash

yumemaru@Azure:~/LabAKS$ az network vnet subnet create --name windowsnodepoolsubnet --vnet-name $vnetname --resource-group $rgname --address-prefixes 10.225.0.0/26
{
  "addressPrefix": "10.225.0.0/26",
  "addressPrefixes": null,
  "applicationGatewayIpConfigurations": null,
  "delegations": [],
  "etag": "W/\"71f9dbe7-7b62-4dcf-9780-5cc83f49a7a2\"",
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MC_rsg-aksTraining1_akscli-1_eastus/providers/Microsoft.Network/virtualNetworks/aks-vnet-16914537/subnets/windowsnodepoolsubnet",
  "ipAllocations": null,
  "ipConfigurationProfiles": null,
  "ipConfigurations": null,
  "name": "windowsnodepoolsubnet",
  "natGateway": null,
  "networkSecurityGroup": null,
  "privateEndpointNetworkPolicies": "Disabled",
  "privateEndpoints": null,
  "privateLinkServiceNetworkPolicies": "Enabled",
  "provisioningState": "Succeeded",
  "purpose": null,
  "resourceGroup": "MC_rsg-aksTraining1_akscli-1_eastus",
  "resourceNavigationLinks": null,
  "routeTable": null,
  "serviceAssociationLinks": null,
  "serviceEndpointPolicies": null,
  "serviceEndpoints": null,
  "type": "Microsoft.Network/virtualNetworks/subnets"
}

```


We will need the subnets ids:

```bash

yumemaru@Azure:~/LabAKS$ az network vnet subnet list --vnet-name $vnetname --resource-group $rgname | jq .[].id
"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/akssubnet"
"/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/winsubnet"
yumemaru@Azure:~/LabAKS$ export winsubnet='/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/winsubnet'
yumemaru@Azure:~/LabAKS$ export akssubnet='/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/akssubnet'

```

Now we can create a new cluster:

```bash

yumemaru@Azure:~/LabAKS$ az aks create --resource-group rsg-aksTraining1 --name akscli-3 --enable-aad --enable-oidc-issuer --load-balancer-sku standard --location eastus --network-plugin kubenet --network-policy calico --vnet-subnet-id $akssubnet --zones 1 2 3 --aad-admin-group-object-ids 00000000-0000-0000-0000-000000000000

{
  "aadProfile": {
    "adminGroupObjectIDs": [
      "00000000-0000-0000-0000-000000000000"
    ],
    "adminUsers": null,
    "clientAppId": null,
    "enableAzureRbac": false,
    "managed": true,
    "serverAppId": null,
    "serverAppSecret": null,
    "tenantId": "00000000-0000-0000-0000-000000000000"
  },
  "addonProfiles": null,
  "agentPoolProfiles": [
    {
      "availabilityZones": [
        "1",
        "2",
        "3"
      ],
      "count": 3,
      "creationData": null,
      "currentOrchestratorVersion": "1.23.12",
      "enableAutoScaling": false,
      "enableEncryptionAtHost": false,
      "enableFips": false,
      "enableNodePublicIp": false,
      "enableUltraSsd": false,
      "gpuInstanceProfile": null,
      "hostGroupId": null,
      "kubeletConfig": null,
      "kubeletDiskType": "OS",
      "linuxOsConfig": null,
      "maxCount": null,
      "maxPods": 110,
      "minCount": null,
      "mode": "System",
      "name": "nodepool1",
      "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2022.11.12",
      "nodeLabels": null,
      "nodePublicIpPrefixId": null,
      "nodeTaints": null,
      "orchestratorVersion": "1.23.12",
      "osDiskSizeGb": 128,
      "osDiskType": "Managed",
      "osSku": "Ubuntu",
      "osType": "Linux",
      "podSubnetId": null,
      "powerState": {
        "code": "Running"
      },
      "provisioningState": "Succeeded",
      "proximityPlacementGroupId": null,
      "scaleDownMode": null,
      "scaleSetEvictionPolicy": null,
      "scaleSetPriority": null,
      "spotMaxPrice": null,
      "tags": null,
      "type": "VirtualMachineScaleSets",
      "upgradeSettings": {
        "maxSurge": null
      },
      "vmSize": "Standard_DS2_v2",
      "vnetSubnetId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/akssubnet",
      "workloadRuntime": null
    }
  ],
  "apiServerAccessProfile": null,
  "autoScalerProfile": null,
  "autoUpgradeProfile": null,
  "azurePortalFqdn": "akscli-3-rsg-akstraining1-00000-5c633efa.portal.hcp.eastus.azmk8s.io",
  "currentKubernetesVersion": "1.23.12",
  "disableLocalAccounts": false,
  "diskEncryptionSetId": null,
  "dnsPrefix": "akscli-3-rsg-aksTraining1-00000",
  "enablePodSecurityPolicy": null,
  "enableRbac": true,
  "extendedLocation": null,
  "fqdn": "akscli-3-rsg-akstraining1-00000-5c633efa.hcp.eastus.azmk8s.io",
  "fqdnSubdomain": null,
  "httpProxyConfig": null,
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rsg-aksTraining1/providers/Microsoft.ContainerService/managedClusters/akscli-3",
  "identity": {
    "principalId": "a0c344cc-8987-4ad3-b797-d497ff30cb50",
    "tenantId": "00000000-0000-0000-0000-000000000000",
    "type": "SystemAssigned",
    "userAssignedIdentities": null
  },
  "identityProfile": {
    "kubeletidentity": {
      "clientId": "00000000-0000-0000-0000-000000000000",
      "objectId": "00000000-0000-0000-0000-000000000000",
      "resourceId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/MC_rsg-aksTraining1_akscli-3_eastus/providers/Microsoft.ManagedIdentity/userAssignedIdentities/akscli-3-agentpool"
    }
  },
  "kubernetesVersion": "1.23.12",
  "linuxProfile": {
    "adminUsername": "azureuser",
    "ssh": {
      "publicKeys": [
        {
          "keyData": ""
        }
      ]
    }
  },
  "location": "eastus",
  "maxAgentPools": 100,
  "name": "akscli-3",
  "networkProfile": {
    "dnsServiceIp": "10.0.0.10",
    "dockerBridgeCidr": "172.17.0.1/16",
    "ipFamilies": [
      "IPv4"
    ],
    "loadBalancerProfile": {
      "allocatedOutboundPorts": null,
      "effectiveOutboundIPs": [
        {
          "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/MC_rsg-aksTraining1_akscli-3_eastus/providers/Microsoft.Network/publicIPAddresses/00000000-0000-0000-0000-000000000000",
          "resourceGroup": "MC_rsg-aksTraining1_akscli-3_eastus"
        }
      ],
      "enableMultipleStandardLoadBalancers": null,
      "idleTimeoutInMinutes": null,
      "managedOutboundIPs": {
        "count": 1,
        "countIpv6": null
      },
      "outboundIPs": null,
      "outboundIpPrefixes": null
    },
    "loadBalancerSku": "Standard",
    "natGatewayProfile": null,
    "networkMode": null,
    "networkPlugin": "kubenet",
    "networkPolicy": "calico",
    "outboundType": "loadBalancer",
    "podCidr": "10.244.0.0/16",
    "podCidrs": [
      "10.244.0.0/16"
    ],
    "serviceCidr": "10.0.0.0/16",
    "serviceCidrs": [
      "10.0.0.0/16"
    ]
  },
  "nodeResourceGroup": "MC_rsg-aksTraining1_akscli-3_eastus",
  "oidcIssuerProfile": {
    "enabled": true,
    "issuerUrl": "https://eastus.oic.prod-aks.azure.com/00000000-0000-0000-0000-000000000000/82ebbc0b-a958-4843-9687-6d8e096b30dc/"
  },
  "podIdentityProfile": null,
  "powerState": {
    "code": "Running"
  },
  "privateFqdn": null,
  "privateLinkResources": null,
  "provisioningState": "Succeeded",
  "publicNetworkAccess": null,
  "resourceGroup": "rsg-aksTraining1",
  "securityProfile": {
    "azureKeyVaultKms": null,
    "defender": null
  },
  "servicePrincipalProfile": {
    "clientId": "msi",
    "secret": null
  },
  "sku": {
    "name": "Basic",
    "tier": "Free"
  },
  "storageProfile": {
    "blobCsiDriver": null,
    "diskCsiDriver": {
      "enabled": true
    },
    "fileCsiDriver": {
      "enabled": true
    },
    "snapshotController": {
      "enabled": true
    }
  },
  "systemData": null,
  "tags": null,
  "type": "Microsoft.ContainerService/ManagedClusters",
  "windowsProfile": null
}

```

And a windows nodepool in the dedicated subnet

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool add --name winnodepool --cluster-name akscli-3 -g $rgname --node-count 3 --vnet-subnet-id $winsubnet
{
  "availabilityZones": null,
  "count": 3,
  "creationData": null,
  "currentOrchestratorVersion": "1.23.12",
  "enableAutoScaling": false,
  "enableEncryptionAtHost": false,
  "enableFips": false,
  "enableNodePublicIp": false,
  "enableUltraSsd": false,
  "gpuInstanceProfile": null,
  "hostGroupId": null,
  "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourcegroups/rsg-akstraining1/providers/Microsoft.ContainerService/managedClusters/akscli-3/agentPools/winnodepool",
  "kubeletConfig": null,
  "kubeletDiskType": "OS",
  "linuxOsConfig": null,
  "maxCount": null,
  "maxPods": 110,
  "minCount": null,
  "mode": "User",
  "name": "winnodepool",
  "nodeImageVersion": "AKSUbuntu-1804gen2containerd-2022.11.12",
  "nodeLabels": null,
  "nodePublicIpPrefixId": null,
  "nodeTaints": null,
  "orchestratorVersion": "1.23.12",
  "osDiskSizeGb": 128,
  "osDiskType": "Managed",
  "osSku": "Ubuntu",
  "osType": "Linux",
  "podSubnetId": null,
  "powerState": {
    "code": "Running"
  },
  "provisioningState": "Succeeded",
  "proximityPlacementGroupId": null,
  "resourceGroup": "rsg-akstraining1",
  "scaleDownMode": "Delete",
  "scaleSetEvictionPolicy": null,
  "scaleSetPriority": null,
  "spotMaxPrice": null,
  "tags": null,
  "type": "Microsoft.ContainerService/managedClusters/agentPools",
  "typePropertiesType": "VirtualMachineScaleSets",
  "upgradeSettings": {
    "maxSurge": null
  },
  "vmSize": "Standard_DS2_v2",
  "vnetSubnetId": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rsg-akstraining1/providers/Microsoft.Network/virtualNetworks/vnet-akscli-3/subnets/winsubnet",
  "workloadRuntime": null
}

```

## 4. Spot nodepool

Spot VMs are an efficient way to optimize costs.
In AKS there is a possiblity to use spot nodepool for workload that can be interrupted.
To create a spot nodepool, we use the following command:


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

Similarly to what we saw previously, a spot nodepool comes with a taint by default. Which means that workloads need a tolerations to run on this node pool.
Also, to be sure that the workload does run on the spot VMs, either all other node pools have taint, or we need to managed affinity on the pods
Let's check the taint on the node pool:

```bash

yumemaru@Azure:~/LabAKS$ az aks nodepool list --cluster-name akscli-3 -g $rgname | jq .[].nodeTaints
null
[
  "kubernetes.azure.com/scalesetpriority=spot:NoSchedule"
]
null

```

Now that the taint is identified, let's create a yaml manifest for a pod, with the appropriate toleration, and a node affinity:


```yaml

apiVersion: v1
kind: Pod
metadata:
  labels:
    run: testspot
  name: testspot
spec:
  containers:
  - image: nginx:alpine
    name: testspot
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
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
status: {}

```

Once thepod is created, we can check that it is running on the spot nodepool with the following command:

```bash

yumemaru@Azure:~/LabAKS$ k get pod -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP           NODE                                   NOMINATED NODE   READINESS GATES
testspot   1/1     Running   0          12s   10.244.6.2   aks-spotnodepool-22837959-vmss000001   <none>           <none>

```