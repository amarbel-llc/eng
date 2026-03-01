#!/usr/bin/env bash
# SoftHSM2 PKCS#11 helpers for integration testing

# Default test values
SOFTHSM2_TEST_PIN="${SOFTHSM2_TEST_PIN:-1234}"
SOFTHSM2_TEST_SO_PIN="${SOFTHSM2_TEST_SO_PIN:-12345678}"
SOFTHSM2_TEST_LABEL="${SOFTHSM2_TEST_LABEL:-test-token}"

softhsm2_init_token() {
  local label="${1:-$SOFTHSM2_TEST_LABEL}"
  local pin="${2:-$SOFTHSM2_TEST_PIN}"
  local so_pin="${3:-$SOFTHSM2_TEST_SO_PIN}"

  softhsm2-util --init-token --free --label "$label" \
    --pin "$pin" --so-pin "$so_pin"
}

softhsm2_cleanup() {
  if [[ -n "${SOFTHSM2_TOKEN_DIR:-}" ]]; then
    rm -rf "${SOFTHSM2_TOKEN_DIR:?}"/*
  fi
}

softhsm2_generate_p256_key() {
  local label="${1:-test-key}"
  local id="${2:-01}"
  local pin="${3:-$SOFTHSM2_TEST_PIN}"
  local token_label="${4:-$SOFTHSM2_TEST_LABEL}"

  pkcs11-tool --module "$(softhsm2_module_path)" \
    --token-label "$token_label" \
    --login --pin "$pin" \
    --keypairgen --key-type EC:prime256v1 \
    --label "$label" --id "$id"
}

softhsm2_sign_verify_roundtrip() {
  local data_file="$1"
  local key_label="${2:-test-key}"
  local pin="${3:-$SOFTHSM2_TEST_PIN}"
  local token_label="${4:-$SOFTHSM2_TEST_LABEL}"
  local module
  module="$(softhsm2_module_path)"

  local sig_file
  sig_file="$(mktemp)"

  # Sign
  pkcs11-tool --module "$module" \
    --token-label "$token_label" \
    --login --pin "$pin" \
    --sign --mechanism ECDSA \
    --label "$key_label" \
    --input-file "$data_file" \
    --output-file "$sig_file"

  # Verify
  pkcs11-tool --module "$module" \
    --token-label "$token_label" \
    --login --pin "$pin" \
    --verify --mechanism ECDSA \
    --label "$key_label" \
    --input-file "$data_file" \
    --signature-file "$sig_file"

  local rc=$?
  rm -f "$sig_file"
  return $rc
}

softhsm2_module_path() {
  # Try common paths
  local paths=(
    "/run/current-system/sw/lib/softhsm/libsofthsm2.so"
    "$HOME/.nix-profile/lib/softhsm/libsofthsm2.so"
    "/usr/lib/softhsm/libsofthsm2.so"
    "/usr/lib/x86_64-linux-gnu/softhsm/libsofthsm2.so"
  )

  # Check nix store paths from environment
  if command -v softhsm2-util &>/dev/null; then
    local bin_path
    bin_path="$(command -v softhsm2-util)"
    local store_path="${bin_path%/bin/softhsm2-util}"
    paths=("$store_path/lib/softhsm/libsofthsm2.so" "${paths[@]}")
  fi

  for p in "${paths[@]}"; do
    if [[ -f "$p" ]]; then
      echo "$p"
      return 0
    fi
  done

  echo "ERROR: Could not find libsofthsm2.so" >&2
  return 1
}
