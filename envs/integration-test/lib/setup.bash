#!/usr/bin/env bash
# Integration test BATS helpers
# Source this from BATS test files: load '../lib/setup'

# --- Setup / Teardown ---

integration_setup() {
  export INTEGRATION_TEST_TMPDIR="${BATS_TMPDIR}/integration-${BATS_TEST_NUMBER}"
  export XDG_RUNTIME_DIR="$INTEGRATION_TEST_TMPDIR/run"
  export XDG_STATE_HOME="$INTEGRATION_TEST_TMPDIR/state"
  export XDG_CONFIG_HOME="$INTEGRATION_TEST_TMPDIR/config"
  export GIT_CONFIG_GLOBAL="$XDG_CONFIG_HOME/git/config"

  mkdir -p "$XDG_RUNTIME_DIR" "$XDG_STATE_HOME" "$XDG_CONFIG_HOME/git"

  # SoftHSM2 isolation
  export SOFTHSM2_CONF="$INTEGRATION_TEST_TMPDIR/softhsm2.conf"
  export SOFTHSM2_TOKEN_DIR="$INTEGRATION_TEST_TMPDIR/tokens"
  mkdir -p "$SOFTHSM2_TOKEN_DIR"
  echo "directories.tokendir = $SOFTHSM2_TOKEN_DIR" > "$SOFTHSM2_CONF"
}

integration_teardown() {
  ssh_agent_stop || true

  if [[ -n "${INTEGRATION_TEST_TMPDIR:-}" && -d "$INTEGRATION_TEST_TMPDIR" ]]; then
    rm -rf "$INTEGRATION_TEST_TMPDIR"
  fi
}

# --- SSH Agent ---

ssh_agent_start() {
  local socket="$XDG_RUNTIME_DIR/ssh-agent.sock"
  eval "$(ssh-agent -a "$socket")"
  export SSH_AUTH_SOCK="$socket"
}

ssh_agent_stop() {
  if [[ -n "${SSH_AGENT_PID:-}" ]]; then
    kill "$SSH_AGENT_PID" 2>/dev/null || true
    unset SSH_AGENT_PID SSH_AUTH_SOCK
  fi
}

# --- Direnv ---

direnv_test_env() {
  local dir="$1"
  local envrc_content="${2:-.}"

  mkdir -p "$dir"
  echo "$envrc_content" > "$dir/.envrc"
  direnv allow "$dir"

  # Evaluate and return the environment
  direnv exec "$dir" env
}

# --- Systemd --user ---

assert_service_running() {
  local service="$1"
  systemctl --user is-active "$service"
}

assert_service_stopped() {
  local service="$1"
  ! systemctl --user is-active "$service" 2>/dev/null
}
