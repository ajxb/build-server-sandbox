#!/bin/bash

###############################################################################
# Update the apt package index
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
apt_update() {
  echo 'Updating apt package index'
  apt-get -qq -y update
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update the package index'
  fi
}

###############################################################################
# Upgrade packages
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
apt_upgrade() {
  echo 'Upgrading packages'
  DEBIAN_FRONTEND=noninteractive apt-get -y -o DPkg::options::="--force-confdef" -o DPkg::options::="--force-confold" -qq upgrade
  if [[ $? -ne 0 ]]; then
    abort 'Failed to upgrade packages'
  fi
}

###############################################################################
# Parse script input for validity and configure global variables for use
# throughout the script
# Globals:
#   None
# Arguments:
#   $@
# Returns:
#   None
###############################################################################
setup_vars() {
  # Process script options
  while getopts ':h' option; do
    case "${option}" in
      h) usage ;;
      :)
        echo "Option -${OPTARG} requires an argument"
        usage
        ;;
      ?)
        echo "Option -${OPTARG} is invalid"
        usage
        ;;
    esac
  done
}

###############################################################################
# Output usage information for the script to the terminal
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
usage() {
  local script_name
  script_name="$(basename "$0")"

  echo "usage: ${script_name} options"
  echo
  echo 'Update system packages'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"

  exit 1
}

main() {
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"
  apt_update
  apt_upgrade

  popd > /dev/null 2>&1
}

echo '**** update_system ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** update_system - done ****'

exit 0
