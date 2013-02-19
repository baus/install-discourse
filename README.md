# Overview

Discourse is the new [web discussion forum software](http://discourse.org) by Jeff Atwood. Based on the current
state of forum software, I'm confident it is going to be a breakout success, but it is still in a very early state, 
and if you are not an expert on Linux and Rail administration, getting a Discourse site up and running can be 
dunting task.

While I consider myself to be moderately skilled at Linux administration, this is the first Rails app
(I prefer Python myself) I have attempted to deploy and run, so now that I've been through the installation 
process a few times, I've decided to try to more formally document it for others who want to try out the software.

# Install on a DigitalOcean VPS using Ubuntu 12.10x64

[DigitalOcean](https://www.digitalocean.com/) is offering very inexpensive VPS options based on SSDs. While their
offering isn't as proven as others including Linode, DigitalOcean is one of the least expensive hosting options 
available for Discourse, so I will start there.

# Provision your server

While I'm a long time RedHat and CentOS user, I've recently made the move to Ubuntu, primarily because they offer more 
update to date packages. With a project as cutting edge as Discourse, this makes installation easier as it prevents having
to download packages from source and install them, so my instructions with assume Ubuntu 12.10 x64 server (note:  with 
small RAM amounts, a 32bit image would probably work as well, but I'm standardizing on 64bit images). 

After createing your account at DigitalOcean, select the OS image you want, and DigitalOcean will email the root 
password to you.

# Login to your server

If you are using OS X or Linux, fire up a terminal ssh to your new server which be at the IP address that DigitialOcean 
has provided. Windows users should consider installing Putty to access your new server.

```bash
# From your local shell
~$ ssh root@<ip_addr>
# Enter your root password
```

# Change your roor password

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

The apt-get command is used to add packages to Ubuntu (and all Debian based). DigitalOcean, like many VPS's, ships
with a limited Ubuntu configuration, so you will have to install many of the software the dependencies yourself.

To install system packages, you have to have root privledges. Since the admin account is part of the sudo group, the
admin account can run commands with root privledges by using the sudo command. Just prepend sudo to any commands you
want to run as root. This includes apt-get commands to install packages.

```bash
# Install the Postgres sql server
admin@host:~# sudo apt-get install postgresql-9.1
# Install the Ruby language
admin@host:~# sudo apt-get install ruby1.9.3
# Install the Redis datastore
#
# Note: This installs redis 2.4. 
# Discourse explicitly states that they require Redis 2.6. This should be addressed, 
# and requires building redis from source.
admin@host:~# sudo apt-get install redis-server
# Install git to allow pulling Discourse source from github.
admin@host:~# sudo apt-get install git
```

# Configure Postgres user account

Like all the cool kids these days, Discourse uses the Postgres database as a datastore. The configuration procedure is
similar to MySQL, but I will admit that I am somewhat of a Postgres newbie, so I'm looking to improve this aspect of
the installation procedure.


- Postgres 9.1
 - Enable support for HSTORE
 - Create a discourse database and seed it with a basic image
- Redis 2.6
- Ruby 1.9.3
 - Install all rubygems via bundler
 - Edit database.yml and redis.yml and point them at your databases.
 - Prepackage all assets using rake
 - Run the Rails database migrations 
 - Run a sidekiq process for background jobs
 - Run a clockwork process for enqueing scheduled jobs
 - Run several Rails processes, preferably behind a proxy like Nginx.

```
git clone git@github.com:discourse/discourse.git
cd discourse
sudo bundle install
rake db:create
rake db:migrate
rake db:seed_fu
redis-cli flushall
thin start
```

# Set Rails configuration
export RAILS_ENV=development

# Ubuntu Dependencies (from fresh 12.10 install)
```
ruby1.9.3
git
redis-server
bundler
postgresql-contrib
libxml2-dev
libxslt-dev
libpq-dev
```

# configure database.yml
* Add username: 
* Add password: 

# Postgres cheatsheet

## login to db as root user
sudo -u postgres psql postgres

## show users
\du

## Create User
CREATE USER <name>;

## Change User Password
ALTER USER name PASSWORD 'password';

## Make user superuser
ALTER USER <name> WITH SUPERUSER;

## connect over TCP/IP
psql -h host -p port -U username -W password database
