# Overview

# Setup the www-data account
```bash
sudo mkdir /var/www
sudo chgrp www-data /var/www
sudo chmod g+w /var/www
```
edit config/nginx.sample.conf

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

```
export RAILS_ENV=production
rake assets:precompile
edit config/initializers/secret_token.rb
sudo -u www-data cp -r discourse/ /var/www
sudo cp config/nginx.sample.conf /etc/nginx/sites-available/discourse.conf
sudo ln -s /etc/nginx/sites-available/discourse.conf /etc/nginx/sites-enabled/discourse.conf
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx start
sudo -u www-data mkdir /var/www/discourse/tmp/sockets
sudo -u www-data thin start -e production -s4 --socket /var/www/discourse/tmp/sockets/puma.sock
sudo -u www-data thin stop -e production -s4 --socket /var/www/discourse/tmp/sockets/puma.sock
```
