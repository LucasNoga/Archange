#!/bin/bash

# ------------------------------------------------------------------
# [Title] : Archange
# [Description] : Save the history of a server with ls -R and scp command
# [Version] : v1.0.0
# [Author] : Lucas Noga
# [Usage] : save_nas_history <folder>"
# ------------------------------------------------------------------

# TODO mettre une constante
# qui represente le folder HISTORY ou on stocke les fichiers
# exemple: ./HISTORY/

## TODO changer les options de settings.conf en enlevant ARCHANGE devant chacune d'elle

## creer un fichier settings.sample.conf avec les options par defaut
## AJOUTER DANS LE README de mv se file en settings.sample.conf

## TODO README modif
## mettre les differents params comme -d pour debug ou --erase-trace
## adapter la partic config

## TODO mettre pas mal de log en debug

## TODO TAGGER en v1.1.0 maintenant

PROJECT_NAME=ARCHANGE
PROJECT_VERSION=v1.0.0

typeset -A SERVER=(
    [ip]=''
    [port]=''
    [user]=''
    [password]=''
    [path]=''
)

# File created on the server
SERVER_FILE="HISTORY.txt"

# Name of the file which will get the copy (default HISTORY_date)
FILENAME=HISTORY_$(date +"%Y-%m-%d").txt

# Options params setup with command parameters
typeset -A OPTIONS=(
    [debug]=false       # Debug mode to show more log
    [debug_color]=blue  # Color to show log in debug mode
    [erase_trace]=false # if true we erase trace on the remote machine
)

###
# Main body of script starts here
###
main() {
    read_config

    read_options $@

    log_debug "OPTIONS KEY ${!OPTIONS[@]}"
    log_debug "OPTIONS VALUES ${OPTIONS[@]}"

    log_debug "Launch Project ${PROJECT_NAME} : ${PROJECT_VERSION}"

    folder=$(get_folder)
    echo -e Folder when you save your history: $(log_color "$(pwd)" yellow)

    echo -e Default name is: $(log_color $FILENAME yellow)

    get_server_path_history

    get_server_password

    create_history
    copy_history_to_local $folder

    # remove file(s) from servers if option is activated
    if [ "${OPTIONS[erase_trace]}" = true ]; then
        erase_trace
    fi
}

###
# Check if config are ok and get variables from settings.file
###
read_config() {
    FILE="./settings.conf"
    if [ -f "$FILE" ]; then
        source "./settings.conf"

        ## TODO a changer avec cette formule OPTIONS+=([debug]=true)
        ## TODO lire autrement les valeurs probablement dans un array
        USER=$(eval echo \$$PROJECT_NAME"_USER")
        PASSWORD=$(eval echo \$$PROJECT_NAME"_PASSWORD")
        IP=$(eval echo \$$PROJECT_NAME"_IP")
        PORT=$(eval echo \$$PROJECT_NAME"_PORT")
        SERVER_PATH=$(eval echo \$$PROJECT_NAME"_PATH")

        # Mapping config
        if [ ! -z $IP ]; then SERVER["ip"]=$IP; else
            echo -e "$(log_color "ERROR: $NAME"_IP" is not defined into settings.conf" red)\nExiting..."
            exit 1
        fi
        if [ ! -z $PORT ]; then SERVER["port"]=$PORT; else
            echo -e "$(log_color "ERROR: $NAME"_PORT" is not defined into settings.conf" red)\nExiting..."
            exit 1
        fi
        if [ ! -z $USER ]; then SERVER["user"]=$USER; else
            echo -e "$(log_color "ERROR: $NAME"_USER" is not defined into settings.conf" red)\nExiting..."
            exit 1
        fi
        if [ ! -z $PASSWORD ]; then
            SERVER["password"]=$PASSWORD
        fi
        if [ ! -z $SERVER_PATH ]; then
            SERVER["path"]=$SERVER_PATH
        fi

    else
        echo -e "$(log_color "ERROR: $FILE doesn't exists." red)\nExiting..."
        exit 1
    fi
}

################################################################### Params Scripts ###################################################################

###
# Setup params passed with the script
# -d | --debug : Setup debug mode
# --erase-trace : Erase file and your trace on remote machine
###
read_options() {
    params=("$@") # Convert params into an array

    # Step through all param passed
    for param in "${params[@]}"; do
        case $param in
        "-d")
            active_debug_mode
            ;;
        "--debug")
            active_debug_mode
            ;;
        "--erase-trace")
            handle_erase_trace
            ;;
        *) ;;
        esac
        log_debug "Option '$param' founded"
    done
}

