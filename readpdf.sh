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
voice=''

# temporary file directory and files
temp_dir=""
temp_text=""
temp_audio=""

# Determine tts program
tts=""
if [ -x "$(command -v say)" ]
then 
	tts="say"
	voice='Tom'
elif [ -x "$(command -v espeak)" ]
then
	tts="espeak"
	voice='english-us'
else
	echo "Error: no supported text-to-speech program" && exit 1
fi

# function to clean up temp files
cleanup() {
	# don't run if program exits early somewhere else
	if [ ! -z "$temp_dir" ]
	then
		rm -rf "${temp_dir}" && \
			echo "> temporary files deleted" || \
			echo "Error: error deleting temporary files"
	fi
}

# bind cleanup function to exit, incl. interrupt
trap cleanup EXIT
trap cleanup SIGINT

# if programs in the script aren't installed, don't run the script
requirements() {
	if [ ! -x "$(command -v gs)" ] && [ ! -x "$(command -v pandoc)" ] && [ ! -x "$(command -v ffmpeg)" ] && [ ! -x "$(command -v $tts)"]
	then
		echo "Error: requirements not met"
		echo "More info: https://github.com/dandrewbarlow/readpdf"
		exit 1
	fi
}

# in case I (or you) fuck up
usage() {
	echo "readpdf- use OSX's native text-to-speech programs to read pdf text"
	echo ""
	echo "USAGE: ./readpdf.sh -i [input] -v [voice] -n [install] [-och]"
	echo "options: -i -o -c -h"
    echo "i (argument) input - specify input file"
    echo "v (argument) voice - specify voice to use. Defaults to Tom."
	echo "   See list of english voices with '-v list', or use say -v '?' to get full list."
	echo "n (argument) install - since i is already used, this runs a simple installation script by confirming with '-n install'"
    echo "o (flag) output - if provided, outputs to input.aiff"
    echo "c (flag) convert - convert to mp3 using ffmpeg"
	echo ""
	echo "for more information, visit https://github.com/dandrewbarlow/readpdf"

}

# check requirements before running
requirements

# options: -i [input] -v [voice] -n [install] -o -c -h
# i : input- argument, specify input file
# v : voice- specify voice, use -v list to list voices
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
			;;
		o)
			output_file=true
			;;
		c)
			convert=true
			;;
		v)
			# if argument is list, list the voices
			if [ "$OPTARG" == "list" ]
			then 
				if [ "$tts" == say ]
				then
					say -v '?' | grep en_US
				elif [ "$tts" == espeak ]
				then
					espeak --voices | grep english
				fi
				exit 0
			fi

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
				[ ! -d "$HOME/.scripts/" ] && \
					mkdir "$HOME/.scripts" && echo "$HOME/.scripts/ directory created"

				# copy this script to ~/.scripts/
				if [ -e "./readpdf.sh" ]
				then
					cp ./readpdf.sh "$HOME/.scripts/" && echo "Script copied to $HOME/.scripts/"
				else
					echo "Error: installation script must be run from same directory as script"
					exit 1
				fi

				# check which shell the user is using
				# bash & zsh are the only shells I rly know or use (and are both OSX defaults, depending on ur computer's age) so I'm only messing with them
				# sh and fish users can figure it out themselves
				if [[ "$SHELL" =~ "bash" ]]
				then
					# check if the user already has an alias for this script
					if [ -z "$(cat $HOME/.bashrc | grep -i 'readpdf')" ]
					then
						# echo alias into shell config if not
						echo "alias readpdf=~/.scripts/readpdf.sh" >> "$HOME/.bashrc" && \
							echo "Bash alias 'readpdf' has been created to access"
						echo "Restart terminal or re-source bash config to use"
					fi
				# same process as above, but for zsh
				elif [[ "$SHELL" =~ "zsh" ]]
				then
					if [ -z "$(cat $HOME/.zshrc | grep -i 'readpdf')" ]
					then
						echo "alias readpdf=~/.scripts/readpdf.sh" >> "$HOME/.zshrc" && \
							echo "Zsh alias 'readpdf' has been created to access"
						echo "Restart terminal or re-source bash config to use"
					fi
				else
					echo "Unknown shell, no alias created"
				fi
				
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

	# convert to txt
	echo "> converting to txt"

	if [ "$extension" == "pdf" ]
	then
		gs -q -dNOPROMPT -dBATCH -dNOPAUSE -sDEVICE=txtwrite -sOutputFile="$temp_text" "$input_file" || 
			echo "Error: ghostscript conversion failed" || exit 1

	elif [ "$extension" == "epub" ]
	then
		pandoc "$input_file" -f epub -t plain -o "$temp_text" || 
			echo "Error: pandoc conversion failed" || exit 1

	else
		echo "Unsupported filetype, attempting implicit pandoc conversion"
		# attempt conversion, on fail output error message and exit
		pandoc ${input_file} -t plain -o ${temp_text} || \ 
			echo "Error: pandoc implicit conversion failed" || exit 1
	fi

	# create an audio file
	if [ "$output_file" = true ]
	then
		
		echo "> generating audio"

		# narrate and then compress audio file
		if [ "$convert" = true ]
		then

			# handle different tts programs
			if [ "$tts" == "say" ]
			then

				# Create temp audio
				touch "${temp_dir}/audio.aiff"
				temp_audio="${temp_dir}/audio.aiff"
				
				# check if temp audio actually exists
				[ -z "$temp_audio" ] && \
				echo "Error creating temporary file (audio)" && exit 1

				say -v "$voice" -f "$temp_text" "--output-file=$temp_audio" || \
					echo "Error: say returned an error" || exit 1

			elif [ "$tts" == "espeak" ]
			then
				# Create temp audio
				touch "${temp_dir}/audio.wav"
				temp_audio="${temp_dir}/audio.wav"
				
				# check if temp audio actually exists
				[ -z "$temp_audio" ] && \
				echo "Error creating temporary file (audio)" && exit 1
				espeak -v "$voice" -f "$temp_text" -w "$temp_audio"

			fi

			# get the bitrate of output file and use that for equivalent conversion
			bit="$(ffmpeg -i "${temp_audio}" 2>&1 | grep Audio | awk -F", " '{print $5}' | cut -d' ' -f1)"

			echo "> converting audio"
			ffmpeg -hide_banner -loglevel fatal -i "$temp_audio" -f mp3 -acodec libmp3lame -ab "$bit"k "./${name}.mp3" || \
				echo "Error: ffmpeg mp3 conversion failed; Exiting program" || \
				exit 1

		# Narrate to uncompressed audio file
		else
			if [ "$tts" == "say" ]
			then
				say -v "$voice" -f "$temp_text" -o "./${name}.aiff" || \
					echo "Error: say returned error code" || \
					exit 1
			elif [ "$tts" == "espeak" ]
			then
				espeak -v "$voice" -f "$temp_text" -w "./${name}.wav" || \
					echo "Error: espeak returned error code" || \
					exit 1
			fi

		fi


	# narrate from command line
	else

		if [ "$tts" == "say" ]
			then
				echo "> starting narration"
				say -v "$voice" -f "$temp_text" || \
					echo "Error: say returned an error"|| \
					exit 1
			elif [ "$tts" == "espeak" ]
			then
				espeak -v "$voice" -f "$temp_text" || \
					echo "Error: espeak returned error code" || \
					exit 1
			fi
	
		

	fi

else

	echo "Error: no input file specified"
	echo "" 
	usage

fi
