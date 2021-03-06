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


SOURCE="${PWD}"

# Imports
. ${SOURCE}/helper_functions.sh

function find_lib_depth_1() {
    
    local _LIBNAME=${1}
    _ALL_NEEDED=${2}
    _FILENAME=$(basename "$_LIBNAME")
    
    while [ -h "$_LIBNAME" ]; do
        DIR="$( cd -P "$( dirname "$_LIBNAME" )" >/dev/null 2>&1 && pwd )"
        _LIBNAME="$(readlink "$_LIBNAME")"
        [[ $_LIBNAME != /* ]] && _LIBNAME="$DIR/$_LIBNAME"
    done
    
    _FILENAME="$( cd -P "$( dirname "$_LIBNAME" )" >/dev/null 2>&1 && pwd )/$_FILENAME"
    _echo_err "$_FILENAME"
    
    local buffer="/tmp/.expvbuf" && touch "${buffer}"
    
    if [[ -f "${_FILENAME}" ]] ; then
	_ALL_NEEDED="$(sudo readelf -d ${_FILENAME} | grep NEEDED | sed -e 's/0x0000000000000001 (NEEDED)             Shared library\: \[//g' | sed -e 's/\]//g') ${_ALL_NEEDED}"
	
	for _lib in  $_ALL_NEEDED  ;
	do
	    _echo_err "Looking for $_lib"
	    _finds="$(sudo find /usr -iname $_lib -printf '%p\n')"
	    if [ -n "$_finds" ] ; then
		echo "$_finds" >> $buffer
            	_echo_err "Found match(es):" && _echo_err "$_finds"
	    else
	    	_echo_err "No matches found!"
	    fi
	done
    else
	_echo_err "Not found: $_FILENAME"
    fi
    
    _echo_err "make set"
    make_set $(read_buffer $buffer)

    rm -rf $buffer
    
}

find_lib_depth_1 "$(which $1)" ""
