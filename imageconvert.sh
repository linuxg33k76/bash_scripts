#!/usr/bin/env bash

# Convert all images in a directory from png to jpg
# Usage: ./imageconvert.sh <directory>

# Check if directory is provided
if [ -z "$1" ]; then
    echo "Usage: ./imageconvert.sh <directory>"
    exit 1
fi

# Check if imagemagick is installed
if ! [ -x "$(command -v convert)" ]; then
    echo "Error: imagemagick is not installed."
    echo "Please install imagemagick! Exiting..."
    exit 1
fi

# Check if directory exists
if [ ! -d "$1" ]; then
    echo "Directory does not exist"
    exit 1
fi

# Convert images
for file in "$1"/*.png; do
    if [ -f "$file" ]; then
        echo "Converting $file"
        magick "$file" "${file%.png}.jpg"
    fi
done

echo "Conversion complete"
 
echo "Do you wish to delete the original files? (y/n)"

read answer

if [ "$answer" == "y" ]; then
    for file in "$1"/*.png; do
        if [ -f "$file" ]; then
            echo "Deleting $file"
            rm "$file"
        fi
    done
    echo "Deletion complete"
fi
 
exit 0

