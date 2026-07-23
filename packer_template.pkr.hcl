packer {
  required_plugins {
    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = "~> 1"
    }
    azure = {
      source  = "github.com/hashicorp/azure"
      version = "~> 1"
    }
  }
}

source "azure-arm" "ado_agent_vm" {
  use_azure_cli_auth                = true
  image_offer                       = var.image_offer
  image_publisher                   = var.image_publisher
  image_sku                         = var.image_sku
  location                          = var.az_location
  managed_image_name                = "${var.image_prefix}-${var.image_version}"
  managed_image_resource_group_name = var.rgroup_name
  os_type                           = "Linux"
  subscription_id                   = var.subscription_id
  tenant_id                         = "3a4af158-b8a5-4bc8-833c-d973205f2bc2"
  vm_size                           = var.vm_size
}

build {
  sources = ["source.azure-arm.ado_agent_vm"]
  provisioner "ansible" {
    playbook_file = "../../ansible/ansible-roles/custom-ami.yml"
    use_proxy     = false
  }
  provisioner "shell" {
    script       = "../../scripts/provisioners/custom-ami.sh"
    pause_before = "10s"
    timeout      = "10s"
  }
}
