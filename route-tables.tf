resource "azurerm_route_table" "spoke_workload_rt" {
  name                = "rt-spoke-workload"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_route" "spoke_default_to_firewall" {
  name                   = "route-default-to-firewall"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.spoke_workload_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_private_ip
}

resource "azurerm_subnet_route_table_association" "workload_subnet_assoc" {
  subnet_id      = azurerm_subnet.workload_subnet.id
  route_table_id = azurerm_route_table.spoke_workload_rt.id
}