#!/bin/sh
# Blueprint patch-management: EXAMPLE, not a running configuration.
# Fictional names under mess.systems.
# Verify a Cosign signature before an image is treated as ready to promote.
# Official signing-with-a-key form:
#   https://docs.sigstore.dev/cosign/key_management/signing_with_self-managed_keys/
#
# The public key path is a placeholder. Do not embed private keys here.

set -eu

IMAGE="${1:-oci.sdlc.eng.svc.mess.systems/eng-sdlc/example-app@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef}"
PUBKEY="${COSIGN_PUB_FILE:-/path/to/public-key-placeholder.pub}"

cosign verify --key "${PUBKEY}" "${IMAGE}"
