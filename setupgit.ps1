# Equivalent to 'set -e' in bash
$ErrorActionPreference = "Stop"

Write-Host "Setting up GIT!"

$has_selected_platform = $false
$selected_platform = ""

function Select-Platform {
    $platform = Read-Host "Enter the platform you are currently configuring. (gh) for GitHub, (gl) for GitLab and (bb) for BitBucket"
    
    switch ($platform) {
        "gh" {
            Write-Host "Using GitHub."
            $script:selected_platform = "github"
            $script:has_selected_platform = $true
        }
        "gl" {
            Write-Host "Using GitLab."
            $script:selected_platform = "gitlab"
            $script:has_selected_platform = $true
        }
        "bb" {
            Write-Host "Using BitBucket."
            $script:selected_platform = "bitbucket"
            $script:has_selected_platform = $true
        }
        default {
            Write-Host "Please, select a platform by passing the initials, for example: gh for Github."
        }
    }
}

while ($has_selected_platform -eq $false) {
    Select-Platform
}

$USER_NAME = Read-Host "Enter your username"
$USER_EMAIL = Read-Host "Enter your GIT email"

Write-Host "Setting username and email..."
git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"

Write-Host "Setting default branch..."
git config --global init.defaultBranch master

Write-Host "Setting colorful output..."
git config --global color.ui auto

Write-Host "Setting branch reconciliation"
git config --global pull.rebase false

Write-Host "Getting current user..."
git config --get user.name
git config --get user.email

Write-Host "Setting up SSH and finishing setup..."

# Generate SSH key without prompt for file overwrite
# PowerShell doesn't have direct ssh-keygen, so we use process call
$sshPath = "$env:USERPROFILE\.ssh"
if (-not (Test-Path $sshPath)) {
    New-Item -ItemType Directory -Path $sshPath -Force | Out-Null
}

# Generate SSH key
$keyPath = "$sshPath\id_ed25519"
$process = Start-Process -FilePath "ssh-keygen" -ArgumentList "-t", "ed25519", "-C", "$USER_EMAIL", "-N", '""', "-f", "$keyPath" -NoNewWindow -PassThru -Wait

# Create SSH config
$configContent = @"
Host ${selected_platform}.com
    StrictHostKeyChecking no
"@
Set-Content -Path "$sshPath\config" -Value $configContent

Write-Host "Your SSH key is: "
Get-Content "$keyPath.pub"

function Check-SSHKey {
    $HAS_COPIED_SSH_KEY = Read-Host "Have you entered your ssh key in $($selected_platform.Substring(0,1).ToUpper() + $selected_platform.Substring(1)) settings? [y/n]"
    
    if ($HAS_COPIED_SSH_KEY -match "^[yY]") {
        Write-Host "Testing connection with SSH..."
        Start-Process -FilePath "ssh" -ArgumentList "-T", "git@${selected_platform}.com" -NoNewWindow -Wait
        return $true
    }
    elseif ($HAS_COPIED_SSH_KEY -match "^[nN]") {
        return $false
    }
    else {
        Write-Host "Invalid input. Please enter 'y' or 'n'."
        return $false
    }
}

$sshKeyAdded = $false
while (-not $sshKeyAdded) {
    $sshKeyAdded = Check-SSHKey
    if (-not $sshKeyAdded) {
        Write-Host "Please add your SSH key to $($selected_platform.Substring(0,1).ToUpper() + $selected_platform.Substring(1)) before continuing."
    }
}

Write-Host "Done!"

