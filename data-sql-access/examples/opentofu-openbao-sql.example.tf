# Blueprint data-sql-access: EXAMPLE, not a running configuration.
# Access of people to PostgreSQL through OpenBao: login role, policy,
# database secrets engine, PKI issuing role. Fictional names under
# mess.systems. Argument names follow the hashicorp/vault provider docs; the
# provider talks to OpenBao through the Vault-compatible API.
#
# Credentials never sit in this file:
#   VAULT_ADDR   https://secrets.iam.shared.svc.mess.systems
#   VAULT_TOKEN  short-lived token of the -adm account or of the pipeline,
#                set just before the run
#   TF_VAR_openbao_pg_password  initial password of svc_shared_iam_openbao;
#                replaced by rotate-root after issuance has been verified

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

provider "vault" {}

# --- Sign-in: Keycloak group -> OpenBao login role -> policy ---------------

# The mount auth/jwt-keycloak exists already (identity blueprint). Read only.
locals {
  jwt_mount = "jwt-keycloak"
  # Login role, policy and Keycloak group share one ID.
  sql_user_group = "app-sql-user"
}

resource "vault_policy" "app_sql_user" {
  name   = local.sql_user_group
  policy = <<-HCL
    # Read credentials of the read role only. No config, roles, rotate-root,
    # or sys/leases.
    path "database-shared/creds/eng_sdlc_git_ro" {
      capabilities = ["read"]
    }
  HCL
}

resource "vault_jwt_auth_backend_role" "app_sql_user" {
  backend         = local.jwt_mount
  role_name       = local.sql_user_group
  role_type       = "oidc"
  user_claim      = "preferred_username"
  groups_claim    = "groups"
  bound_audiences = ["shared-iam-openbao"]
  bound_claims = {
    groups = local.sql_user_group
  }
  allowed_redirect_uris = [
    "https://secrets.iam.shared.svc.mess.systems/ui/vault/auth/jwt-keycloak/oidc/callback",
    "http://localhost:8250/oidc/callback",
  ]
  token_policies = [vault_policy.app_sql_user.name]
  token_ttl      = 28800 # 8h
  token_max_ttl  = 28800
}

# --- Database secrets engine ---------------------------------------------

variable "openbao_pg_password" {
  description = "Initial password of svc_shared_iam_openbao. Rotated by rotate-root."
  type        = string
  sensitive   = true
}

resource "vault_mount" "database_shared" {
  path = "database-shared"
  type = "database"
  # Keep the temporary user name readable in the audit log.
  audit_non_hmac_response_keys = ["username"]
}

resource "vault_database_secret_backend_connection" "shared_data_postgres" {
  backend       = vault_mount.database_shared.path
  name          = "shared-data-postgres"
  allowed_roles = ["eng_sdlc_git_ro"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@sql.data.shared.svc.mess.systems:5432/eng_sdlc_git_prd?sslmode=verify-full"
    username       = "svc_shared_iam_openbao"
    password       = var.openbao_pg_password
    # v_<auth>_<identity>_<role>_<ts>_<rand6>, naming standard 04 section 11.1.
    # timestamp renders in the local zone of the OpenBao process: run it with
    # TZ=UTC (openbao-tz-utc.example.conf).
    username_template = "{{ printf \"v_%s_%s_%s_%s\" (.DisplayName | replace \"jwt-keycloak-\" \"oidc-\" | replace \"-\" \"_\" | truncate 21) (.RoleName) (timestamp \"20060102t150405z\") (random 6 | lowercase) }}"
  }
}

resource "vault_database_secret_backend_role" "eng_sdlc_git_ro" {
  backend     = vault_mount.database_shared.path
  name        = "eng_sdlc_git_ro"
  db_name     = vault_database_secret_backend_connection.shared_data_postgres.name
  default_ttl = 28800 # 8h
  max_ttl     = 86400 # 24h
  creation_statements = [
    "CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';",
    "GRANT eng_sdlc_git_ro TO \"{{name}}\";",
  ]
  revocation_statements = [
    "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE usename = '{{name}}';",
    "DROP ROLE IF EXISTS \"{{name}}\";",
  ]
}

# Write is off by default: no role eng_sdlc_git_rw here. Enabling it adds the
# Keycloak group app-sql-editor, a login role and policy of the same ID with
# read on database-shared/creds/eng_sdlc_git_rw, and this role.

# --- PKI: server certificate of sql.data.shared ----------------------------

resource "vault_pki_secret_backend_role" "data_shared" {
  backend                     = "pki-int"
  name                        = "data-shared"
  issuer_ref                  = "mess-systems-int-2026"
  allowed_domains             = ["data.shared.svc.mess.systems"]
  allow_subdomains            = true
  allow_bare_domains          = false
  allow_glob_domains          = false
  allow_wildcard_certificates = false
  allow_ip_sans               = false
  allow_localhost             = false
  server_flag                 = true
  client_flag                 = false
  key_type                    = "ec"
  key_bits                    = 256
  ttl                         = "720h"
  max_ttl                     = "2160h"
}
