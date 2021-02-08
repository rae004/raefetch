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
  if [ "${os_check_passed}" ]; then
    echo -e "$distro"
  fi
}

get_colors() {
  color_2=(0 1 5 6 19 2 3)
  color_1=(8 9 12 14 18 10 11)
  top_color=$(for i in "${color_1[@]}"; do echo -en "\e[48;5;${i}m     \e[0m"; done)
  bottom_color=$(for i in "${color_2[@]}"; do echo -en "\e[48;5;${i}m     \e[0m"; done)
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
  echo -e "$(grep -i 'model name' /proc/cpuinfo | head -1 | cut -f5- -d ' ') @ $(nproc) cores"
}

# Get Available Ram in kb.
# Get Total Ram in kb.
# Subtract Total in kb from Available in kb to get Ram Used in kb.
# Convert values to MiB & GB.
# Use package bc to convert GB division to float value, ie: 3.37/GB.
get_ram() {
  divider=1024;
  #Total ram values
  available_kb=$(grep -i MemAvailable /proc/meminfo | awk '{print $2}');
  total_kb=$(grep -i MemTotal /proc/meminfo | awk '{print $2}');
  total_mb=$(( total_kb / divider ));
  # Get float value
  total_gb=$(echo "scale=2; $total_mb / $divider;" | bc);
  ## Used ram values
  used_kb=$(( total_kb - available_kb ));
  used_mb=$(( used_kb / divider ));
  # Get float value
  used_gb=$(echo "scale=2; $used_mb / $divider;" | bc);

  echo -e "Total: $total_gb/GB > Used: $used_gb/GB";
}

get_shell() {
  echo "$SHELL" "$($SHELL --version | grep -i 'version' | head -1 | cut -f4- -d ' ')";
}

get_packages() {
  # Detect apk packages installed.
  if [ -x "$(command -v apk)" ]; then
    pkgs="$(apk list --installed | wc -l)";
    pkgs+="(apk) ";
  fi

  # Detect apt packages installed.
  if [ -x "$(command -v apt)" ]; then
    pkgs="$(dpkg-query -f '${binary:Package}\n' -W | wc -l)";
    pkgs+="(apt) ";
  fi

  # Detect dnf packages installed.
  if [ -x "$(command -v dnf)" ]; then
    pkgs="$(dnf list installed | wc -l)";
    pkgs+="(dnf) ";
  fi

  # Detect emerge packages installed.
  if [ -x "$(command -v emerge)" ]; then
    pkgs="$(qlist -I | wc -l)";
    pkgs+="(emerge) ";
  fi

  # Detect kiss packages installed.
  if [ -x "$(command -v kiss)" ]; then
    pkgs="$(kiss list | wc -l)";
    pkgs+="(kiss) ";
  fi

  # Detect snap packages installed.
  if [ -x "$(command -v nix)" ]; then
    pkgs="$(nix-store -q --requisites /run/current-system/sw | wc -l)";
    pkgs+="(nix) ";
  fi

  # Detect opkg packages installed.
  if [ -x "$(command -v opkg)" ]; then
    pkgs="$(opkg list-installed | wc -l)";
    pkgs+="(opkg) ";
  fi

  # Detect pacman packages installed.
  if [ -x "$(command -v pacman)" ]; then
    pkgs="$(pacman -Q | wc -l)";
    pkgs+="(pacman) ";
  fi

  # Detect rpm packages installed.
  if [ -x "$(command -v rpm)" ]; then
    pkgs="$(rpm -qa --last | wc -l)";
    pkgs+="(rpm) ";
  fi

  # Detect xbps packages installed.
  if [ -x "$(command -v xbps)" ]; then
    pkgs="$(xbps-query -l | wc -l)";
    pkgs+="(xbps) ";
  fi

  # Detect yay packages installed.
  if [ -x "$(command -v yay)" ]; then
    pkgs="$(yay -Q | wc -l)";
    pkgs+="(yay) ";
  fi

  # Detect yum packages installed.
  if [ -x "$(command -v yum)" ]; then
    pkgs="$(yum list installed | wc -l)";
    pkgs+="(yum) ";
  fi

  # Detect zypper packages installed.
  if [ -x "$(command -v zypper)" ]; then
    pkgs="$(zypper se | wc -l)";
    pkgs+="(zypper) ";
  fi

  # Detect flatpak packages installed.
  if [ -x "$(command -v flatpak)" ]; then
    pkgs+="$(flatpak list | wc -l)";
    pkgs+="(flatpak) ";
  fi

  # Detect snap packages installed.
  if [ -x "$(command -v snap)" ]; then
    pkgs+="$(snap list | wc -l)";
    pkgs+="(snap) ";
  fi

  echo -e "$pkgs"packages;
}

