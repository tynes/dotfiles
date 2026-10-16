# shellcheck shell=bash
# shellcheck disable=SC2154 # $direnv is set by the direnv stdlib
#
# use sops [FILE]
#
# Load secrets from a sops-encrypted dotenv file committed in the repo
# (default: secrets.enc.env). Decryption happens in memory; the plaintext is
# piped straight into `direnv dotenv`.
#
#   # .envrc
#   use sops                  # or: use sops config/dev.enc.env
#
# Create or edit the file with:  sops secrets.enc.env
# (recipients come from the repo's .sops.yaml; with age-plugin-yubikey the
# private key stays on a YubiKey.)
#
# A missing sops binary or file logs a warning and skips the secrets.
use_sops() {
  local file=${1:-secrets.enc.env}
  local plain

  if [[ ${ENVRC_VAULT_SKIP:-} == 1 ]]; then
    log_status "sops: ENVRC_VAULT_SKIP=1, not loading secrets"
    return 0
  fi
  if ! has sops; then
    log_error "sops: not installed, not loading $file"
    return 0
  fi
  if [[ ! -f $file ]]; then
    log_error "sops: $file not found"
    return 0
  fi

  watch_file "$file"

  if ! plain=$(sops --decrypt --output-type dotenv "$file"); then
    log_error "sops: could not decrypt $file, not loading secrets"
    return 0
  fi
  eval "$(printf '%s\n' "$plain" | "$direnv" dotenv bash /dev/stdin)"
}
