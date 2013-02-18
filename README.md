# Overview

Discourse is the new [web discussion forum software](http://discourse.org) by Jeff Atwood, co-founder of StackOverflow. While I believe, based on the current
state of forum software, it is going to be a breakout success, it is still in a very early forum, and if you are not 
an expert on Linux and Rail administration, getting a Discourse site up and running can be dunting task.

While I consider myself to be moderately skilled at Linux administration, this is the first Rails app (I prefer Python myself) 
I have attempted to deploy and run, so now that I've been through the installation process a few times, I've decided to try
to more formally document it for others who want to try out the software.

# As

# Install Discourse on a DigitalOcean VPS
 

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
sudo -u postgres postgres

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
