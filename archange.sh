#!/bin/bash

# ------------------------------------------------------------------
# [Title] : Archange
# [Description] : Save the history of a server with ls -R and scp command
# [Version] : 1.0.0
# [Author] : Lucas Noga
# [Usage] : save_nas_history <folder>"
# ------------------------------------------------------------------

#TODO ameliorer le process de copy :
# - en supprimant le fichier dans le server
# - pour cela voir si on ne peut pas faire une commande ssh et scp en meme temps

NAME=ARCHANGE
VERSION=1.0.0

typeset -A COLORS
COLORS=([red]='\033[0;31m'
    [green]='\033[0;32m'
    [yellow]='\033[0;33m'
    [nc]='\033[0m') # No Color

typeset -A SERVER=([ip]=''
    [port]=''
    [user]=''
    [password]=''
    [path]='')

# File created on the server
SERVER_FILE="HISTORY.txt"

# Name of the file which will get the copy (default HISTORY_date)
FILENAME=HISTORY_$(date +"%Y-%m-%d").txt

###
# Main body of script starts here
###
main() {
    read_config

    folder=$(get_folder $1)
    echo -e Folder when you save your history: $(color_log "$(pwd)" yellow)

    echo -e Default name is: $(color_log $FILENAME yellow)

    get_server_path_history

    get_server_password

    create_history
    copy_history_to_local $folder
}

###
# Check if config are ok and get variables from settings.file
###
read_config() {
    FILE="./settings.conf"
    if [ -f "$FILE" ]; then
        source "./settings.conf"

        USER=$(eval echo \$$NAME"_USER")
        PASSWORD=$(eval echo \$$NAME"_PASSWORD")
        IP=$(eval echo \$$NAME"_IP")
        PORT=$(eval echo \$$NAME"_PORT")
        SERVER_PATH=$(eval echo \$$NAME"_PATH")

        # Mapping config
        if [ ! -z $IP ]; then SERVER["ip"]=$IP; else
            echo -e "$(color_log "ERROR: $NAME"_IP" is not defined into settings.conf" red)\nExiting..."
            exit 1
        fi
        if [ ! -z $PORT ]; then SERVER["port"]=$PORT; else
            echo -e "$(color_log "ERROR: $NAME"_PORT" is not defined into settings.conf" red)\nExiting..."
            exit 1
        fi
        if [ ! -z $USER ]; then SERVER["user"]=$USER; else
            echo -e "$(color_log "ERROR: $NAME"_USER" is not defined into settings.conf" red)\nExiting..."
            exit 1
        fi
        if [ ! -z $PASSWORD ]; then
            SERVER["password"]=$PASSWORD
        fi
        if [ ! -z $SERVER_PATH ]; then
            SERVER["path"]=$SERVER_PATH
        fi

    else
        echo -e "$(color_log "ERROR: $FILE doesn't exists." red)\nExiting..."
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
# Read server password asked if it's not set in config
###
get_server_password() {
    if [ -z ${SERVER[password]} ]; then
        read -s -p "Type your nas admin password: " SERVER[password]
        echo
    fi
}

###
# Get path on the server to get the history
###
get_server_path_history() {
    if [ -z ${SERVER[path]} ]; then
        read -p "Type the path you want to get history: " SERVER[path]
    fi
    echo -e "You will get the history file of this path: $(color_log ${SERVER[path]} yellow)"
}

###
# Create ssh connection to server and create a file with all history
###
create_history() {
    echo "Creating SERVER history..."
    echo "Connection to the SERVER..."
    sshpass -p ${SERVER[password]} ssh ${SERVER[user]}@${SERVER[ip]} -p ${SERVER[port]} "cd ${SERVER[path]} && ls . -R > $SERVER_FILE"
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "$(color_log "History created" green)"
    else
        echo -e "$(color_log "ERROR: Failed to create history with your credentials." red)\nExiting..."
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
    echo Copy the file $(color_log "${SERVER[ip]}:${SERVER[path]}/$SERVER_FILE" yellow) into $(color_log "$folder/$FILENAME" yellow)
    sshpass -p ${SERVER[password]} scp -P ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]}:${SERVER[path]}/$SERVER_FILE $folder/$FILENAME
    ret=$?

    if [ $ret -eq 0 ]; then
        echo -e "$(color_log "History retrieve" green)"
        echo -e History copied: $(color_log "$folder/$FILENAME" yellow)
    else
        echo -e "$(color_log "ERROR: Failed to retrieve history with your credentials." red)\nExiting..."
        exit 1
    fi
}

###
# Log the message in specific color
###
color_log() {
    message=$1
    color=$2
    echo -e ${COLORS[$color]}$message${COLORS[nc]}
}

main $@
