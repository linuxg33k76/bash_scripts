#!/usr/bin/env bash

# Authored by: Ben Calvert
# Date: 2018-03-22 16:31:02

# NOTES:
# This script converts any .m4a file in specific directory to .mp3


# Constant Declarations
LOG="/var/log/m4a2mp3.log"
DIR=$1

# Move to /var/spool/asterisk/monitor
echo
echo "Changing Directory to $DIR"
echo
cd $DIR

{
# Get list of .wav file count
echo
echo "Total files for conversion: $(ls -lahR *.m4a | wc -l)"
echo 

# Issue conversion string
echo
echo "Converting .m4a to .mp3 in $DIR..."
echo

for i in *.m4a; do
    # Convert .m4a to .mp3 using lame

    lame -b 320 -h "${i}" "${i%.m4a}.mp3"
    #ffmpeg -i "$i" -codec:v copy -codec:a libmp3lame -q:a 2 "${i%.m4a}.mp3"

    # Update the Modified and Access times to match old .m4a file
    touch "${i%.m4a}.mp3" -r "${i}"
done

# Change new file permissions

echo
echo "Changing permissions on .mp3 files in $DIR..."
echo

chown asterisk:www-data *.mp3

# Remove Old .m4a files IF a .mp3 exists

echo
echo "Removing Converted .m4a files in $DIR..."
echo

for i in *.m4a; do
    # Check if .mp3 file exists
    if [[ -f "${i%.m4a}.mp3" ]]; then
    
        # Display stats on both files (.wav and .mp3)
        stat "${i}"
        stat "${i%.m4a}.mp3"
    
        # Remove .wav file - no longer needed
        rm "${i}"
    fi
done

echo
echo "Complete!"
echo

# Get list of .mp3 file count
echo
echo "Total files after conversion: $(ls -lah *.mp3 | wc -l)"
echo 

} > $LOG

