#!/bin/bash

# MIT License

# Copyright (c) [2020] [Tristan Miano] [jacobeus@protonmail.com]

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

VERSION=0.1.0
SUBJECT=exportvar

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
EXPORTVAR_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"


. ${EXPORTVAR_DIR}/shFlags/shflags

USAGE="Usage: exportvar v-$VERSION --help | [-e | --envvar [variable_name]] [-d | --dir [directory_name]] [-g | --useglobal | --nouseglobal] "

# --- Option processing --------------------------------------------
#if [ $# == 0 ] ; then
#    echo $USAGE
#    exit 1;
#fi
#
#if [ $1 == '--help' ] ; then
#    echo $USAGE
#    exit 0;
#fi

DEFINE_string 'envvar' '' 'The environment variable to add a directory to.' e
DEFINE_string 'dir' '' 'The directory to add to the variable.' d
DEFINE_boolean 'useglobal' true 'Apply this update to the global .globalenv profile instead of your local .profile. The presense of the flag indicates true, otherwise, false.' g
DEFINE_boolean 'prepend' true 'whether to prepend the new directory to the path list rather than append. The presense of the flag indicates true, otherwise, false.' p
DEFINE_boolean 'ignore_dupes' true 'if this path already exists in the variable, use this flag to ignore the error and add anyway.' i

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

export ENVVAR_VAL=$FLAGS_envvar
export DIR_VAL=$FLAGS_dir
export USE_GLOBAL=$FLAGS_useglobal
export PREPEND=$FLAGS_prepend
export IGNORE_DUPES="${FLAGS_ignore_dupes}"

echo "envvar: $ENVVAR_VAL"
echo "dir: $DIR_VAL"
echo "useglobal: $USE_GLOBAL"
echo "prepend: $PREPEND"
echo "ignore_dupes: $IGNORE_DUPES"

# --- Locks -------------------------------------------------------
LOCK_FILE=/tmp/${SUBJECT}.lock

if [ -f "$LOCK_FILE" ]; then
echo "Script is already running"
exit
fi

trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE

# -- Functions ---------------------------------------------------------


function prepend_dir() {
	_env_var=$1
	_dir_val=$2
	echo "export ${_env_var}=${_dir_val}\${$_env_var:+:\${$_env_var}}"
}

function append_dir() {
        _env_var=$1
        _dir_val=$2
        echo "export ${_env_var}=\${$_env_var:+\${$_env_var}:}${_dir_val}"
}


function get_all_vars() {
	dot_prof=$1
	envvar_val=$2
	dir_list=$(echo $(cat $dot_prof | grep -n '$envvar_val' | awk -F= '{print $2}'))
	echo $dir_list
}

function split_var_to_list() {
	_env_var=$1
	_dir_str=${!_env_var}
	_dir_list=$(echo ${_dir_str} | tr ':' ' ')
	echo $_dir_list
}

## add_to_profile
#  args:
#  	dot_prof: file containing the profile of the user or the globalenv profile.
#	envvar_val: name of the path variable.
#	dir_val: path to concatenate to the parh variable.
# returns:
#	0 on success, 1 otherwise. 
function add_to_profile() {
        dot_prof=$1
	envvar_val=$2
	dir_val=$3

        . $dot_prof

	_dir_str=${!envvar_val}

        echo "Current value: "
	echo ""
        echo "$envvar_val = ${_dir_str}"
	echo ""

	_dir_list=$(split_var_to_list $envvar_val)

	for _dir in ${_dir_list} ;
	do
		echo "checking $_dir ..."
		if [[ "${dir_val}" == "${_dir}" ]] ; then
		    if [[ "$IGNORE_DUPES" == "0" ]] ; then
			echo "This variable already contains the requested directory. Quitting."
			exit 0;
		    fi
		fi
	done 

        header_str="#--------- Added this line from $SUBJECT v-$VERSION on $(date). ---------#"

	echo "" >> ${dot_prof}
        echo "$header_str" >> ${dot_prof}

	if [[ "$PREPEND" == "1" ]] ; then
        	export_str=$(prepend_dir $envvar_val $dir_val)
	else
		export_str=$(append_dir $envvar_val $dir_val)
	fi

        echo "$export_str" >> ${dot_prof}
        echo "#---------" >> ${dot_prof}

        echo "echo \"$export_str\" >> $dot_prof"
        echo ""
        echo "sourcing your .profile ... "

	. ${dot_prof}

	return 0;
}

## add_to_profile_main
#  args:
#  	dir_val: A string containining the string value of the directory to be added.
#  returns:
#  	exit 0 if success, 1 otherwise.
function add_to_profile_main() {

	dir_val=$1

	if [ $USE_GLOBAL == 1 ]  ; then
		echo "$(get_all_vars /usr/share/.globalenv $ENVVAR_VAL $dir_val)"
		add_to_profile /usr/share/.globalenv $ENVVAR_VAL $dir_val
		exit 0;
	else
	    USER=$(whoami)
	    if [[ "${USER}" == "root" ]] ; then
		DOT_PROFILE="/root/.profile"
	    else
		DOT_PROFILE="/home/${USER}/.profile"
	    fi
	    echo "Looking for $DOT_PROFILE..."
	    echo ""
	    
	    if [ -f "$DOT_PROFILE" ] ; then
		echo ".profile: $DOT_PROFILE found."
		echo "$(get_all_vars /usr/share/.globalenv $ENVVAR_VAL $dir_val)"
		add_to_profile $DOT_PROFILE $ENVVAR_VAL $dir_val
		exit 0; 
	    else
		echo ".profile not found in /home/$USER. "
		exit 1;
	    fi
	fi

}

## Main ------------------------------------------------------- #
if [[ "$DIR_VAL" =~ ":"  ]] ; then
	_add_dirs=$(split_var_to_list $DIR_VAL)
	for _dir in ${_add_dirs} ; 
	do
		add_to_profile_main $_dir
	done
else
	add_to_profile_main $DIR_VAL
fi


