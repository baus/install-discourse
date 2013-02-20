```
sudo apt-get install nginx

# Discourse Production Configuration
export RAILS_ENV=production

edit config/initializers/secrete_token.rb
sudo
sudo -u www-data cp -r discourse/ /var/www
sudo mkdir /var/www
sudo chown www-data /var/www
sudo chgrp www-data /var/www
sudo cp -r discourse /var/www/ 
sudo cp nginx.sample.conf /etc/nginx/sites-available/discourse.conf
sudo ln -s /etc/nginx/sites-available/discourse.conf /etc/nginx/sites-enabled/discourse.conf
sudo rm /etc/nginx/sites-enabled/default
sudo nginx start
```
