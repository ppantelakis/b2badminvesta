#!/usr/bin/env bash
[[ -z ${BASH_SOURCE[0]} ]] && lc_script_base_file="$0" || lc_script_base_file="${BASH_SOURCE[0]}"
DIR_SCRIPT="$( cd "$( dirname "${lc_script_base_file}" )" >/dev/null 2>&1 && pwd )"

# B2bAdminVesta Debian installer v.01

#----------------------------------------------------------#
#                  Variables&Functions                     #
#----------------------------------------------------------#
export PATH=$PATH:/sbin
export DEBIAN_FRONTEND=noninteractive
VERSION='debian'
B2BADMINVESTA='/usr/local/b2badminvesta'
mkdir -p "${B2BADMINVESTA}"
ignore_dir="${DIR_SCRIPT}/../ignore"
mkdir -p "${ignore_dir}"
memory=$(grep 'MemTotal' /proc/meminfo |tr ' ' '\n' |grep [0-9])
arch=$(uname -i)
os='debian'
release=$(cat /etc/debian_version|grep -o [0-9]|head -n1)
codename="$(cat /etc/os-release |grep VERSION= |cut -f 2 -d \(|cut -f 1 -d \))"
vestacp="$B2BADMINVESTA/install/$VERSION/$release"

software="
apt-transport-https
ansible
apt-file
bind9
bind9utils
bind9-doc
build-essential
ca-certificates
cifs-utils
dnsutils
gawk
git
glances
gnupg
htop
iftop
ioping
iotop
iptables-persistent
letsencrypt
libcurl4-openssl-dev
libffi-dev
libssl-dev
lsb-release
mailutils
make
manpages-dev
nano
net-tools
nmap
openssl
php5.6-cli php5.6-common php5.6-curl php5.6-dev php5.6-fpm php5.6-gd php5.6-mbstring php5.6-mcrypt php5.6-pgsql php5.6-xdebug php5.6-xml
php7.*-cli php7.*-common php7.*-curl php7.*-dev php7.*-fpm php7.*-gd php7.*-mbstring php7.*-mcrypt php7.*-pgsql php7.*-xdebug php7.*-xml
php8.*-cli php8.*-common php8.*-curl php8.*-dev php8.*-fpm php8.*-gd php8.*-mbstring php8.*-mcrypt php8.*-pgsql php8.*-xdebug php8.*-xml
postfix
python-dnspython
re2c
rsync
screen
software-properties-common
tar
tcl-dev
tcpdump
tk-dev
tree
unzip
vim
wget
wkhtmltopdf"

check_result() {
    if [ $1 -ne 0 ]; then
        echo "Error: $2"
        exit $1
    fi
}


#----------------------------------------------------------#
#                   Install repository                     #
#----------------------------------------------------------#

# Updating system
apt-get -y upgrade
check_result $? 'apt-get upgrade failed'

apt=/etc/apt/sources.list.d

# Installing sury repo
echo "deb http://ftp.de.debian.org/debian stretch main
deb https://packages.sury.org/php/ $(lsb_release -sc) main" > $apt/b2badminvesta.list
wget -qO - https://packages.sury.org/php/apt.gpg | sudo apt-key add - 

#----------------------------------------------------------#
#                     Install packages                     #
#----------------------------------------------------------#

# Update system packages
apt-get update

# Install apt packages
apt-get -y install $software
check_result $? "apt-get install failed"

# Compile cphalcon
cat ${DIR_SCRIPT}/cphalcon/* > ${ignore_dir}/cphalcon.tar.gz
pushd ${ignore_dir}
    rm -rf cphalcon
    tar -xvf cphalcon.tar.gz
    cd cphalcon/build
    ./install --phpize /usr/bin/phpize5.6 --php-config /usr/bin/php-config5.6
    cp ${DIR_SCRIPT}/php/phalcon.ini /etc/php/5.6/mods-available/phalcon.ini
    cp ${DIR_SCRIPT}/php/phalcon.ini /etc/php/5.6/cli/conf.d/phalcon.ini
    cp ${DIR_SCRIPT}/php/phalcon.ini /etc/php/5.6/fpm/conf.d/phalcon.ini
    systemctl restart php5.6-fpm.service
pushd ${ignore_dir}

pushd ${B2BADMINVESTA}
    git clone https://github.com/ppantelakis/b2badminvesta.git ./
    git pull
popd

# Help commands
echo 'Help commands
-- get available php versions and set default
update-alternatives --config php'

# Congrats
echo '======================================================='
echo
echo ' _|      _|  _|_|_|_|    _|_|_|  _|_|_|_|_|    _|_|   '
echo ' _|      _|  _|        _|            _|      _|    _| '
echo ' _|      _|  _|_|_|      _|_|        _|      _|_|_|_| '
echo '   _|  _|    _|              _|      _|      _|    _| '
echo '     _|      _|_|_|_|  _|_|_|        _|      _|    _| '
echo
echo

# EOF
