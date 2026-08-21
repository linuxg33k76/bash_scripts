#!/usr/bin/env bash

set -eo pipefail

SSH_DIR="$HOME/.ssh"
GNUPG_DIR="${GNUPGHOME:-$HOME/.gnupg}"
DEFAULT_BACKUP_NAME="$HOME/ssh_keys_backup_$(hostname)_$(date +%Y-%m-%d_%Hh%Mm%Ss).tar.gz.gpg"

# Prefer Homebrew-installed GPG when available
GPG_BIN=""
if command -v brew >/dev/null 2>&1; then
    BREW_GNUPG_PREFIX=$(brew --prefix gnupg 2>/dev/null || true)
fi
if [ -n "${BREW_GNUPG_PREFIX:-}" ] && [ -x "${BREW_GNUPG_PREFIX}/bin/gpg" ]; then
    GPG_BIN="${BREW_GNUPG_PREFIX}/bin/gpg"
elif [ -x "/opt/homebrew/bin/gpg" ]; then
    GPG_BIN="/opt/homebrew/bin/gpg"
elif [ -x "/usr/local/bin/gpg" ]; then
    GPG_BIN="/usr/local/bin/gpg"
else
    GPG_BIN="$(command -v gpg || true)"
fi

if [ -z "${GPG_BIN}" ]; then
    echo "Error: gpg not found. Install gnupg via Homebrew (brew install gnupg) or system package." >&2
    exit 1
fi

fix_ssh_permissions() {
    echo "Enforcing strict SSH permissions..."
    chmod 700 "$SSH_DIR"

    # Restrict private keys
    find "$SSH_DIR" -maxdepth 1 -type f \( -name "id_*" ! -name "*.pub" -o -name "*_key" ! -name "*.pub" \) -exec chmod 600 {} +

    # Set read-only for public keys and standard configs
    find "$SSH_DIR" -maxdepth 1 -type f -name "*.pub" -exec chmod 644 {} +
    
    for file in "$SSH_DIR/config" "$SSH_DIR/known_hosts" "$SSH_DIR/authorized_keys"; do
        if [ -f "$file" ]; then
            chmod 644 "$file"
        fi
    done
}

perform_backup() {
    local INCLUDE_GPG="n"
    read -rp "Include GPG keys and trust database in this backup? [y/N]: " INCLUDE_GPG

    read -rp "Enter destination archive path [Default: $DEFAULT_BACKUP_NAME]: " TARGET_PATH
    TARGET_PATH="${TARGET_PATH:-$DEFAULT_BACKUP_NAME}"
    TARGET_PATH="${TARGET_PATH/#\~/$HOME}"

    TEMP_STAGING=$(mktemp -d)
    PW_FILE=""
    trap 'rm -rf "$TEMP_STAGING"; [ -n "$PW_FILE" ] && rm -f "$PW_FILE"' EXIT

    # Stage SSH keys
    if [ -d "$SSH_DIR" ] && [ -n "$(ls -A "$SSH_DIR" 2>/dev/null)" ]; then
        mkdir -p "$TEMP_STAGING/.ssh"
        cp -a "$SSH_DIR/." "$TEMP_STAGING/.ssh/"
    else
        echo "Warning: ~/.ssh is missing or empty. Skipping SSH files."
    fi

    # Stage GPG keys
    if [[ "$INCLUDE_GPG" =~ ^[Yy]$ ]]; then
        mkdir -p "$TEMP_STAGING/gpg_exports"
        echo "Exporting GPG public keys..."
        "$GPG_BIN" --armor --export > "$TEMP_STAGING/gpg_exports/public_keys.asc" 2>/dev/null || true

        echo "Exporting GPG secret keys..."
        "$GPG_BIN" --armor --export-secret-keys > "$TEMP_STAGING/gpg_exports/secret_keys.asc" 2>/dev/null || true

        echo "Exporting GPG ownertrust..."
        "$GPG_BIN" --export-ownertrust > "$TEMP_STAGING/gpg_exports/ownertrust.txt" 2>/dev/null || true
    fi

    # Prompt for symmetric passphrase (use loopback so pinentry isn't required)
    read -rsp "Enter passphrase to encrypt archive: " PW1
    echo
    read -rsp "Confirm passphrase: " PW2
    echo
    if [ "$PW1" != "$PW2" ]; then
        echo "Error: passphrases do not match." >&2
        exit 1
    fi

    PW_FILE=$(mktemp)
    chmod 600 "$PW_FILE"
    printf '%s' "$PW1" > "$PW_FILE"
    unset PW1 PW2

    echo "Encrypting backup with AES-256..."
    tar -czf - -C "$TEMP_STAGING" . | "$GPG_BIN" --symmetric --cipher-algo AES256 --pinentry-mode loopback --passphrase-file "$PW_FILE" -o "$TARGET_PATH"

    echo "Backup completed successfully: $TARGET_PATH"
}

