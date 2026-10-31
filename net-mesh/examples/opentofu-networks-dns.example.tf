# Blueprint net-mesh: EXAMPLE, not a running configuration.
# A site network for devices without an agent, the internal resolver as a
# network resource, the nameserver group for svc.mess.systems and account
# settings. Names follow the mesh sections of the naming standard
# (04-identity-conventions.md, "Mesh networks, resources and keys" and "Mesh
# DNS"). Addresses are from the RFC 5737 documentation ranges and live only in
# the address field, never in a name.

resource "netbird_network" "site_dc1" {
  name        = "site-dc1"
  description = "Management LAN of site dc1: devices that cannot run an agent"
}

# Two routing peers in one group: failover, not load balancing.
resource "netbird_network_router" "site_dc1" {
  network_id  = netbird_network.site_dc1.id
  peer_groups = [netbird_group.router_dc1.id]
  metric      = 9999
  masquerade  = true
  enabled     = true
}

# Narrow resources: single addresses, never the whole LAN. A resource is
# unreachable until a policy names it or its group.
# The resolver is a service that may run on several hosts: <site>-<application>.
resource "netbird_network_resource" "dc1_shared_net_dns" {
  network_id  = netbird_network.site_dc1.id
  name        = "dc1-shared-net-dns"
  description = "Internal resolver dns.net.shared at site dc1, 192.0.2.53"
  address     = "192.0.2.53/32"
  groups      = [netbird_group.svc_shared_net_dns.id]
  enabled     = true
}

# The admin interface of the site router is one host: the resource takes the
# host name.
resource "netbird_network_resource" "dc1_shared_net_mikrotik_prd_01" {
  network_id  = netbird_network.site_dc1.id
  name        = "dc1-shared-net-mikrotik-prd-01"
  description = "Admin interface of the site router, 192.0.2.1"
  address     = "192.0.2.1/32"
  groups      = [netbird_group.zone_shared.id]
  enabled     = true
}

# Everyone who can sign in may query the resolver, and nothing else on the LAN.
# One policy per pair of groups. NetBird allows one protocol per rule, so each
# pair has a UDP policy for queries and a TCP policy for large answers.
resource "netbird_policy" "people_to_dns_udp" {
  for_each = local.people_groups
  name     = "${each.key} -> svc-shared-net-dns (udp)"
  enabled  = true
  rule {
    name          = "domain"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "udp"
    ports         = ["53"]
    sources       = [each.value]
    destinations  = [netbird_group.svc_shared_net_dns.id]
  }
}

resource "netbird_policy" "people_to_dns_tcp" {
  for_each = local.people_groups
  name     = "${each.key} -> svc-shared-net-dns (tcp)"
  enabled  = true
  rule {
    name          = "domain"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["53"]
    sources       = [each.value]
    destinations  = [netbird_group.svc_shared_net_dns.id]
  }
}

# Split DNS: only names under svc.mess.systems go to the internal resolver.
# Peers without systemd-resolved or a match-domain capable OS fall back to
# the NetBird forwarder.
resource "netbird_nameserver_group" "svc_mess_systems_dc1" {
  name        = "svc-mess-systems-dc1"
  description = "Internal service zone svc.mess.systems, served by dns.net.shared at dc1"
  nameservers = [
    {
      ip      = "192.0.2.53"
      ns_type = "udp"
      port    = 53
    }
  ]
  domains                = ["svc.mess.systems"]
  search_domains_enabled = false
  enabled                = true
  groups = concat(values(local.people_groups), [
    netbird_group.zone_shared.id,
    netbird_group.zone_corp.id,
    netbird_group.zone_eng.id,
  ])
}

# Account settings: IdP groups drive access; peer login lasts 24 hours.
# jwt_allow_groups can lock everyone out: apply it only after the groups claim
# has been checked on a test account.
resource "netbird_account_settings" "mesh_prd" {
  jwt_groups_enabled                 = true
  jwt_groups_claim_name              = "groups"
  groups_propagation_enabled         = true
  peer_login_expiration_enabled      = true
  peer_login_expiration              = 86400
  peer_inactivity_expiration_enabled = false
  regular_users_view_blocked         = true
  peer_expose_enabled                = false
}
