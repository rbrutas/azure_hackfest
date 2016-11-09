# Configure the Microsoft Azure Provider
provider "azurerm" {
  subscription_id = "..."
  client_id       = "..."
  client_secret   = "..."
  tenant_id       = "..."
}

variable "azure_resource_group_name" {
  default = "azurefest-sed-rg"
}

variable "azure_region" {
  default = "eastus"
}

variable "azure_storage_account" {
    default = "azurefest-east-persistent-sa"
}

variable "environment" {
  default = "demo"
}

variable "consul_instance_count" {
  default = 3
}

resource "azurerm_availability_set" "consul-eastus" {
    name = "consul-eastus"
    location = "eastus"
    resource_group_name = "${var.azure_resource_group_name}"

    tags {
        environment = "demo"
    }
}

resource "azurerm_network_interface" "consul_nic" {
    count = "${var.consul_instance_count}"
    name = "consul_nic-${count.index+1}"
    location = "${var.azure_region}"
    resource_group_name = "${var.azure_resource_group_name}"
    network_security_group_id = "/subscriptions/.../resourceGroups/${var.azure_resource_group_name}/providers/Microsoft.Network/networkSecurityGroups/azurefest-east-sg"
    ip_configuration {
        name = "consul-ip"
        subnet_id = "/subscriptions/.../resourceGroups/azurefest-sed-rg/providers/Microsoft.Network/virtualNetworks/azurefest-east-network/subnets/consul"
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = "/subscriptions/.../resourceGroups/azurefest-sed-rg/providers/Microsoft.Network/publicIPAddresses/consul_public_ips-${count.index+1}"
    }
}

resource "azurerm_virtual_machine" "consul_node" {
    count = "${var.consul_instance_count}"
    name = "consul-${var.azure_region}-${count.index+1}"
    location = "${var.azure_region}"
    availability_set_id = "${azurerm_availability_set.consul-eastus.id}"
    resource_group_name = "${var.azure_resource_group_name}"
    network_interface_ids = ["${element(azurerm_network_interface.consul_nic.*.id, count.index)}"]
    vm_size = "Standard_DS2_v2"
    delete_os_disk_on_termination = "true"

    storage_os_disk {
        name = "consul_image-${count.index+1}"
        vhd_uri = "https://azurefestpersistentsa.blob.core.windows.net/vhds/blue-consul-${count.index+1}.vhd"
        create_option = "FromImage"
        caching = "ReadWrite"
        image_uri = "https://azurefestpersistentsa.blob.core.windows.net/system/Microsoft.Compute/Images/vhds/consul-osDisk.eea01fb9-44f2-41b8-9891-810cd8055030.vhd"
        os_type = "linux"
    }

    os_profile {
        computer_name = "consul-${var.azure_region}-${count.index+1}"
        admin_username = "ubuntu"
        admin_password = "Passw0rd!"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
        path = "/home/ubuntu/.ssh/authorized_keys"
        key_data = "${file("~/.ssh/id_rsa.pub")}"
      }
    }
    tags {
        environment = "demo"
    }
}

resource "null_resource" "consul_join_cluster" {
  triggers {
    cluster_instance_ids = "${join(",", azurerm_virtual_machine.consul_node.*.name)}"
  }
  provisioner "local-exec"{
   command = "sleep 10"
  }
  connection {
    host = "13.92.36.55"
    user = "ubuntu"
    key_file = "${file("~/.ssh/id_rsa.pub")}"
  }
  provisioner "remote-exec" {
   inline = [
    "sudo /opt/consul/bin/consul join ${join(" ", azurerm_virtual_machine.consul_node.*.name)}"
   ]
  }
}
