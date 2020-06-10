export SEARCH_TERM=${1}

if [ "${2}" ]; then
    	export EXCLUDES=" | grep -v -E ${2} "
else
	export EXCLUDES=""
fi

sudo dnf list available | eval "grep -i -E ${SEARCH_TERM} ${EXCLUDES}"  \
	| grep -E 'noarch|x86_64' \
	| sed -e 's/.x86_64 //g' \
	| sed -e 's/.noarch //g' \
	| sed -E 's/ [a-zA-Z0-9\:\.\-]+//g'
