#!/bin/bash

# This script grabs information from the provided log file, with functionality that
# allows for targeting particular users and outputting the information to a file.

function helpInfo {
    echo ""
    echo "This script fetches login information from the log and outputs
    it either to"
    echo "the command line or to a specified file. It accepts the
    following options"
    echo ""
    echo "WARNING: THIS SCRIPT MAY REQUIRE ROOT PRIVILEGES IN ORDER TO
    ACCESS LOGIN INFORMATION"
    echo ""
    echo "-u : specify a specific user (returns all users if not used)"
    echo "-F : includes failed login attempts"
    echo "-f : outputs information to a specified file"
    echo "-h : prints this help screen"
    echo ""
}

# Parameters

path="/var/log/auth.log" # specify which log file to look at
user="" # if -u flag is used, user info stored here
output=""
success="successful" # what type of log-in to look for
logins=() # stores login information in an array

# Check for options at CLI and sets the appropriate global variable

while getopts "u:f:F:h" flag; do
    case $flag in
        u) user="$OPTARG" ;;
        f) output="$OPTARG" ;;
        F) success="failed" ;;
        h) helpInfo
            exit 1 ;;
        \?) echo "Unrecognized argument, please use -u, -F, or -f. Use -h for
        more information." >&2
        exit 1
    esac
done

# Outputs the information to the appropriate place.
function outputLogins {
    
    # Ensure valid file provided
    if [ -z "$output" ]; then
    
    # echos the logins array to the terminal in reverse order
        for ((i=${#logins[@]}-1; i>=0; i--)); do
            echo "${logins[i]}"
        done
    else

    # check if the output destination is valid
    if [ ! -d "$(dirname "$output")" ]; then
        echo "Invalid destination path, please provide a
        different file" >&2
        exit 1
    fi
   
    # check if destination is writeable
    if [ ! -w "$(dirname "$output")" ]; then
        echo "Insufficient permissions to write to destination,
        please provide a different file" >&2
        exit 1
    fi

    # outputs the user information to a file
    for ((i=${#logins[@]}-1; i>=0; i--)); do
    echo "${logins[i]}" > $output
    done
    echo ""
    echo "Printing complete. Log stored in $output"
    fi
}

# uses grep tool to capture logins
if [ -z "$user" ]; then
    if [ "$success" == "successful" ]; then
        events=$(last -w -f $path)
    else
        events=$(lastb -w -f $path)
    fi
else
    if [ "$success" == "successful" ]; then
        events=$(last -w -f $path | grep $user)
    else
        events=$(lastb -w -f $path | grep $user)
    fi
fi
# prints to standard error if no events found
if [ -z "$events" ]; then
    echo "No events found. Please check the log file." >&2
    exit 1
fi

# adds events to the logins array
logins+=("$events")
outputLogins