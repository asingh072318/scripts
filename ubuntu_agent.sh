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
      fi
    fi
    ;;
  *)
    echo -e "[${RED} OS not Supported ${NC}]"
    exit
    ;;
esac
