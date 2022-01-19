#!/bin/bash

# ------------------------------------------------------------------
# [Title] : Archange
# [Description] : Save the history of a server
# [Version] : v1.5.0
# [Author] : Lucas Noga
# [Shell] : Bash v5.0.17
# [Usage] : ./archange.sh
#           ./archange.sh --debug
#           ./archange.sh --debug --setup
#           ./archange.sh --show-config
# ------------------------------------------------------------------

PROJECT_NAME=ARCHANGE
PROJECT_VERSION=v1.5.0

# Parameters to execute script
typeset -A CONFIG=(
    [run]=true                                         # If run is to false we don't execute the script
    [config_prefix]=$PROJECT_NAME                      # For settings.conf variable already used in the system ($USER, $PATH)
    [config_file]="./settings.conf"                    # Configuration file
    [server_file]="HISTORY.txt"                        # File created on the server to get history
    [folder_history]=""                                # Folder to store on the local machine the history
    [filename_history]=HISTORY-$(date +"%Y-%m-%d").txt # Name of the file which will get the copy (default HISTORY_date)
    [default_folder_history]="./History"               # Default Folder to store if no define in settings.conf
    [debug_color]=light_blue                           # Color to show log in debug mode
)

# Options params setup with command parameters
typeset -A OPTIONS=(
    [debug]=false          # Debug mode to show more log
    [erase_trace]=false    # if true we erase trace on the remote machine
    [show_history]=false   # If true launch script to show all history files
    [show_settings]=false  # If true launch script to show configuration file
    [setup_settings]=false # If true launch script to setup configuration file
    [no_details]=false     # if true we get only the file name in our history if not we get ls --format=long --all --recursive --human-readable
)

# Parameters to get access to the remote machine
typeset -A SERVER=(
    [ip]=""       # ip of the server set in config
    [port]=""     # port of the server set in config
    [user]=""     # user of the server set in config
    [password]="" # password of the server set in config
    [path]=""     # path of the server set in config
)

###
# Main body of script starts here
###
function main {
    read_options $@ # Read script options like (--debug)
    log_debug "Launch Project $(log_color "${PROJECT_NAME} : ${PROJECT_VERSION}" "magenta")"

    # Read .conf file (default ./setting.conf)
    read_config ${CONFIG[config_file]}

    # Launch specific script depend of options
    launch_script
}

###
# Show which script to execute default (history)
###
function launch_script {
    if [ ${OPTIONS[show_history]} == true ]; then
        log_debug "Showing history"
        show_history ${CONFIG[folder_history]}
        return
    elif [ ${OPTIONS[show_settings]} == true ]; then
        show_settings
        return
    elif [ ${OPTIONS[setup_settings]} == true ]; then
        setup_settings
        return
    fi

    # Create the file to kept data history of your server
    launch_history
}

###
# Setup variables from config file
# $1 = path to the config file (default: ./setting.conf)
###
function read_config {
    configuration_file=$1
    log_debug "Read configuration file: $configuration_file"

    if [ ! -f "$configuration_file" ]; then
        log_color "ERROR: $configuration_file doesn't exists." "red"
        log "Exiting..."
        exit 1
    fi

    # Load configuration file
    source $configuration_file
    log_debug "Configuration file $configuration_file loaded"

    # Load data to get access to remote machine
    read_config_server $configuration_file

    # Load the other data
    set_config "folder_history" $(eval echo $FOLDER_HISTORY)
    if [ -z ${CONFIG[folder_history]} ]; then
        set_config "folder_history" ${CONFIG[default_folder_history]}
        log "No folder define get default value of folder: $(log_color "${CONFIG[default_folder_history]}" "yellow")"
    fi

    log_debug "Dump: $(declare -p CONFIG)"
    log_debug "Dump: $(declare -p SERVER)"
}

