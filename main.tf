terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.66.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {
    virtual_machine {
      delete_os_disk_on_deletion = true
    }
    key_vault {
      recover_soft_deleted_key_vaults = true
      purge_soft_delete_on_destroy    = true
    }
    virtual_machine_scale_set {
      roll_instances_when_required = true
    }
  }
}

