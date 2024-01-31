# Resoure Group
resource "azurerm_resource_group" "ado-2401-rg" {
  name     = "ado-2401"
  location = "East Us"
    tags = {
    env = "dev"
  }
}

# Virtual Network 
resource "azurerm_virtual_network" "ado-vnet" {
  name                = "ado-network"
  location            = azurerm_resource_group.ado-2401-rg.location
  resource_group_name = azurerm_resource_group.ado-2401-rg.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet
resource "azurerm_subnet" "ado-sn" {
  name                 = "ado-subnet"
  resource_group_name  = azurerm_resource_group.ado-2401-rg.name
  virtual_network_name = azurerm_virtual_network.ado-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP - PIP
resource "azurerm_public_ip" "ado-pip" {
  name                = "ado-public-ip"
  resource_group_name = azurerm_resource_group.ado-2401-rg.name
  location            = azurerm_resource_group.ado-2401-rg.location
  allocation_method   = "Static"

  tags = {
    env = "dev"
  }
}

# Network Interface - NIC
resource "azurerm_network_interface" "ado-nic" {
  name                = "ado-network-card"
  location            = azurerm_resource_group.ado-2401-rg.location
  resource_group_name = azurerm_resource_group.ado-2401-rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.ado-sn.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.ado-pip.id
  }
}

# Virtual Machine
resource "azurerm_linux_virtual_machine" "ado-vm" {
  name                = "ado-docker-machine"
  resource_group_name = azurerm_resource_group.ado-2401-rg.name
  location            = azurerm_resource_group.ado-2401-rg.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  custom_data = filebase64("script.sh")
  network_interface_ids = [
    azurerm_network_interface.ado-nic.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub") 
    # generate key using command ssh-keygen
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}