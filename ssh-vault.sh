#!/usr/bin/env bash

set -eo pipefail

SSH_DIR="$HOME/.ssh"
GNUPG_DIR="${GNUPGHOME:-$HOME/.gnupg}"
DEFAULT_BACKUP_NAME="$HOME/ssh_keys_backup_$(date +%Y-%m-%d_%Hh%Mm%Ss).tar.gz.gpg"

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
    trap 'rm -rf "$TEMP_STAGING"' EXIT

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
        gpg --armor --export > "$TEMP_STAGING/gpg_exports/public_keys.asc" 2>/dev/null || true

        echo "Exporting GPG secret keys..."
        gpg --armor --export-secret-keys > "$TEMP_STAGING/gpg_exports/secret_keys.asc" 2>/dev/null || true

        echo "Exporting GPG ownertrust..."
        gpg --export-ownertrust > "$TEMP_STAGING/gpg_exports/ownertrust.txt" 2>/dev/null || true
    fi

    echo "Encrypting backup with AES-256..."
    tar -czf - -C "$TEMP_STAGING" . | gpg --symmetric --cipher-algo AES256 -o "$TARGET_PATH"

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
    trap 'rm -rf "$TEMP_RESTORE"' EXIT

    echo "Decrypting archive..."
    gpg --decrypt "$SOURCE_PATH" | tar -xzf - -C "$TEMP_RESTORE"

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
                gpg --import "$TEMP_RESTORE/gpg_exports/public_keys.asc"
            fi

            if [ -s "$TEMP_RESTORE/gpg_exports/secret_keys.asc" ]; then
                echo "Importing secret keys..."
                gpg --import "$TEMP_RESTORE/gpg_exports/secret_keys.asc"
            fi

            if [ -s "$TEMP_RESTORE/gpg_exports/ownertrust.txt" ]; then
                echo "Importing ownertrust..."
                gpg --import-ownertrust "$TEMP_RESTORE/gpg_exports/ownertrust.txt"
            fi

            echo "GPG keys and trustdb successfully imported."
        fi
    fi

    echo "Restore operations complete."
}

# --- Main Menu ---

echo "=== SSH & GPG Key Vault ==="
echo "1) Backup keys"
echo "2) Restore keys"
echo "3) Exit"
read -rp "Select an option [1-3]: " CHOICE

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