###
# Setup remote machine (user, password, ip, port) from config file
# $1 = path to the config file (default: ./setting.conf)
###
function read_config_server {
    configuration_file=$1

    SERVER+=(
        [ip]=$(eval echo $IP)
        [port]=$(eval echo $PORT)
        [user]=$(eval echo \$${CONFIG[config_prefix]}"_USER") # Env variable already defined in the system ($USER) so we prefix it with ARCHANGE_
        [password]=$(eval echo $PASSWORD)
        [path]=$(eval echo \$${CONFIG[config_prefix]}"_PATH") # Env variable already defined in the system ($PATH) so we prefix it with ARCHANGE_
    )

    # Check empty values
    if [ -z ${SERVER[ip]} ]; then
        log_color "ERROR: IP is not defined into $configuration_file" "red"
        log "Exiting..."
        exit 1
    fi
    if [ -z ${SERVER[port]} ]; then
        log_color "ERROR: PORT is not defined into $configuration_file" "red"
        log "Exiting..."
        exit 1
    fi
    if [ -z ${SERVER[user]} ]; then
        log_color "ERROR: USER is not defined into $configuration_file" "red"
        log "Exiting..."
        exit 1
    fi
}

################################################################### Params Scripts ###################################################################

###
# Setup params passed with the script
# -d | --debug : Setup debug mode
# --erase-trace : Erase file and your trace on remote machine
###
function read_options {
    params=("$@") # Convert params into an array

    # Check if debug exists between all parametters
    for param in "${params[@]}"; do
        [[ $param == "-d" ]] || [[ $param == "--debug" ]] && active_debug_mode
    done

    # Step through all params passed to the script
    for param in "${params[@]}"; do
        log_debug "Option '$param' founded"
        case $param in
        "--erase-trace")
            log_debug "Erase Trace activated"
            set_option "erase_trace" "true"
            ;;
        "--no-details")
            log_debug "No details activated"
            set_option "no_details" "true"
            ;;
        "--show-history")
            set_option "show_history" "true"
            ;;
        "-c" | "--config" | "--show-config")
            set_option "show_settings" "true"
            ;;
        "-s" | "--setup" | "--setup-config")
            set_option "setup_settings" "true"
            ;;
        *) ;;
        esac
    done

    log_debug "Dump: $(declare -p OPTIONS)"
}

###
# Active the debug mode by changing options params
###
function active_debug_mode {
    if [ ${OPTIONS[debug]} == true ]; then
        log_debug "Debug Mode already activated"
        return
    fi
    set_option "debug" "true"
    log_debug "Debug Mode Activated"
}

###
# Set value to the OPTIONS array
# $1 : [string] key to update
# $2 : [string] value to set
###
function set_option {
    OPTIONS+=([$1]=$2)
}

###
# Set value to the CONFIG array
# $1 : [string] key to update
# $2 : [string] value to set
###
function set_config {
    CONFIG+=([$1]=$2)
}

###
# List settings in settings.conf file if they are defined
# $1: path where the settings file is (default: "./settings.conf")
###
function show_settings {
    file=$1
    # get default configuration file if no filled
    if [ -z $file ]; then
        file=${CONFIG[config_file]}
    fi

    read_config $file

    log "Here's your settings: "
    log "\t- Ip:" $(log_color "${SERVER[ip]}" "yellow")
    log "\t- Port:" $(log_color "${SERVER[port]}" "yellow")
    log "\t- User:" $(log_color "${SERVER[user]}" "yellow")
    log "\t- Password:" $(log_color "${SERVER[password]}" "yellow")
    log "\t- Path:" $(log_color "${SERVER[path]}" "yellow")
    log "\t- File where the history is saved:" $(log_color "${CONFIG[folder_history]}/${CONFIG[filename_history]}" "yellow")
}

