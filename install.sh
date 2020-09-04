#!/bin/bash

# Copyright (C) 2020  Tristan Miano <jacobeus@protonmail.com>

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

if [ -z "${1}" ] ; then
	PREFIX="/usr/local"
else
	PREFIX="${1}"
fi

if [ ! -f "${PWD}/exportvar.sh" ] ; then
	echo "You can only run this script from the exportvar directory."
	exit 1;
fi

echo "Installing to: ${PREFIX}/exportvar"

if [ ! -d ${PREFIX}/exportvar ] ; then
	mkdir -p ${PREFIX}/exportvar
fi

cp -r ${PWD} ${PREFIX}

ln -sf ${PREFIX}/exportvar/exportvar.sh ${PREFIX}/bin/exportvar
ln -sf ${PREFIX}/exportvar/.beacon ${PREFIX}/bin/exportvar_root
ln -sf ${PREFIX}/exportvar/scripts/.beacon ${PREFIX}/bin/exportvar_scripts

echo "exportvar: $(which exportvar) -> $(exportvar_root)"
echo "to get script dir, run 'exportvar_scripts' : $(exportvar_scripts)"
