#! /bin/bash

# Define Bash Script Variables

CONFIG_FILE="/home/$(whoami)/.bashrc"
ALIAS_FILE="/home/$(whoami)/.bash_aliases"
VIMRC="/home/$(whoami)/.vimrc"
#LOG="/home/$(whoami)/Pop_OS_script_$(date +%d%b%Y-%H:%M).log" 

# Install missing packages via apt

sudo apt-get clean && sudo apt-get update -y

sudo apt-get install -y snapd code vim screenfetch gnome-tweaks libavcodec-extra nixnote2 steam

sudo apt-get install -y gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libavcodec-extra gstreamer1.0-libav

# Install Snap Packages

sudo snap install p3x-onenote

sudo snap install skype --classic

sudo snap install spotify

sudo snap install mailspring

#sudo snap install simplenote

# Check for Macbook Air wireless hardware and install extra package if needed

lshw -c network | grep BCM4360

if [ $? -eq 0 ]; then
	sudo apt-get install bcmwl-kernel-source
fi

# Add screenfetch to .bashrc if it does NOT already exist

cat $CONFIG_FILE | grep screenfetch

if [ $? -ne 0 ]; then 

	echo "" >> $CONFIG_FILE
	echo "# Entry for screenfetch on startup of terminal" >> $CONFIG_FILE
	echo "screenfetch" >> $CONFIG_FILE
fi

# Create Bash Aliases File if it does NOT already exist

test -f $ALIAS_FILE

if [ $? -ne 0 ]; then

	echo "alias update='sudo apt-get clean && sudo apt-get update && sudo apt-get upgrade'" >> $ALIAS_FILE
	echo "alias cleanup='sudo apt-get update && sudo apt autoremove'" >> $ALIAS_FILE
	echo "alias upgrade='sudo apt-get clean && sudo apt-get update && sudo apt-get dist-upgrade'" >> $ALIAS_FILE
fi

# Create .vimrc File if it does NOT already exist

test -f $VIMRC

if [ $? -ne 0 ]; then

	echo "syntax on" >> $VIMRC
	echo "set number" >> $VIMRC
	echo "colorscheme ron" >> $VIMRC
fi

# Adjust Ubuntu default editor

sudo update-alternatives --config editor

