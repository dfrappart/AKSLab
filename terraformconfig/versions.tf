######################################################################
# backend block for partial configuration
######################################################################

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    azurerm = {
      version = ">= 3.3.0"
    }

    azuread = {
      version = ">= 2.30"
    }

    azapi = {
      source = "azure/azapi"
      version = ">=1.1"
    }

  }

  backend "azurerm" {}
}
