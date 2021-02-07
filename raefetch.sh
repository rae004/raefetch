#!/bin/bash
#RAEFETCH
# Define colours.
{
  r='\033[0m'
  bold='\033[1m'
  white='\033[37m'
  red='\033[31m'
  bb="${bold}${red}"
  bw="${bold}${white}"
}

# Get Os Name & Version
# Try lsb_release, use grep | cut as fall back
# Store this is distro var for use in case statement.
get_os() {
  if [ "$(command -v lsb_release)" ]; then
    distro="$(lsb_release -ds)"
  else
    distro="$(grep -i 'PRETTY_NAME=' /etc/*-release | cut -d '"' -f2)"
  fi
}

# Echo user and hostname string
get_user() {
  echo -e "$(whoami)@$(hostname)"
}

# Echo Kernel string
get_kernel() {
  echo -e "$(uname -smr)"
}

# Echo machine model/product name
get_modal() {
  echo -e "$(cat /sys/devices/virtual/dmi/id/product_name)"
}

# Echo CPU details
get_cpu() {
  echo -e "$(grep -i 'model name' /proc/cpuinfo | head -1 | cut -f5- -d' ') @ $(nproc) cores"
}

# Get Available Ram
# Get Ram used
# Subtract available by amount used
# Echo and convert to MiB
get_ram() {
  used=$(grep -i MemAvailable /proc/meminfo | awk '{print $2}');
  total=$(grep -i MemTotal /proc/meminfo | awk '{print $2}');
  used=$((total - used));
  echo -e "Used: $((used /= 1024))/MiB  Total: $((total /= 1024))/MiB";
}

get_shell() {
  echo "$SHELL" "$($SHELL --version | grep -i 'version' | head -1 | cut -f4- -d ' ')";
}

#todo get packasges from multiple package managers.
get_packages() {
  # Detect apk packages installed.
  if [ -x "$(command -v apk)" ]; then
    pkgs="$(apk list --installed | wc -l)";
    pkgs+=" (apk) ";
  fi

  # Detect apt packages installed.
  if [ -x "$(command -v apt)" ]; then
    pkgs="$(dpkg-query -f '${binary:Package}\n' -W | wc -l)";
    pkgs+=" (apt) ";
  fi

  # Detect dnf packages installed.
  if [ -x "$(command -v dnf)" ]; then
    pkgs="$(dnf list installed | wc -l)";
    pkgs+=" (dnf) ";
  fi

  # Detect emerge packages installed.
  if [ -x "$(command -v emerge)" ]; then
    pkgs="$(qlist -I | wc -l)";
    pkgs+=" (emerge) ";
  fi

  # Detect kiss packages installed.
  if [ -x "$(command -v kiss)" ]; then
    pkgs="$(kiss list | wc -l)";
    pkgs+=" (kiss) ";
  fi

  # Detect snap packages installed.
  if [ -x "$(command -v nix)" ]; then
    pkgs="$(nix-store -q --requisites /run/current-system/sw | wc -l)";
    pkgs+=" (nix) ";
  fi

  # Detect opkg packages installed.
  if [ -x "$(command -v opkg)" ]; then
    pkgs="$(opkg list-installed | wc -l)";
    pkgs+=" (opkg) ";
  fi

  # Detect pacman packages installed.
  if [ -x "$(command -v pacman)" ]; then
    pkgs="$(pacman -Q | wc -l)";
    pkgs+=" (pacman) ";
  fi

  # Detect rpm packages installed.
  if [ -x "$(command -v rpm)" ]; then
    pkgs="$(rpm -qa --last | wc -l)";
    pkgs+=" (rpm) ";
  fi

  # Detect xbps packages installed.
  if [ -x "$(command -v xbps)" ]; then
    pkgs="$(xbps-query -l | wc -l)";
    pkgs+=" (xbps) ";
  fi

  # Detect yay packages installed.
  if [ -x "$(command -v yay)" ]; then
    pkgs="$(yay -Q | wc -l)";
    pkgs+=" (yay) ";
  fi

  # Detect yum packages installed.
  if [ -x "$(command -v yum)" ]; then
    pkgs="$(yum list installed | wc -l)";
    pkgs+=" (yum) ";
  fi

  # Detect zypper packages installed.
  if [ -x "$(command -v zypper)" ]; then
    pkgs="$(zypper se | wc -l)";
    pkgs+=" (zypper) ";
  fi

  # Detect flatpak packages installed.
  if [ -x "$(command -v flatpak)" ]; then
    pkgs+=" $(flatpak list | wc -l)";
    pkgs+=" (flatpak) ";
  fi

  # Detect snap packages installed.
  if [ -x "$(command -v snap)" ]; then
    pkgs+=" $(snap list | wc -l)";
    pkgs+=" (snap) ";
  fi

  echo -e "$pkgs"packages;
}

