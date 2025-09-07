#!/usr/bin/env bash

# Define Usage
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  echo 
  echo "Usage: steampicssync.sh [source_directory] [destination_directory] [results_file]"
  echo "If no arguments are provided, defaults will be used:"
  echo "  Source Directory: $HOME/Pictures/Steam/"
  echo "  Destination Directory: /mnt/remote_cifs/CyberPowerPC/Steam_Game_Photos_Backup/"
  echo "  Results File: $HOME/steampicssync_results.log"
  echo
  exit 0
fi

# Declare User defined variables: {DayOfWeek Day-Month-Year Hour:Minute:Second}
DATE=$(date +%A\ %d-%B-%Y\ %H:%M:%S)

# If 1st agument is given, use it as the source file path

if [ -n "$1" ]; then
  SOURCE_DIR="$1"
else
  SOURCE_DIR="$HOME/Pictures/Steam/"
fi

# If 2nd argument is given, use it as the destination path

if [ -n "$2" ]; then
  DEST_DIR="$2"
else
  DEST_DIR="/mnt/remote_cifs/CyberPowerPC/Steam_Game_Photos_Backup/"
fi

# if 3rd argument is given, use it as the results log file path

if [ -n "$3" ]; then
  RESULTS_FILE="$1"
else
  RESULTS_FILE="$HOME/steampicssync_results.log"
fi

# Run the rsync command and log the results (based on success of each previous command)
echo "$DATE" | tee -a $RESULTS_FILE && rsync -av $SOURCE_DIR $DEST_DIR | tee -a $RESULTS_FILE && echo "--------------------------------------------------------" | tee -a $RESULTS_FILE && echo "" | tee -a $RESULTS_FILE

# End of script
exit 0