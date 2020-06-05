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

# exec 3>&1

VERSION=0.1.0
SUBJECT=exportvar

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
  DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
done
EXPORTVAR_DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
    
# Imports
. ${EXPORTVAR_DIR}/shFlags/shflags
. ${EXPORTVAR_DIR}/helper_functions.sh

export GLOBALENV_DIR=/usr/share

DEFINE_string 'envvar' '' 'The environment variable to add a directory to.' e
DEFINE_string 'dir' '' 'The directory to add to the variable.' d
DEFINE_boolean 'useglobal' true 'Apply this update to the global .globalenv profile instead of your local .profile. The presense of the flag indicates true, otherwise, false.' g
DEFINE_boolean 'prepend' true 'whether to prepend the new directory to the path list rather than append. The presense of the flag indicates true, otherwise, false.' p
DEFINE_boolean 'ignore_dupes' true 'if this path already exists in the variable, use this flag to ignore the error and add anyway.' i
DEFINE_string 'write' 'add' '[add | replace | add-static] The write mode: May be an incremental update "add" (default) in which the additional path is added to the variable incrementally,\
 \nadd-static, which sets the variable equal to a static string with no references, \nor "replace" which simply replaces the value of the variable with the argument to --dir. In this case, the [-p | --prepend] flag is ignored. ' w

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

export ENVVAR_VAL="$FLAGS_envvar"
export DIR_VAL="$FLAGS_dir"
export USE_GLOBAL="$FLAGS_useglobal"
export WRITE_MODE="$FLAGS_write"
export PREPEND="$FLAGS_prepend"
export IGNORE_DUPES="${FLAGS_ignore_dupes}"

# --- Locks -------------------------------------------------------
LOCK_FILE=/tmp/${SUBJECT}.lock

if [ -f "$LOCK_FILE" ]; then
    echo "Script is already running"
    exit
fi

trap "rm -f $LOCK_FILE" EXIT
touch $LOCK_FILE

#-----------------------------------------------------------------

if [[ "$USE_GLOBAL" == "0" ]] ; then 
    _echo_err "Looking for $DOT_PROFILE..."
    _echo_err ""
    export USER=$(whoami)
    if [[ "${USER}" == "root" ]] ; then
	export USER_HOME="/root"
    else
	export USER_HOME="/home/${USER}"
    fi
    if [ -f "${USER_HOME}/.profile" ] ; then
	export DOT_PROFILE="$USER_HOME/.profile"
	_echo_err ".profile: $DOT_PROFILE found."
    elif [ -f "${USER_HOME}/.bash_profile" ] ; then
	export DOT_PROFILE="$USER_HOME/.bash_profile"
	_echo_err ".bash_profile $DOT_PROFILE found."
    else
	_echo_err ".profile not found in /home/$USER. "
	_handle_error "1"
    fi
else
    export DOT_PROFILE="$GLOBALENV_DIR/.globalenv"
    if [[ -f "$DOT_PROFILE" ]] ; then
	_echo_err ".globalenv found."
    else
	_echo_err "No .globalenv file was detected on your system. Installing one now."
	$("cp ${EXPORTVAR_DIR}/template/.globalenv $GLOBALENV_DIR")
    fi
fi

_echo_err "envvar: $ENVVAR_VAL"
_echo_err "dir: $DIR_VAL"
_echo_err "useglobal: $USE_GLOBAL"
_echo_err "write: $WRITE_MODE"
if [[ "$WRITE_MODE" != "replace" ]] ; then    
    _echo_err "prepend: $PREPEND"
    _echo_err "ignore_dupes: $IGNORE_DUPES"  
fi

# -- Functions ---------------------------------------------------------



# add_to_profile
# args:
#      dot_prof: file containing the profile of the user or the globalenv profile.
#      _env_var: name of the path variable.
#      _dir_val: directory string to concatenate to the path variable.
# returns:
#	0 on success. 
function add_to_profile() {

        local dot_prof=$1
	local _env_var=$2
	local _dir_val=$3

        . $dot_prof

	local _dir_str=${!_env_var}

        _echo_err "Current value: "
	_echo_err ""
        _echo_err "$_env_var = ${_dir_str}"
	_echo_err ""

	local _dir_list="$(split_var_to_list $_env_var)"
	local _dedup="${_dir_val}"

	for _dir in ${_dir_list} ;
	do
		_echo_err "checking $_dir ..."
		if [[ "${_dir_val}" == "${_dir}" ]] ; then
		    if [[ "$IGNORE_DUPES" == "0" ]] ; then
			_echo_err "Warning: This variable already contains the requested directory."
			_handle_error '0'
		    else
			_echo_err "Error: This variable already contains the requested directory."
			_handle_error '1'
		    fi 
		else
		    if [[ "$(is_member_of $_dir $_dedup)" == "false" ]] ; then  
			
			if [[ "$PREPEND" == "1" ]] ; then
        		    _dedup="${_dedup}:${_dir}"
			else
			    _dedup="${_dir}:${_dedup}"
			fi
		    fi	
		fi
	done

       	
	if [[ "$WRITE_MODE" == "replace" ]] ; then
	    export_str="export ${_env_var}=${dir_val}"
	else
	    if [[ "$PREPEND" == "1" ]] ; then
        	export_str="$(prepend_dir $_env_var $dir_val)"
	    else
		export_str="$(append_dir $_env_var $dir_val)"
	    fi
	    if [[ "$WRITE_MODE" == "add-static" ]] ; then
		$(${export_str})
		export_str="export ${_env_var}=${!_env_var}"
	    fi
	fi
	
        write_to_profile "$export_str"

        _echo_err "echo \"$export_str\" >> $dot_prof"
        _echo_err ""

	echo "0"
        
}

## add_to_profile_main
#  args:
#  	dir_val: A string containining the string value of the directory to be added.
#  returns:
#  	0 if success, 1 otherwise.
function add_to_profile_main() {
    dir_val=$1
    _echo_err "Adding ${_dir} ..."
    _echo_err "$(get_all_vars ${DOT_PROFILE} $ENVVAR_VAL $dir_val)"
    _handle_error "$(add_to_profile $DOT_PROFILE $ENVVAR_VAL $dir_val)"    
}

function write_to_profile() {
    _msg=$1
    echo "$_msg" >> ${DOT_PROFILE}
}



## Main ------------------------------------------------------- #

header_str="#--------- Added this line from $SUBJECT v-$VERSION on $(date). ---------#"

write_to_profile "$header_str"

if [[ "$DIR_VAL" =~ "*:*"  ]] ; then
	_add_dirs="$(split_list_on $DIR_VAL ':')"
	for _dir in ${_add_dirs} ; 
	do
		_handle_error "$(add_to_profile_main $_dir)"
	done
else
	_handle_error "$(add_to_profile_main $DIR_VAL)"
fi

footer_str="#------------------------------------------------------------------------#"

write_to_profile $footer_str
