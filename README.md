# readpdf by [Andrew Barlow](https://github.com/dandrewbarlow)
Narrate pdf (and other) files from the command line

### Description
A simple script to take a pdf and narrate it. 

This was written on and for my OSX computer, using OSX's native `say` command as a text to speech device. It also uses ghostscript with OSX syntax to convert a pdf to text. As of now it also uses pandoc to convert epub files, and will try to implicitly convert any other file types also with pandoc. All of which is to say it probably *can* work on other OSes, but it might require some tinkering.

Fair warning that this is not *professional* grade software, just a script I made for fun. It still has problems, and comes with no warranty or guarantee of any kind.
### Requirements
* Ghostscript - available from [homebrew](https://brew.sh/): `$ brew install ghostscript`. Used to convert pdf's to text.
* pandoc - available from homebrew: `$ brew install pandoc`. Allows conversion from `epub` format as well as many other formats.
* ffmpeg - available for download from [here](http://ffmpeg.org/download.html) or again via homebrew: `brew install ffmpeg`. Default audio output for `say` is `.aiff`, and I for one would like a nice `mp3` file. ffmpeg is a notoriously cumbersome program to use, so I didn't allow much customization for conversion options. If you want a different file type, that's something you'll have to manually change.
* say - included in OSX, replacement needed for other OS's

### Usage
`./readpdf.sh -i [input] -v [voice] [-och]`

- i (argument) input - specify input file

- v (argument) voice - specify voice to use. Defaults to Tom. No real error checking here, just passing it on to `say` so check what's available.

- o (flag) output - if provided, outputs to input.aiff

- c (flag) convert - convert to mp3 using ffmpeg

### Installation
Seeing as this is more of a small script than a program, I'm not giving much hard advice on how to install. I like keeping a `~/.scripts/` directory and bash aliases for my scripts, but if you're interested in this script, you can probably make an educated decision on this.

### Status
Ostensibly working. I'd like to remove the need for the temporary text file I create in the script, but it was a good opportunity to learn about the mktemp command (here I was making temp files manually, in place like a clown). It can be pretty dang slow with large pdf's and I've encountered a few errors that I don't know how to fix (yet). I'd like to get a more general purpose version working, but it works on my computer, and I was making it for me. If anyone uses this and wants me to make changes, feel free to ask or take a swing at it yourself.
