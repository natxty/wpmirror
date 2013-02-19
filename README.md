##wpmirror
---

####Overview
A simple bash script to quickly create a dev/mirror of a Wordpress (or other site, actually, that uses a mysql database and some files/folders). I threw this together after reading about a similar script somewhere (to-do: find and attribute original script).

####Important Security Note
This script reads in a `config` file using the bash `source` command (or here, ` . $config_file`). This makes it easier for me to separate the configs for different sites. However, it has been noted that this method has some serious security flaws in the wrong hands, so use it privately and sparingly.

####Install
Simply clone, download, or copy into a relevant directory. Make sure you set permissions to execute. 

####Usage
Edit the `sample.cfg` with the necessary information. Run the script with the path-to-your-config file as the first, and only, argument:

    ./wp-mirror.sh config-file.cfg

For example, if we were to use the `sample.config` included in this repo:

    ./wp-mirror.sh sample.cfg

Running it should print out a quick alert and confirmation, since this will empty the target directory & database, if it exists, before copying everything over.  