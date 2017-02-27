# Build Server

## Description

A vagrant machine that provides a full build server environment for sandboxed testing.

The included scripts can be used to provision a physical machine.

### Contains

* Docker
* Git
* Gradle
* Java
* Maven
* Puppet
* Rvm
* Samba

The following are installed but will only work on a physical machine:

* Packer
* Vagrant
* VirtualBox

## Requires

* vagrant plugin vagrant-triggers
* vagrant plugin vagrant-hostsupdater
* vagrant plugin vagrant-reload

## Verified Working With

* vagrant 1.9.1
* VirtualBox 5.1.14
