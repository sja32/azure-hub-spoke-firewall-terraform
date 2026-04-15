output "nva_public_ip" {
  description = "Public IP address of the NVA"
  value       = azurerm_public_ip.nva_pip.ip_address
}

output "spoke_vm_private_ip" {
  description = "Private IP of spoke VM"
  value       = azurerm_network_interface.spoke_nic.private_ip_address
}