# Convert uptime from seconds into days, hours, and minutes.
# Append days, hours, and min if they're equal to zero.
# Print 'dys', 'hrs', and 'minutes' if they're more than two.
get_uptime() {
  IFS=. read -r sec _ </proc/uptime;

  day=$((sec / 60 / 60 / 24));
  hour=$((sec / 60 / 60 % 24));
  min=$((sec / 60 % 60));

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

# Display RAEFETCH usage information. For option --help
get_usage() {
  whiptail --title "RAEFETCH" --msgbox "
  Usage: raefetch <OPTION>
    --help    (Display this page)
    --version (Show current version number)
    --logo <OS-NAME> (Show fetch with different OS logo)

  RAEFETCH is a simple system information tool for Linux. RAEFETCH shows not a whole lot:

  USER/HOST
  OS
  KERNEL
  MODEL
  CPU
  RAM (Total vs Used)
  SHELL (Loaded shells Path & version)
  PACKAGES
  UPTIME

  OS Logos available for:
  Debian, Ubuntu, Pop Os, Raspbian, Arch, Other :)
  For bugs report, email rae004dev@gmail.com

  Copyright (c) 2021 - 2022 Rae <https://github.com/rae004>

  This programme is provided under the GPL-3.0 License. See LICENSE for more details." 28 100
}

# Display RAEFETCH version information. For option --version
get_version() {
  whiptail --title "RAEFETCH" --msgbox "RAEFETCH version 0.0.1" 10 50;
}

