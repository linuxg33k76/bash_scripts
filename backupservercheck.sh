#!/usr/bin/env bash

# Backup Check - checks for backup server and alerts user
# Created by Ben Calvert on 16 Sept 2022

RED='\e[31m'
GREEN='\e[32m'
NC='\e[0m' # No Color

# Local DNS entry of NAS
BACKUPSERVER="ls720dd7b.local"

# Mask all output of the ping command to hide extra terminal content
ping -c 1 $BACKUPSERVER 1> /dev/null 2> /dev/null

# Test for successful command execution
if [ $? = "0" ]; then
  echo -e "Backup Server is ${GREEN}ONLINE${NC}"
else
  echo -e "Backup Server is ${RED}OFFLINE${NC}"
  exit 1
fi

echo
echo "Testing mount point for backups..."
echo

# Test to see if backup mnt is available

if mount | grep "//${BACKUPSERVER}/vault/backups on /mnt/remote_cifs type cifs" > /dev/null; then
  echo -e "Mount point is ${GREEN} AVAILABLE! ${NC}Okay to backup/restore!"
else
  echo -e "${RED}!! WARNING !!  ${NC}Mount point is ${RED}UNAVAILABLE!!${NC}  Use 'sudo mount -a' to remount."
fi

exit 0
