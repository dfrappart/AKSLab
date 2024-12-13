
# Base resources for AKS

resource "azurerm_resource_group" "RGMonitor" {

  name                                  = "rsg-monitor"
  location                              = var.AzureRegion
}

resource "azurerm_resource_group" "RG" {
  #count                                 = 3
  for_each                              = toset(var.TrainingList)
  name                                  = "rsg-${each.value}"
  location                              = var.AzureRegion
}


resource "azurerm_virtual_network" "vnet" {
  #count                                 = 3
  for_each                              = toset(var.TrainingList)
  name                                  = "vnet-aks${each.value}"
  location                              = azurerm_resource_group.RG[each.value].location
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  address_space                         = ["172.22.0.0/20"] 
}

resource "azurerm_subnet" "subnet" {
  #count                                 = 3
  for_each                              = toset(var.TrainingList)
  name                                  = "sub-aks"
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  virtual_network_name                  = azurerm_virtual_network.vnet[each.value].name
  address_prefixes                      = [cidrsubnet("172.22.0.0/20",4,0)]

}

# Additional subnet for API integration

resource "azurerm_subnet" "subnet-k8sapi" {

  lifecycle {
    ignore_changes = [
      delegation
    ]
  }
  for_each                              = toset(var.TrainingList)
  name                                  = "sub-k8sapi"
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  virtual_network_name                  = azurerm_virtual_network.vnet[each.value].name
  address_prefixes                      = [cidrsubnet("172.22.0.0/20",7,8)]

}

resource "azurerm_network_security_group" "nsg-k8sapi" {
  for_each                              = toset(var.TrainingList)
  name                                  = "nsg-${azurerm_subnet.subnet-k8sapi[each.value].name}"
  location                              = azurerm_resource_group.RG[each.value].location
  resource_group_name                   = azurerm_resource_group.RG[each.value].name

}

resource "azurerm_subnet_network_security_group_association" "k8ssub-nsgassociation" {
  for_each                              = toset(var.TrainingList)

  subnet_id                             = azurerm_subnet.subnet-k8sapi[each.value].id
  network_security_group_id             = azurerm_network_security_group.nsg-k8sapi[each.value].id
}

# STA for flow logs

resource "random_string" "randomstringstaflowlogs" {
  for_each                              = toset(var.TrainingList)
  length                                = 4
  special                               = false
  upper                                 = false
}

resource "azurerm_storage_account" "STAForFlowLogs" {
  for_each                              = toset(var.TrainingList)
  #substr(replace("${local.RgName}kvpsq${local.PSQLSuffix}", "-", ""), 0, 24)
  name                                  = substr(replace(replace("staflowlog${resource.random_string.randomstringsta[each.value].result}${lower(each.value)}","-",""),".",""),0,24)
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  location                              = azurerm_resource_group.RG[each.value].location
  account_tier                          = "Standard"
  account_replication_type              = "LRS"

}


resource "azurerm_network_watcher_flow_log" "k8ssub-flowlog" {
  for_each                              = toset(var.TrainingList)

  network_watcher_name                  = "NetworkWatcher_eastus"
  resource_group_name                   = "NetworkWatcherRG"
  name                                  = "nsgflowlog-apiserver-${lower(each.value)}"

  network_security_group_id = azurerm_network_security_group.nsg-k8sapi[each.value].id
  storage_account_id        = azurerm_storage_account.STAForFlowLogs[each.value].id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.logaks.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.logaks.location
    workspace_resource_id = azurerm_log_analytics_workspace.logaks.id
    interval_in_minutes   = 10
  }
}



resource "azurerm_log_analytics_workspace" "logaks" {
  location                              = azurerm_resource_group.RGMonitor.location
  resource_group_name                   = azurerm_resource_group.RGMonitor.name
  name                                  = "law-akstraining"
  sku                                   = "PerGB2018"
  retention_in_days                     = 30
}

# SSH key for AKS creation

resource "tls_private_key" "akssshkey" {
  for_each                              = toset(var.TrainingList)
  algorithm                             = "RSA"
  rsa_bits                              = 4096
}

resource "azurerm_ssh_public_key" "akssshtoazure" {
  for_each                              = toset(var.TrainingList)
  name                                  = substr(replace(replace("akssshkey${each.value}","-",""),".",""),0,24) 
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  location                              = var.AzureRegion
  public_key                            = tls_private_key.akssshkey[each.value].public_key_openssh
}

# STA related resources for PVC test

resource "random_string" "randomstringsta" {
  for_each                              = toset(var.TrainingList)
  length                                = 4
  special                               = false
  upper                                 = false
}

resource "azurerm_storage_account" "STAForPVCTest" {
  for_each                              = toset(var.TrainingList)
  #substr(replace("${local.RgName}kvpsq${local.PSQLSuffix}", "-", ""), 0, 24)
  name                                  = substr(replace(replace("stafile${resource.random_string.randomstringsta[each.value].result}${lower(each.value)}","-",""),".",""),0,24)
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  location                              = azurerm_resource_group.RG[each.value].location
  account_tier                          = "Standard"
  account_replication_type              = "LRS"


}

resource "azurerm_storage_share" "k8scsi" {
  #count                               = 3
  for_each                              = toset(var.TrainingList)
  name                                  = "aksshare"
  storage_account_name                  = azurerm_storage_account.STAForPVCTest[each.value].name
  quota                                 = 50

}