#Fetch the details
raefetch() {
  # If distro var is set, it was passed with --logo option lets us it.
  # Otherwise get os from host system.
  if [ -z ${distro+x}  ]; then
    get_os
  fi

  os_check_passed=true
  get_colors
  shopt -s nocasematch
  case $distro in
  "Debian"*) # Debian
    echo -e
    echo -e "${bb}               USER/HOST  ${r}${bw}$(get_user)"
    echo -e "${bb}     ,---._    OS         ${r}${bw}$(get_os)"
    echo -e "${bb}   /\\\`  __ \\\\   KERNEL     ${r}${bw}$(get_kernel)"
    echo -e "${bb}  |   /    |   MODEL      ${r}${bw}$(get_modal)"
    echo -e "${bb}  |   \\\`.__.   CPU        ${r}${bw}$(get_cpu)"
    echo -e "${bb}   \\           RAM        ${r}${bw}$(get_ram)"
    echo -e "${bb}    \\\`-,_      SHELL      ${r}${bw}$(get_shell)"
    echo -e "${bb}               PKGS       ${r}${bw}$(get_packages)"
    echo -e "${bb}               UPTIME     ${r}${bw}$(get_uptime)"
    echo -e ""
    echo -e "               ${top_color}"
    echo -e "               ${bottom_color}
    "
    ;;
  "Ubuntu"*) # Ubuntu
    echo -e
    echo -e "${bb}               USER/HOST  ${r}${bw}$(get_user)"
    echo -e "${bb}           _   OS         ${r}${bw}$(get_os)"
    echo -e "${bb}       ---(_)  KERNEL     ${r}${bw}$(get_kernel)"
    echo -e "${bb}   _/  ---  \\  MODEL      ${r}${bw}$(get_modal)"
    echo -e "${bb}  (_) |   |    CPU        ${r}${bw}$(get_cpu)"
    echo -e "${bb}    \\  --- _/  RAM        ${r}${bw}$(get_ram)"
    echo -e "${bb}       ---(_)  SHELL      ${r}${bw}$(get_shell)"
    echo -e "${bb}               PKGS       ${r}${bw}$(get_packages)"
    echo -e "${bb}               UPTIME     ${r}${bw}$(get_uptime)"
    echo -e ""
    echo -e "               ${top_color}"
    echo -e "               ${bottom_color}
    "
    ;;
  "Raspbian"*) # Raspbian
    echo -e
    echo -e "${bb}               USER/HOST  ${r}${bw}$(get_user)"
    echo -e "${bb}    __  __     OS         ${r}${bw}$(get_os)"
    echo -e "${bb}   (_\\)(/_)    KERNEL     ${r}${bw}$(get_kernel)"
    echo -e "${bb}   (_(__)_)    MODEL      ${r}${bw}$(get_modal)"
    echo -e "${bb}  (_(_)(_)_)   CPU        ${r}${bw}$(get_cpu)"
    echo -e "${bb}   (_(__)_)    RAM        ${r}${bw}$(get_ram)"
    echo -e "${bb}     (__)      SHELL      ${r}${bw}$(get_shell)"
    echo -e "${bb}               PKGS       ${r}${bw}$(get_packages)"
    echo -e "${bb}               UPTIME     ${r}${bw}$(get_uptime)"
    echo -e ""
    echo -e "               ${top_color}"
    echo -e "               ${bottom_color}
    "
    ;;
  "Pop"*) # Pop
    echo -e
    echo -e "${bb}                  USER/HOST  ${r}${bw}$(get_user)"
    echo -e "${bb} ______           OS         ${r}${bw}$(get_os)"
    echo -e "${bb} \\   _ \\     _    KERNEL     ${r}${bw}$(get_kernel)"
    echo -e "${bb}  \\ \\ \\ \\   | |   MODEL      ${r}${bw}$(get_modal)"
    echo -e "${bb}   \\ \\_\\ \\  | |   CPU        ${r}${bw}$(get_cpu)"
    echo -e "${bb}    \\  ___\\ |_|   RAM        ${r}${bw}$(get_ram)"
    echo -e "${bb}     \\ \\     _    SHELL      ${r}${bw}$(get_shell)"
    echo -e "${bb}    __\\_\\___(_)_  PKGS       ${r}${bw}$(get_packages)"
    echo -e "${bb}   (____________) UPTIME     ${r}${bw}$(get_uptime)"
    echo -e ""
    echo -e "                  ${top_color}"
    echo -e "                  ${bottom_color}
    "
    ;;
  "Arch"*) # Arch
    echo -e
    echo -e "${bb}                  USER/HOST  ${r}${bw}$(get_user)"
    echo -e "${bb}        /\\        OS         ${r}${bw}$(get_os)"
    echo -e "${bb}       /  \\       KERNEL     ${r}${bw}$(get_kernel)"
    echo -e "${bb}      /    \\      MODEL      ${r}${bw}$(get_modal)"
    echo -e "${bb}     /  __  \\     CPU        ${r}${bw}$(get_cpu)"
    echo -e "${bb}    /  (  )  \\    RAM        ${r}${bw}$(get_ram)"
    echo -e "${bb}   / __|  |__ \\   SHELL      ${r}${bw}$(get_shell)"
    echo -e "${bb}  /.\\\`      \\\`.\\  PKGS       ${r}${bw}$(get_packages)"
    echo -e "${bb}                  UPTIME     ${r}${bw}$(get_uptime)"
    echo -e ""
    echo -e "                  ${top_color}"
    echo -e "                  ${bottom_color}
    "
    ;;
  *) # Others
    echo -e
    echo -e "${bb}               USER/HOST ${r}${bw}$(get_user)"
    echo -e "${bb}      ___      OS        ${r}${bw}$(get_os)"
    echo -e "${bb}     (.. |     KERNEL    ${r}${bw}$(get_kernel)"
    echo -e "${bb}     (<> |     MODEL     ${r}${bw}$(get_modal)"
    echo -e "${bb}    / __  \\    CPU       ${r}${bw}$(get_cpu)"
    echo -e "${bb}   ( /  \\ /|   RAM       ${r}${bw}$(get_ram)"
    echo -e "${bb}  _/\\ __)/_)   SHELL     ${r}${bw}$(get_shell)"
    echo -e "${bb}  \\|/-___\\|/   PKGS      ${r}${bw}$(get_packages)"
    echo -e "${bb}               UPTIME     ${r}${bw}$(get_uptime)"
    echo -e ""
    echo -e "               ${top_color}"
    echo -e "               ${bottom_color}
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
      get_version
      ;;
    "--help")
      get_usage
      ;;
    "--logo")
      if [ -n "$2" ]; then
        os_check_passed=true
        distro="$2"
      else
        get_os;
      fi
      raefetch
      ;;
    *)
      echo -e "\n Bad Option passed =(\n"
      ;;
    esac
    exit
  done
}

# todo add functionality for short hand options
main "$@"