###
# Active the debug mode changing options params
###
active_debug_mode() {
    OPTIONS+=([debug]=true)
    log_debug "Debug Mode Activated"
}

###
# Check if erase trace is asked in parameter
###
handle_erase_trace() {
    OPTIONS+=([erase_trace]=true)
    log_debug "Erase Trace active" $DEBUG_COLOR
}

################################################################### Core ###################################################################

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
    echo -e "You will get the history file of this path: $(log_color ${SERVER[path]} yellow)"
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
        echo -e "$(log_color "History created" green)"
    else
        echo -e "$(log_color "ERROR: Failed to create history with your credentials." red)\nExiting..."
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
    echo Copy the file $(log_color "${SERVER[ip]}:${SERVER[path]}/$SERVER_FILE" yellow) into $(log_color "$folder/$FILENAME" yellow)
    sshpass -p ${SERVER[password]} scp -P ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]}:${SERVER[path]}/$SERVER_FILE $folder/$FILENAME
    ret=$?

    if [ $ret -eq 0 ]; then
        echo -e "$(log_color "History retrieve" green)"
        echo -e History copied: $(log_color "$folder/$FILENAME" yellow)
    else
        echo -e "$(log_color "ERROR: Failed to retrieve history with your credentials." red)\nExiting..."
        exit 1
    fi
}

###
# Remove trace of your pass on the server
# For now removing HISTORY.txt file
###
erase_trace() {
    echo "Erasing trace..."
    folder=$1
    filepath=${SERVER[path]}/$SERVER_FILE

    remove_server_file $filepath

    ret=$?

    if [ $ret -eq 0 ]; then
        echo -e "$(log_color "Trace erased from server" green)"
    else
        echo -e "$(log_color "ERROR: Trace not erased from server" red)\nExiting..."
        exit 1
    fi
}

###
# Remove on remote machine file in filepath in param $1
###
remove_server_file() {
    filepath=$1
    echo Removing File : $(log_color "$filepath" red)

    # check if file exists
    # v=$(sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -q [[ -f $filepath ]] && echo "File exists" || echo "File does not exist")
    file_exists=$(check_server_file_exists $1)

    # if not exists do nothing
    if [ $file_exists -eq 0 ]; then
        # TODO mettre un log warning genre file doesn't exist anymore
        echo "File not exists"
        echo -e $(log_color "File $filepath doesn't exist anymore" blue)
        return
    fi

    # remove file
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -t "rm $filepath"

    ret=$?

    if [ $ret -eq 0 ]; then
        echo -e "$(log_color "File $filepath removed" green)"
    else
        echo -e "$(log_color "ERROR: Failed to remove your file $filepath" red)\nExiting..."
        exit 1
    fi
}

###
# Check on remote machine if file exists in param $1
# if return 1 file exists, 0 otherwise
###
check_server_file_exists() {
    file=$1
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -q [[ -f $filepath ]] && echo 1 || echo 0
}

################################################################### Logging functions ###################################################################

###
# Simple log function to support color
###
# TODO a utiliser au lieu des echo -e
log() {
    echo -e $@
}

typeset -A COLORS=(
    [default]='\033[0;39m'
    [black]='\033[0;30m'
    [red]='\033[0;31m'
    [green]='\033[0;32m'
    [yellow]='\033[0;33m'
    [blue]='\033[0;34m'
    [magenta]='\033[0;35m'
    [cyan]='\033[0;36m'
    [light_gray]='\033[0;37m'
    [light_grey]='\033[0;37m'
    [dark_gray]='\033[0;90m'
    [dark_grey]='\033[0;90m'
    [light_red]='\033[0;91m'
    [light_green]='\033[0;92m'
    [light_yellow]='\033[0;93m'
    [light_blue]='\033[0;94m'
    [light_magenta]='\033[0;95m'
    [light_cyan]='\033[0;96m'
    [nc]='\033[0m'
) # No Color

###
# Log the message in specific color
###
log_color() {
    message=$1
    color=$2
    echo -e ${COLORS[$color]}$message${COLORS[nc]}
}

###
# Log the message if debug mode is activated
###
log_debug() {
    message=$@
    date=$(get_datetime)
    if [ "${OPTIONS[debug]}" = true ]; then log_color "[$date] $message" ${OPTIONS[debug_color]}; fi
}

###
# Return datetime of now (ex: 2022-01-10 23:20:35)
###
get_datetime() {
    echo $(date '+%Y-%m-%d %H:%M:%S')
}

main $@