perform_restore() {
    read -rp "Enter path to encrypted backup file: " SOURCE_PATH
    SOURCE_PATH="${SOURCE_PATH/#\~/$HOME}"

    if [ ! -f "$SOURCE_PATH" ]; then
        echo "Error: File not found: $SOURCE_PATH" >&2
        exit 1
    fi

    TEMP_RESTORE=$(mktemp -d)
    PW_FILE=""
    trap 'rm -rf "$TEMP_RESTORE"; [ -n "$PW_FILE" ] && rm -f "$PW_FILE"' EXIT

    echo "Decrypting archive..."
    # Prompt for passphrase to decrypt (use loopback to avoid pinentry issues when piping)
    read -rsp "Enter passphrase to decrypt archive: " PW
    echo
    PW_FILE=$(mktemp)
    chmod 600 "$PW_FILE"
    printf '%s' "$PW" > "$PW_FILE"
    unset PW

    "$GPG_BIN" --pinentry-mode loopback --passphrase-file "$PW_FILE" --decrypt "$SOURCE_PATH" | tar -xzf - -C "$TEMP_RESTORE"

    # Restore SSH
    if [ -d "$TEMP_RESTORE/.ssh" ]; then
        if [ -d "$SSH_DIR" ] && [ -n "$(ls -A "$SSH_DIR" 2>/dev/null)" ]; then
            read -rp "Warning: $SSH_DIR already contains files. Overwrite? [y/N]: " OVERWRITE_SSH
            if [[ "$OVERWRITE_SSH" =~ ^[Yy]$ ]]; then
                mkdir -p "$SSH_DIR"
                cp -a "$TEMP_RESTORE/.ssh/." "$SSH_DIR/"
                fix_ssh_permissions
                echo "SSH keys restored."
            else
                echo "Skipped SSH restoration."
            fi
        else
            mkdir -p "$SSH_DIR"
            cp -a "$TEMP_RESTORE/.ssh/." "$SSH_DIR/"
            fix_ssh_permissions
            echo "SSH keys restored."
        fi
    fi

    # Restore GPG
    if [ -d "$TEMP_RESTORE/gpg_exports" ]; then
        read -rp "Found GPG exports. Import GPG keys and trustdb? [y/N]: " RESTORE_GPG
        if [[ "$RESTORE_GPG" =~ ^[Yy]$ ]]; then
            mkdir -p "$GNUPG_DIR"
            chmod 700 "$GNUPG_DIR"

            if [ -s "$TEMP_RESTORE/gpg_exports/public_keys.asc" ]; then
                echo "Importing public keys..."
                "$GPG_BIN" --import "$TEMP_RESTORE/gpg_exports/public_keys.asc"
            fi

            if [ -s "$TEMP_RESTORE/gpg_exports/secret_keys.asc" ]; then
                echo "Importing secret keys..."
                "$GPG_BIN" --import "$TEMP_RESTORE/gpg_exports/secret_keys.asc"
            fi

            if [ -s "$TEMP_RESTORE/gpg_exports/ownertrust.txt" ]; then
                echo "Importing ownertrust..."
                "$GPG_BIN" --import-ownertrust "$TEMP_RESTORE/gpg_exports/ownertrust.txt"
            fi

            echo "GPG keys and trustdb successfully imported."
        fi
    fi

    echo "Restore operations complete."
}

# --- Main Menu ---
echo
echo "=== SSH & GPG Key Vault ==="
echo "1) Backup keys"
echo "2) Restore keys"
echo "3) Exit"
read -rp "Select an option [1-3]: " CHOICE
echo

case "$CHOICE" in
    1)
        perform_backup
        ;;
    2)
        perform_restore
        ;;
    3)
        echo "Exiting."
        exit 0
        ;;
    *)
        echo "Invalid selection." >&2
        exit 1
        ;;
esac
