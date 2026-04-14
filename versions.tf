terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    massdriver = {
      source  = "massdriver-cloud/massdriver"
      version = ">= 1.0"
    }
  }
}
