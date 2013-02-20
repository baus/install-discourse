# Overview
Copyright 2013 by Christopher Baus <christopher@baus.net>. Licensed under GPL 1.3

This document explains how to deploy a production Discourse environment on Ubuntu 12.10 using a
[DigitalOcean](https://www.digitalocean.com/) VPS. These instructions should work on any Ubuntu 12.10 installation, but
I have tested them on Digital Ocean because it is one of the of the least expensive hosting options for Discourse.

# Warning -- THIS IS WORK IN PROGRESS --

Not only is Discourse new software, these instructions have been pulled together after a couple days of research. 
Use at your own risk. Also there are multiple ways to deploy the production environmen, and there maybe 
easier and more secure options. I will try to improve the document overtime.

# Install on a DigitalOcean VPS using Ubuntu 12.10x64

After creating your account at DigitalOcean, create a Droplet with *at least 1GB of RAM*, and select the Ubuntu 12.10 
Server OS image. DigitalOcean will email the root password to you.

# Login to your server

If you are using OS X or Linux, start a terminal and ssh to your server which will be at the IP address that Digitial Ocean 
has provided. Windows users should consider using [Putty](http://putty.org/) to access your server.

```bash
# From your local shell
~$ ssh root@<ip_addr>
# Enter your root password
```

# Change your root password

Since your password has been emailed to you in clear text, you should immediately change your password for security reasons.

```bash
root@host:~# passwd
# # Enter your new password
```

# Create a user account

It is bad practice to admin your system from the root account. 
Create an administrative account, and add it to the sudo group, so the account can 
make system changes with the sudo command. In this case, I'm going to call the new users "admin."

```bash
root@host:~# adduser admin
root@host:~# adduser admin sudo
```
# Logout and log back in using the admin account

```bash
root@host:~# logout
# now back at the local terminal prompt
~$ ssh admin@<ip_addr>
```

# Use apt-get to install core system dependencies

The apt-get command is used to add packages to Ubuntu (and all Debian based Linux distributions). DigitalOcean, like many VPS's, ships
with a limited Ubuntu configuration, so you will have to install many of the software the dependencies yourself.

To install system packages, you have to have root privledges. Since the admin account is part of the sudo group, the
admin account can run commands with root privledges by using the sudo command. Just prepend sudo to any commands you
want to run as root. This includes apt-get commands to install packages.

```bash
# Install required packages
# Note: This installs redis 2.4. 
# Discourse explicitly states that they require Redis 2.6. This should be addressed, 
# and requires building Redis from source.
admin@host:~$ sudo apt-get install postgresql-9.1 postgresql-contrib-9.1 make g++ \
libxml2-dev libxslt-dev libpq-dev ruby1.9.3 git redis-server nginx
admin@host:~$ sudo gem install bundler
admin@host:~$ sudo gem install therubyracer 
```

# Setup the www-data account
```bash
sudo mkdir /var/www
sudo chgrp www-data /var/www
sudo chmod g+w /var/www
```

# Configure Postgres user account

Discourse uses the Postgres database to store forum data. The configuration procedure is similar to MySQL, but 
I am a Postgres newbie, so if you have improvements to this aspect of the installation procedure, please let me know.

Note: this is the easiest way to setup the Postgres server, but it also creates a highly privledged Postgres user account. 
Future revisions of this document may offer alternatives for creating the Postgres DBs, which would allow Discourse
to login to Postgres as a user with lower privledges.

```bash
admin@host:~$ sudo -u postgres createuser admin -s -P
```


# Pull and configure the latest version of the Discourse app

Now we are ready install the actual Discourse application. Note this step shows how to pull the latest version
of the Discourse application from the main development branch. At this point, there a lot of changes occuring
in this branch, so changes may occur at ANY time.

```bash
# Pull the latest version from github.
admin@host:~$ sudo su -l www-data
$ git clone https://github.com/discourse/discourse.git
$ cd discourse
# Now install the application dependencies using bundle
$ bundle install
```

# Set Discourse application settings
Now you have set the Discourse application settings. The configuration files are in a directory called "config"
There are sample configuration files now included in the master branch, so you need to copy these files and
modify them with your own changes.

```
admin@host:~$ cd ~/discourse/config
admin@host:~$ cp ./database.yml.sample ./database.yml
admin@host:~$ cp ./redis.yml.sample ./redis.yml
```

Now you need to edit the configuration files and apply your own settings. To do this you should use your favorite 
text editor. Vi is installed by default, but I like emacs, so I installed it with: 

```
admin@host:~$ sudo apt-get install emacs
```


Start by editing the database configuration file which should be now located at ~/discourse/config/database.yml

```bash
admin@host:~$ vi ~/discourse/config/database.yml
```

Edit the file to add your Postgres username and password to the file as follows:

```
development:
  adapter: postgresql
  database: discourse_development
  username: admin
  password: <your_postgres_password>
  pool: 5
  timeout: 5000
  host_names:
    - "localhost"
```

I'm not a big fan of entering the DB password as clear text in the database.yml file. If you have a better solution
to this, let me know. 


# Discourse Production Configuration

```
export RAILS_ENV=production

edit config/initializers/secrete_token.rb
sudo mkdir /var/www
sudo chown www-data /var/www
sudo chgrp www-data /var/www
sudo -u www-data cp -r discourse/ /var/www
sudo cp nginx.sample.conf /etc/nginx/sites-available/discourse.conf
```
edit /etc/nginx/site-available/discourse.conf

change the following lines: 
```
upstream discourse {
  server unix:///var/www/discourse/tmp/sockets/puma0.sock;
  server unix:///var/www/discourse/tmp/sockets/puma1.sock;
  server unix:///var/www/discourse/tmp/sockets/puma2.sock;
  server unix:///var/www/discourse/tmp/sockets/puma3.sock;
}
```

to:
```
upstream discourse {
  server unix:///var/www/discourse/tmp/sockets/puma.0.sock;
  server unix:///var/www/discourse/tmp/sockets/puma.1.sock;
  server unix:///var/www/discourse/tmp/sockets/puma.2.sock;
  server unix:///var/www/discourse/tmp/sockets/puma.3.sock;
}
```

I think this is typo in the sample configuration file.

```bash
sudo ln -s /etc/nginx/sites-available/discourse.conf /etc/nginx/sites-enabled/discourse.conf
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx start
sudo -u www-data mkdir /var/www/discourse/tmp/sockets
sudo -u www-data thin start -e production -s4 --socket /var/www/discourse/tmp/sockets/puma.sock
sudo -u www-data thin stop -e production -s4 --socket /var/www/discourse/tmp/sockets/puma.sock
```
