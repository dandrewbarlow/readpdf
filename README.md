# readpdf by [Andrew Barlow](https://github.com/dandrewbarlow)
Narrate pdf (and other) files from the command line

### Description
A simple script to take a pdf and narrate it. 

This was written on and for my OSX computer, using OSX's native `say` command as a text to speech device. As of 1/20/21, it now can use espeak as well. It also uses ghostscript to convert a pdf to text, pandoc to convert epub files, and will try to implicitly convert any [other file types](https://pandoc.org/index.html) you try to send to it. No promises, but pandoc can handle a lot of formats without tweaking (<3 that program). All of which is to say it probably *can* work on other setups, but it might require some tinkering.

Fair warning that this is not *professional* grade software, just a script I made for fun. It's not perfect, has gone through very minimal testing, and comes with no warranty or guarantee of any kind. As a general rule if you can't understand the source code, don't run it. I tried to make it pretty foolproof, but underestimating fools (or assuming I'm not the fool) is also bad practice.

### Requirements
* Bash / ZSH - These are the two default OSX shells, and these are the only one's I coded support for. In theory the bulk of this script is shell agnostic, but the installation script in particular checks for a `.zshrc` or `.bashrc` files to echo an alias into. If you have a different shell (and you want an alias for this script), that's something you have to manually do. 
* Ghostscript - available from [homebrew](https://brew.sh/): `$ brew install ghostscript`. Used to convert pdf's to text.
* pandoc - available from homebrew: `$ brew install pandoc`. Allows conversion from `epub` format as well as many other formats.
* ffmpeg - available for download from [here](http://ffmpeg.org/download.html) or again via homebrew: `$ brew install ffmpeg`. Default audio output for `say` is `.aiff`. `man say` shows that some voices have different formats, but doesn't go into much detail on how to find out more. I for one would like a nice `mp3` file without finnicking with this old ass program, so I chose to convert it with ffmpeg. ffmpeg is a notoriously cumbersome program to use, so I didn't allow much customization for conversion options. If you want a different file type, that's something you'll have to manually change.
* say - included in OSX, replacement needed for other OS's. I wouldn't recommend that unless you are willing to mess with the code, though, because you will need to switch out say with whatever you choose.
* espeak - alternative to say. For linux, download using your package manager of choice (or build it from scratch idgaf). Precompiled binaries are downloadable [here](http://espeak.sourceforge.net/download.html) for *unique* systems.

### Usage
`./readpdf.sh -i [input] -v [voice] [-och]`

- i (argument) input - specify input file. Required

- v (argument) voice - specify voice to use. Defaults to Tom. Use `-v list` to see a list of English voices, or `say -v '?'` to see all voices. Additional voices can also be added from `System Preferences > Accessibility > Speech > System Voice > Customize`.

- n (argument) install - running with `-n install` as a confimation will install this script into `~/.scripts`, then check for existing bash aliases, adding them if not present.

- o (flag) output - if provided, outputs to input.aiff

- c (flag) convert - convert to mp3 using ffmpeg

### Installation
Seeing as this is more of a small script than a program, I'm not giving much hard advice on how to install. I like keeping a `~/.scripts/` directory and bash aliases for my scripts, and have included the `-n install` option to automatically do this, but if you have your own preferences (or use a shell that is not `bash` or `zsh`), you should probably figure this out yourself.

### Status
Ostensibly working. I'd like to remove the need for the temporary text file I create in the script, but it was a good opportunity to learn about the mktemp command (here I was making temp files manually, in place like a clown). It can be pretty dang slow with large pdf's and I've encountered a few weird errors for specific files (not sure if my script or the files are at fault). I'd like to get a more general purpose version working, but it works on my computer, and I was making it for me. If anyone uses this and wants me to make changes, feel free to ask or take a swing at it yourself.