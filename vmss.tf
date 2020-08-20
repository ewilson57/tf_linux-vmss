data "azurerm_shared_image" "ubuntu-nginx" {
  name                = "ubuntu-nginx"
  gallery_name        = "shared_image_gallery_1"
  resource_group_name = "management-rg"
}

resource "azurerm_linux_virtual_machine_scale_set" "linux-vmss" {
  name                            = var.prefix
  computer_name_prefix            = var.prefix
  location                        = azurerm_resource_group.linux-vmss.location
  resource_group_name             = azurerm_resource_group.linux-vmss.name
  sku                             = "Standard_DS1_v2"
  instances                       = 2
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_key)
  }

  source_image_id = data.azurerm_shared_image.ubuntu-nginx.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "${var.prefix}-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.linux-vmss[1].id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.linux-vmss-bpepool.id]
      load_balancer_inbound_nat_rules_ids    = [azurerm_lb_nat_pool.natpool.id]
    }
  }
  depends_on = [azurerm_lb_rule.linux-vmss-lb-rule]
}

resource "azurerm_public_ip" "linux-vmss-public-ip" {
  name                    = "${var.prefix}-public-ip"
  resource_group_name     = azurerm_resource_group.linux-vmss.name
  allocation_method       = "Static"
  idle_timeout_in_minutes = 4
  ip_version              = "IPv4"
  location                = var.location
  sku                     = "Standard"
}

resource "azurerm_lb" "linux-vmss-lb" {
  location            = var.location
  name                = "linux-vmss-lb"
  resource_group_name = azurerm_resource_group.linux-vmss.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                          = "PublicIPAddress"
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
    public_ip_address_id          = azurerm_public_ip.linux-vmss-public-ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "linux-vmss-bpepool" {
  resource_group_name = azurerm_resource_group.linux-vmss.name
  loadbalancer_id     = azurerm_lb.linux-vmss-lb.id
  name                = "bepool"
}

resource "azurerm_lb_probe" "linux-vmss-lb-probe" {
  resource_group_name = azurerm_resource_group.linux-vmss.name
  loadbalancer_id     = azurerm_lb.linux-vmss-lb.id
  name                = "http-probe"
  port                = var.application_port
}

resource "azurerm_lb_rule" "linux-vmss-lb-rule" {
  resource_group_name            = azurerm_resource_group.linux-vmss.name
  loadbalancer_id                = azurerm_lb.linux-vmss-lb.id
  name                           = "http"
  protocol                       = "Tcp"
  frontend_port                  = var.application_port
  backend_port                   = var.application_port
  backend_address_pool_id        = azurerm_lb_backend_address_pool.linux-vmss-bpepool.id
  frontend_ip_configuration_name = azurerm_lb.linux-vmss-lb.frontend_ip_configuration.0.name
  probe_id                       = azurerm_lb_probe.linux-vmss-lb-probe.id
}

resource "azurerm_lb_nat_pool" "natpool" {
  resource_group_name            = azurerm_resource_group.linux-vmss.name
  loadbalancer_id                = azurerm_lb.linux-vmss-lb.id
  name                           = "natpool"
  protocol                       = "Tcp"
  frontend_port_start            = 50000
  frontend_port_end              = 50099
  backend_port                   = 22
  frontend_ip_configuration_name = azurerm_lb.linux-vmss-lb.frontend_ip_configuration.0.name
}