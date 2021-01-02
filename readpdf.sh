#! /bin/bash
# written by Andrew Barlow
# https://github.com/dandrewbarlow
# https://a-barlow.com


# POSIX var that can cause trouble if getopts is used multiple times in a row without resetting
OPTIND=1

# initialize empty file vars
input_file=""
output_file=false
convert=false
voice='Tom'

# list of temporary files
temp_files=( )
temp_text=""
temp_audio=""

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
# options: -o -h -i -c
# o : output- flag, not arg; create file with base filename, and write audio to it
# h : help- display usage info
# i : input- argument, specify input file
# v : voice- specify voice
# c : convert- flag, if present, convert to mp3

while getopts "ohci:v:" opt; do
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
		c)
			convert=true
			if [ "$output_file" != true ]
			then
				echo "Can\'t convert without output"
				exit 1
			fi
			;;
		v)
			voice="$OPTARG"
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

	# create temporary files if they are desired

	temp_text="$(mktemp -t ${name}.txt)"
	tempfiles+=( "$temp_text" )

	if [ "$convert" = true ]
	then 
		temp_audio="$(mktemp -t ${name}.aiff)"
		tempfiles+=( "$temp_audio" )
	fi

	# convert pdf to txt
	echo "> converting pdf"
	gs -q -dNOPROMPT -dBATCH -dNOPAUSE -sDEVICE=txtwrite -sOutputFile="$temp_text" "$input_file"

	# if output is true create one, else do it in place
	# having trouble using pipes, so txt middle man might be necessary evil
	if [ "$output_file" = true ]
	then
		echo "> generating audio"
		if [ "$convert" = true ] 
		then
			say -v 'Tom' -f "$temp_text" -o "$temp_audio"
			# get the bitrate of output file and use that for equivalent conversion
			bit="$(ffmpeg -i "${temp_audio}" 2>&1 | grep Audio | awk -F", " '{print $5}' | cut -d' ' -f1)"
			echo "> converting audio"
			ffmpeg -i "$temp_audio" -f mp3 -acodec libmp3lame -ab "$bit"k "${name}.mp3"
		else
			say -v 'Tom' -f "$temp_text" -o "${name}.aiff"
		fi


	else
		echo "> starting narration"
		say -v 'Tom' -f "$temp_text"
	fi

else
	echo "Error: no input file specified"
	echo "" 
	usage
fi
