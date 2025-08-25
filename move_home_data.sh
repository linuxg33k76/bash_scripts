#!/bin/bash
# move_home_data.sh

# Check to see if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (e.g., sudo $0)"
  exit 1
fi  

# Ask for old and new usernames
echo 
read -p "Enter old username: " OLDUSER
echo
read -p "Enter new username: " NEWUSER

OLDHOME="/Users/$OLDUSER"
NEWHOME="/Users/$NEWUSER"

echo
echo "Moving files from $OLDHOME to $NEWHOME..."

# Press Enter to continue
echo
read -p "Press Enter to continue... (or Ctrl+C to cancel)"

# Move regular files and folders
sudo mv "$OLDHOME"/* "$NEWHOME"/

# Move hidden dotfiles (excluding . and ..)
for file in "$OLDHOME"/.[!.]* "$OLDHOME"/..?*; do
  # Check if file exists before moving
  if [ -e "$file" ]; then
    sudo mv "$file" "$NEWHOME"/
  fi
done

# Fix ownership and permissions
echo "Fixing ownership for $NEWHOME..."
sudo chown -R "$NEWUSER":staff "$NEWHOME"

echo "Done! All files moved and permissions fixed."

