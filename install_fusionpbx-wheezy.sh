#!/bin/bash
#
# The MIT License (MIT)
#
# Copyright (c) <2014> <Michael J. Mavroudis - michael.j.mavroudis@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#

function use {
	echo ""
	echo "Usage: $0"
	echo ""
	echo "  Select a database (Required)"
	echo "    --db=sqlite for SQLite"
	echo "    --db=postgresql for PostgreSQL"
	echo ""
	echo "  Select a webserver (Required)"
	echo "    --web=apache for Apache"
	echo "    --web=nginx for NGINX"
	echo ""
	exit 1
}

# DEFAULTS

CONFOPT="--prefix=/usr/local/freeswitch --enable-zrtp"

# OPTIONS CHECKS

if [ $# -lt 2 ]; then
	use
fi

for opt in "$@"; do
	optkey=$(echo $opt | cut -f 1 -d '=')
	optval=$(echo $opt | cut -f 2 -d '=')
	if [ $optkey == '--db' ]; then
		db=$optval
	fi
	if [ $optkey == '--web' ]; then
		web=$optval
	fi
done

if [ -z $(echo $db | egrep '(sqlite|postgresql)') ]; then
	use
fi

if [ -z $(echo $web | egrep '(apache|nginx)') ]; then
	use
fi

# CHECK CONNECTIVITY

if [ -n "`ping -c 2 8.8.8.8 | grep '100% packet loss'`" ]; then
	echo "This script requires internet connectivity"
	exit
fi

# SYSTEM UPDATE

apt-get update
apt-get -y upgrade

# CHECK ENVIRONMENT

if [ $EUID -ne 0 ]; then
	echo "This script must be run as root"
	exit
fi

if [ -z "`dpkg -l base-files | grep wheezy`" ]; then
	echo "This script was inteneded for Debian Wheezy"
	exit
fi

# INSTALLING DEBIAN PACKAGES

APACHE="apache2 apache2-mpm-prefork apache2-utils apache2.2-bin apache2.2-common libapache2-mod-php5 libapr1 libaprutil1 libaprutil1-dbd-sqlite3 libaprutil1-ldap"
NGINX="nginx nginx-full nginx-common php5-fpm php5-common php5-gd php-pear php5-memcache php-apc php5-json libxslt1.1 libgd2-xpm"

case "$web" in
	apache)
		if [ -n "`which nginx`" ]; then
			update-rc.d nginx disable
		fi
		if [ -n "`pidof nginx`" ]; then
			service nginx stop
		fi
		apt-get install -y $APACHE
	;;
	nginx)
		if [ -n "`which apache2`" ]; then
			update-rc.d apache2 disable
		fi
		if [ -n "`pidof apache2`" ]; then
			service apache2 stop
		fi
		apt-get install -y $NGINX
	;;
esac

DEBBASE="git-core subversion build-essential autoconf automake libtool libncurses5 libncurses5-dev make libjpeg8-dev pkg-config libcurl4-openssl-dev libexpat1-dev libgnutls-dev libtiff4-dev libx11-dev libssl-dev python2.7-dev zlib1g-dev libzrtpcpp-dev libasound2-dev libogg-dev libvorbis-dev libperl-dev libgdbm-dev libdb-dev python-dev uuid-dev bison ssl-cert"
DEBPSQL="postgresql-9.1 postgresql-client-9.1 postgresql-client-common postgresql-common libpq5 libpq-dev php5-pgsql"
DEBSQLL="libsqlite3-0 libsqlite0 sqlite php5-sqlite php-db"

case "$db" in
	sqlite)
		apt-get install -y $DEBBASE $DEBSQLL
	;;
	postgresql)
		CONFOPT="${CONFOPT} --enable-core-pgsql-support"
		apt-get install -y $DEBBASE $DEBPSQL
	;;
esac
