# Blueprint data-sql-access: EXAMPLE, not a running configuration.
# Mesh policies to the database peer group. Provider settings as in
# net-mesh/examples/opentofu-providers.example.tf. Group, policy, rule and
# posture check names follow the mesh sections of the naming standard
# (04-identity-conventions.md). Resource labels are snake_case.

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    netbird = {
      source  = "netbirdio/netbird"
      version = "~> 0.0.11"
    }
  }
}

provider "netbird" {
  management_url = "https://mesh.net.shared.svc.mess.systems"
}

# People groups come from Keycloak through JWT group sync. Read only.
data "netbird_group" "app_sql_user" {
  name = "app-sql-user"
}

data "netbird_group" "tier_t1_platform_ops" {
  name = "tier-t1-platform-ops"
}

# Service peer groups, managed in the net-mesh stack. Read only here.
data "netbird_group" "svc_shared_iam_openbao" {
  name = "svc-shared-iam-openbao"
}

resource "netbird_group" "svc_shared_data_postgres" {
  name = "svc-shared-data-postgres"
}

data "netbird_posture_check" "client_current" {
  name = "posture-client-current"
}

# OpenBao creates and drops temporary users. One-way.
resource "netbird_policy" "openbao_to_postgres" {
  name    = "svc-shared-iam-openbao -> svc-shared-data-postgres"
  enabled = true
  rule {
    name          = "postgresql"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["5432"]
    sources       = [data.netbird_group.svc_shared_iam_openbao.id]
    destinations  = [netbird_group.svc_shared_data_postgres.id]
  }
}

# User path: the app group that also binds the OpenBao login role.
resource "netbird_policy" "app_sql_user_to_postgres" {
  name    = "app-sql-user -> svc-shared-data-postgres"
  enabled = true
  rule {
    name          = "postgresql"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["5432"]
    sources       = [data.netbird_group.app_sql_user.id]
    destinations  = [netbird_group.svc_shared_data_postgres.id]
  }
}

# Admin path: -adm accounts on paw devices, with a posture check.
resource "netbird_policy" "tier_t1_platform_ops_to_postgres" {
  name                  = "tier-t1-platform-ops -> svc-shared-data-postgres"
  enabled               = true
  source_posture_checks = [data.netbird_posture_check.client_current.id]
  rule {
    name          = "postgresql"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "tcp"
    ports         = ["5432"]
    sources       = [data.netbird_group.tier_t1_platform_ops.id]
    destinations  = [netbird_group.svc_shared_data_postgres.id]
  }
}
