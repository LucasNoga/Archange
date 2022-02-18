# Archange project

**_Version v1.5.0_**

Save the history of a server by creating a file history

Developped in Bash `v5.1.0`

## Index

- [Comming Next](#comming-next)
- [Get Started](#get-started)
- [How to use](#how-to-use)
- [Script options](#script-options)
- [Export configuration of DSM](#export-configuration-of-dsm)
- [Manual Process](#manual-process)
- [Trouble-shootings](#trouble-shootings)
- [Credits](#credits)

## Comming next

- Integrate Auto-completion for Archange options
- Add `--help` options with description of the script + options descriptions
- Add pagination in `--show_history` options

## Get Started

You need to create a file call settings.conf in the repo like this

```bash
$ git clone https://github.com/LucasNoga/Archange.git
$ cd archange
```

Then create your configuration file **settings.conf**

```bash
$ touch settings.conf
$ vim settings.conf
```

Put this into the file with your server intels

```bash
IP="XX.XX.XX.XX"
PORT="XX"
ARCHANGE_USER="XXXXXX"
PASSWORD="XXXXXX"
ARCHANGE_PATH="XXXXXX"
FOLDER_HISTORY="XXXXX"
```

- IP (mandatory) : Ip of your server
- PORT (mandatory): SSH port of your server
- ARCHANGE_USER (mandatory): User which has access to the server
- PASSWORD (optional): Password of the user to get access to the server (if you not specified in your config it will be requested later)
- ARCHANGE_PATH (optional): Path on your server to get the history files (if you not specified in your config it will be requested later )
  you can complete the **XX** with your server credentials, careful your user needs read and write access
- FOLDER_HISTORY (optional): Path when you want to store your history files (default: "./History")

Example

```bash
IP="192.168.1.1"
PORT="21"
ARCHANGE_USER="toto"
PASSWORD="password"
ARCHANGE_PATH="/server/dev" # get history files to the folder /server/dev
FOLDER_HISTORY="./MyHistory" # Store files into the folder ./MyHistory
```

## How to use

```bash
$ chmod +x archange.sh
$ cp settings.sample.conf settings.conf
$ ./archange.sh
```

Then follow instructions in your terminal

## Script options

Show help of the script

```bash
$ ./archange.sh --help
```

Display debug mode

```bash
$ ./archange.sh -v
$ ./archange.sh --verbose
```

Only the filename in your history file instead of (size, date, etc...)

```bash
$ ./archange.sh --no-details
```

Show history saved if history=5 we display only the last 5 files backups

```bash
$ ./archange.sh -history
$ ./archange.sh -history=5
```

Show configuration data with your file

```bash
$ ./archange.sh --show-settings
```

Setup configuration file

```bash
$ ./archange.sh --setup
```

Erase trace on the server

```bash
$ ./archange.sh --trace-erase
```

## Export configuration of DSM

- Go to your NAS Synology then go to `Panel Configuration` > `Configuration Backup`
- Click to `Export`

## Manual Process

- Connect to your remote machine with ssh command `ssh <USER>@<IP> -p <PORT>`
- Go to your folder when you want to get history
- Create a file in your server with `ls -R . > HISTORY.txt` command in choosen repository
- Copy in your local machine it choosen folder with `scp -p <PORT> <USER>@<IP>:/PATH/.../HISTORY.txt HISTORY-$(date +"%Y-%m-%d").txt` this file

## Trouble-shootings

If you have any difficulties, problems or enquiries please let me an issue [here](https://github.com/LucasNoga/Archange/issues/new)

## Credits

Made by Lucas Noga  
Licensed under GPLv3.
