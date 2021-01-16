
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
IP="XX.XX.XX.XX"
PORT="XX"
USER="XXXXX"
PASSWORD="XXXX"
```

you can complete the **XX** with your server credentials, careful your user needs read and write access


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
