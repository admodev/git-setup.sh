#!/bin/bash

set -e

echo "Setting up GIT!"

has_selected_platform=false

select_platform() {
	read -p "Enter the platform you are currently configuring. (gh) for GitHub, (gl) for GitLab and (bb) for BitBucket: " PLATFORM 
	
	case $PLATFORM in
		"gh")
			echo "Using GitHub."
			selected_platform="github"
			has_selected_platform=true
			;;
		"gl")
			echo "Using GitLab."
			selected_platform="gitlab"
			has_selected_platform=true
			;;
		"bb")
			echo "Using BitBucket."
			selected_platform="bitbucket"
			has_selected_platform=true
			;;
		*)
			echo "Please, select a platform by passing the initials, for example: gh for Github."
			;;
	esac
}

while [[ $has_selected_platform == "false" ]]; do
	select_platform
done

read -p "Enter your username: " USER_NAME
read -p "Enter your GIT email: " USER_EMAIL

echo "Setting username and email..."
git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

echo "Setting default branch..."
git config --global init.defaultBranch master

echo "Setting colorful output..."
git config --global color.ui auto

echo "Setting branch reconciliation"
git config --global pull.rebase false

echo "Getting current user..."
git config --get user.name
git config --get user.email

echo "Setting up SSH and finishing setup..."
# Generate SSH key without prompt for file overwrite
ssh-keygen -t ed25519 -C "$USER_EMAIL" -N "" -f ~/.ssh/id_ed25519

# Create SSH config
mkdir -p ~/.ssh
cat <<EOF > ~/.ssh/config
Host ${selected_platform}.com
    StrictHostKeyChecking no
EOF

echo "Your SSH key is: "
cat ~/.ssh/id_ed25519.pub

check_ssh_key() {
	read -p "Have you entered your ssh key in ${selected_platform^} settings? [y/n] " HAS_COPIED_SSH_KEY
	
	case $HAS_COPIED_SSH_KEY in
		[yY]*)
			echo "Testing connection with SSH..."
			ssh -T "git@${selected_platform}.com"
			return 0
			;;
		[nN]*)
			return 1
			;;
		*)
			echo "Invalid input. Please enter 'y' or 'n'."
			return 1
			;;
	esac
}

while ! check_ssh_key; do
	echo "Please add your SSH key to ${selected_platform^} before continuing."
done

echo "Done!"

