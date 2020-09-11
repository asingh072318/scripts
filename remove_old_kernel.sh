#!/bin/sh
# shell script to remove all old kernels except current running kernel
# on CentOS systems
# ANKIT SINGH
# 11/09/2020
PATH=/bin:/usr/bin:/sbin:/usr/sbin/
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0;m'
hostnameinfo=`hostnamectl | grep "Operating" | cut -d ":" -f2 | cut -c 2-`

# check if OS is CentOS
case "$OSTYPE" in
  linux*)
    distro=$(echo $hostnameinfo | cut -d " " -f1)
    if distro=="CentOS"
    then
      echo -e "[${GREEN}OS is CentOS${NC}]"
    else
      echo -e "[${RED}OS not Supported ${NC}]"
    fi
    ;;
  *)
    echo -e "[${RED}OS not Supported ${NC}]"
    exit
    ;;
esac

# check if running as root
if [ "$EUID" -ne 0 ]
then
  echo -e "[${RED} Run this script as ROOT, exiting now ${NC}]"
  exit
fi

# check if yum-utils present
(which package-cleanup >>/dev/null 2>&1)&&{
  echo -e "[${GREEN}yum-utils present${NC}]"
}||{
  echo -e "[${RED}yum-utils not present, installing${NC}]"
  yum install -q -y yum-utils
}

# Remove Kernels
echo -e "[${GREEN}Showing current kernels:${NC}]"
rpm -q kernel
echo -e "[${GREEN}Going to clear all old kernels${NC}]"
package-cleanup -y --oldkernels --count=1 >>/dev/null 2>&1
echo -e "[${GREEN}Old kernels cleared, showing current kernels: ${NC}]"
rpm -q kernel
