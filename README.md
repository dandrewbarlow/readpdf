# readpdf by [Andrew Barlow](https://github.com/dandrewbarlow)
Narrate pdf files from the command line

### Description
A simple script to take a pdf and narrate it. Use -i argument to specify input, -o flag to create an .aiff output file, and -h to show help menu.

This was written on and for my OSX computer, using OSX's native 'say' command as a text to speech device. It also uses ghostscript with OSX syntax. All of which is to say it probably *can* work on other OSes, but it might require some tinkering.

### Status
Still being worked on and not technically in working condition. Once I get it working I want to eliminate the temporary txt file being used as an intermediary step between the pdf and say. But right now I'm fiddling with getopt
