#!/bin/sh -e
#
#  Copyright 2021, Roger Brown
#
#  This file is part of rhubarb pi.
#
#  This program is free software: you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published by the
#  Free Software Foundation, either version 3 of the License, or (at your
#  option) any later version.
# 
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
#  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
#  more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>
#
# $Id: package.sh 81 2021-12-04 16:40:58Z rhubarb-geek-nz $
#

APPNAME=rhubarb-pi-dpkg-deb

cleanup()
{
	rm -rf data
}

cleanup

trap cleanup 0

SVNVER=$( echo $( svn log -q . | grep -v "\-------" | wc -l )-1 | bc )
VERSION="1.0.$SVNVER"
DPKGARCH=all
DEPENDS="dpkg (<< 1.19)"
MAINTAINER="rhubarb-geek-nz@users.sourceforge.net"

mkdir -p data/usr/local/bin data/DEBIAN

cp ./dpkg-deb-stretch.sh data/usr/local/bin/dpkg-deb

PACKAGE_NAME="$APPNAME"_"$VERSION"_"$DPKGARCH".deb

(
	cat <<EOF
Package: $APPNAME
Version: $VERSION
Architecture: $DPKGARCH
Maintainer: $MAINTAINER
Depends: $DEPENDS
Section: admin
Priority: extra
Description: dpkg-deb extension for stretch and before
EOF
) > data/DEBIAN/control

rm -rf "$PACKAGE_NAME"

./dpkg-deb-stretch.sh --root-owner-group --build data "$PACKAGE_NAME"

ar t "$PACKAGE_NAME"

dpkg-deb -c "$PACKAGE_NAME"

dpkg-deb -I "$PACKAGE_NAME"
