#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin/:/opt/puppetlabs/bin
DATE=`date '+%Y%m%d'`
SERVER=`uname -n`
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0;m'
hostnameinfo=`hostnamectl | grep "Operating" | cut -d ":" -f2 | cut -c 2-`

case "$OSTYPE" in
  linux*)
    distro=$(echo $hostnameinfo | cut -d " " -f1)
    if distro=="CentOS"
    then
      version=$(echo $hostnameinfo | cut -d " " -f3)
      if [[ $version -ne 6 ]] && [[ $version -ne 7 ]]
      then
        echo -e "[${RED}CentOS Version $version not Supported${NC}]"
        exit
      fi
    else
      echo -e "[${RED} Distro not Supported ${NC}]"
    fi
    echo -e "[${GREEN}USING CentOS Version ${version} ${NC}]"
    ;;
  *)
    echo -e "[${RED} OS not Supported ${NC}]"
    exit
    ;;
esac
  
# check if script run as root
if [ "$EUID" -ne 0 ]
then
  echo -e "[${RED} Run this script as ROOT, exiting now ${NC}]"
  exit
else
  echo -e "[${GREEN} Running as root ${NC}]"
fi

echo -e "${GREEN} SYSTEM REQUIREMENTS CHECK at $DATE for $SERVER ${NC}"

echo -e "[${GREEN} Checking if NSLOOKUP PRESENT ${NC}]"

if (which nslookup >/dev/null 2>&1)
then
  echo -e "[${GREEN} NSLOOKUP Exists ${NC}]"
else
  echo -e "[${RED} NSLOOKUP not found, starting installation ${NC}]"
  yum install -q -y bind-utils
  if (which nslookup >/dev/null 2>&1)
  then
    echo -e "[${GREEN} NSLOOKUP setup done ${NC}]"
  else
    echo -e "[${RED} Issue with YUM, please fix, exiting now] ${NC}"
    exit
  fi
fi

echo -e "[${GREEN} Checking if puppet master in /etc/hosts ${NC}]"
which sed >/dev/null 2>&1 && {
  echo -e "[${GREEN}Creating backup of /etc/hosts at /etc/hosts.bak${NC}]"
  echo -e "[${GREEN}Removing all entries of puppet in /etc/hosts ${NC}]"
  sed -i.bak '/puppet/d' /etc/hosts
  echo "10.0.2.7 puppet puppet-master" >> /etc/hosts
  echo -e "[${GREEN} Appended Puppet Master to /etc/hosts ${NC}]"
} || {
  echo -e "[${RED} SED not found, please install sed ${NC}]"
}

if (timeout 1 bash -c "</dev/tcp/10.0.2.7/8140" >/dev/null 2>&1)
then
  echo -e "[${GREEN} SUCCESSFUL CONNECTION with PUPPET MASTER ${NC}]"
else
  echo -e "[${RED} NO ROUTE to PUPPET MASTER, please check your FIREWALL] ${NC}"
fi

echo -e "[${GREEN} Begin installation of Puppet Agent ${NC}]"

(rpm -qa | grep puppet5-release-5.0.0-12.el$version.noarch >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} RPM already present ${NC}]"
} || {
  echo -e "[${GREEN} Adding RPM ${NC}]"
  rpm -Uvh https://yum.puppet.com/puppet5-release-el-$version.noarch.rpm >>/dev/null 2>&1
}

(rpm -qa | grep puppet-agent >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} PUPPET AGENT already present ${NC}]"
} || {
  echo -e "[${GREEN} Installing AGENT ${NC}]" 
  yum install -q -y puppet-agent
  if (rpm -qa | grep puppet-agent >>/dev/null 2>&1)
  then
    echo -e "[${GREEN} Successfully installed Puppet Agent ${NC}]"
  fi
}

echo -e "[${GREEN} Starting Puppet-agent and enabling it to run on reboot${NC}]"
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true >>/dev/null 2>&1
systemctl is-active --quiet puppet && echo -e "[${GREEN} PUPPET AGENT is RUNNING ${NC}]" || echo -e "[${RED}PUPPET AGENT is not RUNNING${NC}]"
