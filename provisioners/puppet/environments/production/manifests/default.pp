###############################################################################
# Parameters
###############################################################################
$bs_docker_version   = lookup('bs_docker_version')
$bs_gradle_version   = lookup('bs_gradle_version')
$bs_java_version     = lookup('bs_java_version')
$bs_maven_version    = lookup('bs_maven_version')
$bs_packer_version   = lookup('bs_packer_version')
$bs_ruby_version     = lookup('bs_ruby_version')
$bs_rubygems_version = lookup('bs_rubygems_version')
$bs_vagrant_version  = lookup('bs_vagrant_version')

$bs_primary_user_email    = lookup('bs_primary_user_email')
$bs_primary_user_fullname = lookup('bs_primary_user_fullname')
$bs_primary_user_group    = lookup('bs_primary_user_group')
$bs_primary_user_name     = lookup('bs_primary_user_name')
$bs_samba_workgroup       = lookup('bs_samba_workgroup')
$bs_nameservers           = lookup('bs_nameservers')

###############################################################################
# Basic includes now coming from Hiera
###############################################################################
lookup('classes', Array[String], 'unique').include

###############################################################################
# resolvconf
###############################################################################
class { 'resolv_conf':
  nameservers => $bs_nameservers,
}

###############################################################################
# packer
###############################################################################
class { 'packer':
  version => $bs_packer_version,
}

###############################################################################
# vagrant
###############################################################################
class { 'vagrant':
  version => $bs_vagrant_version,
}

###############################################################################
# VirtualBox
###############################################################################
class { 'virtualbox':
  package_name => 'virtualbox-5.1',
}

virtualbox::extpack { 'Oracle_VM_VirtualBox_Extension_Pack':
  ensure           => present,
  source           => 'http://download.virtualbox.org/virtualbox/5.1.16/Oracle_VM_VirtualBox_Extension_Pack-5.1.16.vbox-extpack',
  checksum_string  => 'b328f6a2ab8452b41e77f99fc02d3947',
  follow_redirects => true,
}

###############################################################################
# Java
###############################################################################
$bs_java_type = 'jdk' # DO NOT CHANGE

class { 'oracle_java':
  version        => $bs_java_version,
  type           => $bs_java_type,
  add_system_env => true,
}

# get major/minor version numbers
$bs_java_array_version = split($bs_java_version, 'u')
$bs_java_maj_version = $bs_java_array_version[0]
$bs_java_min_version = $bs_java_array_version[1]

# remove extra particle if minor version is 0
$bs_java_version_final = delete($bs_java_version, 'u0')
$bs_java_longversion = $bs_java_min_version ? {
  '0'       => "${bs_java_type}1.${bs_java_maj_version}.0",
  /^[0-9]$/ => "${bs_java_type}1.${bs_java_maj_version}.0_0${bs_java_min_version}",
  default   => "${bs_java_type}1.${bs_java_maj_version}.0_${bs_java_min_version}"
}

file { '/usr/bin/java':
  ensure => 'link',
  target => "/usr/java/${bs_java_longversion}/jre/bin/java",
  require => Class['oracle_java'],
}

###############################################################################
# RVM, Ruby and Gems
###############################################################################
package { 'curl':
  ensure => 'latest',
}

exec { 'import_gpg_key':
  command => 'curl -sSL https://rvm.io/mpapis.asc | gpg2 --import -',
  path    => '/usr/bin:/bin',
  require => Package['curl'],
}

class { 'rvm':
  gnupg_key_id => false,
  require      => Exec['import_gpg_key'],
}

rvm_system_ruby { "ruby-${bs_ruby_version}":
  ensure      => 'present',
  default_use => true,
}

exec { 'update_rubygems':
  command => "/bin/bash --login -c \"gem update --system ${bs_rubygems_version}\"",
  require => Rvm_system_ruby["ruby-${bs_ruby_version}"],
}

rvm_gem { 'bundler':
  name         => 'bundler',
  ruby_version => "ruby-${bs_ruby_version}",
  ensure       => latest,
  require      => Rvm_system_ruby["ruby-${bs_ruby_version}"],
}

rvm_gem { 'librarian-puppet':
  name         => 'librarian-puppet',
  ruby_version => "ruby-${bs_ruby_version}",
  ensure       => latest,
  require      => Rvm_system_ruby["ruby-${bs_ruby_version}"],
}

###############################################################################
# Samba
###############################################################################
$bs_samba_share_root = '/var/samba'
file { $bs_samba_share_root:
  ensure => 'directory',
}

$bs_samba_share_public = "${bs_samba_share_root}/public"
file { $bs_samba_share_public:
  ensure  => 'directory',
  group   => $bs_primary_user_group,
  owner   => $bs_primary_user_name,
  mode    => '0775',
  require => [
    File[$bs_samba_share_root],
    User[$bs_primary_user_name],
    Group[$bs_primary_user_group],
  ],
}

class { 'samba::server':
  bind_interfaces_only => 'no',
  netbios_name         => $facts['hostname'],
  security             => 'user',
  server_string        => $facts['hostname'],
  workgroup            => $bs_samba_workgroup,
}

samba::server::share { 'public':
  path          => $bs_samba_share_public,
  guest_ok      => true,
  browsable     => true,
  writable      => true,
  read_only     => false,
  force_group   => $bs_primary_user_group,
  force_user    => $bs_primary_user_name,
  require       => File[$bs_samba_share_public],
}

samba::server::user { $bs_primary_user_name:
  password => $bs_primary_user_name,
}

###############################################################################
# Maven
###############################################################################
class { 'maven::maven':
  version => $bs_maven_version,
  require => Class['oracle_java'],
}

maven::environment { 'maven-env':
  user                 => $bs_primary_user_name,
  maven_opts           => '-Xmx1024m',
  maven_path_additions => '',
}

###############################################################################
# Gradle
###############################################################################
class { 'gradle':
  version => $bs_gradle_version,
  require => Class['oracle_java'],
}

###############################################################################
# Git
###############################################################################
class { 'git':
  package_manage => false,
}

###############################################################################
# Docker
###############################################################################
class { 'docker':
  version      => $bs_docker_version,
  dns          => $bs_nameservers,
  docker_users => [ $bs_primary_user_name ],
}

###############################################################################
# Users
###############################################################################
user { $bs_primary_user_name:
  ensure  => present,
  require => Group[$bs_primary_user_group],
}

group { $bs_primary_user_group:
  ensure => present,
}

file { "/home/${bs_primary_user_name}":
  ensure => 'directory',
  owner  => $bs_primary_user_name,
  group  => $bs_primary_user_group,
  mode   => '0700',
  require => [
    User[$bs_primary_user_name],
    Group[$bs_primary_user_group],
  ],
}

rvm::system_user { $bs_primary_user_name:
  create  => false,
  require => User[$bs_primary_user_name],
}

git::config { 'user.name':
  value   => $bs_primary_user_fullname,
  user    => $bs_primary_user_name,
  require => [
    Class['git'],
    User[$bs_primary_user_name],
  ]
}

git::config { 'user.email':
  value   => $bs_primary_user_email,
  user    => $bs_primary_user_name,
  require => [
    Class['git'],
    User[$bs_primary_user_name],
  ]
}

git::config { 'core.editor':
  value   => 'atom --wait',
  user    => $bs_primary_user_name,
  require => [
    Class['git'],
    User[$bs_primary_user_name],
  ]
}

git::config { 'color.ui':
  value   => 'true',
  user    => $bs_primary_user_name,
  require => [
    Class['git'],
    User[$bs_primary_user_name],
  ]
}

###############################################################################
# Ordering
###############################################################################
