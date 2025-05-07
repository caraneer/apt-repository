#!/bin/bash

# Heavily inspired from nodesource
# https://github.com/nodesource/distributions/blob/a2432171896427c32aefbce4983308125bd0a0e6/LICENSE.md

# Logger Function
log() {
  local message="$1"
  local type="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local color
  local endcolor="\033[0m"

  case "$type" in
	"info") color="\033[38;5;79m" ;;
	"success") color="\033[1;32m" ;;
	"error") color="\033[1;31m" ;;
	*) color="\033[1;34m" ;;
  esac

  echo -e "${color}${timestamp} - ${message}${endcolor}"
}

# Error handler function  
handle_error() {
  local exit_code=$1
  local error_message="$2"
  log "Error: $error_message (Exit Code: $exit_code)" "error"
  exit $exit_code
}

# Function to check for command availability
command_exists() {
  command -v "$1" &> /dev/null
}

check_os() {
	if ! [ -f "/etc/debian_version" ]; then
		echo "Error: This script is only supported on Debian-based systems."
		exit 1
	fi
}

# Function to Install the script pre-requisites
install_pre_reqs() {
	log "Installing pre-requisites" "info"

	# Run 'apt-get update'
	if ! apt-get update -y; then
		handle_error "$?" "Failed to run 'apt-get update'"
	fi

	# Run 'apt-get install'
	if ! apt-get install -y apt-transport-https ca-certificates curl gnupg; then
		handle_error "$?" "Failed to install packages"
	fi

	if ! mkdir -p /usr/share/keyrings; then
		handle_error "$?" "Makes sure the path /usr/share/keyrings exist or run ' mkdir -p /usr/share/keyrings' with sudo"
	fi

	rm -f /usr/share/keyrings/deb-caraneer.gpg || true
	rm -f /etc/apt/sources.list.d/deb-caraneer.list || true

	# Run 'curl' and 'gpg' to download and import the MACE signing key
	if ! curl -fsSL https://deb.caraneer.ca/caraneer_signing.key | gpg --dearmor -o /usr/share/keyrings/deb-caraneer.gpg; then
		handle_error "$?" "Failed to download and import the MACE signing key"
	fi

	# Explicitly set the permissions to ensure the file is readable by all
	if ! chmod 644 /usr/share/keyrings/deb-caraneer.gpg; then
		handle_error "$?" "Failed to set correct permissions on /usr/share/keyrings/deb-caraneer.gpg"
	fi
}

# Function to configure the Repo
configure_repo() {

	arch=$(dpkg --print-architecture)
	if [ "$arch" != "amd64" ] && [ "$arch" != "arm64" ]; then
	  handle_error "1" "Unsupported architecture: $arch. Only amd64, and arm64 are supported."
	fi

	# TODO: Ask if they want everything
	echo "deb [signed-by=/usr/share/keyrings/deb-caraneer.gpg] https://deb.caraneer.ca/ gnu-generic configurators" > /etc/apt/sources.list.d/deb-caraneer.list
	echo "deb [signed-by=/usr/share/keyrings/deb-caraneer.gpg] https://deb.caraneer.ca/ gnu-generic third-party" >> /etc/apt/sources.list.d/deb-caraneer.list
	# echo "deb [signed-by=/usr/share/keyrings/deb-caraneer.gpg] https://deb.caraneer.ca/ gnu-generic main" >> /etc/apt/sources.list.d/deb-caraneer.list

	# Uncomment if needed, but we aren't likely to override system packages
	# echo "Package: *" | tee /etc/apt/preferences.d/deb-caraneer > /dev/null
	# echo "Pin: origin deb.caraneer.ca" | tee -a /etc/apt/preferences.d/deb-caraneer > /dev/null
	# echo "Pin-Priority: 600" | tee -a /etc/apt/preferences.d/deb-caraneer > /dev/null

	# Run 'apt-get update'
	if ! apt-get update -y; then
		handle_error "$?" "Failed to run 'apt-get update'"
	else
		log "MACE apt repository configured successfully."
	fi
}

# Check OS
check_os

# Main execution
install_pre_reqs || handle_error $? "Failed installing pre-requisites"
configure_repo || handle_error $? "Failed configuring repository"
