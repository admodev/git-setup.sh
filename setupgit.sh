#!/bin/bash

set -e

################
#### WIP!!! ####
################

echo "Setting up GIT!"

echo "Setting username and email..."
git config --global user.name "user"
git config --global user.email "email@provider.com"

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
ssh-keygen -t ed25519 -C "email@provider.com" -N "" -f ~/.ssh/id_rsa <<<y >/dev/null 2>&1

