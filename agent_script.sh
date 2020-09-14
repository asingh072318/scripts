#!/bin/sh
PATH=/bin:/usr/bin:/sbin:/usr/sbin/:/opt/puppetlabs/bin
DATE=`date '+%Y%m%d'`
SERVER=`uname -n`
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0;m'
hostnameinfo=`hostnamectl | grep "Operating" | cut -d ":" -f2 | cut -c 2-`
hostname=`hostname | cut -d '.' -f1`

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

echo -e "${YELLOW} SYSTEM REQUIREMENTS CHECK at $DATE for $SERVER ${NC}"

echo -e "[${YELLOW} Checking if NSLOOKUP PRESENT ${NC}]"

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

echo -e "[${YELLOW} Checking if puppet master in /etc/hosts ${NC}]"
which sed >/dev/null 2>&1 && {
  echo -e "[${YELLOW} Creating backup of /etc/hosts at /etc/hosts.bak${NC}]"
  echo -e "[${YELLOW} Removing all entries of puppet in /etc/hosts ${NC}]"
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

echo -e "[${YELLOW} Begin installation of Puppet Agent ${NC}]"

(rpm -qa | grep puppet5-release-5.0.0-12.el$version.noarch >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} RPM already present ${NC}]"
} || {
  echo -e "[${YELLOW} Adding RPM ${NC}]"
  rpm -Uvh https://yum.puppet.com/puppet5-release-el-$version.noarch.rpm >>/dev/null 2>&1
}

(rpm -qa | grep puppet-agent >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} PUPPET AGENT already present ${NC}]"
} || {
  echo -e "[${YELLOW} Installing AGENT ${NC}]" 
  yum install -d1 -y puppet-agent
  if (rpm -qa | grep puppet-agent >>/dev/null 2>&1)
  then
    echo -e "[${GREEN} Successfully installed Puppet Agent ${NC}]"
  fi
}

if [ -f /etc/puppetlabs/puppet/puppet.conf ]
then
  echo -e "[${YELLOW} Going to Move old puppet.conf to puppet.conf.old ${NC}]"
  mv /etc/puppetlabs/puppet/puppet.conf /etc/puppetlabs/puppet/puppet.conf.old
fi

echo -e "[${YELLOW} Creating new puppet.conf ${NC}]"
cat > /etc/puppetlabs/puppet/puppet.conf << EOF
[main]
stringify_facts = false
vardir = /var/lib/puppet/$hostname.$hostname.root
bucketlist = $vardir/clientbucket
clientbucketdir = $vardir/clientbucket
[agent]
certname = $hostname.$hostname.root
vardir = /var/lib/puppet/$certname
ssldir = $vardir/ssl
daemonize = false
onetime = true
environment = production
server_list = psdevap002.mzp.world
EOF
echo -e "[${GREEN} puppet.conf created ${NC}]"

(systemctl is-active --quiet puppet)&&{
  echo -e "[${GREEN} Puppet Agent already Running${NC}]"
  systemctl restart puppet && echo -e "[${GREEN} Restarted Puppet Agent ${NC}]"
} || {
  echo -e "[${YELLOW} Starting Puppet-agent and enabling it to run on reboot${NC}]"
  /opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true >>/dev/null 2>&1
  systemctl is-active --quiet puppet && echo -e "[${GREEN} PUPPET AGENT is RUNNING ${NC}]" || echo -e "[${RED} PUPPET AGENT is not RUNNING ${NC}]"
}

puppet agent -vt --noop
