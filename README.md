# addplayedframe
A kid3-based utility to add LastPlayedDate data directly to tags.
A kid3-based utility to add a custom TXXX frame for writing LastPlayedDate data directly to tags.
Generates and applies a random LastPlayedDate for each tag, with TIMEVAL either sql or epoch time

Usage: addplayedframe.sh [option] DIRPATH TIMEVAL

options:
-h display this help file

-m minimum subdirectory depth from top directory of music library to music files (default: 1)

-n specify TXXX frame name (default: Songs-DB_Custom1)

-q quiet - hide terminal output

-r specify upper limit (default: 120) of random number (of days) to be generated for each tag;
   the number is subtracted from the current date, then added as a numerical date value to the tag
   frame
-t specify epoch or sql time as the random numerical date value (default: sql)


Modifies tags to enable other utilities to create custom playlists using "LastPlayedDate" history.
Tag version required is id3v2.3.

Requires kid3. Using the kid3-cli utility, scans all music files in the DIRPATH and checks each 
for existence of the frame name identified (default is Songs-DB_Custom1). If it does not exist,
creates a TXXX frame with that name, then assigns a random LastTimePlayed time value for each tag.

Numerical time value type can be changed to epoch time (default is SQL time).

Time to complete varies by processor and can take time for large libraries. Check tag output
quality more quickly by testing on a subdirectory first.