###
# Setup the settings in command line for the user, if the file exists we erased it
# $1: path where the settings file is (default: "./settings.conf")
###
function setup_settings {
    file=$1
    log "Setup settings need some intels to create your settings"
    # get default configuration file if no filled
    if [ -z $file ]; then
        file=${CONFIG[config_file]}
    fi

    # Check if you want to override the file
    if [ -f $file ]; then
        override=$(ask_yes_no "$(log_color "$file" "yellow") already exists do you want to override it")
        if [ "$override" == false ]; then
            log_color "Abort settings editing - no override" "red"
            exit 0
        fi
    fi

    # DEFAULT VALUES
    typeset -A DEFAULT_VALUES=(
        [IP]="192.168.0.1"
        [PORT]="22"
        [USER]="root"
        [PASSWORD]="root_password"
        [PATH]="/mnt/disk"
        [FOLDER_HISTORY]="./History"
    )

    log_debug "Dump: $(declare -p DEFAULT_VALUES)"

    # Read value for the user
    ip=$(read_data "Ip of remote machine (default: $(log_color ${DEFAULT_VALUES[IP]} yellow))" "number")
    port=$(read_data "Port of remote machine (default: $(log_color ${DEFAULT_VALUES[PORT]} yellow))" "number")
    path=$(read_data "Path of remote machine to save history on your machine (default: $(log_color ${DEFAULT_VALUES[PATH]} yellow))" "text")
    user=$(read_data "User of remote machine (default: $(log_color ${DEFAULT_VALUES[USER]} yellow))" "text" 1)
    folder=$(read_data "Folder local when you want to save your history (default: $(log_color ${DEFAULT_VALUES[FOLDER_HISTORY]} yellow))" "text")
    password=$(read_data "Password of remote machine (default: $(log_color ${DEFAULT_VALUES[PASSWORD]} yellow))" "password")

    typeset -A INPUTS+=(
        [IP]="$ip"
        [PORT]="$port"
        [USER]="$user"
        [PASSWORD]="$password"
        [PATH]="$path"
        [FOLDER_HISTORY]="$folder"
    )

    # Check all the inputs
    check_inputs DEFAULT_VALUES INPUTS

    log_debug "Dump: $(declare -p INPUTS)"

    echo "\n"
    for data in "${!INPUTS[@]}"; do
        if [ $data == "PASSWORD" ]; then
            log_debug "$data -> ${INPUTS[$data]}"
        else
            log_color "$data -> ${INPUTS[$data]}" "light_blue"
        fi
    done

    confirmation=$(ask_yes_no "$(log_color "Do you want to apply this settings ?" "yellow")")
    if [ "$confirmation" == false ]; then
        log_color "Abort settings editing - no confirmation data" "red"
        exit 0
    fi

    # Write the settings
    write_settings_file $file "$(declare -p INPUTS)"

    # show the new settings
    show_settings $file
}

###
# Check data filled by user and process it by replacing by default value if conditions are not satisfied
# $1 : [Assoc-Array] default values set before
# $2 : [Assoc-Array] inputs values from user
# return [Assoc-Array] new inputs value
###
function check_inputs {
    declare -n DEFAULTS="$1" # Get Reference of variable DEFAULTS_VALUE before to not get a copie
    declare -n DATA=$2       # Get Reference of variable INPUTS before to not get a copie

    for key in "${!DATA[@]}"; do
        val=${DATA[$key]}
        count=${#val}
        case $key in
        "IP")
            min_char=1
            regex="^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$"
            ;;
        "PORT")
            min_char=1
            regex="^[0-9]{0,5}$"
            ;;
        "USER" | "PATH" | "PORT" | "FOLDER_HISTORY")
            min_char=1
            regex=""
            ;;
        "PASSWORD")
            min_char=0
            regex=""
            ;;
        *)
            min_char=1 # Default character to check
            regex=""
            ;;
        esac

        # Do the check on char number
        # if no values
        if [ $count -eq 0 ]; then
            log_debug "Setting default value for $key: ${DEFAULTS[$key]}"
            DATA+=([$key]=${DEFAULTS[$key]})
            continue
        # if less than expected
        elif [ $count -lt $min_char ]; then
            log_color "Incorrect value for $key you need $min_char characters at least. You have only $count ($val)" "red"
            log "Setting default value for $key: ${DEFAULTS[$key]}"
            DATA+=([$key]=${DEFAULTS[$key]})
            continue
        fi

        # Check Regex if exists for
        if
            [ ! -z "$regex" ] &
            [[ ! $val =~ $regex ]]
        then
            log_color "Regex not valid for $key (value: \"$val\")" "red"
            log "Setting default value for $(log_color "$key: ${DEFAULTS[$key]}" "yellow")"
            DATA+=([$key]=${DEFAULTS[$key]})
        fi
    done
}

