#!/bin/bash

#!/bin/bash

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
  echo 'Install the system'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"

  exit 1
}

main() {
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"
  check_user

  # Ensure script files are all executable
  chmod +x *.sh
  if [[ $? -ne 0 ]]; then
    abort 'Failed to set scripts to be executable'
  fi

  ./configure_system.sh
  ./install_git.sh
  ./install_puppet.sh
  ./run_puppet.sh

  popd > /dev/null 2>&1
}

echo '**** install ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** install - done ****'

exit 0
