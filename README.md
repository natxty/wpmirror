##wpmirror
---

####Overview
A simple bash script to quickly create a dev/mirror of a Wordpress (or other site, actually, that uses a mysql database and some files/folders). I threw this together after reading about a similar script somewhere (to-do: find and attribute original script). I came across [this](http://jrjdev.net/2012/02/moving-a-wordpress-site-with-bash-scripts/) promising variation, but that was not the original, so I am still looking.

####Important Security Note
This script reads in a `config` file using the bash `source` command (or here, ` . $config_file`). This makes it easier for me to separate the configs for different sites. However, it has been noted that this method has some serious security flaws in the wrong hands, so use it privately and sparingly.

I read about the technique [here](http://wiki.bash-hackers.org/howto/conffile) but didn't yet apply the security checks, as this script is (for me) an isolated tool… however… it's on my to-do list, b/c you never know.

####Install
Simply clone, download, or copy into a relevant directory. Make sure you set permissions to execute. 

####Usage
Edit the `sample.cfg` with the necessary information. Run the script with the path-to-your-config file as the first, and only, argument:

    ./wp-mirror.sh config-file.cfg

For example, if we were to use the `sample.config` included in this repo:

    ./wp-mirror.sh sample.cfg

Running it should print out a quick alert and confirmation, since this will empty the target directory & database, if it exists, before copying everything over.  