#!/bin/bash

# ------------------------------------------------------------------
# [Author] : Lucas Noga
# [Title] : Save NAS History
# [Description] : Save the history of the NAS with ls -R and scp command
# [Version] : 1.0.0
# [Usage] : save_nas_history <folder>"
# ------------------------------------------------------------------

VERSION=1.0.0

typeset -A COLORS
COLORS=([red]='\033[0;31m'
    [green]='\033[0;32m'
    [yellow]='\033[0;33m'
    [nc]='\033[0m') # No Color

# NAS credentials and endpoint (ip + port) 
typeset -A NAS

###
# Main body of script starts here
###
main() {
    read_config

    folder=$(get_folder $1)
    echo -e Folder when you save your history: ${COLORS[yellow]}$(pwd)${COLORS[nc]}

    get_password

    create_nas_history
    copy_history_local $folder
}

###
# Check if config are ok and get variables from settings.file
###
read_config() {
    FILE="./settings.conf"
    if [ -f "$FILE" ]; then
        source ./settings.conf

        # Mapping config
        if [ ! -z ${NAS_USER+x} ]; then NAS["user"]=$NAS_USER; else echo "pas ok user"; fi
        if [ ! -z ${NAS_PASSWORD+x} ]; then NAS["password"]=$NAS_PASSWORD; else echo "pas ok pass"; fi
        if [ ! -z ${NAS_IP+x} ]; then NAS["ip"]=$NAS_IP; else echo "pas ok ip"; fi
        if [ ! -z ${NAS_PORT+x} ]; then NAS["port"]=$NAS_PORT; else echo "pas ok port"; fi

        #echo "ALL CONFIG VALUES:" ${NAS[*]}
    else
        echo -e "${COLORS[red]}ERROR: $FILE doesn't exists.${COLORS[nc]}\nExiting..."
        exit 1
    fi

}

###
# Get folder to copy file
###
get_folder() {
    folder=$1
    if [ -z $folder ] || [ ! -d $folder ]; then
        folder="."
    fi
    echo $folder
}

###
# Read admin password asked if it's not set in config
###
get_password() {
    if [ -z ${NAS[password]} ]; then
        read -s -p "Type your nas admin password: " NAS[password]
        echo 
    fi
}

###
# Create ssh connection to nas and create the NASHISTORY.txt file
###
create_nas_history() {
    echo "Creating NAS history..."
    echo "Connection to the NAS..."
    sshpass -p ${NAS[password]} ssh ${NAS[user]}@${NAS[ip]} -p ${NAS[port]} "cd /volume1 && ls -R NAS/ > NASHISTORY.txt"
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "${COLORS[green]}History created${COLORS[nc]}"
    else
        echo -e "${COLORS[red]}ERROR: Failed to create history with your credentials.${COLORS[nc]}\nExiting..."
        exit 1
    fi
}

###
# Copy history file from nas to local
###
copy_history_local() {
    echo "Copy History in local machine..."
    folder=$1

    echo "Connection to the NAS..."
    sshpass -p ${NAS[password]} scp -P ${NAS[port]} ${NAS[user]}@${NAS[ip]}:/volume1/NASHISTORY.txt $folder/NASHISTORY_$(date +"%Y-%m-%d").txt
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "${COLORS[green]}History retrieve${COLORS[nc]}"
    else
        echo -e "${COLORS[red]}ERROR: Failed to retrieve history with your credentials.${COLORS[nc]}\nExiting..."
        exit 1
    fi
}

main $@
