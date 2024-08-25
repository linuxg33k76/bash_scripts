#!/bin/env bash

# Backup Check - checks for backup server and alerts user
# Created by Ben Calvert on 16 Sept 2022

# Local DNS entry of NAS
BACKUPSERVER="amber-da-vault"

# Mask all output of the ping command to hide extra terminal content
ping -c 1 $BACKUPSERVER 1> /dev/null 2> /dev/null

# Test for successful command execution
if [ $? = "0" ]; then
  echo "Backup Server is ONLINE"
else
  echo "Backup Server is OFFLINE"
fi

