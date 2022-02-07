# We strongly recommend using the required_providers block to set the
# Azure Provider source and version being used
terraform {
  backend "azurerm" {
    resource_group_name   = "pers-robin_mohan-rg"
    storage_account_name  = "storageforrobin"
    container_name        = "tstate"
    key                   = "Rk/X+EPlwSzzBaOrI2UGzVgeaorD+fXPXRllYSG1v2IOv7IqAepI3WDhqRR9Vo60S9zHXJN4GxIcoyR++FR2zA=="
}
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  skip_provider_registration = true
  features {}
}


variable "prefix" {
  default = "featuretest"
}

variable "resource_group_name" {
  default = "pers-robin_mohan-rg"
}

variable "resource_group_location" {
    default = "eastus"
}


resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name = "${var.prefix}-pip"
  location = var.resource_group_location
  resource_group_name = var.resource_group_name
  allocation_method = "Dynamic"
  sku = "Basic"
}

resource "azurerm_network_security_group" "main" {
  name                = "${var.prefix}-securitygroup"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "SSH"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = 22
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "testing"
  }
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "testconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.main.id
  }
}

resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = var.resource_group_location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "robin"
    admin_password = "nibor"
  }
  os_profile_linux_config {
    disable_password_authentication = true

    ssh_keys {
      path     = "/home/robin/.ssh/authorized_keys"
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDeQjMzPRzsXEvRPIlb6FWwJQuZmJhGRPxMTpS0A7qW+cN8097tftBZNXCnEkh6pACxJPjGxUaDxnuqUCtN92M3TtxgYWq78wCQEDOlTMleE38AMch/PTfabFeHQADrbSg+esNWjMdJd8Vn6x6jSY84dig3R3muDZc9a4Jvl1UO7T2PvrGjwjfpgWi0loR24sUowGCt1mtuIvOEpT4YNeYBvQXaL/8uyRlVn4fEzazngA5G45hBV8zu10P+5CJZu5gxId1TmWWp4pfoYmY0dqAnV9GZcWFsETttB4S2atDL/4AQ4RiPKekrfiptG5F6Wdj+upaarReeYaYp1vpnLpl2HOytcdRwKI2zHAvTAFsD/yS2tch2pp31ZhnqNpTgguB8fD4pEilf6hAqmhe4Pb47yTQXf2HAwGcnJ6NksLA/uUPC3ftslyjuffI280PhsRmPYSaMIj0JfW9lVy2ol86B8buK3q12SVnfu+HMkXeYiKmgbSYu44Y61st7mugesxr8i1S7lXJ6H04NSYOxK/XYUlQS8sRErU68kU9uLQZAZJ6QL+zdHqdX5DId3F7dVvbOnCMUtXzNfQc6FYB1xpgzPf+ELvcRmstmRkfLWAekIW1IN6a5VL8NWpJOHq6EiDqEqHrKxxIwgXljT1P8TVDH3d3U5KcQ5bnvTrKNwtYKzw== robin.mohan@devoteam.com"
    }

  }
  tags = {
    environment = "testing"
  }
}

# resource "local_file" "hosts_cfg" {
#   content = templatefile("./templates/hosts.tpl",
#     {
#       test_clients = azurerm_public_ip.main.*.ip_address
#     }
#   )
#   filename = "../ansible/hosts.cfg"
# }