###
# Write the file settings the settings in command line for the user, if the file exists we erased it
# $1: [string] path where the settings file is (default: "./settings.conf")
# $2: [array] data to insert into the setting like (ip, user of else)
###
function write_settings_file {
    file=$1
    eval "declare -A DATA="${2#*=} # eval string into a new associative array

    # if file doesn't exist we create it
    if [ ! -f $file ]; then
        log_debug "Creating $(log_color "$file" "yellow")"
        touch $file
        log_debug "$(log_color "$file" "yellow") Created"
    else
        log_debug "Resetting old settings in $(log_color "$file" "yellow")"
        >$file # Resetting file
        log_debug "$(log_color "$file" "yellow") Reseted"
    fi

    echo "IP=${DATA[IP]}" >>$file
    echo "PORT=${DATA[PORT]}" >>$file
    echo "ARCHANGE_USER=${DATA[USER]}" >>$file
    echo "PASSWORD=${DATA[PASSWORD]}" >>$file
    echo "ARCHANGE_PATH=${DATA[PATH]}" >>$file
    echo "FOLDER_HISTORY=${DATA[FOLDER_HISTORY]}" >>$file
}

################################################################### Core ###################################################################

###
# Main method to create history
###
function launch_history {
    if [ "${CONFIG[run]}" = false ]; then
        log_debug "No run history because some options block it"
        return
    fi

    setup_folder_history ${CONFIG[folder_history]}

    get_server_path_history

    # Ask password if no filled in config
    read_server_password

    create_history
    copy_history_to_local

    # Remove file(s) from servers if option is activated
    if [ "${OPTIONS[erase_trace]}" = true ]; then
        erase_trace
    fi
}

###
# Main method to show files history
# $1 : [string] path to folder where history files are saved
###
function show_history {
    folder=$1
    exists=$(check_folder_exists $folder)

    # if not exists exit program
    if [ $exists -eq 0 ]; then
        log "Path $(log_color "$folder" "yellow") doesn't exist.\nPlease change $(log_color "FOLDER_HISTORY" "yellow") value in $(log_color "${CONFIG[config_file]}" "yellow")"
        log "$(log_color "Because folder" "red") $(log_color "${SERVER[path]}" "magenta") $(log_color "doesn't exist in remote machine" "red")"
        exit 1
    fi

    # Get middle of the screen size
    size=$(($(get_terminal_width) - $(get_terminal_width) / 2))

    # Command to list history
    ls -A1 --reverse --color=always $folder | nl | column -c $size
}

###
# Create History folder if it doesn't created yet
# $1: Folder History path from config
###
function setup_folder_history {
    folder=$1
    if [ -d $folder ]; then
        log_debug "Folder $folder already exists. No need to create it."
    else
        log "Folder $(log_color "$folder" "yellow") doesn't exist.\nCreating..."
        mkdir $folder
        log "Folder $(log_color "$folder" "green") Created"
    fi
}

###
# Get folder to copy the file on your local machine and test if it's exist
# $1: Folder path
# Return: [string] folder where we copy the file
###
function get_folder {
    folder=$1
    if [ -z $folder ] || [ ! -d $folder ]; then
        folder="."
    fi
    echo $folder
}

###
# Read server password asked if it's not set in config
###
function read_server_password {
    if [ -z ${SERVER[password]} ]; then
        read -s -p "Type your nas admin password: " SERVER[password]
    fi
}

###
# Get path on the server to get the history
###
function get_server_path_history {
    if [ -z ${SERVER[path]} ]; then
        read -p "Type the path you want to get history: " SERVER[path]
    fi
    log "Path of the scan history: $(log_color ${SERVER[path]} yellow)"
}

###
# Create ssh connection to server and create a file with all history
###
function create_history {
    log_debug "Creating SERVER history..."
    log_debug "Connection to the SERVER..."

    # Check if folder exists
    folder_exists=$(check_server_folder_exists ${SERVER[path]})
    # if not exists exit program
    if [ $folder_exists -eq 0 ]; then
        log "Please change $(log_color "${CONFIG[config_prefix]}_PATH" "yellow") in $(log_color "${CONFIG[config_file]}" "yellow")"
        log "$(log_color "Because folder" "red") $(log_color "${SERVER[path]}" "magenta") $(log_color "doesn't exist in remote machine" "red")"
        exit 1
    else
        log_debug "Can create history from ${SERVER[path]} because it does exist"
    fi

    # get command to use in remote machine
    cmd=$(get_remote_command)

    sshpass -p ${SERVER[password]} ssh ${SERVER[user]}@${SERVER[ip]} -p ${SERVER[port]} "cd ${SERVER[path]} && $cmd > ${CONFIG[server_file]}"
    ret=$?
    # if something's wrong
    if [ ! $ret -eq 0 ]; then
        log_color "ERROR: Failed to create history with your params." "red"
        log "Exiting..."
        exit 1
    fi
    log $(log_color "History created on the server here:" "green") $(log_color ${SERVER[ip]}:${SERVER[path]}/${CONFIG[server_file]} "yellow")
}

###
# Create command to execute in remote machine to get history
# can be with date size and others or just the filename
# return [string] the command to execute in remote machine
###
function get_remote_command {
    options=""
    cmd=""
    # if only filename is wanted
    if [ ${OPTIONS[no_details]} = true ]; then
        cmd="ls . -R"
    else # with size and date
        # Show file like this (file --- size --- date )
        columns='$7, $5, $6'
        date_format="+%Y-%m-%d--%H:%M:%S"

        space_field="\t\t\t\t\t"
        space_line="\n"
        cmd="ls . -lRh --time-style=$date_format | awk 'BEGIN { OFS = \"$space_field\"; ORS = \"$space_line\" } {print $columns}'"
    fi

    # Show file like this (file --- size --- date )
    columns='$7, $5, $6'

    echo $cmd
}

###
# Copy history file from server to local
###
function copy_history_to_local {
    folder=${CONFIG[folder_history]}
    log_debug "Copy History in local machine...\nConnection to the SERVER..."

    server_path=${SERVER[ip]}:${SERVER[path]}/${CONFIG[server_file]}
    local_path=$folder/${CONFIG[filename_history]}
    log "Copy the file from $(log_color "$server_path" yellow) to $(log_color "$local_path" yellow)"

    # Copy the file
    sshpass -p ${SERVER[password]} scp -P ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]}:${SERVER[path]}/${CONFIG[server_file]} $folder/${CONFIG[filename_history]}

    ret=$?

    # if something's wrong
    if [ ! $ret -eq 0 ]; then
        log_color "ERROR: Failed to retrieve history with your credentials." "red"
        log "Exiting..."
        exit 1
    fi
    log $(log_color "History copied:" "green") $(log_color $folder/${CONFIG[filename_history]} "yellow")
}

