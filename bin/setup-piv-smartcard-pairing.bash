#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

user="$(whoami)"

# check that yubikey is present
if ! pivy-tool list &>/dev/null; then
  gum log --level error "no PIV token found, insert your YubiKey"
  exit 1
fi

# check if 9d needs a new key or just a new cert
has_9d_key=false
if pivy-tool pubkey 9d &>/dev/null; then
  has_9d_key=true
  gum log --level info "existing 9d key found, will regenerate certificate only"
else
  gum log --level info "no 9d key found, will generate key and certificate"
fi

if [[ "$has_9d_key" == "true" ]]; then
  # use ykman to generate a self-signed cert from the existing on-card key
  # ykman signs the cert using the card's private key (truly self-signed)
  gum log --level info "extracting 9d public key"
  pivy-tool pubkey 9d | ssh-keygen -f /dev/stdin -e -m PKCS8 > "$tmp/9d-pub.pem"

  gum log --level info "generating self-signed 9d certificate via ykman (PIN required)"
  ykman piv certificates generate \
    --subject "CN=${user}" \
    9d "$tmp/9d-pub.pem"
else
  # generate both key and cert in one shot
  gum log --level info "generating 9d key pair and certificate via ykman (PIN required)"
  ykman piv keys generate -a ECCP256 9d "$tmp/9d-pub.pem"
  ykman piv certificates generate \
    --subject "CN=${user}" \
    9d "$tmp/9d-pub.pem"
fi

# verify
gum log --level info "verifying 9d certificate on card"
pivy-tool cert 9d | openssl x509 -noout -text | grep -E "Issuer|Subject|Key Usage" || true

# prompt user to remove and reinsert yubikey
gum log --level warn "remove and reinsert your YubiKey now to refresh CryptoTokenKit"
gum confirm "have you reinserted the YubiKey?" || exit 1

# wait for CryptoTokenKit to detect the card
gum log --level info "waiting for CryptoTokenKit to detect the card"
for i in $(seq 1 10); do
  if sc_auth identities 2>/dev/null | grep -qE '[0-9A-F]{40}'; then
    break
  fi
  sleep 1
done

# unpair existing
gum log --level info "unpairing existing smartcard association"
sudo sc_auth unpair -u "$user" 2>/dev/null || true

# detect and pair
gum log --level info "detecting smartcard identity"
hash="$(sc_auth identities | grep -oE '[0-9A-F]{40}' | head -1)"
if [[ -z "$hash" ]]; then
  gum log --level error "no smartcard identity found"
  exit 1
fi

gum log --level info "pairing hash ${hash} to user ${user}"
sudo sc_auth pair -h "$hash" -u "$user"

gum log --level info "verifying pairing"
sc_auth list -u "$user"
