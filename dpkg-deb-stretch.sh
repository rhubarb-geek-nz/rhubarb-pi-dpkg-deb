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
# $Id: dpkg-deb-stretch.sh 81 2021-12-04 16:40:58Z rhubarb-geek-nz $
#

# --build points to directory with contents and special DEBIAN folder containing control entries
# --root-owner-group is magic flag that is not supported

OUTPUT_FILE=
BUILD_DIR=
ROOT_FLAG=false
LAST_FLAG=
ORIGINAL=/usr/bin/dpkg-deb
TMPDIR=/tmp/$(basename $0).$$.d
UNKNOWN_ARG=false

cleanup()
{
	if test -d "$TMPDIR"
	then
		rm -rf "$TMPDIR"
	fi
}

for d in "$@"
do
	if test -z "$LAST_FLAG"
	then
		case "$d" in 
			--build)
				LAST_FLAG="$d"
				;;
			--root-owner-group )
				ROOT_FLAG=true
				;;
			-* )
				UNKNOWN_ARG=true
				;;
			* )
				if test -z "$OUTPUT_FILE"
				then
					OUTPUT_FILE="$d"
				else
					UNKNOWN_ARG=true
				fi
				;;
		esac
	else
		case "$LAST_FLAG" in
			--build )
				BUILD_DIR="$d"
				;;
			* )
				echo error "$LAST_FLAG"
				UNKNOWN_ARG=true
				false
				;;
		esac

		LAST_FLAG=	
	fi	
done

if $UNKNOWN_ARG
then
	ROOT_FLAG=false
fi

if $ROOT_FLAG
then
	test -d "$BUILD_DIR"
	test -n "$OUTPUT_FILE"

	"$ORIGINAL" --build "$BUILD_DIR" "$OUTPUT_FILE"

	CONTROL_NAME=$( ar t "$OUTPUT_FILE" | grep control )
	DATA_NAME=$( ar t "$OUTPUT_FILE" | grep data )

	trap cleanup 0

	mkdir "$TMPDIR"	

	ar t "$OUTPUT_FILE" | while read N
	do
		case "$N" in
			"data.tar.gz" )
				ar p "$OUTPUT_FILE" "$N" | ( mkdir -p "$TMPDIR/data"; cd "$TMPDIR/data" ; tar xfz - )
				;;
			"data.tar.xz" )
				ar p "$OUTPUT_FILE" "$N" | ( mkdir -p "$TMPDIR/data"; cd "$TMPDIR/data" ; tar xfJ - )
				;;
			"control.tar.gz" )
				ar p "$OUTPUT_FILE" "$N" | ( mkdir -p "$TMPDIR/control"; cd "$TMPDIR/control" ; tar xfz - )
				;;
			"control.tar.xz" )
				ar p "$OUTPUT_FILE" "$N" | ( mkdir -p "$TMPDIR/control"; cd "$TMPDIR/control" ; tar xfJ - )
				;;
			* )
				ar p "$OUTPUT_FILE" "$N" > "$TMPDIR/$N"
				;;
		esac
	done

	(
		set -e

		cd "$TMPDIR"
		
		case "$CONTROL_NAME" in
			control.tar.gz )
				( cd control; tar --owner=0 --group=0 --gz --create --file - . ) > "$CONTROL_NAME"
				;;
			control.tar.xz )
				( cd control; tar --owner=0 --group=0 --xz --create --file - . ) > "$CONTROL_NAME"
				;;
			* )
				;;
		esac

		case "$DATA_NAME" in
			data.tar.gz )
				( cd data; tar --owner=0 --group=0 --gz --create --file - . ) > "$DATA_NAME"
				;;
			data.tar.xz )
				( cd data; tar --owner=0 --group=0 --xz --create --file - . ) > "$DATA_NAME"
				;;
			* )
				;;
		esac

		rm -rf data
		rm -rf control

		NAME=$(basename "$OUTPUT_FILE")

		ar r "$NAME" debian-binary "$CONTROL_NAME" "$DATA_NAME"  >/dev/null

		cat "$NAME"

	) > "$OUTPUT_FILE"
else
	exec "$ORIGINAL" "$@"
fi
