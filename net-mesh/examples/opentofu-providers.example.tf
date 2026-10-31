# Blueprint net-mesh: EXAMPLE, not a running configuration.
# Provider and state settings for the stack that manages the mesh account.
# Fictional names under mess.systems. Argument names follow the
# netbirdio/netbird provider docs and the OpenTofu state encryption docs.
#
# Credentials never sit in this file:
#   NB_PAT             personal access token of the NetBird service user
#                      svc-shared-net-iac that runs OpenTofu, read from OpenBao
#                      just before the run
#   NB_MANAGEMENT_URL  may replace management_url below
#   BAO_ADDR, BAO_TOKEN  OpenBao address and a short-lived token for the
#                      transit key that encrypts state

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    netbird = {
      source  = "netbirdio/netbird"
      version = "~> 0.0.11"
    }
  }

  # State and plan files hold setup keys and policy IDs: encrypt them with a
  # transit key in OpenBao. The key takes the application name.
  encryption {
    key_provider "openbao" "mesh" {
      key_name = "shared-net-netbird"
    }
    method "aes_gcm" "mesh" {
      keys = key_provider.openbao.mesh
    }
    state {
      method   = method.aes_gcm.mesh
      enforced = true
    }
    plan {
      method   = method.aes_gcm.mesh
      enforced = true
    }
  }
}

provider "netbird" {
  # Canonical internal name of the corporate coordinator. The public vanity
  # name netbird.mess.systems points to the same installation.
  management_url = "https://mesh.net.shared.svc.mess.systems"
}
