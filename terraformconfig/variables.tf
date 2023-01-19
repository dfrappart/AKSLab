######################################################
# Variables
######################################################

##############################################################
#Variable declaration for provider

variable "AzureSubscriptionID" {
  type                            = string
  description                     = "The subscription id for the authentication in the provider"
}

variable "AzureClientID" {
  type                            = string
  description                     = "The application Id, taken from Azure AD app registration"
}


variable "AzureClientSecret" {
  type                            = string
  description                     = "The Application secret"

}

variable "AzureTenantID" {
  type                            = string
  description                     = "The Azure AD tenant ID"
}


variable "AzureADClientSecret" {
  type                            = string
  description                     = "The AAD Application secret"

}

variable "AzureADClientID" {
  type                            = string
  description                     = "The AAD Client ID"
}


######################################################
# Data sources variables

variable "AKSAdminGroupName" {
  type                            = string
  description                     = "Name of the aks admin group"
}


######################################################
# Common variables

variable "AzureRegion" {
  type                            = string
  description                     = "The region for the Azure resource"
  default                         = "eastus"

}

######################################################
# KV variables

variable "Secretperms_TFApp_AccessPolicy" {
  type                            = list
  description                     = "The authorization on the secret for the Access policy"
  default                         = [
                                      "Backup",
                                      "Purge",
                                      "Recover",
                                      "Restore",
                                      "Get",
                                      "List",
                                      "Set",
                                      "Delete"
                                    ]

}

variable "Certperms_TFApp_AccessPolicy" {
  type                            = list
  description                     = "The authorization on the secret for the Access policy"
  default                         = [
                                      "Backup", 
                                      "Create", 
                                      "Delete", 
                                      "DeleteIssuers", 
                                      "Get", 
                                      "GetIssuers", 
                                      "Import", 
                                      "List", 
                                      "ListIssuers", 
                                      "ManageContacts", 
                                      "ManageIssuers", 
                                      "Purge", 
                                      "Recover", 
                                      "Restore", 
                                      "SetIssuers",
                                      "Update"
                                    ]
                                      
}

variable "Keyperms_TFApp_AccessPolicy" {
  type                            = list
  description                     = "The authorization on the secret for the Access policy"
  default                         = [
                                      "Backup", 
                                      "Create", 
                                      "Decrypt", 
                                      "Delete", 
                                      "Encrypt", 
                                      "Get", 
                                      "Import", 
                                      "List", 
                                      "Purge", 
                                      "Recover", 
                                      "Restore", 
                                      "Sign", 
                                      "UnwrapKey", 
                                      "Update", 
                                      "Verify", 
                                      "WrapKey", 
                                      "Release", 
                                      "Rotate", 
                                      "GetRotationPolicy", 
                                      "SetRotationPolicy"
                                    ]

}

######################################################
# AKS variables

variable "Keyperms_AKSUAI_AccessPolicy" {
  type                            = list
  description                     = "The authorization on the secret for the Access policy"
  default                         = [
                                      "Decrypt", 
                                      "Encrypt" 
                                    ]

}

variable "AKSPrivateDNSZoneId" {
  type                            = string
  description                     = "The private DNS zone Id for AKS Cluster"
  default                         = "System"
}

######################################################
# Training

variable "TrainingList" {
  type = list
  description = "The trainee list"
  default = [
    "david.frappart"
  ]
}