# Convert uptime from seconds into days, hours, and minutes.
# Append days, hours, and min if they're equal to zero.
# Print 'dys', 'hrs', and 'mins' if they're more than two.
get_uptime() {
  IFS=. read -r sec _ </proc/uptime;

  day=$((sec / 60 / 60 / 24));
  hour=$((sec / 60 / 60 % 24));
  min=$((sec / 60 % 60));

#todo make switch case
  if [ "${day}" == 0 ]; then
    uptime="${hour}h ${min}m";
  elif [ "${hour}" == 0 ]; then
    uptime="${day}d ${min}m";
  elif [ "${min}" == 0 ]; then
    uptime="${day}d ${hour}h";
  else
    uptime="${day}d ${hour}h ${min}m";
  fi

  echo -e "$uptime";
  IFS="";
}

# Display RAEFETCH usage information.
usage() {
  whiptail --title "RAEFETCH" --msgbox "
  Usage: RAEFETCH --help

  RAEFETCH is a simple system information tool for Linux. RAEFETCH shows not a whole lot:

  USER/HOST
  OS
  KERNEL
  MODEL
  CPU
  RAM (Used vs Total)
  SHELL (Loaded shells Path & version)
  PACKAGES
  UPTIME

  Compatible OS's:
  Debian, Other :)
  For bugs report, email rae004dev@gmail.com

  Copyright (c) 2021 - 2022 Rae <https://github.com/rae004>

  This programme is provided under the GPL-3.0 License. See LICENSE for more details." 28 100
}

#Fetch the details
raefetch() {
  # set distro var
  get_os

  case $distro in
  "Debian"*) # Debian
    echo -e
    echo -e "${bb}               USER/HOST  ${r}${bw}$(get_user)"
    echo -e "${bb}     ,---._    OS         ${r}${bw}$distro"
    echo -e "${bb}   /\\\`  __ \\\\   KERNEL     ${r}${bw}$(get_kernel)"
    echo -e "${bb}  |   /    |   MODEL      ${r}${bw}$(get_modal)"
    echo -e "${bb}  |   \\\`.__.   CPU        ${r}${bw}$(get_cpu)"
    echo -e "${bb}   \\           RAM        ${r}${bw}$(get_ram)"
    echo -e "${bb}    \\\`-,_      SHELL      ${r}${bw}$(get_shell)"
    echo -e "${bb}               PKGS       ${r}${bw}$(get_packages)"
    echo -e "${bb}               UPTIME     ${r}${bw}$(get_uptime)
    "
    ;;
  *) # Others
    echo -e
    echo -e "${bb}             USER/HOST ${r}$(get_user)"
    echo -e "${bb}      ___    OS         ${r}$distro"
    echo -e "${bb}     (.. |   KERNEL    ${r}$(get_kernel)"
    echo -e "${bb}     (<> |   MODEL  ${r}$(get_modal)"
    echo -e "${bb}    / __  \\  CPU    ${r}$(get_cpu)"
    echo -e "${bb}   ( /  \\ /| RAM    ${r}$(get_ram)"
    echo -e "${bb}  _/\\ __)/_) SHELL  ${r}$(get_shell)"
    echo -e "${bb}  \\|/-___\\|/ PKGS   ${r}$(get_packages)"
    echo -e "${bb}             UPTIME ${r}$(get_uptime)
    "
    ;;
  esac
}

main() {
  #no args lets go!
  if [ $# == 0 ]; then
    raefetch
  fi

  #handle args if we got em.
  while [[ $# -gt 0 ]]; do
    case $1 in
    "--version")
      whiptail --title "RAEFETCH" --msgbox "RAEFETCH version 0.0.1" 10 50
      ;;
    "--help")
      usage
      ;;
    *)
      printf "Bad Option passed\n"
      ;;
    esac
    exit
  done
}

main "$@"
