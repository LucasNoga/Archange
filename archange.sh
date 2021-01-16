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

###
# Main body of script starts here
###
main() {
    read_config

    folder=$(get_folder $1)
    echo -e Folder when you save your history: ${COLORS[yellow]}$(pwd)${COLORS[nc]}

    get_server_path_history

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
        source "./settings.conf"

        USER=$(eval echo \$$NAME"_USER")
        PASSWORD=$(eval echo \$$NAME"_PASSWORD")
        IP=$(eval echo \$$NAME"_IP")
        PORT=$(eval echo \$$NAME"_PORT")
        SERVER_PATH=$(eval echo \$$NAME"_PATH")

        # Mapping config
        if [ ! -z $IP ]; then SERVER["ip"]=$IP; else
            echo -e "${COLORS[red]}ERROR: $NAME"_IP" is not defined into settings.conf .${COLORS[nc]}\nExiting..."
            exit 1
        fi
        if [ ! -z $PORT ]; then SERVER["port"]=$PORT; else
            echo -e "${COLORS[red]}ERROR: $NAME"_PORT" is not defined into settings.conf .${COLORS[nc]}\nExiting..."
            exit 1
        fi
        if [ ! -z $USER ]; then SERVER["user"]=$USER; else
            echo -e "${COLORS[red]}ERROR: $NAME"_USER" is not defined into settings.conf .${COLORS[nc]}\nExiting..."
            exit 1
        fi
        if [ ! -z $PASSWORD ]; then
            SERVER["password"]=$PASSWORD
        fi
         if [ ! -z $SERVER_PATH ]; then
            SERVER["path"]=$SERVER_PATH
        fi

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
# Get path on the server to get the history
###
get_server_path_history() {
    if [ -z ${SERVER[path]} ]; then
        read -p "Type the path you want to get history: " SERVER[path]
    fi
    echo -e "You will get the history file of this path: ${COLORS[yellow]} ${SERVER[path]} ${COLORS[nc]}"
}

###
# Create ssh connection to server and create a file with all history
###
create_history() {
    echo "Creating SERVER history..."
    echo "Connection to the SERVER..."
    sshpass -p ${SERVER[password]} ssh ${SERVER[user]}@${SERVER[ip]} -p ${SERVER[port]} "cd ${SERVER[path]} && ls . -R > HISTORY.txt"
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
    sshpass -p ${SERVER[password]} scp -P ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]}:${SERVER[path]}/HISTORY.txt $folder/HISTORY_$(date +"%Y-%m-%d").txt
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "${COLORS[green]}History retrieve${COLORS[nc]}"
    else
        echo -e "${COLORS[red]}ERROR: Failed to retrieve history with your credentials.${COLORS[nc]}\nExiting..."
        exit 1
    fi
}

main $@
