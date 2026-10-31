# Blueprint net-mesh: EXAMPLE, not a running configuration.
# Groups, posture check and access policies of the corporate mesh account.
# Group, policy, rule and posture check names follow the mesh sections of the
# naming standard (04-identity-conventions.md, "Mesh VPN groups" and "Mesh
# policies, rules and posture checks"). Resource labels are snake_case.

# People groups come from Keycloak through JWT group sync. NetBird creates them
# on first login, so OpenTofu only reads them.
data "netbird_group" "tier_t1_platform_ops" {
  name = "tier-t1-platform-ops"
}

data "netbird_group" "role_developers" {
  name = "role-developers"
}

data "netbird_group" "role_platform_engineers" {
  name = "role-platform-engineers"
}

data "netbird_group" "app_dashboards_user" {
  name = "app-dashboards-user"
}

# Group name => ID. The names are reused in policy names, which name one pair
# of groups each.
locals {
  people_groups = {
    (data.netbird_group.tier_t1_platform_ops.name)    = data.netbird_group.tier_t1_platform_ops.id
    (data.netbird_group.role_developers.name)         = data.netbird_group.role_developers.id
    (data.netbird_group.role_platform_engineers.name) = data.netbird_group.role_platform_engineers.id
    (data.netbird_group.app_dashboards_user.name)     = data.netbird_group.app_dashboards_user.id
  }
}

# Resource groups, managed here. Peers join them through setup key
# auto-groups; network resources join them through their own groups.
resource "netbird_group" "zone_shared" {
  name = "zone-shared"
}

resource "netbird_group" "zone_corp" {
  name = "zone-corp"
}

resource "netbird_group" "zone_eng" {
  name = "zone-eng"
}

resource "netbird_group" "site_dc1" {
  name = "site-dc1"
}

resource "netbird_group" "egress_corp" {
  name = "egress-corp"
}

# Service peer groups: svc-<application>.
resource "netbird_group" "svc_shared_iam_openbao" {
  name = "svc-shared-iam-openbao"
}

resource "netbird_group" "svc_shared_obs_grafana" {
  name = "svc-shared-obs-grafana"
}

resource "netbird_group" "svc_shared_net_dns" {
  name = "svc-shared-net-dns"
}

# Routing peers of a site: router-<site-code>.
resource "netbird_group" "router_dc1" {
  name = "router-dc1"
}

variable "min_client_version" {
  description = "Lowest NetBird client version allowed on admin paths."
  type        = string
}

resource "netbird_posture_check" "client_current" {
  name        = "posture-client-current"
  description = "Client not older than the version set by the platform team"
  netbird_version_check {
    min_version = var.min_client_version
  }
}

# The account's Default policy (All to All) is imported and switched off. It
# keeps its product name; no other policy uses the built-in All group.
variable "default_policy_id" {
  description = "ID of the Default policy created with the account."
  type        = string
}

import {
  to = netbird_policy.default
  id = var.default_policy_id
}

resource "netbird_policy" "default" {
  name    = "Default"
  enabled = false
  rule {
    name          = "Default"
    action        = "accept"
    bidirectional = true
    enabled       = false
    protocol      = "all"
    sources       = [data.netbird_group.tier_t1_platform_ops.id]
    destinations  = [data.netbird_group.tier_t1_platform_ops.id]
  }
}

# Admin path: platform operators reach control surfaces of the shared plane.
# Only -adm accounts are members of tier-t1-platform-ops, and they sign in
# only on paw devices.
resource "netbird_policy" "tier_t1_platform_ops_to_zone_shared" {
  name                  = "tier-t1-platform-ops -> zone-shared"
  enabled               = true
  source_posture_checks = [netbird_posture_check.client_current.id]
  rule {
    name          = "ssh-https"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["22", "443"]
    sources       = [data.netbird_group.tier_t1_platform_ops.id]
    destinations  = [netbird_group.zone_shared.id]
  }
}

# User path: people reach one service, not a whole plane. The source is the
# app group that already authorizes them inside the application.
resource "netbird_policy" "app_dashboards_user_to_grafana" {
  name    = "app-dashboards-user -> svc-shared-obs-grafana"
  enabled = true
  rule {
    name          = "https"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["443"]
    sources       = [data.netbird_group.app_dashboards_user.id]
    destinations  = [netbird_group.svc_shared_obs_grafana.id]
  }
}

# Service path: servers of the corp plane read secrets from OpenBao.
resource "netbird_policy" "zone_corp_to_openbao" {
  name    = "zone-corp -> svc-shared-iam-openbao"
  enabled = true
  rule {
    name          = "tcp-8200"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["8200"]
    sources       = [netbird_group.zone_corp.id]
    destinations  = [netbird_group.svc_shared_iam_openbao.id]
  }
}

# Monitoring has no mesh policy. Site collectors scrape node exporters and the
# coordinator over the site LAN, so telemetry keeps working when the mesh is
# down. The host firewall allows them; see nftables-hostfw.example.nft.
