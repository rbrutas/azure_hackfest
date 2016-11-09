# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "..."
  client_id       = "..."
  client_secret   = "..."
  tenant_id       = "..."
}

# Create a resource group
resource "azurerm_resource_group" "azurefest-sed-rg" {
    name     = "azurefest-sed-rg"
    location = "East US"
}

# Create a virtual network in the web_servers resource group
resource "azurerm_virtual_network" "azurefest-east-network" {
  name                = "azurefest-east-network"
  address_space       = ["10.0.0.0/16"]
  location            = "East US"
  resource_group_name = "${azurerm_resource_group.azurefest-sed-rg.name}"

  subnet {
    name           = "consul"
    address_prefix = "10.0.1.0/24"
  }

  subnet {
    name           = "mesos"
    address_prefix = "10.0.2.0/24"
  }

  subnet {
    name           = "cassandra"
    address_prefix = "10.0.3.0/24"
  }
}
resource "azurerm_storage_account" "azurefest-east-persistent-sa" {
    name = "azurefestpersistentsa"
    resource_group_name = "${azurerm_resource_group.azurefest-sed-rg.name}"

    location = "eastus"
    account_type = "Premium_LRS"

    tags {
        environment = "demo"
    }
}
resource "azurerm_storage_container" "images" {
    name = "vhds"
    resource_group_name = "${azurerm_resource_group.azurefest-sed-rg.name}"
    storage_account_name = "${azurerm_storage_account.azurefest-east-persistent-sa.name}"
    container_access_type = "private"
}
resource "azurerm_storage_account" "azurefest-east-diag-sa" {
    name = "azurefestdiagsa"
    resource_group_name = "${azurerm_resource_group.azurefest-sed-rg.name}"

    location = "eastus"
    account_type = "Standard_GRS"

    tags {
        environment = "demo"
    }
}

resource "azurerm_network_security_group" "azurefest-east-sg" {
    name = "azurefest-east-sg"
    location = "eastus"
    resource_group_name = "${azurerm_resource_group.azurefest-sed-rg.name}"

    security_rule {
        name = "azurefest-east-rule-http"
        priority = 100
        direction = "Inbound"
        access = "Deny"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    security_rule {
        name = "azurefest-east-rule"
        priority = 300
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }

    tags {
        environment = "demo"
    }
}
resource "azurerm_public_ip" "consul_public_ips" {
    count = 3
    name = "consul_public_ips-${count.index+1}"
    location = "East US"
    resource_group_name = "${azurerm_resource_group.azurefest-sed-rg.name}"
    public_ip_address_allocation = "static"

    tags {
        environment = "demo"
    }
}
output "azure_consul_public_ips" {
  value = "${join(" ", azurerm_public_ip.consul_public_ips.*.ip_address)}"
}
