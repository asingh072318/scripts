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

# check if net-tools exists
(rpm -qa | grep net-tools >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} net-tools already present ${NC}]"
} || {
  echo -e "[${RED} net-tools not found ${NC}]"
  echo -e "[${YELLOW} installing net-tools ${NC}]"
  yum install -d1 -y net-tools
  (rpm -qa | grep net-tools >>/dev/null 2>&1)&&{
    echo -e "[${GREEN} net-tools installed ${NC}]"
  } || {
    echo -e "[${RED} could not install net-tools, exiting ${NC}]"
    exit
  }
}

# check if epel-release exists
(rpm -qa | grep epel-release >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} epel-release already present ${NC}]"
} || {
  echo -e "[${RED} epel-release not found ${NC}]"
  echo -e "[${YELLOW} installing epel-release ${NC}]"
  yum install -d1 -y epel-release
  (rpm -qa | grep epel-release >>/dev/null 2>&1)&&{
    echo -e "[${GREEN} epel-release installed ${NC}]"
  } || {
    echo -e "[${RED} could not install epel-release, exiting ${NC}]"
    exit
  }
}

# check and install ngninx
(which nginx >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} nginx already present ${NC}]"
} || {
  echo -e "[${RED} nginx not found ${NC}]"
  echo -e "[${YELLOW} installing nginx ${NC}]"
  yum install -d1 -y nginx
  (rpm -qa | grep nginx >>/dev/null 2>&1)&&{
    echo -e "[${GREEN} nginx installed ${NC}]"
  } || {
    echo -e "[${RED} could not install nginx, exiting ${NC}]"
    exit
  }
}

# check and start nginx service
(systemctl is-active nginx >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} nginx already running ${NC}]"
} || {
  echo -e "[${RED} nginx not running ${NC}]"
  echo -e "[${YELLOW} starting nginx service ${NC}]"
  systemctl start nginx
  systemctl enable nginx
  (systemctl is-active nginx >>/dev/null 2>&1)&&{
    echo -e "[${GREEN} nginx running ${NC}]"
  } || {
    echo -e "[${RED} could not start nginx, exiting ${NC}]"
    exit
  }
}

# Add PORT 80 to firewall-cmd
echo -e "[${YELLOW} Adding PORT 80 to firewall-cmd ${NC}]"
firewall-cmd --zone=public --permanent --add-service=http
firewall-cmd --reload

# Add PORT 443 to firewall-cmd
echo -e "[${YELLOW} Adding PORT 443 to firewall-cmd ${NC}]"
firewall-cmd --zone=public --permanent --add-service=https
firewall-cmd --reload

# check and install createrepo, yum-utils
(rpm -qa | grep yum-utils >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} yum-utils already present ${NC}]"
} || {
  echo -e "[${RED} yum-utils not found ${NC}]"
  echo -e "[${YELLOW} installing yum-utils ${NC}]"
  yum install -d1 -y yum-utils
  (rpm -qa | grep yum-utils >>/dev/null 2>&1)&&{
    echo -e "[${GREEN} yum-utils installed ${NC}]"
  } || {
    echo -e "[${RED} could not install yum-utils, exiting ${NC}]"
    exit
  }
}

(rpm -qa | grep createrepo >>/dev/null 2>&1)&&{
  echo -e "[${GREEN} createrepo already present ${NC}]"
} || {
  echo -e "[${RED} createrepo not found ${NC}]"
  echo -e "[${YELLOW} installing createrepo ${NC}]"
  yum install -d1 -y createrepo
  (rpm -qa | grep createrepo >>/dev/null 2>&1)&&{
    echo -e "[${GREEN} createrepo installed ${NC}]"
  } || {
    echo -e "[${RED} could not install createrepo, exiting ${NC}]"
    exit
  }
}

# create directories for repository
if [ -d /var/www/html/repos ]
then
  echo -e "[${GREEN} PARENT directory present, checking and creating children directories  ${NC}]"
  if [ ! -d /var/www/html/repos/base ]
  then
    mkdir /var/www/html/repos/base
  fi
  if [ ! -d /var/www/html/repos/centosplus ]
  then
    mkdir /var/www/html/repos/centosplus
  fi
  if [ ! -d /var/www/html/repos/extras ]
  then
    mkdir /var/www/html/repos/extras
  fi
  if [ ! -d /var/www/html/repos/updates ]
  then
    mkdir /var/www/html/repos/updates
  fi
else
  echo -e "[${YELLOW} Creating /var/www/html/repos and children directories ${NC}]"
  mkdir -p /var/www/html/repos/{base,centosplus,extras,updates}
fi

# syncronizing repos to local directories
echo -e "[${Yellow} Starting repo Syncronization ${NC}]"
reposync -g -l -d -m --repoid=base --newest-only --download-metadata --download_path=/var/www/html/repos/
reposync -g -l -d -m --repoid=centosplus --newest-only --download-metadata --download_path=/var/www/html/repos/
reposync -g -l -d -m --repoid=extras --newest-only --download-metadata --download_path=/var/www/html/repos/
reposync -g -l -d -m --repoid=updates --newest-only --download-metadata --download_path=/var/www/html/repos/
echo -e "[${GREEN} Repo Sync Complete ${NC}]"

# create repodata
echo -e "[${Yellow} CREATING REPODATA ${NC}]"
createrepo -g comps.xml /var/www/html/repos/base/
createrepo -g comps.xml /var/www/html/repos/centosplus/
createrepo -g comps.xml /var/www/html/repos/extras/
createrepo -g comps.xml /var/www/html/repos/updates/

# configure nginx to show repo
echo -e "[${Yellow} CREATING CONFFILE ${NC}]"
cat >> /etc/nginx/conf.d/repos.conf < EOF
server {
 listen   80;
 server_name  repos.centos.mzp;	#change  test.lab to your real domain 
 root   /var/www/html/repos;
 location / {
   index  index.php index.html index.htm;
   autoindex on;	#enable listing of directory index
 }
}
EOF
echo -e "[${Yellow} RESTARTING NGINX SERVER ${NC}]"
systemctl restart nginx
echo -e "[${GREEN} Yum repository ready, goto repos.centos.mzp ${NC}]"
