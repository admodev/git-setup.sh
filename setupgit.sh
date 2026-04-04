#!/bin/bash
set -e

# ─────────────────────────────────────────────
#  COLORS & STYLES
# ─────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
DIM="\033[2m"

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
WHITE="\033[37m"

BG_BLACK="\033[40m"

AMBER="\033[38;5;214m"
SOFT_GREEN="\033[38;5;120m"
MUTED="\033[38;5;245m"

# ─────────────────────────────────────────────
#  UI PRIMITIVES
# ─────────────────────────────────────────────
TOTAL_STEPS=5
CURRENT_STEP=0

step() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  echo ""
  echo -e "${MUTED}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}"
  echo -e "  ${AMBER}${BOLD}[${CURRENT_STEP}/${TOTAL_STEPS}]${RESET} ${BOLD}${WHITE}$1${RESET}"
  echo -e "${MUTED}  ┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄${RESET}"
}

info()    { echo -e "  ${CYAN}→${RESET}  $1"; }
success() { echo -e "  ${SOFT_GREEN}✔${RESET}  $1"; }
warn()    { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
error()   { echo -e "  ${RED}✖${RESET}  $1"; }

prompt() {
  echo -ne "  ${AMBER}›${RESET} ${BOLD}$1${RESET} "
}

spinner() {
  local pid=$1
  local msg=$2
  local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    echo -ne "  ${AMBER}${frames[$i]}${RESET}  ${DIM}${msg}...${RESET}\r"
    i=$(( (i + 1) % ${#frames[@]} ))
    sleep 0.08
  done
  echo -ne "\033[2K"  # clear line
}

header() {
  clear
  echo ""
  echo -e "  ${AMBER}╔═══════════════════════════════════════════╗${RESET}"
  echo -e "  ${AMBER}║${RESET}  ${BOLD}${WHITE}GIT ENVIRONMENT SETUP${RESET}                     ${AMBER}║${RESET}"
  echo -e "  ${AMBER}║${RESET}  ${MUTED}SSH · Global config · Platform auth${RESET}       ${AMBER}║${RESET}"
  echo -e "  ${AMBER}╚═══════════════════════════════════════════╝${RESET}"
  echo ""
}

# ─────────────────────────────────────────────
#  PLATFORM SELECTION
# ─────────────────────────────────────────────
has_selected_platform=false
selected_platform=""

select_platform() {
  echo ""
  echo -e "  ${MUTED}Available platforms:${RESET}"
  echo -e "  ${DIM}  gh${RESET}  →  GitHub"
  echo -e "  ${DIM}  gl${RESET}  →  GitLab"
  echo -e "  ${DIM}  bb${RESET}  →  BitBucket"
  echo ""
  prompt "Platform (gh / gl / bb):"
  read -r PLATFORM

  case $PLATFORM in
    "gh")
      selected_platform="github"
      has_selected_platform=true
      success "Platform set to ${BOLD}GitHub${RESET}"
      ;;
    "gl")
      selected_platform="gitlab"
      has_selected_platform=true
      success "Platform set to ${BOLD}GitLab${RESET}"
      ;;
    "bb")
      selected_platform="bitbucket"
      has_selected_platform=true
      success "Platform set to ${BOLD}BitBucket${RESET}"
      ;;
    *)
      warn "Invalid option ${BOLD}\"${PLATFORM}\"${RESET}. Use ${BOLD}gh${RESET}, ${BOLD}gl${RESET}, or ${BOLD}bb${RESET}."
      ;;
  esac
}

# ─────────────────────────────────────────────
#  SSH CHECK
# ─────────────────────────────────────────────
check_ssh_key() {
  echo ""
  prompt "Have you added your SSH key to ${BOLD}${selected_platform^}${RESET} settings? (y/n):"
  read -r HAS_COPIED_SSH_KEY

  case $HAS_COPIED_SSH_KEY in
    [yY]*)
      info "Testing SSH connection to ${selected_platform}.com ..."
      (ssh -T "git@${selected_platform}.com" 2>&1 || true) &
      local ssh_pid=$!
      spinner $ssh_pid "Connecting"
      wait $ssh_pid
      success "SSH connection test complete."
      return 0
      ;;
    [nN]*)
      warn "Add your SSH key to ${BOLD}${selected_platform^}${RESET} before continuing."
      return 1
      ;;
    *)
      error "Invalid input. Please enter ${BOLD}y${RESET} or ${BOLD}n${RESET}."
      return 1
      ;;
  esac
}

# ─────────────────────────────────────────────
#  MAIN
# ─────────────────────────────────────────────
header

# STEP 1 — Platform
step "Select Git Platform"
while [[ $has_selected_platform == "false" ]]; do
  select_platform
done

# STEP 2 — Identity
step "Configure Git Identity"
echo ""
prompt "Username:"
read -r USER_NAME
prompt "Email address:"
read -r USER_EMAIL

info "Applying global git config..."
git config --global user.name "$USER_NAME"
git config --global user.email "$USER_EMAIL"
success "Identity set:  ${BOLD}${USER_NAME}${RESET}  <${USER_EMAIL}>"

# STEP 3 — Git preferences
step "Apply Git Preferences"
git config --global init.defaultBranch master
success "Default branch → ${BOLD}master${RESET}"

git config --global color.ui auto
success "Colorful output → ${BOLD}enabled${RESET}"

git config --global pull.rebase false
success "Pull strategy  → ${BOLD}merge (no rebase)${RESET}"

# STEP 4 — SSH Key
step "Generate SSH Key"
info "Generating ed25519 key for ${DIM}<${USER_EMAIL}>${RESET} ..."
(ssh-keygen -t ed25519 -C "$USER_EMAIL" -N "" -f ~/.ssh/id_ed25519 -q) &
spinner $! "Generating key"
wait $!
success "SSH key created at ${BOLD}~/.ssh/id_ed25519${RESET}"

mkdir -p ~/.ssh
cat <<EOF > ~/.ssh/config
Host ${selected_platform}.com
    StrictHostKeyChecking no
EOF
success "SSH config written for ${BOLD}${selected_platform}.com${RESET}"

echo ""
echo -e "  ${AMBER}┌─ Your public SSH key ──────────────────────────────────────┐${RESET}"
echo -e "  ${AMBER}│${RESET}"
while IFS= read -r line; do
  echo -e "  ${AMBER}│${RESET}  ${SOFT_GREEN}${line}${RESET}"
done < ~/.ssh/id_ed25519.pub
echo -e "  ${AMBER}│${RESET}"
echo -e "  ${AMBER}└────────────────────────────────────────────────────────────┘${RESET}"
echo ""
info "Copy the key above and add it to your ${BOLD}${selected_platform^}${RESET} SSH settings."

# STEP 5 — Verify SSH
step "Verify SSH Connection"
while ! check_ssh_key; do
  :
done

# ─── DONE ───────────────────────────────────
echo ""
echo -e "  ${SOFT_GREEN}╔═══════════════════════════════════════════╗${RESET}"
echo -e "  ${SOFT_GREEN}║${RESET}  ${BOLD}${WHITE}✔  Setup complete!${RESET}                         ${SOFT_GREEN}║${RESET}"
echo -e "  ${SOFT_GREEN}║${RESET}  ${MUTED}Git is configured and SSH is ready.${RESET}       ${SOFT_GREEN}║${RESET}"
echo -e "  ${SOFT_GREEN}╚═══════════════════════════════════════════╝${RESET}"
echo ""
