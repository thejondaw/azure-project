# Public IP for Load Balancer
resource "azurerm_public_ip" "example" {
  name                = "Public-IP"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name
  allocation_method   = "Static"
  domain_name_label   = azurerm_resource_group.azure-project.name
}

# Load Balancer (Front-End)
resource "azurerm_lb" "example" {
  name                = "Load-Balancer"
  location            = var.location
  resource_group_name = azurerm_resource_group.azure-project.name

  frontend_ip_configuration {
    name                 = "Public-IP"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

# Load Balancer (Back-End) Address Pool
resource "azurerm_lb_backend_address_pool" "example" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "BackEndAddressPool"
}

# Load Balancer - Probe - HTTP
resource "azurerm_lb_probe" "http" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "http-running-probe"
  port            = 80
}

# Load Balancer - Rule - HTTP
resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "Public-IP"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.example.id]
  probe_id                       = azurerm_lb_probe.http.id
}

# ---------------------------------------------------------------------------



# ---------------------------------------------------------------------------

# Virtual Machine Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "vm_ss" {
  name                            = "vm-ss"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.azure-project.name
  sku                             = "Standard_D2S_v3"
  instances                       = 2
  admin_username                  = "adminuser"
  admin_password                  = "pa$$w0rd"
  health_probe_id                 = azurerm_lb_probe.http.id
  disable_password_authentication = false
  custom_data                     = filebase64("wordpress.sh")

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "7_9-gen2"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                      = "NetworkInterface"
    primary                   = true
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
      name                                   = "IPConfiguration"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet_3.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.example.id]
    }
  }
}
