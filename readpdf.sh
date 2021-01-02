#! /bin/bash
# written by Andrew Barlow
# https://github.com/dandrewbarlow
# https://a-barlow.com


# POSIX var that can cause trouble if getopts is used multiple times in a row without resetting
OPTIND=1

# initialize empty file vars
input_file=""
output_file=false

# options: -o -h
parseOptions() {
	while getopts "ohi:" opt; do
		case $opt in
			h)
				usage
				exit
				;;
			i)
				echo "INPUT TRIG"
				input_file="$OPTARG"
				;;
			o)
				output_file=true
				;;
			*)
				usage
				exit
				;;
		esac
	done
}

usage() {
	echo "readpdf- use OSX's native text-to-speech programs to read pdf text"
	echo "USAGE: readpdf -i[o] [pdf]"
	echo "-o flag sets output to true, which creates .aiff file with input's filename"
	echo "use -h or make a mistake to see this menu"
	echo "requirements: getopt"
}

parseOptions

# check if the input file is specified and extant
if [ "$input_file" != "" ] && [ -e "$input_file" ]
then
	# extract the name of the file without extension
	name=$(echo "$filename" | cut -f 1 -d '.')

	# use ghostscript to convert pdf to text file
	gs -sDEVICE=txtwrite -o "${name}.txt" input_file

	# if output is true create one, else do it in place
	if [ "$output_file" = true ]
	then
		say -v 'Tom' "${name}.txt" -f "${name}.aiff"
	else
		say -v 'Tom' "${name}.txt" 
	fi

	# remove the temporary text file
	rm "${name}.txt"
else
	echo "Error: no input file specified"
	echo "" 
	usage
fi
