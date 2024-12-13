#############################################################################
#This file is used to define data source refering to Azure existing resources
#############################################################################


#############################################################################
#data source for the subscription


data "azurerm_subscription" "current" {}

data "azurerm_client_config" "currentclientconfig" {}

#############################################################################
#data source for azure ad owners

data "azuread_client_config" "current" {}
/*
data "azuread_group" "aksadmin" {
  display_name              = var.AKSAdminGroupName
  security_enabled          = true
}
*/