###
# Remove trace of your pass on the server
# For now removing HISTORY.txt file
###
function erase_trace {
    log_debug "Erasing trace..."
    folder=$1
    filepath=${SERVER[path]}/${CONFIG[server_file]}

    remove_server_file $filepath

    ret=$?

    # if something's wrong
    if [ ! $ret -eq 0 ]; then
        log_color "ERROR: Trace not erased from server" "red"
        exit 1
    fi
    log_color "Trace erased from remote machine" "green"
}

###
# Remove on remote machine file in filepath in param $1
###
function remove_server_file {
    filepath=$1
    log_debug "Removing File in the server : $(log_color "$filepath" red)"

    # check if file exists
    file_exists=$(check_server_file_exists $1)

    # if not exists do nothing
    if [ $file_exists -eq 0 ]; then
        log_color "File $filepath doesn't exist anymore" "light_yellow"
        return
    fi

    # remove file
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -qq -t "rm $filepath"

    ret=$?

    # if something's wrong
    if [ ! $ret -eq 0 ]; then
        log_color "ERROR: Failed to remove your file $filepath" "red"
        log "Exiting..."
        exit 1
    fi
    log "File $(log_color ${SERVER[ip]}:$filepath yellow) removed"
}

###
# Check on remote machine if folder exists in param $1
# $1 : [string] folder path to test
# Return: [bool] 1 file exists, 0 if not
###
function check_server_folder_exists {
    folder_path=$1
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -q [[ -d $folder_path ]] && echo 1 || echo 0
}

