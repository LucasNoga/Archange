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
    [nc]='\033[0m') # No Color

###
# Main body of script starts here
###
main() {
    read_config

    folder=$(get_folder $1)
    echo folder: $folder

    #TODO if password is already set no need to call this function
    get_nas_admin_password
    echo ""

    create_nas_history
    copy_history_local $folder
}

###
# Get variable from settings.file
###
read_config() {
    # TODO detect if config file exit and if variables are set
    source ./settings.conf
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
# Read admin password asked
###
get_nas_admin_password() {
    read -s -p "Type your nas admin password: " NAS_PASSWORD
}

###
# Create ssh connection to nas and create the NASHISTORY.txt file
###
create_nas_history() {
    echo "Connexion to the NAS..."
    sshpass -p $NAS_PASSWORD ssh $NAS_USER@$NAS_IP -p $NAS_PORT "cd /volume1 && ls -R NAS/ > NASHISTORY.txt"
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
    folder=$1
    sshpass -p $NAS_PASSWORD scp -P $NAS_PORT $NAS_USER@$NAS_IP:/volume1/NASHISTORY.txt $folder/NASHISTORY_$(date +"%Y-%m-%d").txt
    ret=$?
    if [ $ret -eq 0 ]; then
        echo -e "${COLORS[green]}History retrieve${COLORS[nc]}"
    else
        echo -e "${COLORS[red]}ERROR: Failed to retrieve history with your credentials.${COLORS[nc]}\nExiting..."
        exit 1
    fi
}

main $@
