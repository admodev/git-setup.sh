#!/bin/bash

set -e

################
#### WIP!!! ####
################

echo "Setting up GIT!"

read -p "Enter your username: " USER_NAME
read -p "Enter your GIT email: " USER_EMAIL

echo "Setting username and email..."
git config --global user.name $USER_NAME
git config --global user.email $USER_EMAIL

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
ssh-keygen -t ed25519 -C $USER_EMAIL -N "" -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1

cat <<EOF
Host github.com
    StrictHostKeyChecking no
EOF

echo "Your GitHub ssh key is: "

cat ~/.ssh/id_rsa.pub

read -p "Have you entered your ssh key in GitHub settings? [yY/nN] " HAS_COPIED_SSH_KEY

case $HAS_COPIED_SSH_KEY in
        [yY]*)
                echo "SSHing into github.com..."
                # TODO!: add a selection of desired platform to test connection (github, gitlab, bitbucket...)
                ssh -T git@github.com
                ;;
        [nN]*)
                read -p "Have you entered your ssh key in GitHub settings? [yY/nN] " HAS_COPIED_SSH_KEY
                ;;
        *)
                echo "An error has occured... exiting."
                exit 1
                ;;
esac

echo "Done!"
