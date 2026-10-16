# shellcheck shell=bash
# shellcheck disable=SC2154 # $direnv is set by the direnv stdlib
#
# vault_export VAR=ENTRY [VAR=ENTRY ...]
#
# Export secrets read from the local KeePass database managed by `envrc-vault`
# (bin/envrc-vault). Each ENTRY is an entry path in the database; its password
# field becomes the value of VAR. Values are decrypted on demand and never
# written to disk.
#
#   # .envrc
#   vault_export API_KEY=myapp/API_KEY RPC_URL=myapp/RPC_URL
#
# Store a value with:  envrc-vault set myapp/API_KEY
#
# With keepassxcr the database is unlocked once and stays unlocked for later
# loads until its agent times out; with keepassxc-cli the master password is
# asked once per load, however many secrets the .envrc reads. A missing tool,
# database or entry, or a locked database with no terminal, logs a warning and
# leaves that variable unset instead of failing, so a committed .envrc still works on
# machines without keepassxcr. Set ENVRC_VAULT_SKIP=1 to skip (e.g. in CI).
vault_export() {
  local db=${ENVRC_VAULT_DB:-$HOME/.local/share/envrc-vault/envrc.kdbx}
  local vault pair var entry value pw=

  if [[ ${ENVRC_VAULT_SKIP:-} == 1 ]]; then
    log_status "vault: ENVRC_VAULT_SKIP=1, not loading secrets"
    return 0
  fi

  vault=$(command -v envrc-vault || echo "$HOME/bin/envrc-vault")
  if [[ ! -x $vault ]]; then
    log_error "vault: envrc-vault not found, not loading secrets"
    return 0
  fi
  if ! has keepassxcr && ! has keepassxc-cli && [[ -z ${ENVRC_VAULT_BIN:-} ]]; then
    log_error "vault: neither keepassxcr nor keepassxc-cli is installed, not loading secrets"
    return 0
  fi
  if [[ ! -f $db ]]; then
    log_error "vault: no database at $db (run: envrc-vault init), not loading secrets"
    return 0
  fi

  # Re-run when the database changes, e.g. after `envrc-vault set`.
  watch_file "$db"

  # With keepassxcr, unlock its agent: the password is asked (or taken from
  # ENVRC_VAULT_PASSWORD_CMD) only while locked, and later loads reuse the
  # agent until it times out. Exit 2 means no agent (keepassxc-cli).
  local rc=0
  "$vault" unlock >&2 || rc=$?
  case $rc in
    0) ;;
    2)
      # Ask for the master password here, once, and hand it to each lookup on
      # stdin. A password command or a password-less database is left to
      # envrc-vault itself.
      if [[ -z ${ENVRC_VAULT_PASSWORD_CMD:-} && ${ENVRC_VAULT_NO_PASSWORD:-} != 1 ]]; then
        if ! { : >/dev/tty; } 2>/dev/null; then
          log_error "vault: no terminal to ask for the password; set ENVRC_VAULT_PASSWORD_CMD"
          return 0
        fi
        printf 'direnv: password for %s: ' "$db" >/dev/tty
        IFS= read -rs pw </dev/tty
        printf '\n' >/dev/tty
      fi
      ;;
    *)
      log_error "vault: could not unlock $db; run 'envrc-vault unlock' then 'direnv reload'"
      return 0
      ;;
  esac

  for pair in "$@"; do
    var=${pair%%=*}
    entry=${pair#*=}
    if [[ $var == "$pair" || -z $var || -z $entry ]]; then
      log_error "vault: expected VAR=ENTRY, got '$pair'"
      continue
    fi
    if [[ -n $pw ]]; then
      value=$(printf '%s\n' "$pw" | ENVRC_VAULT_PASSWORD_CMD="cat" "$vault" get "$entry")
    else
      value=$("$vault" get "$entry")
    fi || {
      log_error "vault: could not read $entry, leaving $var unset"
      continue
    }
    export "$var=$value"
  done
}
