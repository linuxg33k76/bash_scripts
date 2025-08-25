#!/bin/bash
# move_home_data.sh

# Set your old and new usernames here
OLDUSER="oldname"
NEWUSER="newname"

OLDHOME="/Users/$OLDUSER"
NEWHOME="/Users/$NEWUSER"

echo "Moving files from $OLDHOME to $NEWHOME..."

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

