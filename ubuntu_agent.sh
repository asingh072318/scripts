#!/bin/bash
PATH=/bin:/usr/bin:/sbin:/usr/sbin/:/opt/puppetlabs/bin
codename=`lsb_release -a 2>&1 | grep "Codename" | cut -d ":" -f2 | cut -c 2-`
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0;m'
distro=`hostnamectl | grep "Operating" | cut -d ":" -f2| cut -c 2- | cut -d " " -f1`
case "$OSTYPE" in
  linux*)
    if distro=="Ubuntu"
    then
      if [ "$EUID" -ne 0 ]
      then
        echo -e "[${RED} Run this script as ROOT, exiting now ${NC}]"
	exit
      else
	echo -e "[${GREEN} Running as root ${NC}]"
	echo -e "[${YELLOW} Downloading DEB package to /var/tmp/puppet7.deb ${NC}]"
	wget https://apt.puppet.com/puppet7-release-${codename}.deb -qO /var/tmp/puppet7.deb
	if [ -f /var/tmp/puppet7.deb ]
	then
          echo -e "[${GREEN} Successfully downloaded package to /var/tmp/puppet7.deb ${NC}]"
	  dpkg -i /var/tmp/puppet7.deb
	  apt-get install puppet-agent
	  echo -e "[${GREEN} Successfully installed puppet-agent ${NC}]"
	  (cat /etc/profile | grep puppet >>/dev/null 2>&1)&&{ echo -e "${GREEN} Already Present in PATH"; }||{ echo 'PATH=$PATH:/opt/puppetlabs/bin' >> /etc/profile; source /etc/profile; echo -e "[${GREEN} Successfully added puppet to PATH ${NC}]"; }
	fi
      fi
     else
	  echo -e "[${RED} File not downloaded, Exiting ${NC}]"
     fi
     ;;
  *)
    echo -e "[${RED} OS not Supported ${NC}]"
    exit
    ;;
esac
