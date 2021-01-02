#! /bin/bash
# written by Andrew Barlow
# https://github.com/dandrewbarlow
# https://a-barlow.com


# POSIX var that can cause trouble if getopts is used multiple times in a row without resetting
OPTIND=1

# initialize empty file vars
input_file=""
output_file=false

# list of temporary files
temp_files=( )

# function to clean up temp files
cleanup() {
  rm -f "${tempfiles[@]}"
}

# bind cleanup function to exit, incl. interrupt
trap cleanup EXIT
trap cleanup SIGINT


usage() {
	echo "readpdf- use OSX's native text-to-speech programs to read pdf text"
	echo "USAGE: readpdf -i[o] [pdf]"
	echo "-o flag sets output to true, which creates .aiff file with input's filename"
	echo "use -h or make a mistake to see this menu"
	echo "requirements: getopt"
}


# parse options
# options: -o -h -i

while getopts "ohi:" opt; do
	case $opt in
		h)
			usage
			exit 1
			;;
		i)
			if [ -e "$OPTARG" ]
			then
				input_file="$OPTARG"
			else
				echo "Error: file \"${OPTARG}\" does not exist"
				exit 1
			fi
			;;
		o)
			output_file=true
			;;
		*)
			usage
			exit 1
			;;
	esac
done

# check if the input file is specified and extant
if [ "$input_file" != "" ] && [ -e "$input_file" ]
then
	# extract the name of the file without extension
	name=$(echo "$input_file" | cut -f 1 -d '.')


	temp_text="$(mktemp -t ${name}.txt)"
	tempfiles+=( "$temp_text" )

	# if output is true create one, else do it in place
	# having trouble using pipes, so txt middle man might be necessary evil
	if [ "$output_file" = true ]
	then
		gs -q -dNOPROMPT -dNOPAUSE -dBATCH -sDEVICE=txtwrite -sOutputFile="$temp_text" "$input_file"
		say -v 'Tom' -f "$temp_text" -o "${name}.aiff"
	else
		gs -q -dNOPROMPT -dBATCH -dNOPAUSE -sDEVICE=txtwrite -sOutputFile="$temp_text" "$input_file"
		say -v 'Tom' -f "$temp_text"
	fi

else
	echo "Error: no input file specified"
	echo "" 
	usage
fi