###
# Check on remote machine if file exists in param $1
# $1 : [string] file path to test
# Return: [bool] 1 file exists, 0 if not
###
function check_server_file_exists {
    filepath=$1
    sshpass -p ${SERVER[password]} ssh -p ${SERVER[port]} ${SERVER[user]}@${SERVER[ip]} -q [[ -f $filepath ]] && echo 1 || echo 0
}

###
# Check if folder exists in param $1
# $1 : [string] folder path to test
# Return: [bool] 1 file exists, 0 if not
###
function check_folder_exists {
    folder_path=$1
    [[ -d $folder_path ]] && echo 1 || echo 0

}

################################################################### Utils functions ###################################################################

###
# Return datetime of now (ex: 2022-01-10 23:20:35)
###
function get_datetime {
    log $(date '+%Y-%m-%d %H:%M:%S')
}

###
# Ask yes/no question for user and return boolean
# $1 : question to prompt for the user
###
function ask_yes_no {
    message=$1
    read -r -p "$message [y/N] : " ask
    if [ "$ask" == 'y' ] || [ "$ask" == 'Y' ]; then
        echo true
    else
        echo false
    fi
}

###
# Setup a read value for a user, and return it
# $1: [string] message prompt for the user
# $2: [string] type of data wanted (text, number, password)
# $3: [integer] number of character wanted at least
###
function read_data {
    message=$1
    type=$2
    min_char=$3

    if [ -z $min_char ]; then min_char=0; fi

    read_options=""
    case $type in
    "text")
        read_options="-r"
        ;;
    "number")
        read_options="-r"
        ;;
    "password")
        read_options="-rs"
        ;;
    *) ;;
    esac

    # read command value
    read $read_options -p "$message : " value

    echo $value
}

###
# Remember to pass an array as param into a function (pass it in param with $(declare -p array))
# $1 : [Array] associative array to reuse
###
function print_array {
    eval "declare -A func_assoc_array="${1#*=} # eval string into a new associative array
    declare -p func_assoc_array                # proof that array was successfully created
}

###
# Get the terminal witdh in character
# return [number] : width of the terminal screen
###
function get_terminal_width {
    echo $(tput cols)
}

################################################################### Logging functions ###################################################################

###
# Simple log function to support color
###
function log {
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
    [nc]='\033[0m' # No Color
)

###
# Log the message in specific color
###
function log_color {
    message=$1
    color=$2
    log ${COLORS[$color]}$message${COLORS[nc]}
}

###
# Log the message if debug mode is activated
###
function log_debug {
    message=$@
    date=$(get_datetime)
    if [ "${OPTIONS[debug]}" = true ]; then log_color "[$date] $message" ${CONFIG[debug_color]}; fi
}

main $@
