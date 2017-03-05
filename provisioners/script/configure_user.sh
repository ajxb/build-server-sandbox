#!/bin/bash

###############################################################################
# Configures the fonts
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_fonts() {
  echo 'Configuring fonts'
  add-apt-repository -y ppa:no1wantdthisname/ppa
  if [[ $? -ne 0 ]]; then
    abort 'Failed to add apt repository for ppa:no1wantdthisname/ppa'
  fi

  apt-get -qq update
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update apt package cache'
  fi

  apt-get -qq -y install fontconfig-infinality libcairo-gobject2 libcairo2 libfreetype6
  if [[ $? -ne 0 ]]; then
    abort 'Failed to install infinality'
  fi

  apt-get -qq -y install fonts-roboto
  if [[ $? -ne 0 ]]; then
    abort 'Failed to install fonts-roboto'
  fi

  su - ${THE_USER} -c "dbus-launch gsettings set org.gnome.desktop.interface document-font-name 'Roboto 10'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to set document font for ${THE_USER}"
  fi

  su - ${THE_USER} -c "dbus-launch gsettings set org.gnome.desktop.interface font-name 'Roboto 10'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to set default font for ${THE_USER}"
  fi

  su - ${THE_USER} -c "dbus-launch gsettings set org.gnome.desktop.interface monospace-font-name 'Ubuntu Mono 11'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to set monospace font for ${THE_USER}"
  fi

  su - ${THE_USER} -c "dbus-launch   gsettings set org.gnome.desktop.wm.preferences titlebar-font 'Roboto Bold 10'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to set monospace font for ${THE_USER}"
  fi
}


###############################################################################
# Installs and configures the faba-mono icon set
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_icons() {
  echo 'Configuring Unity icons'
  add-apt-repository -y ppa:moka/daily
  if [[ $? -ne 0 ]]; then
    abort 'Failed to add apt repository for ppa:moka/daily'
  fi

  apt-get -qq update
  if [[ $? -ne 0 ]]; then
    abort 'Failed to update apt package cache'
  fi

  apt-get -qq -y install faba-icon-theme faba-mono-icons
  if [[ $? -ne 0 ]]; then
    abort 'Failed to install icons'
  fi

  su - ${THE_USER} -c "dbus-launch gsettings set org.gnome.desktop.interface icon-theme 'Faba-Mono'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to configure icons for ${THE_USER}"
  fi
}

###############################################################################
# Installs and configures the adapta gtk theme
# Globals:
#   $0
# Arguments:
#   None
# Returns:
#   None
###############################################################################
configure_theme() {
  su - ${THE_USER} -c "dbus-launch gsettings set org.gnome.desktop.interface gtk-theme 'Adapta'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to configure gtk theme for ${THE_USER}"
  fi

  su - ${THE_USER} -c "dbus-launch gsettings set org.gnome.desktop.wm.preferences theme 'Adapta'"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to configure wm theme for ${THE_USER}"
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
  while getopts ':hu:' option; do
    case "${option}" in
      h) usage ;;
      u) THE_USER="${OPTARG}" ;;
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

  readonly THE_USER

  if [[ -z "${THE_USER}" ]]; then
    echo 'Option u missing'
    usage
  fi

  THE_USER_HOME=$(eval echo ~${THE_USER})
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
  echo 'Configuration script for user'
  echo
  echo 'OPTIONS:'
  echo "  -h show help information about ${script_name}"
  echo '  -u user to configure'

  exit 1
}

main() {
  pushd "${MY_PATH}" > /dev/null 2>&1

  setup_vars "$@"

  #############################################################################
  # Configure unity
  #############################################################################
  configure_theme
  configure_icons
  configure_fonts

  echo 'Configuring unity launcher'
  su - ${THE_USER} -c "dbus-launch gsettings set com.canonical.Unity.Launcher favorites \"['application://ubiquity.desktop', 'application://org.gnome.Nautilus.desktop', 'application://gnome-terminal.desktop', 'application://firefox.desktop', 'application://atom.desktop', 'unity://running-apps', 'unity://expo-icon', 'unity://devices']\""
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to configure unity launcher for ${THE_USER}"
  fi

  echo 'Configuring .rvmrc'
  su - ${THE_USER} -c "echo rvm_silence_path_mismatch_check_flag=1 >> ~/.rvmrc"
  if [[ $? -ne 0 ]]; then
    echo "WARN: Failed to configure .rvmrc for ${THE_USER}"
  fi

  popd > /dev/null
}

echo '**** configure_user ****'

MY_PATH="$(dirname "$0")"
MY_PATH="$(cd "${MY_PATH}" && pwd)"
readonly MY_PATH

source "${MY_PATH}/common_properties.sh"
source "${MY_PATH}/common_functions.sh"

main "$@"

echo '**** configure_user - done ****'

exit 0
