#! /bin/bash

# Define Bash Script Variables

CONFIG_FILE="/home/$(whoami)/.bashrc"
ALIAS_FILE="/home/$(whoami)/.bash_aliases"
VIMRC="/home/$(whoami)/.vimrc"
DEV="/home/$(whoami)/dev"
LOG="/home/$(whoami)/Pop_OS_script_$(date +%d%b%Y-%H:%M).log" 

# Setup missing items

{

	echo
	echo "Updating and Setting up critical packages..."
	echo

	# Install system updates
	
	sudo apt-get update && sudo apt-get upgrade

	# Install system upgrades

	sudo apt-get update && sudo apt-get dist-upgrade

	# Install favorite packages

	sudo apt-get install -y snapd code vim neofetch gnome-tweaks libavcodec-extra steam deja-dup thunderbird zenmap google-chrome-stable

	# Install additional Codecs

	sudo apt-get install -y gstreamer1.0-plugins-good gstreamer1.0-plugins-bad gstreamer1.0-plugins-ugly libavcodec-extra gstreamer1.0-libav

	# Install foreign filesystem tools

	sudo apt-get install -y exfat-fuse exfat-utils sshfs

	# Python3 Packages

	sudo apt-get install -y python3-pip python3-venv

	# Remove old packages no longer necessary

	sudo apt-get update && sudo apt-get autoremove

	# Install Snap Packages

	echo
	echo "Installing snap packages..."
	echo

	#sudo snap install p3x-onenote

	sudo snap install skype --classic

	#sudo snap install spotify

	#sudo snap install mailspring

	#sudo snap install tusk

	# Install Brave Web Browser

	#sudo apt install apt-transport-https curl

	#curl -s https://brave-browser-apt-release.s3.brave.com/brave-core.asc | sudo apt-key --keyring /etc/apt/trusted.gpg.d/brave-browser-release.gpg add -

	#source /etc/os-release

	#echo "deb [arch=amd64] https://brave-browser-apt-release.s3.brave.com/ $UBUNTU_CODENAME main" | sudo tee /etc/apt/sources.list.d/brave-browser-release-${UBUNTU_CODENAME}.list

	#sudo apt update

	#sudo apt install brave-browser

	# Check for Macbook Air wireless hardware and install extra package if needed

	echo
	echo "Checking for Macbook Air WiFi adapter..."
	echo

	lshw -c network | grep BCM4360

	if [ $? -eq 0 ]; then
	
		echo
		echo "BCM4360 WiFi adapter found.  Installing driver..."
		echo

		sudo apt-get install bcmwl-kernel-source

	fi

	# Add neofetch to .bashrc if it does NOT already exist

	echo
	echo "Setting up neofetch on login..."
	echo

	cat $CONFIG_FILE | grep neofetch

	if [ $? -ne 0 ]; then 

		echo "" >> $CONFIG_FILE
		echo "# Entry for neofetch on startup of terminal" >> $CONFIG_FILE
		echo
		echo "neofetch" >> $CONFIG_FILE

	fi

	# Create Bash Aliases File if it does NOT already exist

	echo
	echo "Testing for .bash_aliases file and adding aliases..."
	echo

	test -f $ALIAS_FILE

	if [ $? -ne 0 ]; then

		echo "alias update='sudo apt-get update && sudo apt-get upgrade'" >> $ALIAS_FILE
		echo "alias upgrade='sudo apt-get update && sudo apt-get dist-upgrade'" >> $ALIAS_FILE
		echo "alias cleanup='sudo apt-get update && sudo apt autoremove'" >> $ALIAS_FILE
	
	fi

	# Create .vimrc File if it does NOT already exist

	echo
	echo "Setting up the vim config file..." 
	echo

	test -f $VIMRC

	if [ $? -ne 0 ]; then

		echo "syntax on" >> $VIMRC
		echo "set number" >> $VIMRC
		echo "colorscheme ron" >> $VIMRC
	
	fi

	# Make dev directory

	echo
	echo "Creating a dev directory under user's /home directory..."
	echo

	test -d $DEV

	if [ $? -ne 0 ]; then
		mkdir $DEV
	fi

	echo 
	echo "Setting default editor via user input..."
	echo

	# Adjust Ubuntu default editor

	sudo update-alternatives --config editor

	echo 
	echo "***NOTE: You will need to download the following:"
	echo "    ExpanDrive - for cloud drive support"
	echo "    ExpressVPN - VPN application"
	echo
	echo "Enjoy your system!"
	echo

} | tee -a $LOG
