resource "azurerm_public_ip" "nva_pip" {
  name                = "pip-nva"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "nva_nsg" {
  name                = "nsg-nva"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_network_security_rule" "allow_ssh_inbound" {
  name                        = "allow-ssh-inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nva_nsg.name
}

resource "azurerm_network_interface" "nva_nic" {
  name                  = "nic-nva"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  ip_forwarding_enabled = true

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.nva_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.2.4"
    public_ip_address_id          = azurerm_public_ip.nva_pip.id
    primary                       = true
  }
}

resource "azurerm_network_interface_security_group_association" "nva_nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nva_nic.id
  network_security_group_id = azurerm_network_security_group.nva_nsg.id
}

resource "azurerm_linux_virtual_machine" "nva_vm" {
  name                = "vm-nva"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_D2s_v3"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nva_nic.id
  ]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("C:/Users/sharo/.ssh/id_ed25519.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    name                 = "osdisk-vm-nva"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  custom_data = base64encode(<<-EOF
    #!/bin/bash
    sysctl -w net.ipv4.ip_forward=1
    sed -i '/net.ipv4.ip_forward/d' /etc/sysctl.conf
    echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
    iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
    apt-get update -y
    apt-get install -y iptables-persistent
    netfilter-persistent save
  EOF
  )
}

resource "azurerm_network_security_rule" "allow_outbound" {
  name                        = "allow-all-outbound"
  priority                    = 200
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nva_nsg.name
}

resource "azurerm_network_security_rule" "allow_spoke_forwarded_inbound" {
  name                        = "allow-spoke-forwarded-inbound"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.1.1.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg.name
  network_security_group_name = azurerm_network_security_group.nva_nsg.name
}