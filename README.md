
# Archange project

Create an history files of your server

### Processus

- Create a file in your server with `ls -R` command in choosen repository
- Copy in your local machine it choosen folder with `scp` this file


#### Version 1.0.0


## Configuration

You need to create a file call setting.conf in the repo like this

```bash
$ cd archange
$ touch settings.conf
$ vim settings.conf`
```

  

then you need to put this on **settings.conf**

```bash
ARCHANGE_IP="XX.XX.XX.XX"
ARCHANGE_PORT="XX"
ARCHANGE_USER="XXXXXX"
ARCHANGE_PASSWORD="XXXXXX"
ARCHANGE_PATH="XXXXXX"
```

- ARCHANGE_IP   (mandatory) : Ip of your server
- ARCHANGE_PORT (mandatory): SSH port of your server
- ARCHANGE_USER (mandatory): User which has access to the server
- ARCHANGE_PASSWORD (optional): Password of the user to get access to the server (if you not specified in your config it will be requested later)
- ARCHANGE_PATH     (optional): Path on your server to get the history files (if you not specified in your config it will be requested later )
you can complete the **XX** with your server credentials, careful your user needs read and write access

example
```bash
ARCHANGE_IP="192.168.1.1"
ARCHANGE_PORT="21"
ARCHANGE_USER="toto"
ARCHANGE_PASSWORD="password"
ARCHANGE_PATH="/server/dev" # get history files to the folder /server/dev
```


## How to use

```bash
$ chmod +x archange.sh
$ ./archange.sh`
```

Then follow instructions in your terminal

## Trouble-shootings

If you have any difficulties, problems or enquiries please let me an issue [here](https://github.com/LucasNoga/Archange/issues/new)

## Credits
Made by Lucas Noga
Licensed under GPLv3.
