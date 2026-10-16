# shellcheck shell=bash
# shellcheck disable=SC2154 # $direnv is set by the direnv stdlib
#
# use keepassxcr [ENTRY]
#
# Load a project's secrets from the local KeePass vault managed by
# `envrc-vault` (bin/envrc-vault). ENTRY defaults to "direnv/<dir name>".
# The decrypted dotenv goes from the vault CLI straight into `direnv dotenv`
# over a pipe and is never written to disk.
#
#   # .envrc
#   use keepassxcr
#
# Store or update a project's secrets with:  envrc-vault push .env.local
#
# Missing tools or a missing vault log a warning and skip the secrets instead
# of failing, so a repo's committed .envrc still works on machines without
# keepassxcr. Set ENVRC_VAULT_SKIP=1 to skip decryption (e.g. in CI).
use_keepassxcr() {
  local db=${ENVRC_VAULT_DB:-$HOME/.local/share/envrc-vault/envrc.kdbx}
  local vault dotenv

  if [[ ${ENVRC_VAULT_SKIP:-} == 1 ]]; then
    log_status "keepassxcr: ENVRC_VAULT_SKIP=1, not loading secrets"
    return 0
  fi

  vault=$(command -v envrc-vault || echo "$HOME/bin/envrc-vault")
  if [[ ! -x $vault ]]; then
    log_error "keepassxcr: envrc-vault not found, not loading secrets"
    return 0
  fi
  if ! has keepassxcr && ! has keepassxc-cli && [[ -z ${ENVRC_VAULT_BIN:-} ]]; then
    log_error "keepassxcr: neither keepassxcr nor keepassxc-cli is installed, not loading secrets"
    return 0
  fi
  if [[ ! -f $db ]]; then
    log_error "keepassxcr: no vault at $db (run: envrc-vault init), not loading secrets"
    return 0
  fi

  # Re-run when the vault changes, e.g. after `envrc-vault push`.
  watch_file "$db"

  if ! dotenv=$("$vault" export "$@"); then
    log_error "keepassxcr: could not read ${1:-direnv/${PWD##*/}} from $db, not loading secrets"
    return 0
  fi
  eval "$(printf '%s\n' "$dotenv" | "$direnv" dotenv bash /dev/stdin)"
}
