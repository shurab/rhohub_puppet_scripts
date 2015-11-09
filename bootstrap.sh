#!/usr/bin/env bash

# update & install
apt-get update

wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb -o /dev/null
dpkg -i puppetlabs-release-trusty.deb
apt-get update && apt-get -y install git puppet
puppet module install puppetlabs-stdlib
puppet module install maestrodev-rvm

# setup hostname
HOSTNAME='rho-builder'
sudo su -c "echo $HOSTNAME >> /etc/hosts" && \
sudo hostname $HOSTNAME && sudo su -c 'echo $HOSTNAME > /etc/hostname'

# disable SSH StrictHostKeyChecking option"
echo "disable SSH StrictHostKeyChecking option"
cd /home/vagrant/.ssh
echo -e "Host github.com\n\tStrictHostKeyChecking no\n" >> config
chown vagrant:vagrant config
