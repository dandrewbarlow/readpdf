#! /bin/bash

# readpdf - narrate a file with native osx tts utility
# written by Andrew Barlow
# https://github.com/dandrewbarlow
# https://a-barlow.com


# POSIX var that can apparently cause trouble if getopts is used multiple times in a row without resetting
OPTIND=1

# initialize empty file vars
input_file=""
output_file=false
convert=false
voice='Tom'

# temporary file directory and files
temp_dir=""
temp_text=""
temp_audio=""

# function to clean up temp files
cleanup() {
	# don't run if program exits early somewhere else
	if [ ! -z "$temp_dir" ]
	then
		echo "> cleaning up temporary files"
		rm -rf "${temp_dir}"
	fi
}

# bind cleanup function to exit, incl. interrupt
trap cleanup EXIT
trap cleanup SIGINT

# if programs in the script aren't installed, don't run the script
requirements() {
	if [ ! -x "$(command -v gs)" ] && [ ! -x "$(command -v pandoc)" ] [ ! -x "$(command -v ffmpeg)" ] && [ ! -x "$(command -v say)"]
	then
		echo "Error: requirements not met"
		echo "More info: https://github.com/dandrewbarlow/readpdf"
		exit 1
	fi
}

# in case I (or you) fuck up
usage() {
	echo "readpdf- use OSX's native text-to-speech programs to read pdf text"
	echo "USAGE: ./readpdf.sh -i [input] -v [voice] [-och]"
	echo "options: -i -o -c -h"
    echo "i (argument) input - specify input file"
    echo "o (flag) output - if provided, outputs to input.aiff"
    echo "c (flag) convert - convert to mp3 using ffmpeg"
    echo "v (argument) voice - specify voice to use. Defaults to Tom."
	echo "n (argument) install - i is already used, so this runs a simple installation script by confirming with '-n install'"
	echo "for more information, visit https://github.com/dandrewbarlow/readpdf"

}

# check requirements before running
requirements

# options: -i [input] -v [voice] -n [install] -o -c -h
# i : input- argument, specify input file
# v : voice- specify voice
# o : output- flag, not arg; create file with base filename, and write audio to it
# c : convert- flag, if present, convert to mp3
# h : help- display usage info
# n : install- i is already used, so this runs a simple installation script by confirming with '-n install'. Auto-creates alias in either 

# parse options and arguments given using getopts
while getopts "ohci:v:n:" opt; do
	case $opt in
		h)
			usage
			exit 1
			;;
		i)
			if [ ! -e "$OPTARG" ]
			then
				echo "Error: file \"${OPTARG}\" does not exist"
				exit 1
			else
			input_file="$OPTARG"
			fi
			# echo "$input_file"
			;;
		o)
			output_file=true
			;;
		c)
			convert=true
			if [ "$output_file" != true ]
			then
				echo "Can't convert without output"
				exit 1
			fi
			;;
		v)
			# validate voice choice matches one of say's voices
			if [ "$OPTARG" == "$(say -v '?' | grep -i ${OPTARG} | awk '{print $1}')" ]
			then
				voice="$OPTARG"
			else
				echo "Error: voice not found, defaulting to 'Tom'"
			fi
			;;
		n)
			if [ "$OPTARG" == "install" ]
			then
				# create a ~/.scripts dir if not present
				if [ ! -d "$HOME/.scripts/" ]
				then
					mkdir "$HOME/.scripts"
					echo "$HOME/.scripts/ directory created"
				fi

				# copy this script to ~/.scripts/
				cp ./readpdf.sh "$HOME/.scripts/"

				echo "Script copied to $HOME/.scripts/"

				# check which shell the user is using
				# bash & zsh are the only shells I rly know or use (and are both OSX defaults, depending on ur computer's age) so I'm only messing with them
				# sh and fish users can figure it out themselves
				if [[ "$SHELL" =~ "bash" ]]
				then
					# check if the user already has an alias for this script
					if [ -z "$(cat $HOME/.bashrc | grep -i 'readpdf')" ]
					then
						# echo alias into shell config if not
						echo "alias readpdf=~/.scripts/readpdf.sh" >> "$HOME/.bashrc"
					fi
				# same process as above, but for zsh
				elif [[ "$SHELL" =~ "zsh" ]]
				then
					if [ -z "$(cat $HOME/.zshrc | grep -i 'readpdf')" ]
					then
						echo "alias readpdf=~/.scripts/readpdf.sh" >> "$HOME/.zshrc"
					fi
				else
					echo "Unknown shell, no alias created"
				fi
				
				echo "Script installed into ~/.scripts/readpdf.sh"
				echo "Bash alias 'readpdf' has been created to access"
				echo "Restart terminal or re-source bash config to use"
				exit 0
			fi
			echo "Error, confirm installation with '-n install'"
			exit 1
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
	# extract the name of the file and extension
	name="$(echo "$input_file" | cut -f 1 -d '.')"
	extension="$(echo "$input_file" | awk -F. '{print $NF}')"


	# create temporary files if they are needed inside temp directory
	temp_dir="$(mktemp -d)"
	temp_text="${temp_dir}/text.txt)"
	touch "$temp_text"

	if [ "$convert" = true ]
	then 
		temp_audio="$(touch ${temp_dir}/audio.aiff)"
	fi

	# convert to txt
	echo "> converting to txt"
	if [ "$extension" == "pdf" ]
	then
		gs -q -dNOPROMPT -dBATCH -dNOPAUSE -sDEVICE=txtwrite -sOutputFile="$temp_text" "$input_file"
	elif [ "$extension" == "epub" ]
	then
		pandoc "$input_file" -f epub -t plain -o "$temp_text"
	else
		echo "Unsupported filetype, attempting implicit pandoc conversion"

		# if implicit conversion succeeds, this command will return an empty string
		# if if does not return a zero type (-z), then exit the script
		if [ ! -z "$(pandoc ${input_file} -t plain -o ${temp_text})" ]
		then
			exit 1
		fi
	fi

	# if output is true create one, else do it in place
	# having trouble using pipes, so txt middle man might be necessary evil
	if [ "$output_file" = true ]
	then
		echo "> generating audio"
		if [ "$convert" = true ] 
		then
			say -v "$voice" -f "$temp_text" -o "$temp_audio"
			# get the bitrate of output file and use that for equivalent conversion
			bit="$(ffmpeg -i "${temp_audio}" 2>&1 | grep Audio | awk -F", " '{print $5}' | cut -d' ' -f1)"
			echo "> converting audio"
			ffmpeg -hide_banner -loglevel fatal -i "$temp_audio" -f mp3 -acodec libmp3lame -ab "$bit"k "./${name}.mp3"
		else
			say -v "$voice" -f "$temp_text" -o "./${name}.aiff"
		fi


	else
		echo "> starting narration"
		say -v "$voice" -f "$temp_text"
	fi

else
	echo "Error: no input file specified"
	echo "" 
	usage
fi
