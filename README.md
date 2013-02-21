# Overview
Copyright 2013 by Christopher Baus <christopher@baus.net>. Licensed under GPL 1.3

Discourse is the new [web discussion forum software](http://discourse.org) by Jeff Atwood (et al.). Considering the 
state of forum software, I'm confident it is going to be a breakout success. With that said it is still in a 
very early state, and if you are not an expert on Linux and Rail administration, getting a Discourse site up 
and running can be a daunting task.

While I consider myself to be moderately skilled at Linux administration, this is the first Rails app I have 
attempted to deploy and run, so now that I've been through the installation process a few times, I've decided to 
to more formally document it for others who want to try out the software.

The following will set up the *development* environment. I am still working out the specifics of 
deploying a production installation.

# Warning

Not only is Discourse new software, these instructions have been pulled together after a couple days of research. 
Use at your own risk. 

# Install on a DigitalOcean VPS using Ubuntu 12.10x64

[DigitalOcean](https://www.digitalocean.com/) is offering very inexpensive VPS options based on SSDs. Please note that it has 
been determined that to complete a full production installation of Discourse *1GB of RAM is required*. 

# Provision your server

While I'm a long time RedHat and CentOS user, I've recently made the move to Ubuntu, primarily because they offer more 
up-to-date packages. With a project as cutting edge as Discourse, this makes installation easier as it prevents having
to download packages from source and install them, so my instructions use Ubuntu 12.10 x64 server (note:with 
small RAM amounts, a 32bit image would probably work as well, but I'm standardizing on 64bit images). 

After creating your account at DigitalOcean, create a Droplet with at least 1GB of RAM, and select the Ubuntu 
OS image you want to use. DigitalOcean will email the root password to you.

# Login to your server

If you are using OS X or Linux, fire up a terminal ssh to your new server which be at the IP address that DigitialOcean 
has provided. Windows users should consider installing [Putty](http://putty.org/) to access your new server.

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
# Install the Bundler app which installs Rails dependencies
admin@host:~$ sudo gem install bundler
admin@host:~$ sudo gem install therubyracer
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
admin@host:~$ git clone https://github.com/discourse/discourse.git
admin@host:~$ cd discourse
# Now install the application dependencies using bundle
admin@host:~$ bundle install
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

Edit the file to add your Postgres username and password to each configuration in the file. Also add host: localhost
to the production configuration because the production DB will also be run on the localhost in this configuration.

When you are done the file should look some like:

```
development:
  adapter: postgresql
  database: discourse_development
  username: admin
  password: <your_postgres_password>
  host: localhost
  pool: 5
  timeout: 5000
  host_names:
    - "localhost"

# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
test:
  adapter: postgresql
  database: discourse_test
  username: admin
  password: <your_postgres_password>
  host: localhost
  pool: 5
  timeout: 5000
  host_names:
    - test.localhost

# using the test db, so jenkins can run this config
# we need it to be in production so it minifies assets
production:
  adapter: postgresql
  database: discourse_development
  username: admin
  password: <your_postgres_password>
  host: localhost
  pool: 5
  timeout: 5000
  host_names:
    - production.localhost
```

I'm not a fan of entering the DB password as clear text in the database.yml file. If you have a better solution
to this, let me know. 

# Deploy the db and start the server

Now you should be ready to deploy the database and start the server.

This will start the development enviroment on port 3000.
```
admin@host:~$ cd ~/discourse
# Set Rails configuration
admin@host:~$ export RAILS_ENV=development
admin@host:~$ rake db:create
admin@host:~$ rake db:migrate
admin@host:~$ rake db:seed_fu
admin@host:~$ thin start
```

# Installing the production environment

## WARNING: very preliminary recipe follows

# Setup the www-data account
```bash
sudo mkdir /var/www
sudo chgrp www-data /var/www
sudo chmod g+w /var/www
```

# Configure nginx

edit ~/discourse/config/nginx.sample.conf

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
cd ~/discourse/
sudo cp config/nginx.sample.conf /etc/nginx/sites-available/discourse.conf
sudo ln -s /etc/nginx/sites-available/discourse.conf /etc/nginx/sites-enabled/discourse.conf
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx start
```

# Deploy Discourse app to /var/www
```
vi config/initializers/secret_token.rb
export RAILS_ENV=production
rake assets:precompile
sudo -u www-data cp -r discourse/ /var/www
sudo -u www-data mkdir /var/www/discourse/tmp/sockets
```

# Start thin as daemon listening on domain sockets
```bash
cd /var/www/discourse
sudo -u www-data thin start -e production -s4 --socket /var/www/discourse/tmp/sockets/puma.sock
```

