#!/bin/bash
set -e
print_help(){
cat << 'EOF'

A kid3-based utility to add a custom TXXX frame for writing LastPlayedDate data directly to tags.
Generates and applies a random LastPlayedDate for each tag, with TIMEVAL either sql or epoch time

Usage: addplayedframe.sh [option] DIRPATH TIMEVAL

options:
-h display this help file
-m minimum subdirectory depth from top directory of music library to music files (default: 1)
-n specify TXXX frame name (default: Songs-DB_Custom1)
-q quiet - hide terminal output

Modifies tags to enable other utilities to create custom playlists using "LastPlayedDate" history.
Tag version required is id3v2.3.

Requires kid3. Using the kid3-cli utility, scans all music files in the DIRPATH and checks each 
for existence of the frame name identified (default is Songs-DB_Custom1). If it does not exist,
creates a TXXX frame with that name, then assigns a random LastTimePlayed time value for each tag.
Upper date limit will vary, depending on the rating for the given track.

Parameter TIMEVAL must be specified as either sql or epoch.

Time to complete varies by processor and can take time for large libraries. Check tag output
quality more quickly by testing on a subdirectory first.

Default ages by rating group:
last played age threshold (in days):
group1=900 #(popularimeter 1-32)
group2=600 #(popularimeter 33-96)
group3=300 #(popularimeter 97-160)
group4=180 #(popularimeter 161-228)
group5=50 #(popularimeter 229-255)
EOF
}

showdisplay=1
dirdepth=1
framename="Songs-DB_Custom1"
upperlimit=120

# Use getops to set any user-assigned options
while getopts ":hm:n:q" opt; do
  case $opt in
    h) 
      print_help
      exit 0;;
    m)
      dirdepth=$OPTARG 
      ;;
    n)
      framename=$OPTARG 
      ;;
    q)      
      showdisplay=0 >&2
      ;;
    \?)
      printf 'Invalid option: -%s\n' "$OPTARG"
      exit 1
      ;;
    :)
      printf 'Option requires an argument: %s\n' "$OPTARG"
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

## Verify user provided required, valid path and time argument
if [[ -z "$1" ]] || [[ -z "$2" ]]
then
    printf  '\n%s\n' "Missing positional argument(s)"
    print_help
    exit 1
fi

# positional variables
libpath=$1
timetype=$2

find "$libpath" -mindepth "$dirdepth" > /tmp/albumdirs;
if [ $showdisplay == 0 ] 
then
     printf '%s\n' "Locating all subdirectories under this path..." > /dev/null 2>&1
else 
    printf '%s\n' "Locating all subdirectories under this path..."
fi

# This is for the spinner, to show the program is working
i=1
sp="/-\|"
echo -n ' '

# add random value for LastPlayedDate
while IFS= read -r line; do
    popmfound=$(kid3-cli -c "get POPM.Rating" "$line")
    if [[ "$popmfound" -ge "$group5low" ]]; then upperlimit=60; 
    elif [[ "$popmfound" -ge "$group4low" ]]; then upperlimit=120; 
    elif [[ "$popmfound" -ge "$group3low" ]]; then upperlimit=180; 
    elif [[ "$popmfound" -ge "$group2low" ]]; then upperlimit=360; 
    elif [[ "$popmfound" -ge "$group1low" ]]; then upperlimit=730; fi
    exists=$(kid3-cli -c "get ""$framename" "$line")
    if [ -z "$exists" ]
    then
        sudo kid3-cli -c "set TXXX.Description ""$framename" "$line"
        myrandomval="$(shuf -i 0-"$upperlimit" -n1)"
        adjtimedays=$(date +%s --date="-$myrandomval days")
        if [ "$timetype" == "sql" ]
        then 
            setsqltime=$(printf "%.6f \n" "$(echo "$adjtimedays/86400 + 25569"| bc -l)")
            sudo kid3-cli -c "set ""$framename"" $setsqltime" "$line"           
        fi
        if [ "$timetype" == "epoch" ]
        then
            sudo kid3-cli -c "set ""$framename"" $adjtimedays" "$line"
        fi
    else
        printf '%s\n' 'There is not a valid time variable or there is already a frame for this value:' "$line"
        exit 1
    fi
    if [ $showdisplay == 0 ] 
    then
        printf '\b%s' "${sp:i++%${#sp}:1}"
    else         
        echo "$line"
    fi
done < /tmp/albumdirs
