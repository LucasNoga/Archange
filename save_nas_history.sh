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

typeset -A SERVER=([ip]=''
    [port]=''
    [user]=''
    [password]='')

###
# Main body of script starts here
###
main() {
    read_config

    folder=$(get_folder $1)
    echo -e Folder when you save your history: ${COLORS[yellow]}$(pwd)${COLORS[nc]}

    get_password

    create_history
    copy_history_to_local $folder
}

###
# Check if config are ok and get variables from settings.file
###
read_config() {
    FILE="./settings.conf"
    if [ -f "$FILE" ]; then
        source ./settings.conf

        # Mapping config
        #TODO a gerer si les valeurs n'existe pas
        if [ ! -z ${USER+x} ]; then SERVER["user"]=$USER; else echo "pas ok user"; fi
        if [ ! -z ${PASSWORD+x} ]; then SERVER["password"]=$PASSWORD; else echo "pas ok pass"; fi
        if [ ! -z ${IP+x} ]; then SERVER["ip"]=$IP; else echo "pas ok ip"; fi
        if [ ! -z ${PORT+x} ]; then SERVER["port"]=$PORT; else echo "pas ok port"; fi

        echo "ALL CONFIG VALUES:" ${SERVER[*]}
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
    if [ -z ${SERVER[password]} ]; then
        read -s -p "Type your nas admin password: " SERVER[password]
        echo
    fi
}

###
# Create ssh connection to server and create a file with all history
###
create_history() {
    echo "Creating SERVER history..."
    echo "Connection to the SERVER..."
    #TODO mettre en config le repertoire a copier
    # sshpass -p ${NAS[password]} ssh ${NAS[user]}@${NAS[ip]} -p ${NAS[port]} "cd /volume1 && ls -R NAS/ > NASHISTORY.txt"
    sshpass -p ${SERVER[password]} ssh ${SERVER[user]}@${SERVER[ip]} -p ${SERVER[port]} "cd /volume1 && ls -R NAS/ > HISTORY.txt"
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "${COLORS[green]}History created${COLORS[nc]}"
    else
        echo -e "${COLORS[red]}ERROR: Failed to create history with your credentials.${COLORS[nc]}\nExiting..."
        exit 1
    fi
}

###
# Copy history file from server to local
###
copy_history_to_local() {
    echo "Copy History in local machine..."
    folder=$1

    echo "Connection to the SERVER..."
    # TODO gerer le nom de sortie
    sshpass -p ${SERVER[password]} scp -P ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]}:/volume1/HISTORY.txt $folder/NASHISTORY_$(date +"%Y-%m-%d").txt
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "${COLORS[green]}History retrieve${COLORS[nc]}"
    else
        echo -e "${COLORS[red]}ERROR: Failed to retrieve history with your credentials.${COLORS[nc]}\nExiting..."
        exit 1
    fi
}

main $@
