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

# Helper Functions and Utility Functions

VERSION=0.1.0
SUBJECT=helper_functions

# _echo_err
# args:
#     An error string to pipe to stderr.
function _echo_err() {
        cat <<< "$@" 1>&2;
}


# _handle_error
# args:
#     _err_cd: Error code value. Exits program if non-zero.
function _handle_error() {
    _err_cd=$(( $1 ))
    if [[ $(($_err_cd)) > 0 ]] ; then
	_echo_err "Program exited with error code: $(($_err_cd))"
	exit $(($_err_cd));
    fi
}


# prepend_dir
# args:
#     _env_var: An environment variable to source from it.
#     _dir_val: prepend the directory to the beginning of the path.
# return:
#     a list containing all of the values assigned to this variable.
function prepend_dir() {
	local _env_var=$1
	local _dir_val=$2
	echo "export ${_env_var}=${_dir_val}\${$_env_var:+:\${$_env_var}}"
}

# append_dir
# args:
#     _env_var: An environment variable to source from it.
#     _dir_val: append the directory to the end of the path.
# return:
#     a list containing all of the values assigned to this variable.
function append_dir() {
        local _env_var=$1
        local _dir_val=$2
        echo "export ${_env_var}=\${$_env_var:+\${$_env_var}:}${_dir_val}"
}

# get_all_vars
# args:
#     _dot_prof: A user's or global ".profile" file.
#     _env_var: An environment variable to source from it.
# return:
#     a list containing all of the values assigned to this variable.
function get_all_vars() {
	local _dot_prof=$1
	local _env_var=$2
	echo "$(echo $(cat $_dot_prof | grep -n '$_env_var' | awk -F= '{print $2}'))"
}

# split_list_on
# args:
#     _split_str: a string to be separated into a list.
#     _sep: separator.
# return:
#     list
function split_list_on() {
    local _split_str=$1
    local _sep=$2
    echo "$(echo ${_split_str} | tr ${_sep} ' ')"
}


# split_to_var_to_list
# args:
#     _env_var: environment variable that stores a path.
# return:
#     string: a list of directories.
function split_var_to_list() {
        local _env_var=$1
       	local _dir_str=${!_env_var}
	echo "$(split_list_on $_dir_str ':')"
}

# is_member_of
# args:
#    _elem: item to search for in list.
#    _list: list to search.
# returns:
#    "true" or "false"
function is_member_of() {
        local _elem=$1
        local _list=$(split_list_on $2 ':')
	local _ret="false"
        for _item in ${_list} ;
	do
     		if [[ "${_item}" == "${_elem}" ]] ; then
		    _ret="true"
		fi
	done
	echo "$_ret"
}
