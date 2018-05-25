# Unofficial Guide to Installing Discourse on Ubuntu and DigitalOcean
Copyright 2013 by Christopher Baus <christopher@baus.net>. Licensed under GPL 2.0

**NOTE: There is now official Ubuntu installation instructions from Discourse**

References:

* [Screen capture of this procedure](http://player.vimeo.com/video/62145259)
* [Official Discourse Ubuntu Guide](https://github.com/discourse/discourse/blob/master/docs/INSTALL-ubuntu.md)
* [Deploying Discourse using Capistrano](http://davidcel.is/blog/2013/05/02/deploying-discourse-with-capistrano/)

Discourse is [web forum software](http://discourse.org) by [Jeff Atwood](http://codinghorror.com/) ([et](http://eviltrout.com/) [al.](http://samsaffron.com/)). Considering the 
state of forum software, and Jeff's previous success with StackOverflow, I'm confident it is going to be a success. 
With that said, if you are not an experienced Linux or Ruby on Rails administration, getting a Discourse 
site up and running can be daunting. 

Hopefully the document will be useful for someone who has some Linux administration experience and wants to run and
administrate their own server. I am erring on the side of verbosity.

### Create DigitalOcean VPS with Ubuntu 12.10x64

While these instructions should work fine on most Ubuntu installations, I have tested them on 
[Digital Ocean](https://www.digitalocean.com/?refcode=d1d5441c5395). DigitalOcean offers low cost VPS hosting, but I can not vouch for their 
reliability. 

I decided on Ubuntu 12.10 x64 which is the most recent Ubuntu release and contains the most recent packages. You may 
want to consider Ubuntu 12.04 LTS which has guaranteed support until 2017, but the installation instructions are a bit 
different due to the availability of some packages.

Before creating your DigitalOcean instance, you should register the domain name you want to use for your forum. 
I'm using discoursetest.org for this instance, and forum.discoursetest.org as the [FQDN](http://en.wikipedia.org/wiki/Fully_qualified_domain_name).  

After creating your account at DigitalOcean, create a Droplet *with at least 1GB of RAM* [1], and select the Ubuntu  
OS image you want to use. I set the Hostname to forum.discoursetest.org. 

DigitalOcean will email the IP address and root password to you. You should go to your domain registrar and set the 
DNS records to point to your new IP. I've set both the * and @ records to point to the VPS IP. This enables the root 
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
~# adduser admin --gecos ""
# Note: --gecos suppresses prompts for the user meta data such as name, room number, work phone, etc.
~# adduser admin sudo
```
### Login using the admin account

```bash
~# logout
# now back at the local terminal prompt
$ ssh admin@discoursetest.org
```

### Use apt-get to install core system dependencies

The apt-get command is used to add packages to Ubuntu (and all Debian based Linux distributions). DigitalOcean, like many VPS's, ships
with a limited Ubuntu configuration, so you will have to install many of the software the dependencies yourself.

To install system packages, you must have root privileges. Since the admin account is part of the sudo group, the
admin account can run commands with root privileges by using the sudo command. Just prepend sudo to any commands you
want to run as root. This includes apt-get commands to install packages.

```bash
# Install required packages
$ sudo apt-get install postgresql-9.1 postgresql-contrib-9.1 make g++ \
libxml2-dev libxslt-dev libpq-dev ruby1.9.3 git redis-server nginx postfix
```

During the installation, you will be prompted for Postfix configuration information. [Postfix](https://help.ubuntu.com/community/Postfix) is used to send mail from 
Discourse. Just keep the default "Internet Site."

At the next prompt just enter your domain name. In my test case this is discoursetest.org.

Also, make sure you system packages are up to date.
```
$ sudo apt-get update
```

### Editing configuration files

At various points in the installation procedure, you will need to edit configuration files with a text editor.
Vi is installed by default and is the de facto standard editor used by admins, so I use vi for any editing commands,
but you may want to consider installing the editor of your choice. I like emacs, so I installed it with: 

```
$ sudo apt-get install emacs
```

### Set the host name

DigitalOcean's provisioning procedure doesn't correctly set the hostname when the instance is created, 
which is inconvenient since they know your hostname at the point the instance is created. I'd recommend 
editing /etc/hosts to correctly contain your hostname.

```bash
$ sudo vi /etc/hosts
```

The first line of my /etc/hosts file looks like:
```bash
127.0.0.1  forum.discoursetest.org forum localhost
```

You should replace discoursetest.org with your own domain name. 


### Install the Bundler app which installs Rails dependencies

```bash
$ sudo gem install bundler
$ sudo gem install therubyracer -v '0.11.3' (is this still needed?)
```

### Configure Postgres user account

Discourse uses the Postgres database to store forum data. This is an easy way to setup the Postgres server, but it also creates a highly privileged Postgres user account. 
Future revisions of this document may offer alternatives for creating the Postgres DBs, which would allow Discourse
to login to Postgres as a user with lower privileges.

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
You must set the Discourse application settings appropriately. The configuration files are in a directory called "config"
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

Edit the file to add your Postgres username and password to each configuration in the file. 

Add `host: localhost` to the production configuration because the production DB will also be run on the 
localhost in this configuration.

For the production configuration make sure the host_names variable references your domain. This is important to 
make sure links in emails are generated properly. 

When you are done the file should look similar to:

```
development:
  adapter: postgresql
  database: discourse_development
  username: admin
  password: <your_postgres_password>
  min_messages: warning
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
  min_messages: warning
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
    - discoursetest.org # Update this to be the domain of your production site

profile:
  adapter: postgresql
  database: discourse_development
  min_messages: warning
  host: localhost
  pool: 5
  timeout: 5000
  host_names:
    - "localhost"

```

I'm not a fan of entering the DB password as clear text in the database.yml file. If you have a better solution
to this, let me know. 

### Deploy the db and start the server

Now you should be ready to deploy the database and start the server.

This will start the development environment on port 3000.
```
$ cd ~/discourse
# Set Rails configuration 
$ rake db:create db:migrate db:seed_fu RAILS_ENV=development
$ thin start
```

I tested the configuration by going to http://discoursetest.org:3000/

## Installing the production environment

## WARNING: very preliminary instructions follows

### Setup the www-data account
```bash
$ sudo mkdir /var/www
$ sudo chgrp www-data /var/www
$ sudo chmod g+w /var/www
```

### Configure nginx

```bash
$ cd ~/discourse/
$ sudo cp config/nginx.sample.conf /etc/nginx/sites-available/discourse.conf
$ sudo ln -s /etc/nginx/sites-available/discourse.conf /etc/nginx/sites-enabled/discourse.conf
$ sudo rm /etc/nginx/sites-enabled/default
$ sudo service nginx start
```

### Deploy Discourse app to /var/www
This needs more discussion...
```
$ rake secret
$ sudo vi config/initializers/secret_token.rb
```


```
$ export RAILS_ENV=production
$ rake db:create db:migrate db:seed_fu
$ rake assets:precompile
$ sudo -u www-data cp -r ~/discourse/ /var/www
$ sudo -u www-data mkdir /var/www/discourse/tmp/sockets
$ sudo cp /var/www/discourse/config/environments/production.sample.rb /var/www/discourse/config/environments/production.rb
```

### Start Thin as a daemon listening on domain sockets
```bash
$ cd /var/www/discourse
$ sudo -u www-data bundle exec thin start -e production -s4 --socket /var/www/discourse/tmp/sockets/thin.sock
```

### Start Sidekiq

```bash
$ sudo -u www-data bundle exec sidekiq -e production -d -l /var/www/discourse/log/sidekiq.log
```

### Create Discourse admin account

* Logon to site and create account using the application UI
* Now make that account the admin:

```bash
$ cd /var/www/discourse
$ sudo -u www-data bundle exec rails c production     
$ u = User.first    
$ u.admin = true    
$ u.save  
```
### Start thin using init.d (work in progress)

[Good explanation of the problems of using thin with init.d](http://jordanhollinger.com/2011/11/29/getting-bundler-and-thin-to-play-nicely)

```bash
$ sudo thin install
$ sudo /usr/sbin/update-rc.d -f thin defaults
```

Todo: add script to create the admin account

### Edit site settings
The default values are in: app/models/site_setting.rb
* Logon to site with the admin account
* Go to the site settings page: http://discoursetest.org/admin/site_settings
* Set the notification_email. It is the from address used in emails from the system. I set it to info@discoursetest.org.

### TODO
* I tried to avoid it, but I've come around to considering [RVM](http://ryanbigg.com/2010/12/ubuntu-ruby-rvm-rails-and-you/)
* Add clockwork instance
* Add script to create the admin account.
* Remove root ssh access
* Add more information about email configuration and start sidekiq when testing development installation. Should the admin account be set when testing the development server?
* Setup social network login (Is it possible to disable this feature?)
* Add Sam Saffron's Ruby GC tunings
* Add thin and sidekiq as init scripts. I find this cleaner than using bluepill
* Create chef script based on the installation procedure
* Lots of info on server configuration here: http://news.ycombinator.com/item?id=5316093
* Add redis 2.6
