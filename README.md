# Installing Discourse on Ubuntu and DigitalOcean
Copyright 2013 by Christopher Baus <christopher@baus.net>. Licensed under GPL 2.0

Discourse is [web discussion forum software](http://discourse.org) by Jeff Atwood (et al.). Considering the 
state of forum software, and Jeff's previous success with StackOverflow, I'm confident it is going to be a success. 
With that said it is still in a very early state, and if you are not an expert on Linux and Ruby on Rails administration, 
getting a Discourse site up and running can be a daunting task. 

Hopefully the document will be useful for someone who has some Linux administration experience and wants to run and
administrate their own Discourse server. I am erring on the side of verbosity.


### Create DigitalOcean VPS with Ubuntu 12.10x64

While these instructions should work fine on most Ubuntu installations, I have explicitly tested them on DigitalOcean. 
DigitalOcearn currently offers low cost VPS hosting, but I can not vouch for their reliability. 

I decided on Ubuntu 12.10 x64 since it is the most recent Ubuntu release with the most up to date packages. If you 
concerned about the long term stability of your systems, you may want to consider Ubuntu 12.04 LTS which has 
gaurenteed support until 2017, but the installation instructions are a bit different do to availability of certain packages.

Before creating your DigitalOcean instance, you should register the domain name you want to use for your forum. I'm using 
discoursetest.org for this instance, and forum.discoursetest.org as the FQDN.  

After creating your account at DigitalOcean, create a Droplet *with at least 1GB of RAM* [1], and select the Ubuntu  
OS image you want to use. I set the Hostname to forum.discoursetest.org. 

DigitalOcean will email the IP address and root password to you. You should go to your domain registrar and set the 
DNS records to point to your new IP. I've set both the * and @ records to point to the VPS IP. This allows the root 
domain and all sub-domains to resolve to VPS instance's IP address. 

[1] A minimum of 1GB of RAM is required to compile assets for production.


### Login to your server

I will use discoursetest.org when a domain name is required in the installation. You should replace 
discoursetest.org with your own domain name. If you are using OS X or Linux, start a terminal and ssh to 
your new server. Windows users should consider installing [Putty](http://putty.org/) to access your new server.

```bash
# From your local shell on OS X or Linux
# Remember to replace discoursetest.org with your own domain.
~$ ssh root@discoursetest.org
# Enter the root password provided by DigitalOcean
```

### Change your root password

Since your password has been emailed to you in clear text, you should immediately change your password for security reasons.

```bash
root@host:~# passwd
# # Enter your new password
```

### Create a user account

It is poor practice to admin your system from the root account. Create an administrative account. I'm going to 
call the new user "admin."

Adding the user to the sudo group will allow the user to perform tasks as root using the 
[sudo](https://help.ubuntu.com/community/RootSudo) command. 

```bash
~# adduser admin
~# adduser admin sudo
```
### Login using the admin account

```bash
~# logout
# now back at the local terminal prompt
$ ssh admin@discoursetest.org
```

Todo: should consider removing root SSH access at this point

### Use apt-get to install core system dependencies

The apt-get command is used to add packages to Ubuntu (and all Debian based Linux distributions). DigitalOcean, like many VPS's, ships
with a limited Ubuntu configuration, so you will have to install many of the software the dependencies yourself.

To install system packages, you must have root privledges. Since the admin account is part of the sudo group, the
admin account can run commands with root privledges by using the sudo command. Just prepend sudo to any commands you
want to run as root. This includes apt-get commands to install packages.

```bash
# Install required packages
$ sudo apt-get install postgresql-9.1 postgresql-contrib-9.1 make g++ \
libxml2-dev libxslt-dev libpq-dev ruby1.9.3 git redis-server nginx postfix
```

During the installation, you will be prompted for Postfix configuration information. [Postfix](https://help.ubuntu.com/community/Postfix) is used to send mail from 
Discourse. Just keep the default "Internet Site."

At the next prompt just enter your domain name. In my test case this is discoursetest.org.

TODO: This installs redis 2.4. Discourse explicitly states that they require Redis 2.6, but this requires installing
from source.

### Editing configuration files

At various points in the installation procedure, you will need to edit configuration files with a text editor.
Vi is installed by default and is the de facto standard editor used by admins, so I use vi for any editing commands,
but you may want to consider installing the editor of your choice. I like emacs, so I installed it with: 

```
$ sudo apt-get install emacs
```

### Set the host name

DigitalOcean's provisioning procedure doesn't correctly set the hostname when the instance is created, 
which is inconvient since they know your hostname at the point the instance is created. I'd recommend 
editing /etc/hosts to correctly contain your hostname.

```bash
$ vi /etc/hosts
```

The first line of my /etc/hosts file looks like:
```bash
127.0.0.1  forum.discoursetest.org forum localhost
```

You should replace discoursetest.org with your own domain name. 


### Install the Bundler app which installs Rails dependencies

```bash
$ sudo gem install bundler
$ sudo gem install therubyracer -v '0.11.3'
```

### Configure Postgres user account

Discourse uses the Postgres database to store forum data. The configuration procedure is similar to MySQL, but 
I am a Postgres newbie, so if you have improvements to this aspect of the installation procedure, please let me know.

Note: this is the easiest way to setup the Postgres server, but it also creates a highly privledged Postgres user account. 
Future revisions of this document may offer alternatives for creating the Postgres DBs, which would allow Discourse
to login to Postgres as a user with lower privledges.

```bash
$ sudo -u postgres createuser admin -s -P
```

### Pull and configure the latest version of the Discourse app

Now we are ready install the actual Discourse application. This will pull a copy of the Discourse app from my own branch. 
The advantage of using this branch is that it has been tested with these instructions, but it may fall behind the master
which is rapidly changing. 

```bash
# Pull the latest version from github.
$ git clone https://github.com/baus/discourse.git
$ cd discourse
# Now install the application dependencies using bundle
$ bundle install
```

### Set Discourse application settings
Now you have set the Discourse application settings. The configuration files are in a directory called "config"
There are sample configuration files now included in the master branch, so you need to copy these files and
modify them with your own changes.

```
$ cd ~/discourse/config
$ cp ./database.yml.sample ./database.yml
$ cp ./redis.yml.sample ./redis.yml
```

Now you need to edit the configuration files and apply your own settings. 


Start by editing the database configuration file which should be now located at ~/discourse/config/database.yml

```bash
$ vi ~/discourse/config/database.yml
```

Edit the file to add your Postgres username and password to each configuration in the file. Also add host: localhost
to the production configuration because the production DB will also be run on the localhost in this configuration.

When you are done the file should look similar to:

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

This will start the development environment on port 3000.
```
$ cd ~/discourse
# Set Rails configuration
$ export RAILS_ENV=development
$ rake db:create
$ rake db:migrate
$ rake db:seed_fu
$ thin start
```

I tested the configuration by going to http://discoursetest.org:3000/

# Installing the production environment

## WARNING: very preliminary recipe follows

# Setup the www-data account
```bash
$ sudo mkdir /var/www
$ sudo chgrp www-data /var/www
$ sudo chmod g+w /var/www
```

# Configure nginx

```bash
$ vi ~/discourse/config/nginx.sample.conf
```
The nginx sample configuration file has settings for Puma. They must be updated to work with the Thin web server.

Change the following lines: 

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
  server unix:///var/www/discourse/tmp/sockets/thin.0.sock;
  server unix:///var/www/discourse/tmp/sockets/thin.1.sock;
  server unix:///var/www/discourse/tmp/sockets/thin.2.sock;
  server unix:///var/www/discourse/tmp/sockets/thin.3.sock;
}
```


```bash
$ cd ~/discourse/
$ sudo cp config/nginx.sample.conf /etc/nginx/sites-available/discourse.conf
$ sudo ln -s /etc/nginx/sites-available/discourse.conf /etc/nginx/sites-enabled/discourse.conf
$ sudo rm /etc/nginx/sites-enabled/default
$ sudo service nginx start
```

# Deploy Discourse app to /var/www
```
$ vi config/initializers/secret_token.rb
$ export RAILS_ENV=production
$ rake assets:precompile
$ sudo -u www-data cp -r discourse/ /var/www
$ sudo -u www-data mkdir /var/www/discourse/tmp/sockets
```

# Start Thin as a daemon listening on domain sockets
```bash
$ cd /var/www/discourse
$ sudo -u www-data thin start -e production -s4 --socket /var/www/discourse/tmp/sockets/thin.sock
```
# Start Sidekiq

```bash
$ sudo -u www-data sidekiq -e production -d -l /var/www/discourse/log/sidekiq.log
```

# Create Discourse admin account

* Logon to site and create account using the application UI
* Now make that account the admin:

```bash
sudo -u www-data rails c     
u = User.first    
u.admin = true    
u.save  
```
Todo: add script to create the admin account

# Edit site settings

* Logon to site with the admin account
* Edit settings page http://discoursetest.org/admin/site_settings
* In particular set the notification_email which is the from address used in emails from the system.
** The default value for this setting is in: app/models/site_setting.rb