resource "azurerm_storage_share_file" "indexhtml" {
  #count                               = 3 
  for_each                              = toset(var.TrainingList)
  name                                  = "index.html"
  storage_share_id                      = azurerm_storage_share.k8scsi[each.value].id
  source                                = "./files/index.html"
}

# KV for kms etcd encryption 

resource "random_string" "randomstringkvkms" {
  for_each                              = toset(var.TrainingList)
  length                                = 4
  special                               = false
  upper                                 = false
}

resource "azurerm_key_vault" "akskmskv" {
  for_each                              = toset(var.TrainingList)
  name                                  = "kvkmsaks${resource.random_string.randomstringkvkms[each.value].result}"
  resource_group_name                   = azurerm_resource_group.RG[each.value].name
  location                              = azurerm_resource_group.RG[each.value].location
  enabled_for_disk_encryption = true
  tenant_id                             = data.azurerm_client_config.currentclientconfig.tenant_id

  sku_name                              = "standard"


}

resource "azurerm_key_vault_access_policy" "akskvkmsaccesspolicyTF" {
  for_each                              = toset(var.TrainingList)

  key_vault_id                           = azurerm_key_vault.akskmskv[each.value].id
  tenant_id                              = data.azurerm_client_config.currentclientconfig.tenant_id
  object_id                              = data.azurerm_client_config.currentclientconfig.object_id

  key_permissions                        = var.Keyperms_TFApp_AccessPolicy

  secret_permissions                     = var.Secretperms_TFApp_AccessPolicy

  certificate_permissions                = var.Certperms_TFApp_AccessPolicy
}

######################################################################
# Module for AKS

# UAI for AKS

module "UAI_AKS" {

  for_each                              = toset(var.TrainingList)
  #Module location
  source = "github.com/dfrappart/Terra-AZModuletest//Modules_building_blocks/441_UserAssignedIdentity/"
  
  #Module variable
  UAISuffix                             = replace("aks${each.value}", ".", "")
  TargetRG                              = azurerm_resource_group.RG[each.value].name

}

# Required role for API Subnet integration

resource "azurerm_role_assignment" "AKSNetworkContributor" {
  for_each                              = toset(var.TrainingList)
  scope                                 = azurerm_resource_group.RG[each.value].id
  role_definition_name                  = "Network Contributor"
  principal_id                          = module.UAI_AKS[each.value].PrincipalId
}

# Access Policy for AKS Control plane UAI

resource "azurerm_key_vault_access_policy" "akskvkmsaccesspolicyAKS" {
  for_each                              = toset(var.TrainingList)

  key_vault_id                          = azurerm_key_vault.akskmskv[each.value].id
  tenant_id                             = data.azurerm_client_config.currentclientconfig.tenant_id
  object_id                             = module.UAI_AKS[each.value].PrincipalId

  key_permissions                       = var.Keyperms_AKSUAI_AccessPolicy


}

# Key used for encryption of etcd

resource "azurerm_key_vault_key" "akskmskey" {
  for_each                              = toset(var.TrainingList)

  name                                  = "akskmskey${module.UAI_AKS[each.value].Name}"
  key_vault_id                          = azurerm_key_vault.akskmskv[each.value].id
  key_type                              = "RSA"
  key_size                              = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]
}

# AKS Cluster
/*
module "AKS" {
  #count = 3
  for_each                              = toset(var.TrainingList)
  #Module Location
  source                                = "github.com/dfrappart/Terra-AZModuletest//Custom_Modules/IaaS_AKS_Cluster?ref=aksv1.3.1" # c8342aca9832e14dfe598c779a374d453ea76204"

  #Module variable


  AKSLocation                           = azurerm_resource_group.RG[each.value].location
  AKSRGName                             = azurerm_resource_group.RG[each.value].name
  AKSSubnetId                           = azurerm_subnet.subnet[each.value].id
  AKSNetworkPlugin                      = "kubenet"
  AKSNetPolProvider                     = "calico"
  AKSClusSuffix                         = substr(replace(replace(each.value,".",""),"-",""),0,12)
  AKSIdentityType                       = "UserAssigned"
  UAIIds                                = [module.UAI_AKS[each.value].FullUAIOutput.id]
  PublicSSHKey                          = tls_private_key.akssshkey[each.value].public_key_openssh  
  AKSClusterAdminsIds                   = [var.AKSAdminGroupObjectId]#[data.azuread_group.aksadmin.object_id]
  TaintCriticalAddonsEnabled            = false
  LawLogId                              = azurerm_log_analytics_workspace.logaks.id
  #EnableHostEncryption                  = true
  #LawDefenderId                         = data.azurerm_log_analytics_workspace.defenderlaw.id
  #IsAKSPrivate                          = true
  #PrivateClusterPublicFqdn              = true
  #PrivateDNSZoneId                      = var.AKSPrivateDNSZoneId
  #IsBYOPrivateDNSZone                   = true
  #IsBlobDriverEnabled                   = true
  EnableDiagSettings = true
  EnableHostEncryption     = false
  AKSNodeCount                         = 1
  EnableAKSAutoScale                   = false
  MaxAutoScaleCount = null
  MinAutoScaleCount = null

}
*/

