### Datasource
data "yandex_client_config" "client" {}

### Locals
locals {
  folder_id = var.folder_id == null ? data.yandex_client_config.client.folder_id : var.folder_id
  vpc_id    = var.create_vpc ? yandex_vpc_network.this[0].id : var.vpc_id
}

### Network
resource "yandex_vpc_network" "this" {
  count       = var.create_vpc ? 1 : 0
  description = var.network_description
  name        = var.network_name
  labels      = var.labels
  folder_id   = local.folder_id
}

resource "yandex_vpc_subnet" "this" {
  for_each       = { for v in var.subnets : v.v4_cidr_blocks => v }
  name           = "${var.network_name}-${each.value.zone}:${each.value.v4_cidr_blocks}"
  description    = "${var.network_name} subnet for zone ${each.value.zone}"
  v4_cidr_blocks = [each.value.v4_cidr_blocks]
  zone           = each.value.zone
  network_id     = local.vpc_id
  folder_id      = local.folder_id
  dhcp_options {
    domain_name         = var.domain_name == null ? "internal." : var.domain_name
    domain_name_servers = var.domain_name_servers == null ? [cidrhost(each.value.v4_cidr_blocks, 2)] : var.domain_name_servers
    ntp_servers         = var.ntp_servers == null ? ["ntp0.NL.net", "clock.isc.org", "ntp.ix.ru"] : var.ntp_servers
  }

  labels = var.labels
}
