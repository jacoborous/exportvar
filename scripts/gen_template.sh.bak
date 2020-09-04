#!/bin/bash


WEB2PDF_ROOT=$(web2pdf_root)
WEB2PDF_SCRIPTS=$(web2pdf_scripts)

LICENSE=${WEB2PDF_SCRIPTS}/license.txt
YEAR="2020"
AUTHOR="Tristan Miano"
EMAIL="jacobeus@protonmail.com"
SUBJECT="gen_template.sh"

. ${WEB2PDF_ROOT}/shFlags/shflags
. ${WEB2PDF_ROOT}/helper_functions.sh

DEFINE_string "filename" "" "Required. Name of BASH script to create. Location is relative to the web2pdf root directory." f
DEFINE_string "scripttype" "executable" "environment, function, executable" t
DEFINE_string "imports" "shFlags/shflags default_vars.sh" "List of BASH scripts containing functions/variables you would like to import. Starting at root directory." i
DEFINE_string "args" "verbose,boolean" "List of command line arguments to add to the script, using [name,type] separated by spaces. Types are: boolean, categorical, string. E.g., verbose,boolean output_directory,string etc." a
DEFINE_string "version" "" "Version number, optional." v

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

if [ -z "${FLAGS_filename}" ] ; then
	_echo_err "Error: Missing filename argument."
	exit 1;
else
	NEW_FILE="${WEB2PDF_ROOT}/${FLAGS_filename}"
	if [ -f "${NEW_FILE}" ] ; then
		_echo_err "Error: file already exists."
		exit 1;
	fi
	touch $NEW_FILE
	chmod +rwx $NEW_FILE
fi

IMPORTS=
for i in ${FLAGS_imports} ; do
	if [ -z ${IMPORTS} ] ; then
		IMPORTS="${i}"
	else
		IMPORTS="${IMPORTS} $i"
	fi
done

function echos() {
	printf '%q\n' "${1}" >> $NEW_FILE
}

function echof() {
        echo "${1}" >> $NEW_FILE
}

echof "#!/bin/bash"
echof ""

while IFS= read -r line
do
	echof "# $(echo $line | sed -e "s/<year>/$YEAR/g" | sed -e "s/<name of author>/$AUTHOR <$EMAIL>/g")" #<year>  <name of author>
done < $LICENSE

echof "PARENT_PID=\$\$"

echof "WEB2PDF_ROOT=\$(web2pdf_root)"
echof "WEB2PDF_SCRIPTS=\$(web2pdf_scripts)"

echof ""
echof "SUBJECT=\"${FLAGS_filename}\""
if [ ! -z "${FLAGS_version}" ] ; then
	echof ""
	echof "VERSION=\"${FLAGS_version}\""
fi

if [ ! "${FLAGS_scripttype}" == "executable" ] ; then
	echof ""
	echof "if [ -z \$_${FLAGS_filename} ] ; then"
	echof "	export \$_${FLAGS_filename}=1"
	echof "else"
	echof "	return;"
	echof "fi"
fi
echof ""

echof "# BEGIN IMPORTS #"

for i in $IMPORTS ; do echof ". \${WEB2PDF_ROOT}/$i" ; done

echof "# END IMPORTS #"
echof ""
echof "# BEGIN CMDLINE ARGS #"
for i in ${FLAGS_args} ; do
	ARG_NAME=$(echo "$i" | sed -e "s/,.*//g")
	ARG_TYPE=$(echo "$i" | sed -e "s/.*,//g")
	if [ "${ARG_TYPE}" == "boolean" ] ; then
		echof "DEFINE_${ARG_TYPE} \"${ARG_NAME}\" \"1\" \"[description]\" "
	else
		echof "DEFINE_${ARG_TYPE} \"${ARG_NAME}\" \"[default value]\" \"[description]\" "
	fi
done
echof ""
echof "# parse command line"
echof "FLAGS \"\$@\" || exit 1"
echof "eval set -- \"\${FLAGS_ARGV}\""
echof ""

for i in ${FLAGS_args} ; do
        ARG_NAME=$(echo "$i" | sed -e "s/,.*//g")
        ARG_TYPE=$(echo "$i" | sed -e "s/.*,//g")
	case ${ARG_TYPE} in
		boolean)
		#In shFlags, strangely, 0 means true and 1 means false. So we parse it into true/false once at the beginning.
                	echof "if [ \"\${FLAGS_${ARG_NAME}}\" == \"0\" ] ; then"
                	echof "         ${ARG_NAME}=\"true\""
                	echof "else"
                	echof "         ${ARG_NAME}=\"false\""
                	echof "fi"
                	echof ""
		;;
		categorical)
			echof "case \${FLAGS_${ARG_NAME}} in"
			echof "    case1)"
			echof "        #do stuff"
			echof "    ;;"
			echof "    case2)"
                        echof "        #do stuff"
                        echof "    ;;"
			echof "    # ..."
			echof "    # ...etc. etc. and so on and so forth..."
			echof "    *)"
                        echof "        _echo_err \"You utter fool! This is an invalid option, didn't you read the non-existent manual!? \""
			echof "        exit 1;"
                        echof "    ;;"
			echof "esac"

		;;
		string)
			echof "${ARG_NAME}=\"\${FLAGS_${ARG_NAME}}\""
			echof ""
		;;
		*)
			echo "Hmm...we don't have a type for that yet. I'm sure it's in the backlog, though. We'll probably get to it no later than the Jaguar-Panda 465 / Apple / gamma-3085757 sprint. " 
			echo "Or you know, just make the change yourself, that works fine too."
			exit 1;
		;;
	esac
done

echof ""

echof "# END CMDLINE ARGS #"
echof ""
echof "# BEGIN _${FLAGS_filename} #"
echof ""
echof "# END _${FLAGS_filename} #"








